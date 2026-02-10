import pool from '../config/database.ts';
import DinariService from '../services/dinari.service.ts';

/**
 * Script to clear invalid Dinari account IDs from the database.
 * Accounts that don't exist in Dinari (404) will be cleared so new ones can be created.
 */
async function clearInvalidAccounts() {
  const client = await pool.connect();
  const dinariService = new DinariService();
  
  try {
    console.log('🔍 Checking for invalid Dinari account IDs...');
    
    // Get all users with dinari_account_id
    const result = await client.query(
      'SELECT id, dinari_account_id FROM users WHERE dinari_account_id IS NOT NULL'
    );
    
    console.log(`Found ${result.rows.length} users with Dinari account IDs`);
    
    let clearedCount = 0;
    let validCount = 0;
    
    for (const row of result.rows) {
      const userId = row.id;
      const accountId = row.dinari_account_id;
      
      try {
        // Verify account exists
        const exists = await dinariService.verifyAccountExists(accountId);
        
        if (!exists) {
          // Clear invalid account ID
          await client.query(
            'UPDATE users SET dinari_account_id = NULL WHERE id = $1',
            [userId]
          );
          console.log(`🗑️  Cleared invalid account ${accountId.substring(0, 8)}... for user ${userId}`);
          clearedCount++;
        } else {
          console.log(`✅ Account ${accountId.substring(0, 8)}... is valid for user ${userId}`);
          validCount++;
        }
      } catch (error: any) {
        console.error(`❌ Error checking account ${accountId.substring(0, 8)}... for user ${userId}:`, error.message);
      }
    }
    
    console.log('\n📊 Summary:');
    console.log(`   Valid accounts: ${validCount}`);
    console.log(`   Cleared invalid accounts: ${clearedCount}`);
    console.log(`   Total checked: ${result.rows.length}`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Script failed:', error);
    process.exit(1);
  } finally {
    client.release();
  }
}

clearInvalidAccounts();
