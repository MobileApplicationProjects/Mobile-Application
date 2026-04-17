require('dotenv').config();
const mysql = require('mysql2/promise');

async function main() {
  const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 4000,
    ssl: {
      minVersion: 'TLSv1.2',
      rejectUnauthorized: true
    }
  });

  try {
    console.log('Adding username to users table...');
    try {
      await pool.query(`ALTER TABLE users ADD COLUMN username VARCHAR(100) DEFAULT NULL;`);
      await pool.query(`ALTER TABLE users ADD UNIQUE INDEX idx_username (username);`);
      console.log('Column username added successfully');
    } catch(e) {
      if (e.code === 'ER_DUP_FIELDNAME' || e.code === 'ER_DUP_KEYNAME') {
        console.log('Column username or index already exists.');
      } else {
        throw e;
      }
    }

    console.log('Creating rooms table...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS rooms (
        id VARCHAR(36) PRIMARY KEY,
        name VARCHAR(255) COLLATE utf8mb4_unicode_ci NOT NULL,
        duration_days INT NOT NULL DEFAULT 7,
        start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        end_date TIMESTAMP NULL DEFAULT NULL,
        created_by VARCHAR(36) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    console.log('Creating room_members table...');
    await pool.query(`
      CREATE TABLE IF NOT EXISTS room_members (
        room_id VARCHAR(36) NOT NULL,
        user_id VARCHAR(36) NOT NULL,
        status ENUM('invited', 'accepted') DEFAULT 'invited',
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (room_id, user_id),
        FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);

    console.log('Migration completed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}
main();
