import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS p2p_transfers (
        id SERIAL PRIMARY KEY,
        sender_id INTEGER REFERENCES users(id),
        receiver_id INTEGER REFERENCES users(id),
        receiver_phone VARCHAR(50),
        receiver_email VARCHAR(255),
        amount_usdc DECIMAL(15, 7) NOT NULL,
        fee_usdc DECIMAL(15, 7) DEFAULT 0,
        status VARCHAR(20) DEFAULT 'completed',
        note TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_p2p_sender ON p2p_transfers(sender_id);
      CREATE INDEX IF NOT EXISTS idx_p2p_receiver ON p2p_transfers(receiver_id);
      CREATE INDEX IF NOT EXISTS idx_p2p_created ON p2p_transfers(created_at);
    `);
    console.log('✅ p2p_transfers table created');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
