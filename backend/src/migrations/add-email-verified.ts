import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE;
    `);
    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);
    `);
    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name VARCHAR(100);
    `);
    // Allow login by email - ensure we can find users by email
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_users_email_lower ON users (LOWER(email)) WHERE email IS NOT NULL;
    `);
    console.log('✅ email_verified migration complete');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
