import pool from '../config/database.ts';

/**
 * Script to get a user's Stellar wallet address
 * Usage: ts-node src/scripts/get-user-wallet.ts [user_id or phone_number or email]
 */
async function getUserWallet() {
  const client = await pool.connect();
  
  try {
    const identifier = process.argv[2];
    
    if (!identifier) {
      console.error('Usage: ts-node src/scripts/get-user-wallet.ts [user_id|phone_number|email]');
      process.exit(1);
    }

    // Try to find user by ID, phone, or email
    let query: string;
    let params: any[];
    
    if (/^\d+$/.test(identifier)) {
      // Numeric - assume user ID
      query = 'SELECT id, phone_number, email, stellar_public_key FROM users WHERE id = $1';
      params = [identifier];
    } else if (identifier.includes('@')) {
      // Contains @ - assume email
      query = 'SELECT id, phone_number, email, stellar_public_key FROM users WHERE LOWER(email) = LOWER($1)';
      params = [identifier];
    } else {
      // Assume phone number
      query = 'SELECT id, phone_number, email, stellar_public_key FROM users WHERE phone_number = $1';
      params = [identifier];
    }

    const result = await client.query(query, params);
    
    if (result.rows.length === 0) {
      console.error(`❌ User not found: ${identifier}`);
      process.exit(1);
    }

    const user = result.rows[0];
    
    console.log('\n✅ User found:');
    console.log(`   User ID: ${user.id}`);
    console.log(`   Phone: ${user.phone_number}`);
    console.log(`   Email: ${user.email || 'N/A'}`);
    console.log(`\n📍 Stellar Wallet Address:`);
    console.log(`   ${user.stellar_public_key}`);
    console.log(`\n💡 Use this address to connect wallet in Dinari dashboard:`);
    console.log(`   1. Go to Dinari dashboard → Accounts → ${process.env.DINARI_SANDBOX_ACCOUNT_ID || 'your-account-id'}`);
    console.log(`   2. Click "+ Connect Wallet"`);
    console.log(`   3. Enter: ${user.stellar_public_key}`);
    console.log(`   4. Complete connection`);
    console.log(`\n✅ After connecting, this user can trade stocks and manage their portfolio!\n`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  } finally {
    client.release();
  }
}

getUserWallet();
