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
    // Try both possible env var names for API secret
    this.apiKeyId = process.env.DINARI_API_KEY_ID || '';
    this.apiSecret = process.env.DINARI_API_SECRET || process.env.DINARI_API_SECRET_KEY || '';
    this.entityId = process.env.DINARI_ENTITY_ID || '';
    this.environment = process.env.DINARI_ENVIRONMENT || 'sandbox';

    // Trim whitespace from credentials
    this.apiKeyId = this.apiKeyId.trim();
    this.apiSecret = this.apiSecret.trim();
    this.entityId = this.entityId.trim();

    // Validate credentials
    if (!this.apiKeyId || !this.apiSecret) {
      console.error('❌ Dinari API credentials missing!');
      console.error('   Required: DINARI_API_KEY_ID, DINARI_API_SECRET (or DINARI_API_SECRET_KEY)');
      console.error(`   API Key ID present: ${!!this.apiKeyId} (length: ${this.apiKeyId.length})`);
      console.error(`   API Secret present: ${!!this.apiSecret} (length: ${this.apiSecret.length})`);
      console.error(`   Checked: DINARI_API_SECRET=${!!process.env.DINARI_API_SECRET}, DINARI_API_SECRET_KEY=${!!process.env.DINARI_API_SECRET_KEY}`);
    } else {
      console.log('✅ Dinari API credentials loaded');
      console.log(`   Environment: ${this.environment}`);
      console.log(`   API Key ID: ${this.apiKeyId.substring(0, 8)}... (length: ${this.apiKeyId.length})`);
      console.log(`   API Secret: ***${this.apiSecret.substring(this.apiSecret.length - 4)} (length: ${this.apiSecret.length})`);
      console.log(`   Entity ID: ${this.entityId || 'not set'}`);
    }

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
      },
      timeout: 30000, // 30 seconds
    });

    // Add request interceptor to:
    // 1. Set Content-Type only for POST/PUT/PATCH requests
    // 2. Log request details for debugging
    this.client.interceptors.request.use(
      (config) => {
        // Set Content-Type only for POST/PUT/PATCH requests
        if (config.method && ['post', 'put', 'patch'].includes(config.method.toLowerCase())) {
          config.headers['Content-Type'] = 'application/json';
        }

        // Log request details (without exposing secrets)
        console.log('🔵 Dinari API Request:', {
          method: config.method?.toUpperCase(),
          url: config.url,
          baseURL: config.baseURL,
          headers: {
            'X-API-Key-Id': config.headers['X-API-Key-Id'] ? `${config.headers['X-API-Key-Id'].toString().substring(0, 8)}...` : 'missing',
            'X-API-Secret-Key': config.headers['X-API-Secret-Key'] ? '***present***' : 'missing',
            'Accept': config.headers['Accept'],
            'Content-Type': config.headers['Content-Type'] || 'not set',
          },
        });
        return config;
      },
      (error) => Promise.reject(error)
    );
  }

  /**
   * Get list of available stocks
   */
  async getAvailableStocks() {
    try {
      // Dinari API v2 endpoint for stocks: /market_data/stocks/
      // Verified working in Postman with trailing slash
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
        status: error.response?.status,
        statusText: error.response?.statusText,
        response: error.response?.data,
        url: error.config?.url,
        baseURL: error.config?.baseURL,
        headersSent: {
          'X-API-Key-Id': error.config?.headers?.['X-API-Key-Id'] ? 'present' : 'missing',
          'X-API-Secret-Key': error.config?.headers?.['X-API-Secret-Key'] ? 'present' : 'missing',
        },
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
   * Create a new Dinari account for an entity
   * POST /entities/{entity_id}/accounts
   */
  async createAccount(): Promise<string> {
    try {
      if (!this.entityId) {
        throw new Error('DINARI_ENTITY_ID must be set to create accounts');
      }

      console.log(`🔵 Creating new Dinari account for entity: ${this.entityId.substring(0, 8)}...`);
      
      const response = await this.client.post(`/entities/${this.entityId}/accounts`, {});
      
      const accountId = response.data.id || response.data.account_id || response.data.accountId;
      if (!accountId) {
        throw new Error('Account creation response missing account ID');
      }

      console.log(`✅ Created Dinari account: ${accountId.substring(0, 8)}...`);
      return accountId;
    } catch (error: any) {
      const errorData = error.response?.data || {};
      console.error('Dinari API error (createAccount):', {
        status: error.response?.status,
        error: errorData,
        message: error.message,
      });
      throw new Error(
        errorData.error?.message ||
        errorData.message ||
        'Failed to create Dinari account'
      );
    }
  }

  /**
   * Verify that an account exists in Dinari
   * Tries multiple endpoints to verify account existence
   */
  async verifyAccountExists(accountId: string): Promise<boolean> {
    try {
      // Try getting account details first - this should work for any account
      await this.client.get(`/accounts/${accountId}`);
      return true;
    } catch (error: any) {
      // If account details returns 404, try portfolio as fallback
      // (some accounts might only be accessible via portfolio)
      if (error.response?.status === 404) {
        try {
          await this.client.get(`/accounts/${accountId}/portfolio`);
          return true;
        } catch (portfolioError: any) {
          // Both endpoints returned 404 - account doesn't exist
          if (portfolioError.response?.status === 404) {
            console.warn(`Account ${accountId.substring(0, 8)}... not found (404 from both endpoints)`);
            return false;
          }
          // Other error - might be auth issue, assume exists
          return true;
        }
      }
      // For other errors (auth, network, etc.), assume account exists
      // This prevents false negatives due to temporary issues
      return true;
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
          console.warn('dinari_account_id column does not exist - will use shared account');
          // Fall through to use shared account
        } else {
          throw error;
        }
      }

      // Check if shared sandbox account is configured
      const sharedAccountId = process.env.DINARI_SANDBOX_ACCOUNT_ID;
      
      // If shared account is configured, always use it (trust it exists from dashboard)
      if (sharedAccountId && this.environment === 'sandbox') {
        // Clear any user-specific account ID to ensure we use shared account
        if (dinariAccountId && dinariAccountId !== sharedAccountId) {
          console.log(`ℹ️  Clearing user account ${dinariAccountId.substring(0, 8)}..., using shared account ${sharedAccountId.substring(0, 8)}...`);
          try {
            await client.query(
              'UPDATE users SET dinari_account_id = NULL WHERE id = $1',
              [userId]
            );
          } catch (error: any) {
            // Ignore errors
          }
        }
        // Use shared account - trust it exists (we know from dashboard)
        const accountId = sharedAccountId;
        console.log(`✅ Using shared sandbox account: ${accountId.substring(0, 8)}...`);
        
        // Connect wallet to shared account
        if (walletAddress) {
          try {
            const existingWallet = await this.getWallet(accountId);
            if (!existingWallet || existingWallet.address !== walletAddress) {
              console.log(`🔗 Connecting wallet ${walletAddress.substring(0, 8)}... to shared account...`);
              await this.connectWallet(accountId, walletAddress);
              console.log(`✅ Wallet connected to shared account`);
            } else {
              console.log(`✅ Wallet already connected to shared account`);
            }
          } catch (walletError: any) {
            // Wallet connection might fail for empty accounts - that's okay, will retry on trade
            console.warn(`⚠️  Wallet connection note: ${walletError.message}`);
            // Try connecting anyway (account might be empty)
            try {
              await this.connectWallet(accountId, walletAddress);
              console.log(`✅ Wallet connected after retry`);
            } catch (retryError: any) {
              console.warn(`⚠️  Wallet connection retry failed: ${retryError.message} - will retry on trade`);
            }
          }
        }
        
        // Save shared account ID to user record for reference
        try {
          await client.query(
            'UPDATE users SET dinari_account_id = $1 WHERE id = $2',
            [accountId, userId]
          );
        } catch (error: any) {
          // Column doesn't exist - skip
          if (error?.code !== '42703') {
            console.warn(`Cannot save account ID: ${error.message}`);
          }
        }
        
        return accountId;
      }
      
      // No shared account configured - use user's account or create new one
      if (dinariAccountId) {
        // User has account ID - verify it exists
        const accountExists = await this.verifyAccountExists(dinariAccountId);
        if (accountExists) {
          console.log(`✅ Using existing account: ${dinariAccountId.substring(0, 8)}...`);
          // Account exists - connect wallet if provided
          if (walletAddress) {
            try {
              const existingWallet = await this.getWallet(dinariAccountId);
              if (!existingWallet || existingWallet.address !== walletAddress) {
                console.log(`🔗 Connecting wallet to existing account...`);
                await this.connectWallet(dinariAccountId, walletAddress);
                console.log(`✅ Wallet connected to existing account`);
              }
            } catch (walletError: any) {
              console.warn(`⚠️  Wallet connection note for existing account: ${walletError.message}`);
            }
          }
          return dinariAccountId;
        } else {
          console.warn(`⚠️  Account ${dinariAccountId.substring(0, 8)}... not found in Dinari, clearing`);
          // Clear invalid account ID from database
          try {
            await client.query(
              'UPDATE users SET dinari_account_id = NULL WHERE id = $1',
              [userId]
            );
            console.log(`🗑️  Cleared invalid account ID from user ${userId}`);
          } catch (error: any) {
            if (error?.code !== '42703') {
              console.warn(`Failed to clear invalid account ID: ${error.message}`);
            }
          }
          // Will create new account below
        }
      }

      // For sandbox: Use shared account ID if set, otherwise create per-user accounts
      // For production: Create per-user accounts via API
      let accountId: string;
      
      if (this.environment === 'sandbox') {
        // Check if shared sandbox account is configured
        const sharedAccountId = process.env.DINARI_SANDBOX_ACCOUNT_ID;
        
        if (sharedAccountId) {
          // Use shared account - trust it exists if set in env vars
          // (verification might fail for empty accounts, but we know it exists from dashboard)
          accountId = sharedAccountId;
          console.log(`ℹ️  Using shared sandbox account: ${accountId.substring(0, 8)}...`);
          console.log(`ℹ️  Note: Account exists in Dinari dashboard, will connect wallet if needed`);
        } else {
          // No shared account configured - create per-user account
          console.log(`ℹ️  No shared sandbox account configured, creating per-user account`);
          accountId = await this.createAccount();
        }
      } else {
        // Production: Create per-user account
        console.log(`ℹ️  Production mode: Creating per-user account`);
        accountId = await this.createAccount();
      }

      // Save account ID to user record (only if column exists)
      try {
        await client.query(
          'UPDATE users SET dinari_account_id = $1 WHERE id = $2',
          [accountId, userId]
        );
        console.log(`✅ Saved account ID ${accountId.substring(0, 8)}... to user ${userId}`);
      } catch (error: any) {
        // Column doesn't exist - skip update, just return account ID
        if (error?.code === '42703') {
          console.warn('Cannot update dinari_account_id - column does not exist (run migration)');
        } else {
          throw error;
        }
      }

      // Connect wallet to account if provided
      // This is required for both sandbox and production accounts
      if (walletAddress) {
        try {
          const existingWallet = await this.getWallet(accountId);
          if (!existingWallet || existingWallet.address !== walletAddress) {
            // Wallet not connected or different address - connect it
            // Stellar addresses don't use chain_id in the same way as EVM
            // Dinari should handle Stellar addresses automatically
            try {
              console.log(`🔗 Connecting Stellar wallet ${walletAddress.substring(0, 8)}... to account ${accountId.substring(0, 8)}...`);
              await this.connectWallet(accountId, walletAddress);
              console.log(`✅ Connected Stellar wallet ${walletAddress.substring(0, 8)}... to Dinari account ${accountId.substring(0, 8)}...`);
            } catch (connectError: any) {
              // If connection fails, log but don't fail - wallet might already be connected
              // or Dinari might handle wallet connection differently
              console.warn(`⚠️  Wallet connection note: ${connectError.message}`);
              // Don't throw - account can still be used, wallet connection might not be required for all operations
            }
          } else {
            console.log(`✅ Wallet ${walletAddress.substring(0, 8)}... already connected to account ${accountId.substring(0, 8)}...`);
          }
        } catch (walletError: any) {
          // If wallet check fails, log but continue - account is still valid
          // Wallet connection can be retried on next trade
          console.warn(`⚠️  Wallet check note: ${walletError.message}`);
          // Try to connect anyway if wallet check failed
          if (walletError.response?.status === 404) {
            // Wallet endpoint not found - try connecting
            try {
              console.log(`🔗 Attempting to connect wallet after 404...`);
              await this.connectWallet(accountId, walletAddress);
              console.log(`✅ Successfully connected wallet after retry`);
            } catch (retryError: any) {
              console.warn(`⚠️  Wallet connection retry failed: ${retryError.message}`);
            }
          }
        }
      } else {
        console.log(`ℹ️  No wallet address provided, skipping wallet connection`);
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

      if (!accountId) {
        throw new Error('Dinari account ID is required. Please ensure DINARI_ENTITY_ID or DINARI_SANDBOX_ACCOUNT_ID is set.');
      }

      // Ensure wallet is connected before placing order (required for trading)
      // Retry wallet connection if needed
      let walletConnected = false;
      try {
        const existingWallet = await this.getWallet(accountId);
        if (existingWallet && existingWallet.address === params.walletAddress) {
          walletConnected = true;
          console.log(`✅ Wallet already connected to account ${accountId.substring(0, 8)}...`);
        }
      } catch (walletCheckError: any) {
        // Wallet check might fail for empty accounts - try connecting
        console.log(`ℹ️  Wallet check returned: ${walletCheckError.message}, attempting to connect...`);
      }

      if (!walletConnected) {
        try {
          console.log(`🔗 Connecting wallet ${params.walletAddress.substring(0, 8)}... to account ${accountId.substring(0, 8)}... before placing order`);
          await this.connectWallet(accountId, params.walletAddress);
          walletConnected = true;
          console.log(`✅ Wallet connected successfully`);
        } catch (connectError: any) {
          // If connection fails, log but continue - some accounts might work without explicit connection
          console.warn(`⚠️  Wallet connection failed: ${connectError.message}`);
          console.warn(`⚠️  Attempting to place order anyway - account might support trading without explicit wallet connection`);
        }
      }

      // Place buy order with Dinari
      // Dinari API v2 endpoint: POST /orders
      const orderPayload = {
        account_id: accountId,
        symbol: params.ticker.toUpperCase(),
        side: 'buy',
        type: 'market',
        amount_usd: params.amountUSD,
        destination_address: params.walletAddress,
      };

      console.log(`🔵 Placing buy order:`, {
        accountId: accountId,
        ticker: params.ticker.toUpperCase(),
        amountUSD: params.amountUSD,
        walletAddress: params.walletAddress.substring(0, 8) + '...',
        walletConnected: walletConnected,
        environment: this.environment,
      });

      const orderResponse = await this.client.post('/orders', orderPayload);

      console.log(`✅ Order placed successfully:`, {
        orderId: orderResponse.data?.id || orderResponse.data?.order_id,
        status: orderResponse.data?.status,
      });

      return orderResponse.data;
    } catch (error: any) {
      const errorData = error.response?.data || {};
      const statusCode = error.response?.status;
      const requestUrl = error.config?.url || '/orders';
      
      console.error('❌ Dinari API error (buyStock):', {
        status: statusCode,
        url: requestUrl,
        method: error.config?.method?.toUpperCase(),
        error: errorData,
        message: error.message,
        accountId: await this.getOrCreateAccount(params.userId, params.walletAddress).catch(() => 'unknown'),
        environment: this.environment,
        fullError: error.response ? JSON.stringify(error.response.data, null, 2) : error.message,
      });

      // Provide more specific error messages
      if (statusCode === 404) {
        const accountId = await this.getOrCreateAccount(params.userId, params.walletAddress).catch(() => 'unknown');
        throw new Error(
          `Account not found (404) when placing order. ` +
          `Account ID: ${accountId}. ` +
          `This might mean: 1) Account doesn't exist in Dinari, 2) Account needs wallet connected, 3) Account needs to be activated. ` +
          `Check Dinari dashboard to verify account ${accountId} exists and has a wallet connected.`
        );
      }

      throw new Error(
        errorData.error?.message ||
        errorData.message ||
        error.message ||
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
