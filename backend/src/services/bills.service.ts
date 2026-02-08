import Flutterwave from 'flutterwave-node-v3';
import pool from '../config/database.ts';
import { NGN_USD_RATE } from '../config/limits.ts';

const flw = new Flutterwave(
  process.env.FLUTTERWAVE_PUBLIC_KEY!,
  process.env.FLUTTERWAVE_SECRET_KEY!
);

/** Bill payments via Flutterwave: Airtime, Data, Cable TV, Electricity */
class BillsService {
  /** Get bill categories (airtime, DSTV, electricity, etc.) for Nigeria */
  async getCategories() {
    const response = await flw.Bills.fetch_bills_Cat();
    if (response.status !== 'success') {
      throw new Error(response.message || 'Failed to fetch categories');
    }
    const data = response.data as Array<{ country?: string }>;
    // Filter to Nigeria only
    const ng = (data || []).filter((c: { country?: string }) => c.country === 'NG');
    return ng.length > 0 ? ng : data;
  }

  /** Validate customer (meter number, smartcard, phone) before payment */
  async validate(itemCode: string, billerCode: string, customer: string) {
    const response = await flw.Bills.validate({
      item_code: itemCode,
      code: billerCode,
      customer,
    });
    if (response.status !== 'success') {
      throw new Error(response.message || 'Validation failed');
    }
    return response.data;
  }

  /** Pay bill: deduct USDC, call Flutterwave, record transaction */
  async payBill(
    userId: number,
    customer: string,
    amount: number,
    type: string,
    reference: string
  ) {
    const balanceResult = await pool.query(
      'SELECT usdc_balance FROM wallets WHERE user_id = $1',
      [userId]
    );
    if (balanceResult.rows.length === 0) {
      throw new Error('Wallet not found');
    }

    const usdcBalance = parseFloat(String(balanceResult.rows[0].usdc_balance ?? 0)) || 0;
    const usdcRequired = amount / NGN_USD_RATE;

    if (usdcBalance < usdcRequired) {
      throw new Error('Insufficient USDC balance');
    }

    const payload = {
      country: 'NG',
      customer,
      amount,
      recurrence: 'ONCE',
      type: type.toUpperCase(),
      reference,
    };

    const response = await flw.Bills.create_bill(payload);

    if (response.status !== 'success') {
      throw new Error(response.message || 'Bill payment failed');
    }

    await pool.query(
      'UPDATE wallets SET usdc_balance = usdc_balance - $1, last_synced_at = NOW() WHERE user_id = $2',
      [usdcRequired, userId]
    );

    await pool.query(
      `INSERT INTO transactions (user_id, type, amount_naira, amount_usdc, status, reference)
       VALUES ($1, 'bill_payment', $2, $3, 'completed', $4)`,
      [userId, amount, usdcRequired, reference]
    );

    return {
      success: true,
      reference,
      amount,
      usdc_spent: usdcRequired,
      flw_ref: (response.data as { flw_ref?: string })?.flw_ref,
      tx_ref: (response.data as { tx_ref?: string })?.tx_ref,
    };
  }

  /** Get bill payment status */
  async getStatus(reference: string) {
    const response = await flw.Bills.fetch_status({ reference });
    if (response.status !== 'success') {
      throw new Error(response.message || 'Failed to fetch status');
    }
    return response.data;
  }
}

export default new BillsService();
