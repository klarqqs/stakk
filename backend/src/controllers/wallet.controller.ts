import type { Response } from 'express';
import pool from '../config/database.ts';
import stellarService from '../services/stellar.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class WalletController {
  // Get wallet balance
  async getBalance(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId;

      const result = await pool.query(
        `SELECT w.usdc_balance, u.stellar_public_key 
         FROM wallets w 
         JOIN users u ON w.user_id = u.id 
         WHERE w.user_id = $1`,
        [userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Wallet not found' });
      }

      const wallet = result.rows[0];

      // Get live balance from Stellar
      const stellarBalances = await stellarService.getBalance(wallet.stellar_public_key, 5, true);

      res.json({
        database_balance: {
          usdc: parseFloat(wallet.usdc_balance)
        },
        stellar_balance: stellarBalances,
        stellar_address: wallet.stellar_public_key
      });
    } catch (error) {
      console.error('Balance error:', error);
      res.status(500).json({ error: 'Failed to get balance' });
    }
  }

  // Get transaction history
  async getTransactions(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId;

      const result = await pool.query(
        `SELECT id, type, amount_naira, amount_usdc, status, created_at 
         FROM transactions 
         WHERE user_id = $1 
         ORDER BY created_at DESC 
         LIMIT 50`,
        [userId]
      );

      res.json({
        transactions: result.rows
      });
    } catch (error) {
      console.error('Transactions error:', error);
      res.status(500).json({ error: 'Failed to get transactions' });
    }
  }
}