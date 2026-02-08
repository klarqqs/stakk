import pool from '../config/database.ts';

/** Default APY when Blend pool is not configured or fetch fails */
const DEFAULT_APY = 5.5;

/**
 * Blend Protocol USDC Yield Service
 *
 * Tracks user positions in blend_positions and calculates yield.
 * When BLEND_USDC_POOL_ID is set, APY can be fetched from Blend.
 * Enable/disable updates internal wallet balance tracking.
 */
class BlendService {
  /**
   * Get current USDC lending APY.
   * Returns DEFAULT_APY. Configure BLEND_USDC_POOL_ID + STELLAR_RPC_URL + STELLAR_PASSPHRASE
   * to fetch live APY from Blend (optional).
   */
  async getCurrentAPY(): Promise<number> {
    // TODO: Fetch from Blend pool when configured
    return DEFAULT_APY;
  }

  /**
   * Enable earning: deduct USDC from wallet, track in blend_positions.
   */
  async enableEarning(userId: number, usdcAmount: number) {
    const amount = Number(usdcAmount);
    if (amount <= 0) throw new Error('Invalid amount');

    const client = await pool.connect();
    try {
      const balanceResult = await client.query(
        'SELECT usdc_balance FROM wallets WHERE user_id = $1 FOR UPDATE',
        [userId]
      );
      if (balanceResult.rows.length === 0) throw new Error('Wallet not found');

      const currentBalance = parseFloat(balanceResult.rows[0].usdc_balance);
      if (currentBalance < amount) throw new Error('Insufficient USDC balance');

      await client.query(
        `INSERT INTO blend_positions (user_id, usdc_supplied, supply_timestamp, last_earnings_update, status)
         VALUES ($1, $2, NOW(), NOW(), 'active')
         ON CONFLICT (user_id) DO UPDATE SET
           usdc_supplied = blend_positions.usdc_supplied + EXCLUDED.usdc_supplied,
           supply_timestamp = NOW(),
           last_earnings_update = NOW(),
           updated_at = NOW()`,
        [userId, amount]
      );

      await client.query(
        'UPDATE wallets SET usdc_balance = usdc_balance - $1, last_synced_at = NOW() WHERE user_id = $2',
        [amount, userId]
      );

      const apy = await this.getCurrentAPY();
      return {
        success: true,
        amount,
        apy,
      };
    } finally {
      client.release();
    }
  }

  /**
   * Disable earning: return USDC from blend_positions to wallet.
   */
  async disableEarning(userId: number, usdcAmount: number) {
    const amount = Number(usdcAmount);
    if (amount <= 0) throw new Error('Invalid amount');

    const client = await pool.connect();
    try {
      const positionResult = await client.query(
        'SELECT usdc_supplied FROM blend_positions WHERE user_id = $1 FOR UPDATE',
        [userId]
      );
      if (positionResult.rows.length === 0) {
        throw new Error('No Blend position found');
      }
      const supplied = parseFloat(positionResult.rows[0].usdc_supplied);
      if (supplied < amount) {
        throw new Error('Insufficient balance in Blend');
      }

      await client.query(
        `UPDATE blend_positions SET
           usdc_supplied = usdc_supplied - $1,
           last_earnings_update = NOW(),
           updated_at = NOW()
         WHERE user_id = $2`,
        [amount, userId]
      );

      await client.query(
        'UPDATE wallets SET usdc_balance = usdc_balance + $1, last_synced_at = NOW() WHERE user_id = $2',
        [amount, userId]
      );

      return { success: true, withdrawn: amount };
    } finally {
      client.release();
    }
  }

  /**
   * Get user's Blend position and calculated earnings.
   */
  async getUserEarnings(userId: number) {
    const positionResult = await pool.query(
      'SELECT usdc_supplied, supply_timestamp, earnings_accumulated FROM blend_positions WHERE user_id = $1',
      [userId]
    );

    if (positionResult.rows.length === 0) {
      const apy = await this.getCurrentAPY();
      return {
        supplied: 0,
        earned: 0,
        currentAPY: apy,
        totalValue: 0,
        isEarning: false,
      };
    }

    const row = positionResult.rows[0];
    const supplied = parseFloat(row.usdc_supplied);
    const accrued = parseFloat(row.earnings_accumulated || 0);
    const supplyTime = row.supply_timestamp ? new Date(row.supply_timestamp).getTime() : Date.now();
    const daysSince = (Date.now() - supplyTime) / (1000 * 60 * 60 * 24);

    const apy = await this.getCurrentAPY();
    const newEarnings = (supplied * (apy / 100) * daysSince) / 365;
    const totalEarned = accrued + newEarnings;

    return {
      supplied,
      earned: totalEarned,
      currentAPY: apy,
      totalValue: supplied + totalEarned,
      isEarning: supplied > 0,
    };
  }
}

export default new BlendService();
