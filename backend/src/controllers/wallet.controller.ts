import type { Response } from 'express';
import pool from '../config/database.ts';
import stellarService from '../services/stellar.service.ts';
import flutterwaveService from '../services/flutterwave.service.ts';
import { encrypt, decrypt } from '../utils/encrypt.ts';
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
          usdc: parseFloat(String(wallet.usdc_balance ?? 0)) || 0
        },
        stellar_balance: stellarBalances,
        stellar_address: wallet.stellar_public_key
      });
    } catch (error) {
      console.error('Balance error:', error);
      res.status(500).json({ error: 'Failed to get balance' });
    }
  }

  // Submit BVN for static virtual account (required for permanent deposit accounts)
  async submitBvn(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { bvn } = req.body;

      if (!bvn || typeof bvn !== 'string') {
        return res.status(400).json({ error: 'BVN is required' });
      }

      const trimmed = bvn.trim().replace(/\s/g, '');
      if (!/^\d{11}$/.test(trimmed)) {
        return res.status(400).json({
          error: 'Invalid BVN. Must be exactly 11 digits.',
        });
      }

      const encrypted = encrypt(trimmed);

      await pool.query(
        'UPDATE users SET bvn_encrypted = $1, updated_at = NOW() WHERE id = $2',
        [encrypted, userId]
      );

      res.json({
        message: 'BVN saved successfully. You can now get your deposit account.',
      });
    } catch (error) {
      console.error('BVN submission error:', error);
      res.status(500).json({ error: 'Failed to save BVN' });
    }
  }

  // Get or create virtual account for NGN funding (requires BVN for static account)
  async getVirtualAccount(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;

      // Check if user already has a virtual account
      const existing = await pool.query(
        `SELECT account_number, account_name, bank_name 
         FROM virtual_accounts 
         WHERE user_id = $1`,
        [userId]
      );

      if (existing.rows.length > 0) {
        const va = existing.rows[0];
        return res.json({
          account_number: va.account_number,
          account_name: va.account_name,
          bank_name: va.bank_name,
        });
      }

      // Fetch user details including BVN
      const userResult = await pool.query(
        'SELECT phone_number, email, bvn_encrypted FROM users WHERE id = $1',
        [userId]
      );

      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }

      const user = userResult.rows[0];
      const email = user.email || `${user.phone_number}@klyng.ng`;
      const fullName = user.email ? user.email.split('@')[0] : `KLYNG ${user.phone_number}`;

      // Require BVN for static (permanent) account
      let bvn: string | undefined;
      if (user.bvn_encrypted) {
        try {
          bvn = decrypt(user.bvn_encrypted);
        } catch {
          return res.status(500).json({ error: 'Failed to read BVN. Please resubmit.' });
        }
      }

      if (!bvn) {
        return res.status(400).json({
          error: 'BVN required for deposit account',
          message: 'Please submit your BVN first to get a permanent deposit account. Call POST /api/wallet/bvn with { "bvn": "your_11_digit_bvn" }',
        });
      }

      const accountData = await flutterwaveService.createVirtualAccount(
        userId,
        email,
        user.phone_number,
        fullName,
        { bvn }
      );

      res.json({
        account_number: accountData.account_number,
        account_name: accountData.account_name || `KLYNG/${email}`,
        bank_name: accountData.bank_name || 'Wema Bank',
      });
    } catch (error) {
      console.error('Virtual account error:', error);
      res.status(500).json({ error: 'Failed to get virtual account' });
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