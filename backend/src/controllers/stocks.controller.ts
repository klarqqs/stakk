import type { Response } from 'express';
import dinariService from '../services/dinari.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';
import pool from '../config/database.ts';

export class StocksController {
  /**
   * Get available stocks
   * GET /api/stocks/available
   */
  async getAvailableStocks(_req: AuthRequest, res: Response) {
    try {
      const data = await dinariService.getAvailableStocks();
      res.json({ stocks: data.stocks || data || [] });
    } catch (error: unknown) {
      console.error('Get available stocks error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to fetch stocks',
      });
    }
  }

  /**
   * Get stock details and price
   * GET /api/stocks/:ticker
   */
  async getStockDetails(req: AuthRequest, res: Response) {
    try {
      const { ticker } = req.params;
      if (!ticker) {
        return res.status(400).json({ error: 'Ticker is required' });
      }

      const [stockInfo, priceData] = await Promise.all([
        dinariService.getStock(ticker),
        dinariService.getPrice(ticker).catch(() => null), // Price might fail, continue with stock info
      ]);

      res.json({
        ...stockInfo,
        price: priceData,
      });
    } catch (error: unknown) {
      console.error('Get stock details error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to fetch stock details',
      });
    }
  }

  /**
   * Buy stock with USDC
   * POST /api/stocks/buy
   */
  async buyStock(req: AuthRequest, res: Response) {
    const client = await pool.connect();
    try {
      const userId = req.userId!;
      const { ticker, amountUSD } = req.body;

      if (!ticker || !amountUSD || Number(amountUSD) <= 0) {
        return res.status(400).json({ error: 'Invalid ticker or amount' });
      }

      const amount = Number(amountUSD);

      // Check user's USDC balance
      const balanceResult = await client.query(
        'SELECT usdc_balance, stellar_public_key FROM wallets WHERE user_id = $1 FOR UPDATE',
        [userId]
      );

      if (balanceResult.rows.length === 0) {
        return res.status(404).json({ error: 'Wallet not found' });
      }

      const currentBalance = parseFloat(balanceResult.rows[0].usdc_balance || '0');
      if (currentBalance < amount) {
        return res.status(400).json({ error: 'Insufficient USDC balance' });
      }

      const walletAddress = balanceResult.rows[0].stellar_public_key;
      if (!walletAddress) {
        return res.status(400).json({ error: 'Stellar wallet address not found' });
      }

      // Start transaction
      await client.query('BEGIN');

      // Place buy order with Dinari
      const order = await dinariService.buyStock({
        userId,
        ticker,
        amountUSD: amount,
        walletAddress,
      });

      // Deduct USDC from user's balance
      await client.query(
        'UPDATE wallets SET usdc_balance = usdc_balance - $1 WHERE user_id = $2',
        [amount, userId]
      );

      // Record trade in database
      await client.query(
        `INSERT INTO stock_trades (
          user_id, dinari_order_id, dinari_account_id, ticker, side, amount_usd, status, created_at
        ) VALUES ($1, $2, $3, $4, 'buy', $5, 'pending', NOW())`,
        [
          userId,
          order.id || order.order_id,
          order.account_id,
          ticker.toUpperCase(),
          amount,
        ]
      );

      await client.query('COMMIT');

      res.json({
        success: true,
        order,
        message: `Successfully purchased $${amount.toFixed(2)} of ${ticker.toUpperCase()}`,
      });
    } catch (error: unknown) {
      await client.query('ROLLBACK');
      console.error('Buy stock error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to buy stock',
      });
    } finally {
      client.release();
    }
  }

  /**
   * Get user's stock portfolio
   * GET /api/stocks/portfolio/mine
   */
  async getPortfolio(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;

      // Get user's Dinari account ID
      const userResult = await pool.query(
        'SELECT dinari_account_id FROM users WHERE id = $1',
        [userId]
      );

      const dinariAccountId = userResult.rows[0]?.dinari_account_id;

      if (!dinariAccountId) {
        return res.json({
          holdings: [],
          totalValue: 0,
          totalChange: 0,
          totalChangePercent: 0,
        });
      }

      const portfolio = await dinariService.getPortfolio(dinariAccountId);

      // Calculate total value if not provided
      const holdings = portfolio.holdings || portfolio.positions || [];
      const totalValue =
        portfolio.total_value ||
        holdings.reduce((sum: number, h: any) => sum + (h.total_value || h.value || 0), 0);

      res.json({
        holdings,
        totalValue,
        totalChange: portfolio.total_change || 0,
        totalChangePercent: portfolio.total_change_percent || 0,
      });
    } catch (error: unknown) {
      console.error('Get portfolio error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to fetch portfolio',
      });
    }
  }

  /**
   * Get trade history
   * GET /api/stocks/trades/history
   */
  async getTradeHistory(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;

      const trades = await pool.query(
        `SELECT 
          id,
          dinari_order_id,
          ticker,
          side,
          amount_usd,
          shares,
          price,
          fee,
          status,
          created_at,
          completed_at
        FROM stock_trades 
        WHERE user_id = $1 
        ORDER BY created_at DESC 
        LIMIT 50`,
        [userId]
      );

      res.json({ trades: trades.rows });
    } catch (error: unknown) {
      console.error('Get trade history error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to fetch trade history',
      });
    }
  }
}
