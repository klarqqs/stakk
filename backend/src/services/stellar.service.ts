import * as StellarSdk from 'stellar-sdk';

class StellarService {
  private server: StellarSdk.Horizon.Server;
  private readonly isMainnet: boolean;

  constructor() {
    this.isMainnet = process.env.STELLAR_NETWORK !== 'testnet';
    const horizonUrl = this.isMainnet
      ? 'https://horizon.stellar.org'
      : 'https://horizon-testnet.stellar.org';
    this.server = new StellarSdk.Horizon.Server(horizonUrl);
  }

  // Create a new wallet
  createWallet() {
    const pair = StellarSdk.Keypair.random();

    return {
      publicKey: pair.publicKey(),
      secretKey: pair.secret()
    };
  }

  // Fund testnet account with free XLM (only works on testnet)
  async fundTestnetAccount(publicKey: string) {
    if (this.isMainnet) {
      console.log('⚠️ Skipping friendbot - mainnet has no free XLM. Fund account manually.');
      return;
    }
    try {
      const response = await fetch(
        `https://friendbot.stellar.org?addr=${publicKey}`
      );
      const result = await response.json();
      console.log('✅ Testnet account funded!');
      return result;
    } catch (error) {
      console.error('❌ Error funding account:', error);
      throw error;
    }
  }

  // Get account balance (with retry for propagation delay)
  async getBalance(publicKey: string, maxRetries = 5, silent = false) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const account = await this.server.loadAccount(publicKey);
        if (!silent) {
          console.log('💰 Balances:');
          account.balances.forEach((balance: { asset_type: string; balance: string }) => {
            console.log(`   ${balance.asset_type}: ${balance.balance}`);
          });
        }
        return account.balances;
      } catch (error) {
        const msg = error instanceof Error ? error.message : String(error);
        if (attempt < maxRetries) {
          const delay = attempt * 2000;
          if (!silent) {
            console.log(`   ⏳ Attempt ${attempt}/${maxRetries} failed, retrying in ${delay / 1000}s...`);
          }
          await new Promise(resolve => setTimeout(resolve, delay));
        } else {
          console.error('❌ Error loading account:', msg);
          throw error;
        }
      }
    }
  }
}

export default new StellarService();