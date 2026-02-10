import axios from 'axios';
import pool from '../config/database.ts';

/**
 * Dinari API Service for Tokenized Stock Trading
 * 
 * Integrates with Dinari API to enable users to buy/sell US stocks with USDC.
 * All trades are tokenized and backed 1:1 by real shares.
 */
class DinariService {
  private client: ReturnType<typeof axios.create>;
  private apiKeyId: string;
  private apiSecret: string;
  private entityId: string;
  private environment: string;

  constructor() {
    this.apiKeyId = process.env.DINARI_API_KEY_ID || '';
    this.apiSecret = process.env.DINARI_API_SECRET || '';
    this.entityId = process.env.DINARI_ENTITY_ID || '';
    this.environment = process.env.DINARI_ENVIRONMENT || 'sandbox';

    // Dinari API base URLs
    // Documentation: https://docs.dinari.com/reference/environments
    // Sandbox: https://api-enterprise.sandbox.dinari.com/api/v2
    // Live: https://api-enterprise.sbt.dinari.com/api/v2
    const baseURL =
      this.environment === 'production'
        ? 'https://api-enterprise.sbt.dinari.com/api/v2'
        : 'https://api-enterprise.sandbox.dinari.com/api/v2';

    this.client = axios.create({
      baseURL,
      headers: {
        'X-API-Key-Id': this.apiKeyId,
        'X-API-Secret-Key': this.apiSecret,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      timeout: 30000, // 30 seconds
    });
  }

  /**
   * Get list of available stocks
   */
  async getAvailableStocks() {
    try {
      // Dinari API v2 endpoint for stocks: /market_data/stocks/
      const response = await this.client.get('/market_data/stocks/');
      return response.data;
    } catch (error: any) {
      const errorMessage = error.response?.data?.error?.message ||
        error.response?.data?.message ||
        error.message ||
        'Failed to fetch available stocks';
      
      // Log full error details for debugging
      console.error('Dinari API error (getAvailableStocks):', {
        message: errorMessage,
        code: error.code,
        response: error.response?.data,
        url: error.config?.url,
        baseURL: error.config?.baseURL,
      });
      
      // If DNS error, suggest checking API URL
      if (error.code === 'ENOTFOUND' || error.message?.includes('getaddrinfo')) {
        throw new Error(
          `Dinari API connection failed. Check DINARI_ENVIRONMENT and API URL. ` +
          `Current baseURL: ${this.client.defaults.baseURL}. ` +
          `Error: ${errorMessage}`
        );
      }
      
      throw new Error(errorMessage);
    }
  }

  /**
   * Get stock details and current price
   */
  async getStock(ticker: string) {
    try {
      // Get stock details - using market_data endpoint
      const response = await this.client.get(`/market_data/stocks/?symbols=${ticker.toUpperCase()}`);
      const stocks = response.data || [];
      return stocks.length > 0 ? stocks[0] : null;
    } catch (error: any) {
      console.error(`Dinari API error (getStock ${ticker}):`, error.response?.data || error.message);
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        `Failed to fetch stock ${ticker}`
      );
    }
  }

