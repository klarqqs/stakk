import pool from '../config/database.ts';

async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Add dinari_account_id column to users table if it doesn't exist
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS dinari_account_id VARCHAR(100);
    `);

    // Create stock_holdings table
    await client.query(`
      CREATE TABLE IF NOT EXISTS stock_holdings (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        dinari_account_id VARCHAR(100),
        ticker VARCHAR(10) NOT NULL,
        shares DECIMAL(15, 8),
        avg_buy_price DECIMAL(15, 7),
        current_price DECIMAL(15, 7),
        total_value DECIMAL(15, 7),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, ticker)
      );
      CREATE INDEX IF NOT EXISTS idx_stock_holdings_user ON stock_holdings(user_id);
      CREATE INDEX IF NOT EXISTS idx_stock_holdings_ticker ON stock_holdings(ticker);
    `);

    // Create stock_trades table
    await client.query(`
      CREATE TABLE IF NOT EXISTS stock_trades (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        dinari_order_id VARCHAR(100) UNIQUE,
        dinari_account_id VARCHAR(100),
        ticker VARCHAR(10) NOT NULL,
        side VARCHAR(10) NOT NULL,
        amount_usd DECIMAL(15, 7),
        shares DECIMAL(15, 8),
        price DECIMAL(15, 7),
        fee DECIMAL(15, 7),
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_stock_trades_user ON stock_trades(user_id);
      CREATE INDEX IF NOT EXISTS idx_stock_trades_ticker ON stock_trades(ticker);
      CREATE INDEX IF NOT EXISTS idx_stock_trades_status ON stock_trades(status);
      CREATE INDEX IF NOT EXISTS idx_stock_trades_created ON stock_trades(created_at);
    `);

    await client.query('COMMIT');
    console.log('✅ Stock trading tables created');
    process.exit(0);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    client.release();
  }
}

migrate();
