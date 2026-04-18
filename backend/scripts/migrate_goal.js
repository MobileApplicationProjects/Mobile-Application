// Migration: add step_goal_daily to user_profiles if missing
// Run once: node backend/scripts/migrate_goal.js

require('dotenv').config({ path: __dirname + '/../.env' });
const pool = require('../src/config/db');

async function migrate() {
  try {
    await pool.execute(`
      ALTER TABLE user_profiles
      ADD COLUMN IF NOT EXISTS step_goal_daily INT NOT NULL DEFAULT 5000
    `);
    console.log('✅ step_goal_daily column ensured in user_profiles');
  } catch (e) {
    // MySQL 5.x does not support ADD COLUMN IF NOT EXISTS — try with check
    if (e.code === 'ER_PARSE_ERROR') {
      try {
        const [cols] = await pool.execute(`
          SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_profiles' AND COLUMN_NAME = 'step_goal_daily'
        `);
        if (cols.length === 0) {
          await pool.execute(`
            ALTER TABLE user_profiles ADD COLUMN step_goal_daily INT NOT NULL DEFAULT 5000
          `);
          console.log('✅ step_goal_daily column added to user_profiles');
        } else {
          console.log('ℹ️  step_goal_daily already exists, no change needed');
        }
      } catch (e2) {
        console.error('Migration failed:', e2.message);
      }
    } else {
      console.error('Migration failed:', e.message);
    }
  }
  process.exit(0);
}

migrate();
