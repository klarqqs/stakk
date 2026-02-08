import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      ALTER TABLE users ALTER COLUMN phone_number TYPE VARCHAR(255);
    `);
    console.log('✅ Extended phone_number to VARCHAR(255)');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
