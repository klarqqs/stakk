import pool from '../config/database.ts';

/**
 * Script to clear Dinari account IDs from all users (or specific user)
 * Useful when switching to shared sandbox account
 */
async function clearDinariAccounts() {
  const client = await pool.connect();
  
  try {
    const userId = process.argv[2]; // Optional: specific user ID
    
    if (userId) {
      // Clear specific user
      await client.query(
        'UPDATE users SET dinari_account_id = NULL WHERE id = $1',
        [userId]
      );
      console.log(`✅ Cleared Dinari account ID for user ${userId}`);
    } else {
      // Clear all users
      const result = await client.query(
        'UPDATE users SET dinari_account_id = NULL RETURNING id'
      );
      console.log(`✅ Cleared Dinari account IDs for ${result.rows.length} users`);
    }
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Script failed:', error);
    process.exit(1);
  } finally {
    client.release();
  }
}

clearDinariAccounts();
