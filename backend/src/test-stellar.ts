import stellarService from './services/stellar.service.ts';

async function testStellar() {
  console.log('🚀 Creating your first Stellar wallet...\n');
  
  // Step 1: Create wallet
  const wallet = stellarService.createWallet();
  console.log('🔑 Wallet Created!');
  console.log('Public Key:', wallet.publicKey);
  console.log('Secret Key:', wallet.secretKey);
  console.log('\n⚠️  SAVE THESE! You\'ll need them.\n');
  
  // Step 2: Fund with test XLM
  console.log('💸 Funding testnet account with free XLM...');
  await stellarService.fundTestnetAccount(wallet.publicKey);
  
  // Step 3: Check balance (retries handle propagation delay)
  console.log('\n💰 Checking balance...');
  await new Promise(resolve => setTimeout(resolve, 2000)); // Initial wait for ledger close
  await stellarService.getBalance(wallet.publicKey);
  
  console.log('\n✅ Success! Your Stellar wallet is ready on testnet!');
}

testStellar().catch(console.error);