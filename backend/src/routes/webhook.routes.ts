import { Router } from 'express';
import type { Request, Response } from 'express';
import pool from '../config/database.ts';

const router = Router();

// Health check endpoint (GET)
router.get('/flutterwave', (req: Request, res: Response) => {
  console.log('✅ GET /webhook/flutterwave - Health check called');
  res.json({ 
    status: 'ok', 
    message: 'Flutterwave webhook endpoint is active',
    timestamp: new Date().toISOString()
  });
});

// Flutterwave webhook endpoint (POST)
router.post('/flutterwave', async (req: Request, res: Response) => {
  try {
    console.log('\n🔔 ============================================');
    console.log('WEBHOOK RECEIVED FROM FLUTTERWAVE');
    console.log('============================================');
    console.log('Time:', new Date().toISOString());
    console.log('Headers:', JSON.stringify(req.headers, null, 2));
    console.log('Body:', JSON.stringify(req.body, null, 2));
    console.log('========================================\n');

    // Verify webhook signature
    const secretHash = process.env.FLUTTERWAVE_SECRET_HASH;
    const signature = req.headers['verif-hash'];

    if (!signature || signature !== secretHash) {
      console.log('❌ INVALID SIGNATURE!');
      return res.status(401).json({ error: 'Invalid signature' });
    }

    console.log('✅ Signature verified!');

    const payload = req.body;

    // Handle successful transfer to virtual account
    if (payload?.event === 'charge.completed' && payload?.data?.status === 'successful') {
      console.log('💰 PAYMENT SUCCESSFUL!');
      
      const { amount, customer, tx_ref, id } = payload.data;
      
      console.log('Amount:', amount);
      console.log('Customer:', customer.email);
      console.log('Reference:', tx_ref || id);

      // Find user by email
      const userResult = await pool.query(
        'SELECT id FROM users WHERE email = $1',
        [customer.email]
      );

      if (userResult.rows.length > 0) {
        const userId = userResult.rows[0].id;

        // Create pending deposit transaction
        const txResult = await pool.query(
          `INSERT INTO transactions (user_id, type, amount_naira, status, reference)
           VALUES ($1, 'deposit', $2, 'pending', $3)
           RETURNING id, amount_naira, status`,
          [userId, amount, tx_ref || id]
        );

        console.log('✅ TRANSACTION CREATED IN DATABASE:');
        console.log('Transaction ID:', txResult.rows[0].id);
        console.log('User ID:', userId);
        console.log('Amount:', txResult.rows[0].amount_naira);
        console.log('Status:', txResult.rows[0].status);
      } else {
        console.log('⚠️ USER NOT FOUND:', customer.email);
      }
    } else {
      console.log('ℹ️ Event type:', payload.event);
      console.log('ℹ️ Status:', payload.data?.status);
    }

    res.status(200).json({ status: 'success', message: 'Webhook processed' });
  } catch (error) {
    console.error('❌ WEBHOOK ERROR:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
