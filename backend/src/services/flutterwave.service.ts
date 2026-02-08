import Flutterwave from 'flutterwave-node-v3';
import pool from '../config/database.ts';

const flw = new Flutterwave(
  process.env.FLUTTERWAVE_PUBLIC_KEY!,
  process.env.FLUTTERWAVE_SECRET_KEY!
);

class FlutterwaveService {
  // Create virtual account for user
  // Uses dynamic (temporary) accounts when bvn omitted - expires in 1h, no BVN required.
  // For permanent accounts, pass bvn (required by Flutterwave for static accounts).
  async createVirtualAccount(
    userId: number,
    email: string,
    phoneNumber: string,
    fullName: string,
    options?: { amount?: number; bvn?: string; firstName?: string; lastName?: string }
  ) {
    try {
      const isPermanent = Boolean(options?.bvn);
      const firstName = options?.firstName?.trim() || fullName.split(' ')[0] || 'User';
      const lastName = options?.lastName?.trim() || fullName.split(' ').slice(1).join(' ') || `${userId}`;
      const payload: Record<string, unknown> = {
        email: email,
        is_permanent: isPermanent,
        tx_ref: `KLYNG-${userId}-${Date.now()}`,
        narration: fullName,
        firstname: firstName,
        lastname: lastName,
      };
      if (isPermanent && options?.bvn) payload.bvn = options.bvn;
      if (!isPermanent) payload.amount = options?.amount ?? 100; // Required for dynamic accounts

      const response = await flw.VirtualAcct.create(payload);

      if (response.status === 'success') {
        const accountData = response.data;
        if (!accountData) throw new Error('No account data in response');

        // Save to database
        await pool.query(
          `INSERT INTO virtual_accounts (user_id, account_number, account_name, bank_name)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (user_id) DO NOTHING`,
          [
            userId,
            accountData.account_number,
            accountData.account_name || `KLYNG/${email}`,
            accountData.bank_name || 'Wema Bank'
          ]
        );

        return accountData;
      } else {
        throw new Error(response.message || 'Failed to create virtual account');
      }
    } catch (error: any) {
      console.error('Flutterwave error:', error);
      throw error;
    }
  }

  // Verify transaction
  async verifyTransaction(transactionId: string) {
    try {
      const response = await flw.Transaction.verify({ id: transactionId });
      return response;
    } catch (error) {
      console.error('Verify error:', error);
      throw error;
    }
  }

  // Get virtual account details
  async getVirtualAccount(accountNumber: string) {
    try {
      const response = await flw.VirtualAcct.fetch({ account_number: accountNumber });
      return response;
    } catch (error) {
      console.error('Get account error:', error);
      throw error;
    }
  }
}

export default new FlutterwaveService();