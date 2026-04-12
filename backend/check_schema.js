require('dotenv').config();
const mysql = require('mysql2/promise');

async function main() {
  try {
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

    const [rows] = await pool.query('SHOW CREATE TABLE users');
    console.log(rows[0]['Create Table']);
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}
main();
