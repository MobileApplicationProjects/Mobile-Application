const pool = require('../config/db');
const crypto = require('crypto');

// Helper to convert DD/MM/YYYY to YYYY-MM-DD
function toSqlDate(dateStr) {
  if (!dateStr || !dateStr.includes('/')) return dateStr;
  const parts = dateStr.split('/');
  if (parts.length === 3) {
    return `${parts[2]}-${parts[1]}-${parts[0]}`;
  }
  return dateStr;
}

// Helper to convert YYYY-MM-DD to DD/MM/YYYY
function fromSqlDate(dateObj) {
  if (!dateObj) return null;
  // If the database returns a Date object:
  if (dateObj instanceof Date) {
    const y = dateObj.getFullYear();
    const m = String(dateObj.getMonth() + 1).padStart(2, '0');
    const d = String(dateObj.getDate()).padStart(2, '0');
    return `${d}/${m}/${y}`;
  }
  // If it's a string from db
  const str = dateObj.toString();
  if (str.includes('-')) {
    const parts = str.split('T')[0].split('-');
    if (parts.length === 3) {
      return `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
  }
  return str;
}

class HealthModel {
  static async upsertDailyData(userId, date, steps, calories, distance) {
    const sqlDate = toSqlDate(date);
    const safeSteps = steps || 0;
    const safeCalories = calories || 0;
    const safeDistance = distance || 0;

    let earnedCoins = 0;
    const connection = await pool.getConnection();

    try {
      await connection.beginTransaction();

      // 1. Get old steps with lock
      const [oldDataRows] = await connection.execute(
        'SELECT steps FROM health_data WHERE user_id = ? AND date = ? FOR UPDATE',
        [userId, sqlDate]
      );

      const oldSteps = oldDataRows.length > 0 ? oldDataRows[0].steps : 0;

      // 2. Calculate newly earned coins (1 coin per 200 steps)
      const prevCoinCount = Math.floor(oldSteps / 200);
      const currCoinCount = Math.floor(safeSteps / 200);
      earnedCoins = Math.max(0, currCoinCount - prevCoinCount);

      // 3. Upsert health data
      const query = `
        INSERT INTO health_data (user_id, date, steps, calories, distance)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
          steps = VALUES(steps),
          calories = VALUES(calories),
          distance = VALUES(distance),
          updated_at = CURRENT_TIMESTAMP
      `;
      await connection.execute(query, [userId, sqlDate, safeSteps, safeCalories, safeDistance]);

      // 4. Update Token Wallet if earned
      if (earnedCoins > 0) {
        const [walletRows] = await connection.execute(
          'SELECT current_balance, total_earned_lifetime FROM user_wallets WHERE user_id = ? FOR UPDATE',
          [userId]
        );

        if (walletRows.length === 0) {
          await connection.execute(
            'INSERT INTO user_wallets (user_id, current_balance, total_earned_lifetime) VALUES (?, ?, ?)',
            [userId, earnedCoins, earnedCoins]
          );
        } else {
          await connection.execute(
            'UPDATE user_wallets SET current_balance = current_balance + ?, total_earned_lifetime = total_earned_lifetime + ?, updated_at = CURRENT_TIMESTAMP WHERE user_id = ?',
            [earnedCoins, earnedCoins, userId]
          );
        }

        // 5. Record Transaction
        const txId = crypto.randomUUID();
        await connection.execute(
          `INSERT INTO token_transactions (id, user_id, amount, transaction_type, reference_id) 
           VALUES (?, ?, ?, 'Earn_Step', ?)`,
          [txId, userId, earnedCoins, sqlDate]
        );
      }

      await connection.commit();
      return { success: true, earnedCoins };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }

  static async getDailyData(userId, date) {
    const sqlDate = toSqlDate(date);
    const query = `
      SELECT id, date, steps, calories, distance
      FROM health_data
      WHERE user_id = ? AND date = ?
      LIMIT 1
    `;
    const [rows] = await pool.execute(query, [userId, sqlDate]);
    
    if (rows.length > 0) {
      const row = rows[0];
      row.dateFormatted = fromSqlDate(row.date);
      return row;
    }
    return null;
  }

  static async getWeeklyData(userId, startDate, endDate) {
    const sqlStart = toSqlDate(startDate);
    const sqlEnd = toSqlDate(endDate);

    const query = `
      SELECT id, date, steps, calories, distance
      FROM health_data
      WHERE user_id = ? AND date BETWEEN ? AND ?
      ORDER BY date ASC
    `;
    const [rows] = await pool.execute(query, [userId, sqlStart, sqlEnd]);
    
    return rows.map(row => ({
      ...row,
      dateFormatted: fromSqlDate(row.date)
    }));
  }

  static async getYearlyData(userId, year) {
    const query = `
      SELECT date, steps
      FROM health_data
      WHERE user_id = ? AND YEAR(date) = ?
      ORDER BY date ASC
    `;
    const [rows] = await pool.execute(query, [userId, year]);
    
    // Return as a simple map of { "YYYY-MM-DD": steps }
    const result = {};
    rows.forEach(row => {
      // row.date is usually a Date object or "YYYY-MM-DD" string
      const dateKey = row.date instanceof Date 
        ? row.date.toISOString().split('T')[0] 
        : row.date.toString().split('T')[0];
      result[dateKey] = row.steps;
    });
    return result;
  }

  static async getStreak(userId) {
    const query = `
      SELECT date
      FROM health_data
      WHERE user_id = ? AND steps >= 3000
      ORDER BY date DESC
    `;
    const [rows] = await pool.execute(query, [userId]);
    
    if (rows.length === 0) return 0;

    const today = new Date();
    // Normalize to timezone offset to avoidUTC offset bugs if running locally
    // Actually, simple strings are safer since SQL date behaves oddly in JS
    const toDateString = (d) => {
      const y = d.getFullYear();
      const m = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${y}-${m}-${day}`;
    };

    const todayDate = new Date();
    
    const yesterdayDate = new Date(todayDate);
    yesterdayDate.setDate(yesterdayDate.getDate() - 1);

    const activeDatesStr = rows.map(r => {
      const d = new Date(r.date);
      return toDateString(d);
    });

    let currentDateToCheck = todayDate;
    let currentDateStr = toDateString(currentDateToCheck);
    
    if (!activeDatesStr.includes(currentDateStr)) {
      currentDateToCheck = yesterdayDate;
      currentDateStr = toDateString(currentDateToCheck);
      if (!activeDatesStr.includes(currentDateStr)) {
         return 0;
      }
    }

    let streak = 0;
    while (activeDatesStr.includes(currentDateStr)) {
      streak++;
      currentDateToCheck.setDate(currentDateToCheck.getDate() - 1);
      currentDateStr = toDateString(currentDateToCheck);
    }
    
    return streak;
  }

  static async getStatistics(userId) {
    // 1. Health data stats
    const healthQuery = `
      SELECT 
        COUNT(*) as total_days,
        SUM(steps) as total_steps,
        SUM(calories) as total_calories,
        SUM(distance) as total_distance,
        MAX(steps) as max_steps,
        MAX(calories) as max_calories,
        MAX(distance) as max_distance
      FROM health_data
      WHERE user_id = ?
    `;
    const [healthRows] = await pool.execute(healthQuery, [userId]);
    const h = healthRows[0];

    const totalDays = h.total_days || 0;
    const totalWeeks = totalDays > 0 ? Math.max(1, totalDays / 7) : 1;

    // 2. Token stats
    const tokenQuery = `
      SELECT 
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as total_earned,
        MAX(CASE WHEN amount > 0 THEN amount ELSE 0 END) as max_token_transaction,
        MIN(CASE WHEN amount < 0 THEN amount ELSE 0 END) as max_token_spent
      FROM token_transactions
      WHERE user_id = ?
    `;
    const [tokenRows] = await pool.execute(tokenQuery, [userId]);
    const t = tokenRows[0];

    const totalEarned = t.total_earned || 0;
    const maxToken = t.max_token_transaction || 0;
    const maxPay = Math.abs(t.max_token_spent || 0);

    const activeDays = totalDays > 0 ? totalDays : 1; // avoid division by zero
    
    // We will ensure values are integers for UI formatting if they are meant to be discrete
    return {
      avgStepsPerWeek: Math.round((h.total_steps || 0) / totalWeeks),
      avgCaloriesPerWeek: Math.round((h.total_calories || 0) / totalWeeks),
      avgDistancePerWeek: Number(((h.total_distance || 0) / totalWeeks).toFixed(1)),
      maxSteps: Math.round(h.max_steps || 0),
      maxCalories: Math.round(h.max_calories || 0),
      maxDistance: Number((h.max_distance || 0).toFixed(1)),
      avgTokenPerDay: Math.round(totalEarned / activeDays),
      maxToken: Math.round(maxToken),
      maxPay: Math.round(maxPay)
    };
  }
}

module.exports = HealthModel;
