-- Users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  phone_number VARCHAR(255) UNIQUE NOT NULL,
  email VARCHAR(255),
  password_hash VARCHAR(255) NOT NULL,
  stellar_public_key VARCHAR(56) NOT NULL,
  stellar_secret_key_encrypted TEXT NOT NULL,
  bvn_encrypted TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add bvn_encrypted if table already exists
ALTER TABLE users ADD COLUMN IF NOT EXISTS bvn_encrypted TEXT;

-- Transactions table
CREATE TABLE transactions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  type VARCHAR(20) NOT NULL, -- 'deposit', 'withdrawal', 'transfer'
  amount_naira DECIMAL(15, 2),
  amount_usdc DECIMAL(15, 7),
  status VARCHAR(20) NOT NULL, -- 'pending', 'completed', 'failed'
  paystack_reference VARCHAR(255),
  stellar_transaction_hash VARCHAR(64),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wallets table (tracks USDC balances)
CREATE TABLE wallets (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) UNIQUE,
  usdc_balance DECIMAL(15, 7) DEFAULT 0,
  last_synced_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Virtual Accounts table
CREATE TABLE IF NOT EXISTS virtual_accounts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) UNIQUE,
  account_number VARCHAR(20) NOT NULL,
  account_name VARCHAR(255) NOT NULL,
  bank_name VARCHAR(100) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Update transactions table to include paystack reference
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS reference VARCHAR(255);
