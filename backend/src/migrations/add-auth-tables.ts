import pool from '../config/database.ts';

async function migrate() {
  try {
    // Make password_hash nullable for OAuth/OTP users (use placeholder for them)
    await pool.query(`
      ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
    `);
    await pool.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS users_email_unique ON users (email) WHERE email IS NOT NULL;
    `);

    // OTP codes table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS otp_codes (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) NOT NULL,
        code_hash VARCHAR(255) NOT NULL,
        purpose VARCHAR(50) NOT NULL,
        attempts INT DEFAULT 0,
        verified BOOLEAN DEFAULT FALSE,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_otp_email_purpose ON otp_codes (email, purpose);`);

    // Auth providers (Google, Apple, email)
    await pool.query(`
      CREATE TABLE IF NOT EXISTS auth_providers (
        id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(id) ON DELETE CASCADE,
        provider VARCHAR(50) NOT NULL,
        provider_user_id VARCHAR(255),
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(provider, provider_user_id)
      );
    `);

    // Refresh tokens
    await pool.query(`
      CREATE TABLE IF NOT EXISTS refresh_tokens (
        id SERIAL PRIMARY KEY,
        user_id INT REFERENCES users(id) ON DELETE CASCADE,
        token VARCHAR(500) UNIQUE NOT NULL,
        device_id VARCHAR(255),
        expires_at TIMESTAMP NOT NULL,
        revoked BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);
    await pool.query(`CREATE INDEX IF NOT EXISTS idx_refresh_user ON refresh_tokens (user_id);`);

    console.log('✅ Auth tables migrated');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
