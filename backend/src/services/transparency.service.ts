import pool from '../config/database.ts';
import stellarService from '../services/stellar.service.ts';

const NGN_USD_RATE = Number(process.env.NGN_USD_RATE) || 1580;
const TREASURY_PUBLIC_KEY = process.env.TREASURY_PUBLIC_KEY;

export async function getTreasuryBalance(): Promise<{ xlm: number; usdc: number }> {
  if (!TREASURY_PUBLIC_KEY) {
    return { xlm: 0, usdc: 0 };
  }

  try {
    const balances = await stellarService.getBalance(TREASURY_PUBLIC_KEY, 3, true);
    const xlm = (balances as { asset_type: string; balance: string }[]).find((b) => b.asset_type === 'native');
    const usdc = (balances as { asset_type: string; asset_code?: string; balance: string }[]).find(
      (b) => b.asset_type !== 'native' && b.asset_code === 'USDC'
    );

    return {
      xlm: xlm ? parseFloat(xlm.balance) : 0,
      usdc: usdc ? parseFloat(usdc.balance) : 0
    };
  } catch {
    return { xlm: 0, usdc: 0 };
  }
}

export async function getTotalUserBalances(): Promise<number> {
  const result = await pool.query(
    'SELECT COALESCE(SUM(usdc_balance), 0)::numeric as total FROM wallets'
  );
  return parseFloat(result.rows[0]?.total || 0);
}

export async function getTransactionStats(): Promise<{
  totalTransactions: number;
  totalVolumeUsdc: number;
  totalVolumeNaira: number;
}> {
  const txResult = await pool.query(
    `SELECT COUNT(*) as cnt, COALESCE(SUM(amount_usdc), 0)::numeric as usdc_sum
     FROM transactions WHERE status = 'completed'`
  );
  const ngnResult = await pool.query(
    `SELECT COALESCE(SUM(amount_naira), 0)::numeric as ngn_sum
     FROM transactions WHERE type = 'deposit' AND status = 'completed'`
  );

  return {
    totalTransactions: parseInt(txResult.rows[0]?.cnt || 0, 10),
    totalVolumeUsdc: parseFloat(txResult.rows[0]?.usdc_sum || 0),
    totalVolumeNaira: parseFloat(ngnResult.rows[0]?.ngn_sum || 0)
  };
}

export async function getSavedFromDevaluation(): Promise<number> {
  const result = await pool.query(
    `SELECT COALESCE(SUM(amount_naira), 0)::numeric as total
     FROM transactions WHERE type = 'deposit' AND status = 'completed'`
  );
  return parseFloat(result.rows[0]?.total || 0);
}

export async function getPublicStats(): Promise<{
  treasuryUsdc: number;
  treasuryXlm: number;
  totalUserBalances: number;
  reservesRatio: number;
  totalTransactions: number;
  totalVolumeUsdc: number;
  totalSavedNaira: number;
  treasuryAddress: string;
}> {
  const [treasury, userBalances, txStats, savedNaira] = await Promise.all([
    getTreasuryBalance(),
    getTotalUserBalances(),
    getTransactionStats(),
    getSavedFromDevaluation()
  ]);

  const reservesRatio =
    treasury.usdc > 0 && userBalances > 0
      ? Math.round((treasury.usdc / userBalances) * 100)
      : 100;

  return {
    treasuryUsdc: treasury.usdc,
    treasuryXlm: treasury.xlm,
    totalUserBalances: userBalances,
    reservesRatio,
    totalTransactions: txStats.totalTransactions,
    totalVolumeUsdc: txStats.totalVolumeUsdc,
    totalSavedNaira: savedNaira,
    treasuryAddress: TREASURY_PUBLIC_KEY || ''
  };
}

export async function getRecentTransactions(limit = 10): Promise<
  Array<{
    type: string;
    amount_usdc: number;
    created_at: string;
  }>
> {
  const result = await pool.query(
    `SELECT type, amount_usdc, created_at
     FROM transactions
     WHERE status = 'completed' AND amount_usdc IS NOT NULL
     ORDER BY created_at DESC
     LIMIT $1`,
    [limit]
  );

  return result.rows.map((r) => ({
    type: r.type,
    amount_usdc: parseFloat(r.amount_usdc || 0),
    created_at: r.created_at
  }));
}

export default {
  getTreasuryBalance,
  getTotalUserBalances,
  getTransactionStats,
  getSavedFromDevaluation,
  getPublicStats,
  getRecentTransactions
};
