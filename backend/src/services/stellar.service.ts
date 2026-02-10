import * as StellarSdk from 'stellar-sdk';

/** Circle's official USDC on Stellar mainnet */
const USDC_ISSUER_MAINNET = 'GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN';
/** Test USDC issuer for Stellar testnet (Stellar Quest testnet USDC) */
const USDC_ISSUER_TESTNET = 'GBBD47IF6LWK7P7MUNSC6V5TOTLSADJ7XUO3RBQZ7Q2W54OPB6L6F5TQ';
const XLM_PER_NEW_ACCOUNT = '1.5';
const TEST_USDC_AMOUNT = '1000'; // Amount of test USDC to fund new accounts for testing

class StellarService {
  private server: StellarSdk.Horizon.Server;
  private readonly isMainnet: boolean;
  private readonly networkPassphrase: string;
  private readonly usdcIssuer: string;

  constructor() {
    this.isMainnet = process.env.STELLAR_NETWORK !== 'testnet';
    const horizonUrl = this.isMainnet
      ? 'https://horizon.stellar.org'
      : 'https://horizon-testnet.stellar.org';
    this.server = new StellarSdk.Horizon.Server(horizonUrl);
    this.networkPassphrase = this.isMainnet
      ? StellarSdk.Networks.PUBLIC
      : StellarSdk.Networks.TESTNET;
    this.usdcIssuer = this.isMainnet ? USDC_ISSUER_MAINNET : USDC_ISSUER_TESTNET;
  }

  createWallet() {
    const pair = StellarSdk.Keypair.random();
    return {
      publicKey: pair.publicKey(),
      secretKey: pair.secret()
    };
  }

  /**
   * Fund new account: testnet = friendbot, mainnet = treasury wallet.
   * Requires TREASURY_SECRET_KEY on mainnet.
   */
  async fundNewAccount(publicKey: string): Promise<void> {
    if (!this.isMainnet) {
      // Fund with XLM via Friendbot
      const response = await fetch(
        `https://friendbot.stellar.org?addr=${publicKey}`
      );
      const result = await response.json();
      console.log('✅ Testnet account funded with XLM');
      
      // Also fund with test USDC for testing Dinari
      await this.fundTestUSDC(publicKey);
      return;
    }

    const treasurySecret = process.env.TREASURY_SECRET_KEY;
    if (!treasurySecret) {
      throw new Error(
        'TREASURY_SECRET_KEY required for mainnet. Fund accounts manually or add to env.'
      );
    }

    try {
      const treasuryKeypair = StellarSdk.Keypair.fromSecret(treasurySecret);
      const treasuryAccount = await this.server.loadAccount(treasuryKeypair.publicKey());

      const transaction = new StellarSdk.TransactionBuilder(treasuryAccount, {
        fee: StellarSdk.BASE_FEE,
        networkPassphrase: this.networkPassphrase
      })
        .addOperation(
          StellarSdk.Operation.createAccount({
            destination: publicKey,
            startingBalance: XLM_PER_NEW_ACCOUNT
          })
        )
        .setTimeout(30)
        .build();

      transaction.sign(treasuryKeypair);
      await this.server.submitTransaction(transaction);
      console.log(`✅ Account funded on mainnet: ${publicKey.slice(0, 8)}...`);
    } catch (error) {
      console.error('❌ Error funding account:', error);
      throw new Error(
        'Unable to fund Stellar account. Treasury may be low on XLM. Please try again later.'
      );
    }
  }

  /**
   * Fund test USDC on testnet for new accounts (for testing Dinari).
   * Note: For sandbox testing, we'll add test USDC balance directly to the database
   * since Stellar testnet doesn't have a standard test USDC issuer.
   */
  async fundTestUSDC(publicKey: string): Promise<void> {
    if (this.isMainnet) {
      return; // Skip on mainnet
    }

    // For testnet/sandbox, we'll add test USDC balance via database update
    // This is handled in auth-helpers.ts after wallet creation
    console.log(`💵 Test USDC will be added to database for ${publicKey.slice(0, 8)}...`);
  }

  /**
   * Send USDC from treasury to user (mainnet only).
   */
  async sendUSDC(userPublicKey: string, amount: string): Promise<string> {
    if (!this.isMainnet) {
      throw new Error('sendUSDC is for mainnet only');
    }

    const treasurySecret = process.env.TREASURY_SECRET_KEY;
    if (!treasurySecret) {
      throw new Error('TREASURY_SECRET_KEY required');
    }

    const usdcAsset = new StellarSdk.Asset('USDC', this.usdcIssuer);
    const treasuryKeypair = StellarSdk.Keypair.fromSecret(treasurySecret);
    const treasuryAccount = await this.server.loadAccount(treasuryKeypair.publicKey());

    const transaction = new StellarSdk.TransactionBuilder(treasuryAccount, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: this.networkPassphrase
    })
      .addOperation(
        StellarSdk.Operation.payment({
          destination: userPublicKey,
          asset: usdcAsset,
          amount
        })
      )
      .setTimeout(30)
      .build();

    transaction.sign(treasuryKeypair);
    const result = await this.server.submitTransaction(transaction);
    console.log(`✅ Sent ${amount} USDC to ${userPublicKey.slice(0, 8)}...`);
    return result.hash;
  }

  /**
   * Send USDC from a user's Stellar wallet to another address.
   * Used for withdrawals to external USDC wallets.
   */
  async sendUSDCFromUser(
    userSecretKey: string,
    recipientAddress: string,
    amount: string
  ): Promise<string> {
    const userKeypair = StellarSdk.Keypair.fromSecret(userSecretKey);
    const account = await this.server.loadAccount(userKeypair.publicKey());
    const usdcAsset = new StellarSdk.Asset('USDC', this.usdcIssuer);

    const transaction = new StellarSdk.TransactionBuilder(account, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: this.networkPassphrase,
    })
      .addOperation(
        StellarSdk.Operation.payment({
          destination: recipientAddress,
          asset: usdcAsset,
          amount,
        })
      )
      .setTimeout(30)
      .build();

    transaction.sign(userKeypair);
    const result = await this.server.submitTransaction(transaction);
    console.log(`✅ Sent ${amount} USDC from user to ${recipientAddress.slice(0, 8)}...`);
    return result.hash;
  }

  /** @deprecated Use fundNewAccount instead */
  async fundTestnetAccount(publicKey: string) {
    return this.fundNewAccount(publicKey);
  }

  async getBalance(publicKey: string, maxRetries = 5, silent = false) {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const account = await this.server.loadAccount(publicKey);
        if (!silent) {
          console.log('💰 Balances:');
          account.balances.forEach((b: { asset_type: string; balance: string }) => {
            const name = b.asset_type === 'native' ? 'XLM' : b.asset_type;
            console.log(`   ${name}: ${b.balance}`);
          });
        }
        return account.balances;
      } catch (error: unknown) {
        const resp = (error as { response?: { status?: number } })?.response;
        if (resp?.status === 404) {
          if (!silent) console.log('⚠️ Account not yet funded on Stellar');
          return [];
        }
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
    return [];
  }
}

export default new StellarService();
