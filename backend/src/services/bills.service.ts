import Flutterwave from 'flutterwave-node-v3';
import pool from '../config/database.ts';
import { NGN_USD_RATE } from '../config/limits.ts';

const FLW_BASE = 'https://api.flutterwave.com/v3';
const SECRET_KEY = process.env.FLUTTERWAVE_SECRET_KEY;

const flw = new Flutterwave(
  process.env.FLUTTERWAVE_PUBLIC_KEY!,
  SECRET_KEY!
);

/** Biller shape from Flutterwave (bill-categories or billers response) */
interface BillerItem {
  id?: number;
  biller_code?: string;
  code?: string;
  name?: string;
  biller_name?: string;
  item_code?: string;
  short_name?: string;
  label_name?: string;
  is_airtime?: boolean;
  country?: string;
  country_code?: string;
}

/** Normalize to format expected by mobile (BillCategory) */
function toBillCategory(item: BillerItem, index: number): Record<string, unknown> {
  const code = item.biller_code ?? item.code ?? '';
  const shortName = item.short_name ?? item.name ?? '';
  const billerName = item.biller_name ?? item.name ?? '';
  const itemCode = item.item_code ?? 'AT099';
  const labelName = item.label_name ?? 'Mobile Number';
  const isAirtime = item.is_airtime ?? false;
  return {
    id: item.id ?? index + 1,
    biller_code: code,
    name: item.name ?? shortName,
    biller_name: billerName,
    item_code: itemCode,
    short_name: shortName,
    label_name: labelName,
    is_airtime: isAirtime,
    country: item.country ?? item.country_code ?? 'NG',
  };
}

/** Direct HTTP fetch to Flutterwave (bypass SDK for resilience) */
async function flwFetch<T>(path: string): Promise<T> {
  const res = await fetch(`${FLW_BASE}${path}`, {
    headers: { Authorization: `Bearer ${SECRET_KEY}` },
  });
  return (await res.json()) as T;
}

/** Fallback Nigerian bill categories when all Flutterwave APIs fail */
const FALLBACK_CATEGORIES: Record<string, unknown>[] = [
  { id: 1, biller_code: 'BIL099', name: 'MTN Nigeria', biller_name: 'AIRTIME', item_code: 'AT099', short_name: 'MTN', label_name: 'Mobile Number', is_airtime: true, country: 'NG' },
  { id: 2, biller_code: 'BIL099', name: 'GLO Nigeria', biller_name: 'AIRTIME', item_code: 'AT099', short_name: 'GLO', label_name: 'Mobile Number', is_airtime: true, country: 'NG' },
  { id: 3, biller_code: 'BIL099', name: '9Mobile', biller_name: 'AIRTIME', item_code: 'AT099', short_name: '9MOBILE', label_name: 'Mobile Number', is_airtime: true, country: 'NG' },
  { id: 4, biller_code: 'BIL099', name: 'Airtel Nigeria', biller_name: 'AIRTIME', item_code: 'AT099', short_name: 'AIRTEL', label_name: 'Mobile Number', is_airtime: true, country: 'NG' },
  { id: 7, biller_code: 'BIL119', name: 'DSTV Payment', biller_name: 'DSTV', item_code: 'CB141', short_name: 'DSTV', label_name: 'Smart Card Number', is_airtime: false, country: 'NG' },
  { id: 8, biller_code: 'BIL119', name: 'GOtv', biller_name: 'GOTV', item_code: 'CB142', short_name: 'GOTV', label_name: 'Smart Card Number', is_airtime: false, country: 'NG' },
  { id: 13, biller_code: 'BIL110', name: 'EKO PREPAID', biller_name: 'EKEDC PREPAID TOPUP', item_code: 'UB134', short_name: 'EKEDC', label_name: 'Meter Number', is_airtime: false, country: 'NG' },
  { id: 14, biller_code: 'BIL110', name: 'IKEJA PREPAID', biller_name: 'IKEDC PREPAID TOPUP', item_code: 'UB133', short_name: 'IKEDC', label_name: 'Meter Number', is_airtime: false, country: 'NG' },
  { id: 15, biller_code: 'BIL108', name: 'MTN Data', biller_name: 'MTN DATA', item_code: 'DT101', short_name: 'MTN-DATA', label_name: 'Mobile Number', is_airtime: false, country: 'NG' },
  { id: 16, biller_code: 'BIL108', name: 'GLO Data', biller_name: 'GLO DATA', item_code: 'DT102', short_name: 'GLO-DATA', label_name: 'Mobile Number', is_airtime: false, country: 'NG' },
  { id: 17, biller_code: 'BIL108', name: 'Airtel Data', biller_name: 'AIRTEL DATA', item_code: 'DT103', short_name: 'AIRTEL-DATA', label_name: 'Mobile Number', is_airtime: false, country: 'NG' },
  { id: 18, biller_code: 'BIL108', name: '9Mobile Data', biller_name: '9MOBILE DATA', item_code: 'DT104', short_name: '9MOBILE-DATA', label_name: 'Mobile Number', is_airtime: false, country: 'NG' },
];

