const pool = require('../config/db');

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
    
    const query = `
      INSERT INTO health_data (user_id, date, steps, calories, distance)
      VALUES (?, ?, ?, ?, ?)
      ON DUPLICATE KEY UPDATE
        steps = VALUES(steps),
        calories = VALUES(calories),
        distance = VALUES(distance),
        updated_at = CURRENT_TIMESTAMP
    `;
    
    // Convert undefined/null to 0 just in case
    const safeSteps = steps || 0;
    const safeCalories = calories || 0;
    const safeDistance = distance || 0;

    const [result] = await pool.execute(query, [userId, sqlDate, safeSteps, safeCalories, safeDistance]);
    return result;
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
}

module.exports = HealthModel;
