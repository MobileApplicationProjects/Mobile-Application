const pool = require('./src/config/db');
const jwt = require('jsonwebtoken');
require('dotenv').config();

async function testApi() {
  const [userRows] = await pool.execute("SELECT id FROM users LIMIT 1");
  if (userRows.length === 0) {
    console.log("No users found");
    process.exit(1);
  }
  const userId = userRows[0].id;
  const token = jwt.sign({ id: userId }, process.env.JWT_SECRET, { expiresIn: '1h' });
  
  const res = await fetch('http://127.0.0.1:5000/api/challenges/latest', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  const text = await res.text();
  console.log(`Status: ${res.status}`);
  console.log(`Response: ${text}`);
  process.exit(0);
}

testApi();
