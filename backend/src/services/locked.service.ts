import pool from '../config/database.ts';

const APY_BY_DAYS: Record<number, number> = {
  30: 8,
  60: 10,
  90: 12
};

export interface LockedSavings {
  id: number;
  user_id: number;
  amount_usdc: number;
  lock_duration: number;
  apy_rate: number;
  start_date: Date;
  maturity_date: Date;
  status: string;
  interest_earned: number;
  auto_renew: boolean;
}

export function getLockedSavingsAPY(durationDays: number): number {
  return APY_BY_DAYS[durationDays] ?? 8;
}

export async function createLockedSavings(
  userId: number,
  amount: number,
  durationDays: number,
  autoRenew: boolean = false
): Promise<LockedSavings> {
  if (![30, 60, 90].includes(durationDays)) {
    throw new Error('Lock duration must be 30, 60, or 90 days');
  }

  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }

  const apy = getLockedSavingsAPY(durationDays);
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const walletResult = await client.query(
      'SELECT usdc_balance FROM wallets WHERE user_id = $1 FOR UPDATE',
      [userId]
    );

    if (walletResult.rows.length === 0) {
      throw new Error('Wallet not found');
    }

    const balance = parseFloat(walletResult.rows[0].usdc_balance);
    if (balance < amount) {
      throw new Error('Insufficient USDC balance');
    }

    const maturityDate = new Date();
    maturityDate.setDate(maturityDate.getDate() + durationDays);

    await client.query(
      'UPDATE wallets SET usdc_balance = usdc_balance - $1, last_synced_at = NOW() WHERE user_id = $2',
      [amount, userId]
    );

    const result = await client.query(
      `INSERT INTO locked_savings (user_id, amount_usdc, lock_duration, apy_rate, maturity_date, auto_renew)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [userId, amount, durationDays, apy, maturityDate, autoRenew]
    );

    await client.query(
      `INSERT INTO transactions (user_id, type, amount_usdc, status, reference)
       VALUES ($1, 'locked_savings', $2, 'completed', $3)`,
      [userId, amount, `LOCK-${Date.now()}`]
    );

    await client.query('COMMIT');
    return result.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function getUserLockedSavings(userId: number): Promise<LockedSavings[]> {
  const result = await pool.query(
    `SELECT * FROM locked_savings
     WHERE user_id = $1
     ORDER BY start_date DESC`,
    [userId]
  );

  return result.rows.map((row) => ({
    ...row,
    amount_usdc: parseFloat(row.amount_usdc),
    interest_earned: parseFloat(row.interest_earned || 0)
  }));
}

export function calculateInterest(amount: number, apy: number, daysElapsed: number): number {
  return (amount * (apy / 100) * daysElapsed) / 365;
}

export async function withdrawMatured(userId: number, lockId: number): Promise<LockedSavings> {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const lockResult = await client.query(
      'SELECT * FROM locked_savings WHERE id = $1 AND user_id = $2 FOR UPDATE',
      [lockId, userId]
    );

    if (lockResult.rows.length === 0) {
      throw new Error('Lock not found');
    }

    const lock = lockResult.rows[0];
    if (lock.status !== 'active') {
      throw new Error('Lock is not active');
    }

    const maturityDate = new Date(lock.maturity_date);
    if (new Date() < maturityDate) {
      throw new Error('Lock has not matured yet');
    }

    const amount = parseFloat(lock.amount_usdc);
    const startDate = new Date(lock.start_date);
    const daysElapsed = Math.floor((maturityDate.getTime() - startDate.getTime()) / (24 * 60 * 60 * 1000));
    const interest = calculateInterest(amount, parseFloat(lock.apy_rate), daysElapsed);
    const total = amount + interest;

    await client.query(
      'UPDATE wallets SET usdc_balance = usdc_balance + $1, last_synced_at = NOW() WHERE user_id = $2',
      [total, userId]
    );

    await client.query(
      "UPDATE locked_savings SET status = 'withdrawn', interest_earned = $1 WHERE id = $2",
      [interest, lockId]
    );

    await client.query(
      `INSERT INTO transactions (user_id, type, amount_usdc, status, reference)
       VALUES ($1, 'locked_withdrawal', $2, 'completed', $3)`,
      [userId, total, `LOCK-WD-${lockId}`]
    );

    await client.query('COMMIT');

    const updated = await pool.query('SELECT * FROM locked_savings WHERE id = $1', [lockId]);
    return updated.rows[0];
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export async function processMaturedDeposits(): Promise<void> {
  const result = await pool.query(
    `SELECT * FROM locked_savings
     WHERE status = 'active' AND maturity_date <= NOW()`
  );

  for (const lock of result.rows) {
    try {
      await withdrawMatured(lock.user_id, lock.id);
      if (lock.auto_renew) {
        await createLockedSavings(
          lock.user_id,
          parseFloat(lock.amount_usdc),
          lock.lock_duration,
          true
        );
      }
    } catch (err) {
      console.error('Process matured lock failed', lock.id, err);
    }
  }
}

export async function getAPYRates(): Promise<{ duration: number; apy: number }[]> {
  return [
    { duration: 30, apy: APY_BY_DAYS[30] },
    { duration: 60, apy: APY_BY_DAYS[60] },
    { duration: 90, apy: APY_BY_DAYS[90] }
  ];
}

export default {
  createLockedSavings,
  getUserLockedSavings,
  withdrawMatured,
  getLockedSavingsAPY,
  getAPYRates,
  calculateInterest,
  processMaturedDeposits
};
