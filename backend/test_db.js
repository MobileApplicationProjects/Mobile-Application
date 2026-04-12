const pool = require('./src/config/db');

async function test() {
  const [rows] = await pool.execute("SELECT * FROM challenges ORDER BY id DESC");
  console.log('All challenges:', rows);
  
  const [activeRows] = await pool.execute("SELECT * FROM challenges WHERE is_active = 1");
  console.log('Active challenges:', activeRows);

  process.exit(0);
}

test();