/** Bill payments via Flutterwave: Airtime, Data, Cable TV, Electricity */
class BillsService {
  /** Get bill categories (airtime, DSTV, electricity, etc.) for Nigeria */
  async getCategories() {
    // 1. Try SDK (v3/bill-categories) – returns billers directly
    try {
      const response = await flw.Bills.fetch_bills_Cat();
      if (response?.status === 'success' && Array.isArray(response.data)) {
        const data = response.data as BillerItem[];
        const ng = data.filter((c) => (c.country ?? c.country_code) === 'NG');
        const list = ng.length > 0 ? ng : data;
        return list.map((c, i) => toBillCategory(c, i));
      }
    } catch (err) {
      console.warn('Flutterwave SDK bill categories failed, trying direct API:', (err as Error).message);
    }

    // 2. Try direct HTTP (v3/bill-categories) – same endpoint, different client
    try {
      const res = await flwFetch<{ status?: string; data?: BillerItem[] }>('/bill-categories?country=NG');
      if (res?.status === 'success' && Array.isArray(res.data)) {
        const ng = res.data.filter((c) => (c.country ?? c.country_code) === 'NG');
        const list = ng.length > 0 ? ng : res.data;
        return list.map((c, i) => toBillCategory(c, i));
      }
    } catch (err) {
      console.warn('Direct bill-categories failed, trying top-bill-categories:', (err as Error).message);
    }

    // 3. Try v3/top-bill-categories, then fetch billers per category
    try {
      const topRes = await flwFetch<{ status?: string; data?: Array<{ code?: string; name?: string }> }>('/top-bill-categories?country=NG');
      if (topRes?.status !== 'success' || !Array.isArray(topRes.data)) throw new Error('No top categories');

      const allBillers: BillerItem[] = [];
      for (const cat of topRes.data) {
        const code = cat.code;
        if (!code) continue;
        try {
          const billersRes = await flwFetch<{ status?: string; data?: BillerItem[] }>(`/billers?category=${encodeURIComponent(code)}&country=NG`);
          if (billersRes?.status === 'success' && Array.isArray(billersRes.data)) {
            for (const b of billersRes.data) {
              allBillers.push({ ...b, biller_name: cat.name ?? b.biller_name ?? b.name } as BillerItem);
            }
          }
        } catch {
          // Skip category if billers fetch fails
        }
      }
      if (allBillers.length > 0) {
        return allBillers.map((c, i) => toBillCategory(c, i));
      }
    } catch (err) {
      console.warn('Top-bill-categories + billers flow failed:', (err as Error).message);
    }

    // 4. Fallback: hardcoded Nigerian billers
    return FALLBACK_CATEGORIES;
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
