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
  const json = (await res.json()) as T & { status?: string; message?: string };
  if (res.status !== 200 || json?.status === 'error') {
    console.warn(`Flutterwave ${path}: HTTP ${res.status}`, JSON.stringify({ status: json?.status, message: json?.message }));
  }
  return json as T;
}

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
      const topRes = await flwFetch<{ status?: string; message?: string; data?: Array<{ code?: string; name?: string }> }>('/top-bill-categories?country=NG');
      if (topRes?.status !== 'success' || !Array.isArray(topRes.data)) {
        const msg = (topRes as { message?: string })?.message || 'No top categories';
        console.warn('Flutterwave top-bill-categories response:', JSON.stringify(topRes));
        throw new Error(msg);
      }

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

    throw new Error('Failed to fetch bill categories. Please check your Flutterwave API keys and IP whitelist.');
  }

  /** Get top-level categories only (Airtime, Data, Electricity, TV Cable, etc.) */
  async getTopCategories() {
    const topRes = await flwFetch<{ status?: string; data?: Array<{ id?: number; code?: string; name?: string; description?: string; country_code?: string }> }>('/top-bill-categories?country=NG');
    if (topRes?.status !== 'success' || !Array.isArray(topRes.data)) {
      throw new Error((topRes as { message?: string })?.message || 'Failed to fetch categories');
    }
    return topRes.data
      .filter((c) => (c.country_code ?? 'NG') === 'NG')
      .map((c) => ({
        id: c.id ?? 0,
        code: c.code ?? '',
        name: c.name ?? '',
        description: c.description ?? c.name ?? '',
      }));
  }

  /** Map top-bill-category code to biller_name in bill-categories */
  private static readonly CATEGORY_TO_BILLER_NAME: Record<string, string[]> = {
    AIRTIME: ['AIRTIME'],
    MOBILEDATA: ['MOBILEDATA', 'DATA', 'MOBILE DATA'],
    CABLEBILLS: ['CABLEBILLS', 'CABLE', 'CABLE TV'],
    INTSERVICE: ['INTSERVICE', 'INTERNET'],
    UTILITYBILLS: ['UTILITYBILLS', 'UTILITY', 'PREPAID', 'POSTPAID', 'ELECTRICITY'],
    TAX: ['TAX'],
    DONATIONS: ['DONATIONS'],
    TRANSLOG: ['TRANSLOG', 'TRANSPORT'],
    DEALPAY: ['DEALPAY'],
    RELINST: ['RELINST'],
    SCHPB: ['SCHPB'],
  };

  /** Get providers (billers) for a category. Uses bill-categories for accurate MTN/GLO/Airtel for airtime. */
  async getProviders(categoryCode: string) {
    const codeUpper = categoryCode.toUpperCase().trim();
    const billerNames = BillsService.CATEGORY_TO_BILLER_NAME[codeUpper] ?? [codeUpper];

    // 1. Try bill-categories – returns MTN, GLO, Airtel etc. for AIRTIME (billers API can return wrong billers)
    try {
      const catRes = await flwFetch<{ status?: string; data?: BillerItem[] }>('/bill-categories?country=NG');
      if (catRes?.status === 'success' && Array.isArray(catRes.data)) {
        const filtered = catRes.data.filter((b) => {
          const country = b.country ?? b.country_code ?? 'NG';
          if (country !== 'NG') return false;
          const bn = (b.biller_name ?? b.name ?? '').toUpperCase();
          return billerNames.some((expected) => bn === expected || bn.includes(expected));
        });
        if (filtered.length > 0) {
          return filtered.map((b, i) => ({
            id: b.id ?? i + 1,
            billerCode: b.biller_code ?? b.code ?? '',
            name: b.name ?? b.short_name ?? '',
            shortName: b.short_name ?? b.name ?? '',
          }));
        }
      }
    } catch (e) {
      console.warn('bill-categories for providers failed, trying billers:', (e as Error).message);
    }

    // 2. Fallback to billers API
    const res = await flwFetch<{ status?: string; data?: Array<{ id?: number; name?: string; biller_code?: string; short_name?: string; country_code?: string }> }>(`/billers?category=${encodeURIComponent(categoryCode)}&country=NG`);
    if (res?.status !== 'success' || !Array.isArray(res.data)) {
      throw new Error((res as { message?: string })?.message || 'Failed to fetch providers');
    }
    let filtered = res.data.filter((b) => (b.country_code ?? 'NG') === 'NG');
    // For AIRTIME, exclude mis-categorized billers (government, tax, etc.)
    if (codeUpper === 'AIRTIME') {
      const exclude = /\b(government|state|tax|kogi|donation|religious|school)\b/i;
      filtered = filtered.filter((b) => !exclude.test(b.name ?? b.short_name ?? ''));
    }
    return filtered.map((b, i) => ({
      id: b.id ?? i + 1,
      billerCode: b.biller_code ?? '',
      name: b.name ?? '',
      shortName: b.short_name ?? b.name ?? '',
    }));
  }

  /** Get products for a provider (biller) */
  async getProducts(billerCode: string) {
    try {
      const res = await flwFetch<{ status?: string; data?: { products?: Array<{ code?: string; name?: string; amount?: string }> } }>(`/billers/${encodeURIComponent(billerCode)}/products`);
      if (res?.status !== 'success') return [];
      const products = res.data?.products ?? [];
      return products.map((p) => ({
        id: p.code ?? '',
        productCode: p.code ?? '',
        name: p.name ?? '',
        amount: parseFloat(String(p.amount ?? '0')) || 0,
      }));
    } catch {
      return [];
    }
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
