import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS device_tokens (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE NOT NULL,
        token VARCHAR(255) NOT NULL,
        platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, token)
      );
      CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);
      CREATE INDEX IF NOT EXISTS idx_device_tokens_token ON device_tokens(token);
    `);
    console.log('✅ device_tokens table created');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
