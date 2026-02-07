import pool from './config/database.ts';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function setupDatabase() {
  try {
    console.log('🚀 Setting up database schema...\n');
    
    // Read SQL file
    const sqlPath = path.join(__dirname, 'config', 'database.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Execute SQL
    await pool.query(sql);
    
    console.log('✅ Database schema created successfully!');
    console.log('\nTables created:');
    console.log('  - users');
    console.log('  - transactions');
    console.log('  - wallets');
    
    // Verify tables exist
    const result = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    
    console.log('\n📊 Verified tables in database:');
    result.rows.forEach((row: { table_name: string }) => {
      console.log(`  ✓ ${row.table_name}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error setting up database:', error);
    process.exit(1);
  }
}

setupDatabase();