// Migration: Create tables for Location tracking and Share logging
require('dotenv').config({ path: __dirname + '/../.env' });
const pool = require('../src/config/db');

async function migrate() {
  try {
    console.log('🚀 Starting migration...');

    // 1. location_sessions
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS location_sessions (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        started_at DATETIME NOT NULL,
        ended_at DATETIME,
        distance_m DECIMAL(10, 2) DEFAULT 0,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_user_start (user_id, started_at)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
    console.log('✅ Table "location_sessions" ensured.');

    // 2. location_points
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS location_points (
        id VARCHAR(36) PRIMARY KEY,
        session_id VARCHAR(36) NOT NULL,
        lat DECIMAL(10, 8) NOT NULL,
        lng DECIMAL(11, 8) NOT NULL,
        altitude DECIMAL(8, 2),
        speed DECIMAL(6, 2),
        recorded_at DATETIME NOT NULL,
        INDEX idx_session_time (session_id, recorded_at)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
    console.log('✅ Table "location_points" ensured.');

    // 3. share_logs
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS share_logs (
        id VARCHAR(36) PRIMARY KEY,
        user_id VARCHAR(36) NOT NULL,
        platform VARCHAR(50) NOT NULL,
        shared_data JSON,
        created_at DATETIME NOT NULL,
        INDEX idx_user_platform (user_id, platform)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
    console.log('✅ Table "share_logs" ensured.');

    console.log('✨ All migrations completed successfully.');
  } catch (e) {
    console.error('❌ Migration failed:', e.message);
  } finally {
    process.exit(0);
  }
}

migrate();
