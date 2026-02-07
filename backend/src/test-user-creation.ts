import pool from './config/database.ts';
import stellarService from './services/stellar.service.ts';
import crypto from 'crypto';

async function createTestUser() {
  try {
    console.log('🧪 Creating test user with Stellar wallet...\n');
    
    // Step 1: Create Stellar wallet
    const wallet = stellarService.createWallet();
    console.log('🔑 Stellar wallet created');
    console.log('Public Key:', wallet.publicKey);
    
    // Step 2: Fund the wallet on testnet
    console.log('\n💸 Funding wallet on testnet...');
    await stellarService.fundTestnetAccount(wallet.publicKey);
    
    // Step 3: Encrypt the secret key (simple version for MVP)
    // In production, use proper encryption like AES-256
    const encryptedSecret = Buffer.from(wallet.secretKey).toString('base64');
    
    // Step 4: Hash password (simple version - use bcrypt in production)
    const password = 'TestPassword123!';
    const passwordHash = crypto.createHash('sha256').update(password).digest('hex');
    
    // Step 5: Insert user into database
    const result = await pool.query(`
      INSERT INTO users (
        phone_number, 
        email, 
        password_hash, 
        stellar_public_key, 
        stellar_secret_key_encrypted
      ) VALUES ($1, $2, $3, $4, $5)
      RETURNING id, phone_number, stellar_public_key, created_at
    `, [
      '+2348012345678',
      'test@example.com',
      passwordHash,
      wallet.publicKey,
      encryptedSecret
    ]);
    
    const user = result.rows[0];
    console.log('\n✅ User created in database!');
    console.log('User ID:', user.id);
    console.log('Phone:', user.phone_number);
    console.log('Stellar Address:', user.stellar_public_key);
    console.log('Created:', user.created_at);
    
    // Step 6: Create wallet record
    await pool.query(`
      INSERT INTO wallets (user_id, usdc_balance, last_synced_at)
      VALUES ($1, $2, NOW())
    `, [user.id, 0]);
    
    console.log('\n💰 Wallet record created (Balance: 0 USDC)');
    
    // Step 7: Check balance on Stellar
    console.log('\n🌟 Checking Stellar balance...');
    await new Promise(resolve => setTimeout(resolve, 2000));
    await stellarService.getBalance(wallet.publicKey);
    
    console.log('\n🎉 Success! First user with Stellar wallet created!');
    console.log('\n📝 Login credentials for testing:');
    console.log('Phone: +2348012345678');
    console.log('Password: TestPassword123!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createTestUser();