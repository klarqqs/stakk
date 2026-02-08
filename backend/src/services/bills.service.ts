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
async function flwFetch<T>(path: string, method: 'GET' | 'POST' = 'GET', body?: Record<string, unknown>): Promise<T> {
  const opts: RequestInit = {
    method,
    headers: {
      Authorization: `Bearer ${SECRET_KEY}`,
      'Content-Type': 'application/json',
    },
  };
  if (method === 'POST' && body != null) opts.body = JSON.stringify(body);
  const res = await fetch(`${FLW_BASE}${path}`, opts);
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
          const billersRes = await flwFetch<{ status?: string; data?: BillerItem[] }>(`/bills/${encodeURIComponent(code)}/billers?country=NG`);
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

  /** Get providers (billers) for a category. Uses correct Flutterwave endpoint: /bills/{category}/billers */
  async getProviders(categoryCode: string) {
    const codeUpper = categoryCode.toUpperCase().trim();

    // 1. Use correct Flutterwave endpoint: /bills/{category}/billers (e.g. /bills/CABLEBILLS/billers, /bills/AIRTIME/billers)
    const res = await flwFetch<{ status?: string; data?: Array<{ id?: number; name?: string; biller_code?: string; short_name?: string; country_code?: string }> }>(`/bills/${encodeURIComponent(categoryCode)}/billers?country=NG`);
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

  /** Get bill items/products for a provider (biller). Uses /billers/{biller_code}/items */
  async getProducts(billerCode: string) {
    try {
      const res = await flwFetch<{
        status?: string;
        data?: Array<{ id?: number; item_code?: string; name?: string; short_name?: string; amount?: number }>;
      }>(`/billers/${encodeURIComponent(billerCode)}/items`);
      if (res?.status !== 'success' || !Array.isArray(res.data)) return [];
      const seen = new Set<string>();
      return res.data
        .filter((p) => {
          const code = p.item_code ?? '';
          if (!code || seen.has(code)) return false;
          seen.add(code);
          return true;
        })
        .map((p) => ({
          id: p.item_code ?? String(p.id ?? ''),
          productCode: p.item_code ?? '',
          name: p.short_name ?? p.name ?? '',
          amount: Number(p.amount ?? 0) || 0,
        }));
    } catch {
      return [];
    }
  }

  /** Validate customer (meter number, smartcard, phone) before payment. Uses GET /bill-items/{item_code}/validate */
  async validate(itemCode: string, _billerCode: string, customer: string) {
    const res = await flwFetch<{
      status?: string;
      message?: string;
      data?: { name?: string; customer?: string; product_code?: string };
    }>(`/bill-items/${encodeURIComponent(itemCode)}/validate?customer=${encodeURIComponent(customer)}`);
    if (res?.status !== 'success') {
      throw new Error((res as { message?: string })?.message || 'Validation failed');
    }
    return res.data ?? {};
  }

  /** Pay bill: deduct USDC, call Flutterwave POST /billers/{biller_code}/items/{item_code}/payment */
  async payBill(
    userId: number,
    billerCode: string,
    itemCode: string,
    customer: string,
    amount: number,
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

    // Format Nigerian phone as +234... for airtime/data; pass as-is for smartcard/meter
    const custId = /^0\d{10}$/.test(customer) ? `+234${customer.slice(1)}` : customer;

    const payload = {
      country: 'NG',
      customer_id: custId,
      amount,
      reference,
    };

    const res = await flwFetch<{ status?: string; message?: string; data?: { tx_ref?: string; reference?: string } }>(
      `/billers/${encodeURIComponent(billerCode)}/items/${encodeURIComponent(itemCode)}/payment`,
      'POST',
      payload
    );

    if (res?.status !== 'success') {
      throw new Error((res as { message?: string })?.message || 'Bill payment failed');
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
      tx_ref: res.data?.tx_ref,
      flw_ref: res.data?.reference,
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
