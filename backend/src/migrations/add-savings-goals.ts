import pool from '../config/database.ts';

async function migrate() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS savings_goals (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) NOT NULL,
        name VARCHAR(255) NOT NULL,
        target_amount DECIMAL(15, 7) NOT NULL,
        current_amount DECIMAL(15, 7) DEFAULT 0,
        deadline DATE,
        auto_save_amount DECIMAL(15, 7),
        auto_save_frequency VARCHAR(20),
        status VARCHAR(20) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_goals_user ON savings_goals(user_id);
      CREATE INDEX IF NOT EXISTS idx_goals_status ON savings_goals(status);

      CREATE TABLE IF NOT EXISTS goal_contributions (
        id SERIAL PRIMARY KEY,
        goal_id INTEGER REFERENCES savings_goals(id) NOT NULL,
        user_id INTEGER REFERENCES users(id) NOT NULL,
        amount_usdc DECIMAL(15, 7) NOT NULL,
        source VARCHAR(50) DEFAULT 'manual',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_contributions_goal ON goal_contributions(goal_id);
    `);
    console.log('✅ savings_goals and goal_contributions tables created');
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

migrate();
