import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS transactions_reference_unique
      ON transactions (reference) WHERE reference IS NOT NULL;
    `);
    console.log('✅ Added unique index on transactions.reference');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
