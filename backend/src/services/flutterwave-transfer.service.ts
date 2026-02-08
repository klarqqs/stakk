import Flutterwave from 'flutterwave-node-v3';

const flw = new Flutterwave(
  process.env.FLUTTERWAVE_PUBLIC_KEY!,
  process.env.FLUTTERWAVE_SECRET_KEY!
);

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
    const response = await flw.Transfer.initiate({
      account_bank: bankCode,
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
    const response = await flw.Misc.verify_Account({
      account_number: accountNumber,
      account_bank: bankCode,
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
