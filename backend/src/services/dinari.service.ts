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

    const baseURL =
      this.environment === 'production'
        ? 'https://api.dinari.com'
        : 'https://api.sandbox.dinari.com';

    this.client = axios.create({
      baseURL,
      headers: {
        'X-Api-Key-Id': this.apiKeyId,
        'X-Api-Secret': this.apiSecret,
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
      const response = await this.client.get('/v1/stocks');
      return response.data;
    } catch (error: any) {
      console.error('Dinari API error (getAvailableStocks):', error.response?.data || error.message);
      throw new Error(
        error.response?.data?.error?.message ||
        error.response?.data?.message ||
        'Failed to fetch available stocks'
      );
    }
  }

  /**
   * Get stock details and current price
   */
  async getStock(ticker: string) {
    try {
      const response = await this.client.get(`/v1/stocks/${ticker.toUpperCase()}`);
      return response.data;
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
      const response = await this.client.get(`/v1/stocks/${ticker.toUpperCase()}/price`);
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
   * Get or create Dinari account for user
   */
  async getOrCreateAccount(userId: number): Promise<string> {
    const client = await pool.connect();
    try {
      // Check if user already has a Dinari account
      const result = await client.query(
        'SELECT dinari_account_id FROM users WHERE id = $1',
        [userId]
      );

      if (result.rows.length > 0 && result.rows[0].dinari_account_id) {
        return result.rows[0].dinari_account_id;
      }

      // For sandbox, use the shared account ID
      // In production, you would create a new account via Dinari API
      const accountId = this.environment === 'sandbox'
        ? process.env.DINARI_SANDBOX_ACCOUNT_ID || this.entityId
        : this.entityId; // In production, create per-user accounts

      // Save account ID to user record
      await client.query(
        'UPDATE users SET dinari_account_id = $1 WHERE id = $2',
        [accountId, userId]
      );

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
      const accountId = await this.getOrCreateAccount(params.userId);

      // Place buy order with Dinari
      const orderResponse = await this.client.post('/v1/orders', {
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

      const orderResponse = await this.client.post('/v1/orders', {
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
      const response = await this.client.get(`/v1/accounts/${accountId}/positions`);
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
      const response = await this.client.get(`/v1/accounts/${accountId}/orders`);
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
      const response = await this.client.get(`/v1/orders/${orderId}`);
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
