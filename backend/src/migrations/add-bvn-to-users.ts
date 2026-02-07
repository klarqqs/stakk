import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS bvn_encrypted TEXT;
    `);
    console.log('✅ Added bvn_encrypted column to users');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
