import pool from '../config/database.ts';
import notificationService from './notification.service.ts';

const P2P_FEE_USDC = Number(process.env.P2P_FEE_USDC) || 0;
const MIN_P2P_AMOUNT = 0.01;

interface User {
  id: number;
  phone_number: string;
  email: string | null;
  stellar_public_key: string;
}

export interface SearchResult {
  id: number;
  phone_number: string;
  email: string | null;
  displayName: string;
}

export interface P2PTransfer {
  id: number;
  sender_id: number;
  receiver_id: number | null;
  receiver_phone: string | null;
  receiver_email: string | null;
  amount_usdc: number;
  fee_usdc: number;
  status: string;
  note: string | null;
  created_at: Date;
  direction: 'sent' | 'received';
  other_user?: { phone_number: string; email: string | null };
}

async function findUserByPhoneOrEmail(identifier: string): Promise<User | null> {
  const trimmed = identifier.trim();
  const normalized = trimmed.toLowerCase();
  const isEmail = normalized.includes('@');

  let result;
  if (isEmail) {
    result = await pool.query(
      `SELECT id, phone_number, email, stellar_public_key FROM users WHERE LOWER(email) = $1`,
      [normalized]
    );
  } else {
    result = await pool.query(
      `SELECT id, phone_number, email, stellar_public_key FROM users 
       WHERE phone_number = $1 OR phone_number = $2`,
      [trimmed, normalized]
    );
  }

  if (result.rows.length === 0) return null;
  return result.rows[0];
}

export async function searchUser(query: string): Promise<SearchResult | null> {
  const user = await findUserByPhoneOrEmail(query);
  if (!user) return null;

  const displayName = user.email || user.phone_number;
  return {
    id: user.id,
    phone_number: user.phone_number,
    email: user.email,
    displayName: user.email || user.phone_number.replace(/(\d{4})\d+(\d{4})/, '$1***$2')
  };
}

export async function transferToUser(
  senderId: number,
  receiverIdentifier: string,
  amountUsdc: number,
  note?: string
): Promise<{ transferId: number; receiverName: string }> {
  if (amountUsdc < MIN_P2P_AMOUNT) {
    throw new Error('Minimum transfer amount is $0.01 USDC');
  }

  const receiver = await findUserByPhoneOrEmail(receiverIdentifier);
  if (!receiver) {
    throw new Error('User not found. Please check the phone number or email.');
  }

  if (receiver.id === senderId) {
    throw new Error('You cannot send money to yourself');
  }

  const totalDeduct = amountUsdc + P2P_FEE_USDC;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const senderWallet = await client.query(
      'SELECT usdc_balance FROM wallets WHERE user_id = $1 FOR UPDATE',
      [senderId]
    );
    if (senderWallet.rows.length === 0) {
      throw new Error('Wallet not found');
    }
    const balance = parseFloat(senderWallet.rows[0].usdc_balance);
    if (balance < totalDeduct) {
      throw new Error('Insufficient USDC balance');
    }

    await client.query(
      'UPDATE wallets SET usdc_balance = usdc_balance - $1, last_synced_at = NOW() WHERE user_id = $2',
      [totalDeduct, senderId]
    );

    await client.query(
      'UPDATE wallets SET usdc_balance = usdc_balance + $1, last_synced_at = NOW() WHERE user_id = $2',
      [amountUsdc, receiver.id]
    );

    const txResult = await client.query(
      `INSERT INTO transactions (user_id, type, amount_usdc, status, reference)
       VALUES ($1, 'p2p_sent', $2, 'completed', $3)`,
      [senderId, amountUsdc, `P2P-${Date.now()}-${senderId}`]
    );

    await client.query(
      `INSERT INTO transactions (user_id, type, amount_usdc, status, reference)
       VALUES ($1, 'p2p_received', $2, 'completed', $3)`,
      [receiver.id, amountUsdc, `P2P-${Date.now()}-${receiver.id}`]
    );

    const transferResult = await client.query(
      `INSERT INTO p2p_transfers 
       (sender_id, receiver_id, receiver_phone, receiver_email, amount_usdc, fee_usdc, status, note)
       VALUES ($1, $2, $3, $4, $5, $6, 'completed', $7)
       RETURNING id`,
      [
        senderId,
        receiver.id,
        receiver.phone_number,
        receiver.email,
        amountUsdc,
        P2P_FEE_USDC,
        note || null
      ]
    );

    await client.query('COMMIT');

    try {
      await notificationService.createNotification(
        receiver.id,
        'p2p_received',
        'You received USDC',
        `You received $${amountUsdc.toFixed(2)} USDC${note ? `: ${note}` : ''}`
      );
    } catch {
      // Notifications table may not exist
    }

    const receiverName = receiver.email || receiver.phone_number;
    return {
      transferId: transferResult.rows[0].id,
      receiverName
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function getUserTransferHistory(userId: number, limit = 50): Promise<P2PTransfer[]> {
  const result = await pool.query(
    `SELECT t.id, t.sender_id, t.receiver_id, t.receiver_phone, t.receiver_email,
            t.amount_usdc, t.fee_usdc, t.status, t.note, t.created_at,
            s.phone_number as sender_phone, s.email as sender_email,
            r.phone_number as receiver_phone_u, r.email as receiver_email_u
     FROM p2p_transfers t
     LEFT JOIN users s ON t.sender_id = s.id
     LEFT JOIN users r ON t.receiver_id = r.id
     WHERE t.sender_id = $1 OR t.receiver_id = $1
     ORDER BY t.created_at DESC
     LIMIT $2`,
    [userId, limit]
  );

  return result.rows.map((row) => {
    const isSent = row.sender_id === userId;
    return {
      id: row.id,
      sender_id: row.sender_id,
      receiver_id: row.receiver_id,
      receiver_phone: row.receiver_phone,
      receiver_email: row.receiver_email,
      amount_usdc: parseFloat(row.amount_usdc),
      fee_usdc: parseFloat(row.fee_usdc || 0),
      status: row.status,
      note: row.note,
      created_at: row.created_at,
      direction: isSent ? 'sent' : 'received',
      other_user: isSent
        ? { phone_number: row.receiver_phone_u, email: row.receiver_email_u }
        : { phone_number: row.sender_phone, email: row.sender_email }
    };
  });
}

export default {
  searchUser,
  transferToUser,
  getUserTransferHistory
};
