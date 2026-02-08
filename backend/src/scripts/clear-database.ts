import pool from '../config/database.ts';

/**
 * Clears all data from the database (keeps schema).
 * Run: npx ts-node src/scripts/clear-database.ts
 * Requires DATABASE_URL in .env
 */
async function clearDatabase() {
  try {
    // Truncate in order: child tables first (those with FK to users), then users
    await pool.query(`
      TRUNCATE TABLE
        refresh_tokens,
        auth_providers,
        transactions,
        wallets,
        virtual_accounts,
        otp_codes,
        users
      RESTART IDENTITY CASCADE;
    `);
    console.log('✅ Database cleared successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Clear failed:', error);
    process.exit(1);
  }
}

clearDatabase();
