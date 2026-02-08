import pool from '../config/database.ts';

const REWARD_AMOUNT_USDC = 1;
const BONUS_5_REFERRALS_USDC = 2;
const MIN_DEPOSIT_NAIRA = 10_000;

function generateCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'STAKK-';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

export async function generateReferralCode(userId: number): Promise<string> {
  const existing = await pool.query(
    'SELECT code FROM referral_codes WHERE user_id = $1',
    [userId]
  );

  if (existing.rows.length > 0) {
    return existing.rows[0].code;
  }

  let code = generateCode();
  let attempts = 0;
  while (attempts < 10) {
    const dup = await pool.query('SELECT 1 FROM referral_codes WHERE code = $1', [code]);
    if (dup.rows.length === 0) break;
    code = generateCode();
    attempts++;
  }

  await pool.query(
    'INSERT INTO referral_codes (user_id, code) VALUES ($1, $2)',
    [userId, code]
  );

  return code;
}

export async function getUserReferralCode(userId: number): Promise<string | null> {
  const result = await pool.query(
    'SELECT code FROM referral_codes WHERE user_id = $1',
    [userId]
  );
  return result.rows[0]?.code ?? null;
}

export async function getOrCreateReferralCode(userId: number): Promise<string> {
  const existing = await getUserReferralCode(userId);
  if (existing) return existing;
  return generateReferralCode(userId);
}

export async function applyReferralCode(
  newUserId: number,
  code: string
): Promise<{ referrerId: number } | null> {
  const trimmed = code.trim().toUpperCase();
  if (!trimmed) return null;

  const referrerResult = await pool.query(
    'SELECT user_id FROM referral_codes WHERE code = $1',
    [trimmed]
  );

  if (referrerResult.rows.length === 0) return null;

  const referrerId = referrerResult.rows[0].user_id;
  if (referrerId === newUserId) return null;

  await pool.query(
    'UPDATE users SET referred_by_code = $1 WHERE id = $2',
    [trimmed, newUserId]
  );

  await pool.query(
    'INSERT INTO referrals (referrer_id, referred_user_id, status) VALUES ($1, $2, $3)',
    [referrerId, newUserId, 'pending']
  );

  return { referrerId };
}

export async function getReferralStats(userId: number): Promise<{
  code: string;
  totalReferred: number;
  pendingRewards: number;
  paidRewards: number;
  referrals: Array<{ referredUserId: number; status: string; createdAt: string }>;
}> {
  const code = await getOrCreateReferralCode(userId);

  const countResult = await pool.query(
    'SELECT COUNT(*) as cnt FROM referrals WHERE referrer_id = $1',
    [userId]
  );
  const totalReferred = parseInt(countResult.rows[0].cnt, 10);

  const pendingResult = await pool.query(
    `SELECT COUNT(*) as cnt FROM referrals
     WHERE referrer_id = $1 AND status = 'pending'`,
    [userId]
  );
  const pendingRewards = parseInt(pendingResult.rows[0].cnt, 10);

  const paidResult = await pool.query(
    `SELECT COALESCE(SUM(reward_amount), 0) as total FROM referrals
     WHERE referrer_id = $1 AND status = 'paid'`,
    [userId]
  );
  const paidRewards = parseFloat(paidResult.rows[0].total || 0);

  const refsResult = await pool.query(
    `SELECT r.referred_user_id, r.status, r.created_at
     FROM referrals r
     WHERE r.referrer_id = $1
     ORDER BY r.created_at DESC
     LIMIT 20`,
    [userId]
  );

  return {
    code,
    totalReferred,
    pendingRewards,
    paidRewards,
    referrals: refsResult.rows.map((r) => ({
      referredUserId: r.referred_user_id,
      status: r.status,
      createdAt: r.created_at
    }))
  };
}

export async function payReferralReward(referralId: number): Promise<void> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const refResult = await client.query(
      'SELECT * FROM referrals WHERE id = $1 AND status = $2 FOR UPDATE',
      [referralId, 'pending']
    );

    if (refResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return;
    }

    const ref = refResult.rows[0];
    const referrerId = ref.referrer_id;
    const reward = parseFloat(ref.reward_amount || REWARD_AMOUNT_USDC);

    const walletResult = await client.query(
      'SELECT usdc_balance FROM wallets WHERE user_id = $1 FOR UPDATE',
      [referrerId]
    );

    if (walletResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return;
    }

    await client.query(
      'UPDATE wallets SET usdc_balance = usdc_balance + $1, last_synced_at = NOW() WHERE user_id = $2',
      [reward, referrerId]
    );

    await client.query(
      "UPDATE referrals SET status = 'paid', paid_at = NOW() WHERE id = $1",
      [referralId]
    );

    await client.query(
      `INSERT INTO transactions (user_id, type, amount_usdc, status, reference)
       VALUES ($1, 'referral_reward', $2, 'completed', $3)`,
      [referrerId, reward, `REF-${referralId}`]
    );

    await client.query('COMMIT');

    try {
      await pool.query(
        `INSERT INTO notifications (user_id, type, title, message)
         VALUES ($1, 'referral_reward', $2, $3)`,
        [referrerId, 'Referral reward!', `You earned $${reward.toFixed(2)} USDC from a referral.`]
      );
    } catch {
      // notifications table may not exist
    }
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function checkAndPayReferralOnDeposit(
  userId: number,
  amountNaira: number
): Promise<void> {
  if (amountNaira < MIN_DEPOSIT_NAIRA) return;

  const userResult = await pool.query(
    'SELECT referred_by_code FROM users WHERE id = $1',
    [userId]
  );

  if (userResult.rows.length === 0 || !userResult.rows[0].referred_by_code) return;

  const refResult = await pool.query(
    `SELECT id FROM referrals
     WHERE referred_user_id = $1 AND status = 'pending'
     ORDER BY created_at ASC LIMIT 1`,
    [userId]
  );

  if (refResult.rows.length === 0) return;

  await payReferralReward(refResult.rows[0].id);
}

export async function getLeaderboard(limit = 10): Promise<
  Array<{
    rank: number;
    userId: number;
    totalReferred: number;
    totalEarned: number;
  }>
> {
  const result = await pool.query(
    `SELECT r.referrer_id as user_id,
            COUNT(*) as total_referred,
            COALESCE(SUM(CASE WHEN r.status = 'paid' THEN r.reward_amount ELSE 0 END), 0) as total_earned
     FROM referrals r
     GROUP BY r.referrer_id
     ORDER BY total_referred DESC, total_earned DESC
     LIMIT $1`,
    [limit]
  );

  return result.rows.map((row, i) => ({
    rank: i + 1,
    userId: row.user_id,
    totalReferred: parseInt(row.total_referred, 10),
    totalEarned: parseFloat(row.total_earned || 0)
  }));
}

export default {
  generateReferralCode,
  getUserReferralCode,
  getOrCreateReferralCode,
  applyReferralCode,
  getReferralStats,
  payReferralReward,
  checkAndPayReferralOnDeposit,
  getLeaderboard
};
