import Flutterwave from 'flutterwave-node-v3';

const flw = new Flutterwave(
  process.env.FLUTTERWAVE_PUBLIC_KEY!,
  process.env.FLUTTERWAVE_SECRET_KEY!
);

/** Normalize bank code to Flutterwave format (numeric string, e.g. "044") */
export function normalizeBankCode(code: string | number | undefined): string {
  const s = String(code ?? '').trim();
  if (!s) return '';
  const num = s.replace(/\D/g, '');
  if (!num) return s;
  return num.length >= 3 ? num : num.padStart(3, '0');
}

/** NGN bank transfers and account resolution via Flutterwave */
class FlutterwaveTransferService {
  /** Send NGN to a Nigerian bank account */
  async sendToBank(
    accountNumber: string,
    bankCode: string,
    amount: number,
    narration: string,
    reference: string
  ) {
    const code = normalizeBankCode(bankCode);
    const response = await flw.Transfer.initiate({
      account_bank: code,
      account_number: accountNumber,
      amount,
      currency: 'NGN',
      debit_currency: 'NGN',
      narration,
      reference,
      callback_url: process.env.FLUTTERWAVE_CALLBACK_URL,
    });

    if (response.status !== 'success') {
      throw new Error(response.message || 'Transfer failed');
    }
    return response.data;
  }

  /** Resolve NGN account to get account name */
  async resolveAccount(accountNumber: string, bankCode: string) {
    const code = normalizeBankCode(bankCode);
    const response = await flw.Misc.verify_Account({
      account_number: accountNumber,
      account_bank: code,
    });

    if (response.status !== 'success') {
      throw new Error(response.message || 'Account resolution failed');
    }
    return response.data;
  }

  /** Get list of Nigerian banks for transfers */
  async getBanks() {
    const response = await flw.Bank.country({ country: 'NG' });
    if (response.status !== 'success') {
      throw new Error(response.message || 'Failed to fetch banks');
    }
    return response.data;
  }
}

export default new FlutterwaveTransferService();
