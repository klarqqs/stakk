import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS locked_savings (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) NOT NULL,
        amount_usdc DECIMAL(15, 7) NOT NULL,
        lock_duration INTEGER NOT NULL,
        apy_rate DECIMAL(5, 2) NOT NULL,
        start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        maturity_date TIMESTAMP NOT NULL,
        status VARCHAR(20) DEFAULT 'active',
        interest_earned DECIMAL(15, 7) DEFAULT 0,
        auto_renew BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_locked_user ON locked_savings(user_id);
      CREATE INDEX IF NOT EXISTS idx_locked_status ON locked_savings(status);
    `);
    console.log('✅ locked_savings table created');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