  /**
   * Get current price for a stock
   */
  async getPrice(ticker: string) {
    try {
      // Get current stock price/quote
      const response = await this.client.get(`/market_data/stocks/${ticker.toUpperCase()}/quote`);
      return response.data;
    } catch (error: any) {
      console.error(`Dinari API error (getPrice ${ticker}):`, error.response?.data || error.message);
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        `Failed to fetch price for ${ticker}`
      );
    }
  }

  /**
   * Get wallet for an account
   */
  async getWallet(accountId: string) {
    try {
      const response = await this.client.get(`/accounts/${accountId}/wallet`);
      return response.data;
    } catch (error: any) {
      console.error('Dinari API error (getWallet):', error.response?.data || error.message);
      if (error.response?.status === 404) {
        return null; // Wallet not connected yet
      }
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        'Failed to get wallet'
      );
    }
  }

  /**
   * Connect wallet to account
   * For Stellar wallets, Dinari may handle them differently
   * Check Dinari docs for exact endpoint: POST /accounts/{account_id}/wallet/connect
   */
  async connectWallet(accountId: string, walletAddress: string, chainId?: string) {
    try {
      // For Stellar addresses, chain_id might be different or not needed
      // Try connecting with the wallet address
      const payload: any = {
        address: walletAddress,
      };
      
      // Add chain_id if provided (for EVM chains)
      // Stellar might use a different format or endpoint
      if (chainId) {
        payload.chain_id = chainId;
      }

      const response = await this.client.post(`/accounts/${accountId}/wallet/connect`, payload);
      return response.data;
    } catch (error: any) {
      // If wallet is already connected, that's okay
      if (error.response?.status === 409 || error.response?.status === 400) {
        console.log(`Wallet ${walletAddress} may already be connected to account ${accountId}`);
        return { address: walletAddress, connected: true };
      }
      
      console.error('Dinari API error (connectWallet):', error.response?.data || error.message);
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        'Failed to connect wallet'
      );
    }
  }

  /**
   * Get or create Dinari account for user and ensure wallet is connected
   */
  async getOrCreateAccount(userId: number, walletAddress?: string): Promise<string> {
    const client = await pool.connect();
    try {
      // Check if user already has a Dinari account
      // Handle case where column doesn't exist (migration not run yet)
      let dinariAccountId: string | null = null;
      try {
        const result = await client.query(
          'SELECT dinari_account_id FROM users WHERE id = $1',
          [userId]
        );
        dinariAccountId = result.rows[0]?.dinari_account_id || null;
      } catch (error: any) {
        // Column doesn't exist - migration hasn't run yet
        if (error?.code === '42703') {
          console.warn('dinari_account_id column does not exist - using entity ID as fallback');
          // Return entity ID as fallback until migration is run
          return this.entityId;
        }
        throw error;
      }

      if (dinariAccountId) {
        return dinariAccountId;
      }

      // For sandbox, use the shared account ID from Railway env vars
      // In production, you would create a new account via Dinari API: POST /entities/{entity_id}/accounts
      let accountId: string;
      if (this.environment === 'sandbox') {
        accountId = process.env.DINARI_SANDBOX_ACCOUNT_ID || this.entityId;
      } else {
        // In production, could create per-user accounts via API
        // For now, use entity ID as fallback
        accountId = this.entityId;
      }

      // Save account ID to user record (only if column exists)
      try {
        await client.query(
          'UPDATE users SET dinari_account_id = $1 WHERE id = $2',
          [accountId, userId]
        );
      } catch (error: any) {
        // Column doesn't exist - skip update, just return account ID
        if (error?.code === '42703') {
          console.warn('Cannot update dinari_account_id - column does not exist');
        } else {
          throw error;
        }
      }

      // Ensure wallet is connected to account if wallet address provided
      // This ensures users' Stellar wallets are properly linked to their Dinari accounts
      if (walletAddress) {
        try {
          const existingWallet = await this.getWallet(accountId);
          if (!existingWallet || existingWallet.address !== walletAddress) {
            // Wallet not connected or different address - connect it
            // Stellar addresses don't use chain_id in the same way as EVM
            // Dinari should handle Stellar addresses automatically
            try {
              await this.connectWallet(accountId, walletAddress);
              console.log(`✅ Connected Stellar wallet ${walletAddress} to Dinari account ${accountId}`);
            } catch (connectError: any) {
              // If connection fails, log but don't fail - wallet might already be connected
              // or Dinari might handle wallet connection differently
              console.warn(`Wallet connection note: ${connectError.message}`);
            }
          } else {
            console.log(`✅ Wallet ${walletAddress} already connected to account ${accountId}`);
          }
        } catch (walletError: any) {
          // If wallet check fails, log but continue - account is still valid
          // Wallet connection can be retried on next trade
          console.warn(`Wallet check note: ${walletError.message}`);
        }
      }

      return accountId;
    } finally {
      client.release();
    }
  }

  /**
   * Buy stock with USDC
   */
  async buyStock(params: {
    userId: number;
    ticker: string;
    amountUSD: number;
    walletAddress: string;
  }) {
    try {
      // Get or create account and ensure wallet is connected
      const accountId = await this.getOrCreateAccount(params.userId, params.walletAddress);

      // Place buy order with Dinari
      const orderResponse = await this.client.post('/orders', {
        account_id: accountId,
        symbol: params.ticker.toUpperCase(),
        side: 'buy',
        type: 'market',
        amount_usd: params.amountUSD,
        destination_address: params.walletAddress,
      });

      return orderResponse.data;
    } catch (error: any) {
      console.error('Dinari API error (buyStock):', error.response?.data || error.message);
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        'Failed to buy stock'
      );
    }
  }

  /**
   * Sell stock (get USDC back)
   */
  async sellStock(params: {
    userId: number;
    ticker: string;
    shares: number;
  }) {
    try {
      const accountId = await this.getOrCreateAccount(params.userId);

      const orderResponse = await this.client.post('/orders', {
        account_id: accountId,
        symbol: params.ticker.toUpperCase(),
        side: 'sell',
        type: 'market',
        quantity: params.shares,
      });

      return orderResponse.data;
    } catch (error: any) {
      console.error('Dinari API error (sellStock):', error.response?.data || error.message);
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        'Failed to sell stock'
      );
    }
  }

  /**
   * Get user's portfolio (stock holdings)
   */
  async getPortfolio(accountId: string) {
    try {
      // Dinari API endpoint: /accounts/{account_id}/portfolio
      const response = await this.client.get(`/accounts/${accountId}/portfolio`);
      return response.data;
    } catch (error: any) {
      console.error('Dinari API error (getPortfolio):', error.response?.data || error.message);
      // Return empty portfolio if account doesn't exist yet
      if (error.response?.status === 404) {
        return { holdings: [], total_value: 0 };
      }
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        'Failed to fetch portfolio'
      );
    }
  }

  /**
   * Get order history
   */
  async getOrderHistory(accountId: string) {
    try {
      const response = await this.client.get(`/accounts/${accountId}/orders`);
      return response.data;
    } catch (error: any) {
      console.error('Dinari API error (getOrderHistory):', error.response?.data || error.message);
      if (error.response?.status === 404) {
        return { orders: [] };
      }
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        'Failed to fetch order history'
      );
    }
  }

  /**
   * Get order status
   */
  async getOrderStatus(orderId: string) {
    try {
      const response = await this.client.get(`/orders/${orderId}`);
      return response.data;
    } catch (error: any) {
      console.error('Dinari API error (getOrderStatus):', error.response?.data || error.message);
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        'Failed to fetch order status'
      );
    }
  }
}

export default new DinariService();
