import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS blend_positions (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) UNIQUE,
        usdc_supplied DECIMAL(15, 7) DEFAULT 0,
        earnings_accumulated DECIMAL(15, 7) DEFAULT 0,
        supply_timestamp TIMESTAMP,
        last_earnings_update TIMESTAMP,
        status VARCHAR(20) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_blend_user ON blend_positions(user_id);
    `);
    console.log('✅ Blend positions table created');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
