import type { Response } from 'express';
import pool from '../config/database.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class AdminController {
  // Get all pending deposits
  async getPendingDeposits(req: AuthRequest, res: Response) {
    try {
      const result = await pool.query(
        `SELECT t.id, t.amount_naira, t.reference, t.created_at,
                u.phone_number, u.email, u.stellar_public_key
         FROM transactions t
         JOIN users u ON t.user_id = u.id
         WHERE t.type = 'deposit' AND t.status = 'pending'
         ORDER BY t.created_at DESC`
      );

      res.json({ deposits: result.rows });
    } catch (error) {
      console.error('Error fetching deposits:', error);
      res.status(500).json({ error: 'Failed to fetch deposits' });
    }
  }

  // Process deposit (send USDC to user)
  async processDeposit(req: AuthRequest, res: Response) {
    try {
      const { transactionId, usdcAmount } = req.body;

      // Get transaction details
      const txResult = await pool.query(
        `SELECT t.*, u.stellar_public_key, u.stellar_secret_key_encrypted
         FROM transactions t
         JOIN users u ON t.user_id = u.id
         WHERE t.id = $1 AND t.status = 'pending'`,
        [transactionId]
      );

      if (txResult.rows.length === 0) {
        return res.status(404).json({ error: 'Transaction not found' });
      }

      const tx = txResult.rows[0];

      // TODO: Send USDC from your treasury wallet to user's wallet
      // For now, we'll update the database
      
      // Update transaction status
      await pool.query(
        `UPDATE transactions 
         SET status = 'completed', amount_usdc = $1, updated_at = NOW()
         WHERE id = $2`,
        [usdcAmount, transactionId]
      );

      // Update user's USDC balance
      await pool.query(
        `UPDATE wallets 
         SET usdc_balance = usdc_balance + $1, last_synced_at = NOW()
         WHERE user_id = $2`,
        [usdcAmount, tx.user_id]
      );

      res.json({ message: 'Deposit processed successfully' });
    } catch (error) {
      console.error('Error processing deposit:', error);
      res.status(500).json({ error: 'Failed to process deposit' });
    }
  }
}