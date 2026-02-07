import { Router } from 'express';
import type { Request, Response } from 'express';
import pool from '../config/database.ts';
import stellarService from '../services/stellar.service.ts';
import { DEPOSIT_LIMITS, NGN_USD_RATE, DEPOSIT_FEE_RATE } from '../config/limits.ts';

const router = Router();
const isProd = process.env.NODE_ENV === 'production';

// Health check endpoint (GET)
router.get('/flutterwave', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    message: 'Flutterwave webhook endpoint is active',
    timestamp: new Date().toISOString()
  });
});

// Flutterwave webhook endpoint (POST)
router.post('/flutterwave', async (req: Request, res: Response) => {
  try {
    if (!isProd) {
      console.log('🔔 Flutterwave webhook received');
    }

    const secretHash = process.env.FLUTTERWAVE_SECRET_HASH;
    const signature = req.headers['verif-hash'];

    if (!signature || signature !== secretHash) {
      if (!isProd) console.log('❌ Invalid signature');
      return res.status(401).json({ error: 'Invalid signature' });
    }

    const payload = req.body;

    if (payload?.event !== 'charge.completed' || payload?.data?.status !== 'successful') {
      return res.status(200).json({ status: 'success', message: 'Webhook processed' });
    }

    const { amount, customer, tx_ref, id } = payload.data;
    const ref = String(id || tx_ref || '');

    // Idempotency: skip if already processed (use Flutterwave tx id)
    const existing = await pool.query(
      'SELECT id, status FROM transactions WHERE reference = $1',
      [ref]
    );
    if (existing.rows.length > 0 && existing.rows[0].status === 'completed') {
      return res.status(200).json({ status: 'success', message: 'Already processed' });
    }

    // Parse userId from tx_ref (KLYNG-{userId}-{timestamp})
    let userId: number | null = null;
    const txRefStr = String(tx_ref || '');
    const txRefParts = txRefStr.split('-');
    if (txRefParts[0] === 'KLYNG' && txRefParts[1]) {
      userId = parseInt(txRefParts[1], 10);
    }

    // Fallback: find by email
    if (!userId && customer?.email) {
      const userResult = await pool.query(
        'SELECT id FROM users WHERE email = $1',
        [customer.email]
      );
      userId = userResult.rows[0]?.id ?? null;
    }

    if (!userId) {
      if (!isProd) console.log('⚠️ User not found for ref:', ref);
      return res.status(200).json({ status: 'success', message: 'Webhook processed' });
    }

    const amountNaira = Number(amount) || 0;

    // Apply deposit limits
    if (amountNaira > DEPOSIT_LIMITS.MAX_PER_DEPOSIT) {
      await pool.query(
        `INSERT INTO transactions (user_id, type, amount_naira, status, reference)
         VALUES ($1, 'deposit', $2, 'failed', $3)`,
        [userId, amountNaira, ref]
      );
      if (!isProd) console.log('❌ Deposit exceeds limit:', amountNaira);
      return res.status(200).json({ status: 'success', message: 'Webhook processed' });
    }

    const userTotalResult = await pool.query(
      `SELECT COALESCE(SUM(amount_naira), 0)::numeric as total
       FROM transactions WHERE user_id = $1 AND type = 'deposit' AND status = 'completed'`,
      [userId]
    );
    const userTotal = Number(userTotalResult.rows[0]?.total || 0);
    if (userTotal + amountNaira > DEPOSIT_LIMITS.MAX_PER_USER) {
      await pool.query(
        `INSERT INTO transactions (user_id, type, amount_naira, status, reference)
         VALUES ($1, 'deposit', $2, 'failed', $3)`,
        [userId, amountNaira, ref]
      );
      if (!isProd) console.log('❌ User deposit limit exceeded');
      return res.status(200).json({ status: 'success', message: 'Webhook processed' });
    }

    // Create pending transaction
    const txResult = await pool.query(
      `INSERT INTO transactions (user_id, type, amount_naira, status, reference)
       VALUES ($1, 'deposit', $2, 'pending', $3)
       RETURNING id`,
      [userId, amountNaira, ref]
    );

    const txId = txResult.rows[0]?.id;
    if (!txId) {
      return res.status(200).json({ status: 'success', message: 'Webhook processed' });
    }

    // Get user's Stellar address
    const userRow = await pool.query(
      'SELECT stellar_public_key FROM users WHERE id = $1',
      [userId]
    );
    const stellarPublicKey = userRow.rows[0]?.stellar_public_key;

    if (!stellarPublicKey) {
      await pool.query(
        'UPDATE transactions SET status = $1 WHERE id = $2',
        ['failed', txId]
      );
      return res.status(200).json({ status: 'success', message: 'Webhook processed' });
    }

    // Convert NGN to USDC (after fee)
    const amountAfterFee = amountNaira * (1 - DEPOSIT_FEE_RATE);
    const amountUsd = amountAfterFee / NGN_USD_RATE;
    const amountUsdc = Math.floor(amountUsd * 100) / 100; // 2 decimals

    if (amountUsdc < 0.01) {
      await pool.query(
        'UPDATE transactions SET status = $1 WHERE id = $2',
        ['failed', txId]
      );
      return res.status(200).json({ status: 'success', message: 'Webhook processed' });
    }

    try {
      const txHash = await stellarService.sendUSDC(
        stellarPublicKey,
        amountUsdc.toFixed(2)
      );

      await pool.query(
        `UPDATE transactions SET status = 'completed', amount_usdc = $1, stellar_transaction_hash = $2 WHERE id = $3`,
        [amountUsdc, txHash, txId]
      );

      await pool.query(
        `UPDATE wallets SET usdc_balance = usdc_balance + $1, last_synced_at = NOW() WHERE user_id = $2`,
        [amountUsdc, userId]
      );

      if (!isProd) {
        console.log(`✅ Deposit completed: ${amountUsdc} USDC to user ${userId}`);
      }
    } catch (sendError) {
      console.error('USDC send failed:', sendError);
      await pool.query(
        'UPDATE transactions SET status = $1 WHERE id = $2',
        ['failed', txId]
      );
    }

    res.status(200).json({ status: 'success', message: 'Webhook processed' });
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
