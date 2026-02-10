/**
 * Database Reset Script
 * 
 * WARNING: This will DELETE ALL DATA from the database!
 * Only use in development/sandbox environments.
 * 
 * Usage:
 *   npx ts-node src/scripts/reset-database.ts
 * 
 * Or via Railway CLI:
 *   railway run npx ts-node src/scripts/reset-database.ts
 */

import pool from '../config/database.ts';

async function resetDatabase() {
  const client = await pool.connect();
  
  try {
    console.log('⚠️  WARNING: This will delete ALL data from the database!');
    console.log('   Starting database reset...\n');

    // Start transaction
    await client.query('BEGIN');

    // Delete in order (respecting foreign key constraints)
    console.log('🗑️  Deleting data from tables...');
    
    await client.query('DELETE FROM stock_trades');
    console.log('   ✅ Deleted stock_trades');
    
    await client.query('DELETE FROM stock_holdings');
    console.log('   ✅ Deleted stock_holdings');
    
    await client.query('DELETE FROM notifications');
    console.log('   ✅ Deleted notifications');
    
    await client.query('DELETE FROM p2p_transfers');
    console.log('   ✅ Deleted p2p_transfers');
    
    await client.query('DELETE FROM transactions');
    console.log('   ✅ Deleted transactions');
    
    await client.query('DELETE FROM savings_goals');
    console.log('   ✅ Deleted savings_goals');
    
    await client.query('DELETE FROM locked_savings');
    console.log('   ✅ Deleted locked_savings');
    
    await client.query('DELETE FROM blend_positions');
    console.log('   ✅ Deleted blend_positions');
    
    await client.query('DELETE FROM referrals');
    console.log('   ✅ Deleted referrals');
    
    await client.query('DELETE FROM referral_codes');
    console.log('   ✅ Deleted referral_codes');
    
    await client.query('DELETE FROM refresh_tokens');
    console.log('   ✅ Deleted refresh_tokens');
    
    await client.query('DELETE FROM virtual_accounts');
    console.log('   ✅ Deleted virtual_accounts');
    
    await client.query('DELETE FROM wallets');
    console.log('   ✅ Deleted wallets');
    
    await client.query('DELETE FROM users');
    console.log('   ✅ Deleted users');

    // Reset sequences
    console.log('\n🔄 Resetting sequences...');
    const tables = [
      'users', 'transactions', 'wallets', 'virtual_accounts',
      'refresh_tokens', 'referrals', 'referral_codes', 'blend_positions', 'locked_savings',
      'savings_goals', 'p2p_transfers', 'notifications', 'stock_holdings', 'stock_trades'
    ];
    
    for (const table of tables) {
      try {
        await client.query(`SELECT setval(pg_get_serial_sequence('${table}', 'id'), 1, false)`);
        console.log(`   ✅ Reset ${table} sequence`);
      } catch (error: any) {
        // Table might not have an id sequence, skip
        if (!error.message?.includes('does not exist')) {
          console.warn(`   ⚠️  Could not reset ${table} sequence: ${error.message}`);
        }
      }
    }

    // Commit transaction
    await client.query('COMMIT');
    
    console.log('\n✅ Database reset complete!');
    console.log('   All tables cleared and sequences reset.');
    console.log('   You can now test from a clean state.\n');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error resetting database:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

// Run if executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  resetDatabase()
    .then(() => {
      console.log('✅ Script completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Script failed:', error);
      process.exit(1);
    });
}

export default resetDatabase;
