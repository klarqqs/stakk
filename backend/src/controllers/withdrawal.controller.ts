import type { Response } from 'express';
import pool from '../config/database.ts';
import stellarService from '../services/stellar.service.ts';
import flutterwaveTransfer, { normalizeBankCode } from '../services/flutterwave-transfer.service.ts';
import { NGN_USD_RATE } from '../config/limits.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class WithdrawalController {
  /** Withdraw USDC to NGN bank account via Flutterwave */
  async withdrawToBank(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { accountNumber, bankCode, amountNGN } = req.body;

      if (!accountNumber || !bankCode || !amountNGN) {
        return res.status(400).json({
          error: 'accountNumber, bankCode, and amountNGN are required',
        });
      }

      const ngn = Number(amountNGN);
      if (ngn < 100 || !Number.isFinite(ngn)) {
        return res.status(400).json({ error: 'Invalid amount. Minimum 100 NGN.' });
      }

      const usdcAmount = ngn / NGN_USD_RATE;

      const walletRow = await pool.query(
        'SELECT usdc_balance FROM wallets WHERE user_id = $1',
        [userId]
      );
      if (walletRow.rows.length === 0) {
        return res.status(404).json({ error: 'Wallet not found' });
      }
      const balance = parseFloat(String(walletRow.rows[0].usdc_balance ?? 0)) || 0;
      if (balance < usdcAmount) {
        return res.status(400).json({ error: 'Insufficient balance' });
      }

      const accountData = await flutterwaveTransfer.resolveAccount(
        String(accountNumber).trim(),
        String(bankCode).trim()
      );
      const accountName = (accountData as { account_name?: string })?.account_name || 'Unknown';

      const reference = `STAKK-WD-${userId}-${Date.now()}`;

      await flutterwaveTransfer.sendToBank(
        String(accountNumber).trim(),
        String(bankCode).trim(),
        Math.round(ngn * 100) / 100,
        'Stakk Withdrawal',
        reference
      );

      await pool.query(
        'UPDATE wallets SET usdc_balance = usdc_balance - $1 WHERE user_id = $2',
        [usdcAmount, userId]
      );

      await pool.query(
        `INSERT INTO transactions (user_id, type, amount_naira, amount_usdc, status, reference)
         VALUES ($1, 'withdrawal', $2, $3, 'completed', $4)`,
        [userId, ngn, usdcAmount, reference]
      );

      res.json({
        message: 'Withdrawal initiated',
        accountName,
        amountNGN: ngn,
        usdcDeducted: usdcAmount,
        reference,
      });
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : 'Withdrawal failed';
      console.error('Withdraw to bank error:', error);
      res.status(500).json({ error: msg });
    }
  }

  /** Withdraw USDC to another Stellar wallet */
  async withdrawToUSDC(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { stellarAddress, amountUSDC } = req.body;

      if (!stellarAddress || !amountUSDC) {
        return res.status(400).json({
          error: 'stellarAddress and amountUSDC are required',
        });
      }

      const amount = parseFloat(String(amountUSDC));
      if (amount < 0.01 || !Number.isFinite(amount)) {
        return res.status(400).json({ error: 'Invalid amount. Minimum 0.01 USDC.' });
      }

      const addr = String(stellarAddress).trim();
      if (addr.length < 20 || !addr.startsWith('G')) {
        return res.status(400).json({ error: 'Invalid Stellar address' });
      }

      const result = await pool.query(
        `SELECT w.usdc_balance, u.stellar_secret_key_encrypted
         FROM wallets w
         JOIN users u ON w.user_id = u.id
         WHERE w.user_id = $1`,
        [userId]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Wallet not found' });
      }

      const balance = parseFloat(String(result.rows[0].usdc_balance ?? 0)) || 0;
      if (balance < amount) {
        return res.status(400).json({ error: 'Insufficient balance' });
      }

      const secretB64 = result.rows[0].stellar_secret_key_encrypted;
      if (!secretB64) {
        return res.status(500).json({ error: 'Wallet key not found' });
      }
      const userSecretKey = Buffer.from(secretB64, 'base64').toString('utf8');

      await stellarService.sendUSDCFromUser(userSecretKey, addr, amount.toFixed(2));

      await pool.query(
        'UPDATE wallets SET usdc_balance = usdc_balance - $1 WHERE user_id = $2',
        [amount, userId]
      );

      await pool.query(
        `INSERT INTO transactions (user_id, type, amount_usdc, status)
         VALUES ($1, 'withdrawal', $2, 'completed')`,
        [userId, amount]
      );

      res.json({
        message: 'USDC sent successfully',
        amount,
        recipient: addr,
      });
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : 'Withdrawal failed';
      console.error('Withdraw to USDC error:', error);
      res.status(500).json({ error: msg });
    }
  }

  /** Resolve bank account to fetch account name (validate before withdrawal) */
  async resolveAccount(req: AuthRequest, res: Response) {
    try {
      const { accountNumber, bankCode } = req.body;
      if (!accountNumber || !bankCode) {
        return res.status(400).json({
          error: 'accountNumber and bankCode are required',
        });
      }
      const account = String(accountNumber).trim();
      if (account.length !== 10) {
        return res.status(400).json({ error: 'Account number must be 10 digits' });
      }
      const code = String(bankCode).trim();
      const accountData = await flutterwaveTransfer.resolveAccount(account, code);
      const accountName = (accountData as { account_name?: string })?.account_name || 'Unknown';
      res.json({ accountName });
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : 'Account resolution failed';
      console.error('Resolve account error:', {
        accountNumber: req.body?.accountNumber,
        bankCode: req.body?.bankCode,
        error: msg,
        fullError: error,
      });
      res.status(400).json({ error: msg });
    }
  }

  /** Get list of Nigerian banks for transfers */
  async getBanks(_req: AuthRequest, res: Response) {
    try {
      const raw = await flutterwaveTransfer.getBanks();
      const banks = (Array.isArray(raw) ? raw : []).map((b: { id?: number; code?: string; name?: string }) => ({
        id: b.id,
        code: normalizeBankCode(b.code ?? b.id),
        name: b.name ?? '',
      }));
      res.json({ banks });
    } catch (error) {
      console.error('Get banks error:', error);
      res.status(500).json({ error: 'Failed to fetch banks' });
    }
  }
}
