import * as StellarSdk from 'stellar-sdk';
import pool from '../config/database.ts';

const USDC_ISSUER = 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
const USDC_ASSET_CODE = 'USDC';

/** Monitor Stellar addresses for incoming USDC deposits (e.g. from Binance, Lobstr) */
class StellarMonitorService {
  private server: StellarSdk.Horizon.Server;
  private readonly isMainnet: boolean;
  private streams: Map<string, { close: () => void }> = new Map();

  constructor() {
    this.isMainnet = process.env.STELLAR_NETWORK !== 'testnet';
    const horizonUrl = this.isMainnet
      ? 'https://horizon.stellar.org'
      : 'https://horizon-testnet.stellar.org';
    this.server = new StellarSdk.Horizon.Server(horizonUrl);
  }

  /** Credit user's wallet when USDC is received on their Stellar address */
  private async creditUserUSDC(
    userId: number,
    amount: string,
    txHash: string
  ): Promise<void> {
    try {
      const existing = await pool.query(
        'SELECT id FROM transactions WHERE stellar_transaction_hash = $1',
        [txHash]
      );
      if (existing.rows.length > 0) {
        return; // Already processed
      }

      const amountNum = parseFloat(amount);
      if (amountNum < 0.01) return;

      await pool.query(
        `INSERT INTO transactions (user_id, type, amount_usdc, status, stellar_transaction_hash)
         VALUES ($1, 'deposit', $2, 'completed', $3)`,
        [userId, amountNum, txHash]
      );

      await pool.query(
        `UPDATE wallets SET usdc_balance = usdc_balance + $1, last_synced_at = NOW()
         WHERE user_id = $2`,
        [amountNum, userId]
      );

      console.log(`✅ Credited ${amount} USDC to user ${userId} (tx: ${txHash.slice(0, 8)}...)`);
    } catch (error) {
      console.error('Error crediting USDC:', error);
    }
  }

  /** Watch a user's address for incoming USDC payments */
  watchForUSDC(publicKey: string, userId: number): void {
    const key = `${publicKey}-${userId}`;
    if (this.streams.has(key)) return;

    const close = this.server
      .payments()
      .forAccount(publicKey)
      .cursor('now')
      .stream({
        onmessage: async (payment) => {
          if (payment.type !== 'payment') return;
          const p = payment as StellarSdk.Horizon.ServerApi.PaymentOperationRecord;
          if (p.to !== publicKey) return;

          const isUSDC =
            (p.asset_type === 'credit_alphanum4' || p.asset_type === 'credit_alphanum12') &&
            (p as { asset_code?: string; asset_issuer?: string }).asset_code === USDC_ASSET_CODE &&
            (p as { asset_issuer?: string }).asset_issuer === USDC_ISSUER;

          if (!isUSDC) return;

          await this.creditUserUSDC(
            userId,
            p.amount,
            p.transaction_hash
          );
        },
        onerror: (err) => {
          console.error(`Stellar stream error for ${publicKey}:`, err);
          this.streams.delete(key);
        },
      });

    this.streams.set(key, { close });
  }

  /** Start monitoring all users with Stellar addresses */
  async startMonitoring(): Promise<void> {
    const result = await pool.query(
      'SELECT id, stellar_public_key FROM users WHERE stellar_public_key IS NOT NULL'
    );

    for (const row of result.rows) {
      this.watchForUSDC(row.stellar_public_key, row.id);
    }

    console.log(`✅ Stellar monitor: watching ${result.rows.length} addresses for USDC deposits`);
  }

  /** Stop all streams */
  stop(): void {
    for (const [, { close }] of this.streams) {
      try {
        close();
      } catch (_) {}
    }
    this.streams.clear();
  }
}

const instance = new StellarMonitorService();
export default instance;
