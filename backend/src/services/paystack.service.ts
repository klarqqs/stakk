import https from 'https';
import pool from '../config/database.ts';

class PaystackService {
  private secretKey = process.env.PAYSTACK_SECRET_KEY!;

  // Create dedicated virtual account for user
  async createVirtualAccount(userId: number, phoneNumber: string, email: string) {
    const params = JSON.stringify({
      customer: {
        email: email,
        phone_number: phoneNumber,
      },
      preferred_bank: 'wema-bank', // or 'titan-paystack'
    });

    const options = {
      hostname: 'api.paystack.co',
      port: 443,
      path: '/dedicated_account',
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        'Content-Type': 'application/json',
      },
    };

    return new Promise((resolve, reject) => {
      const req = https.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', async () => {
          const response = JSON.parse(data);
          if (response.status) {
            // Save to database
            await pool.query(
              `INSERT INTO virtual_accounts (user_id, account_number, account_name, bank_name)
               VALUES ($1, $2, $3, $4)`,
              [userId, response.data.account_number, response.data.account_name, response.data.bank.name]
            );
            resolve(response.data);
          } else {
            reject(response.message);
          }
        });
      });
      req.on('error', reject);
      req.write(params);
      req.end();
    });
  }

  // Verify transaction
  async verifyTransaction(reference: string) {
    const options = {
      hostname: 'api.paystack.co',
      port: 443,
      path: `/transaction/verify/${reference}`,
      method: 'GET',
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
      },
    };

    return new Promise((resolve, reject) => {
      const req = https.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          const response = JSON.parse(data);
          resolve(response);
        });
      });
      req.on('error', reject);
      req.end();
    });
  }
}

export default new PaystackService();