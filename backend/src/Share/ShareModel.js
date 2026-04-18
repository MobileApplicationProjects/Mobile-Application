const pool = require('../config/db');
const crypto = require('crypto');

class ShareModel {
  /**
   * Build the "Today Summary" card data for the share page.
   * Combines: health today + goal + latest route session.
   */
  static async getTodaySummary(userId) {
    const today = new Date().toISOString().split('T')[0];

    // 1. Health data for today
    const [healthRows] = await pool.execute(
      'SELECT steps, calories, distance FROM health_data WHERE user_id = ? AND date = ? LIMIT 1',
      [userId, today]
    );
    const health = healthRows[0] || { steps: 0, calories: 0, distance: 0 };

    // 2. Step goal
    const [goalRows] = await pool.execute(
      'SELECT step_goal_daily FROM user_profiles WHERE user_id = ? LIMIT 1',
      [userId]
    );
    const goal = goalRows[0]?.step_goal_daily || 5000;

    // 3. User profile info (for the share card branding)
    const [profileRows] = await pool.execute(
      'SELECT first_name, last_name, username, avatar_url FROM user_profiles WHERE user_id = ? LIMIT 1',
      [userId]
    );
    const profile = profileRows[0] || {};

    // 4. Latest session route (polyline for map preview)
    let latestRoute = null;
    try {
      const [sessRows] = await pool.execute(
        `SELECT id, started_at, ended_at, distance_m
         FROM location_sessions
         WHERE user_id = ? AND DATE(started_at) = ?
         ORDER BY started_at DESC LIMIT 1`,
        [userId, today]
      );
      if (sessRows.length > 0) {
        const [points] = await pool.execute(
          'SELECT lat, lng FROM location_points WHERE session_id = ? ORDER BY recorded_at ASC',
          [sessRows[0].id]
        );
        latestRoute = {
          sessionId: sessRows[0].id,
          startedAt: sessRows[0].started_at,
          endedAt: sessRows[0].ended_at,
          distanceM: sessRows[0].distance_m,
          points: points.map(p => ({ lat: p.lat, lng: p.lng }))
        };
      }
    } catch (_) {
      // location_sessions table may not exist yet — graceful fallback
    }

    return {
      date: today,
      steps: health.steps || 0,
      calories: Number((health.calories || 0).toFixed(0)),
      distanceM: Number((health.distance || 0).toFixed(1)),
      distanceKm: Number(((health.distance || 0) / 1000).toFixed(2)),
      stepGoalDaily: goal,
      progressPercent: goal > 0 ? Math.min(100, Math.round(((health.steps || 0) / goal) * 100)) : 0,
      profile: {
        firstName: profile.first_name || '',
        lastName: profile.last_name || '',
        username: profile.username || '',
        avatarUrl: profile.avatar_url || null
      },
      route: latestRoute
    };
  }

  /**
   * Log a share event (for analytics tracking).
   */
  static async logShareEvent(userId, platform, sharedData) {
    const id = crypto.randomUUID();
    await pool.execute(
      `INSERT INTO share_logs (id, user_id, platform, shared_data, created_at)
       VALUES (?, ?, ?, ?, NOW())`,
      [id, userId, platform, JSON.stringify(sharedData || {})]
    );
    return id;
  }

  /**
   * Get share history for a user (analytics / recent shares).
   */
  static async getShareHistory(userId, limit = 10) {
    const [rows] = await pool.execute(
      `SELECT id, platform, created_at
       FROM share_logs
       WHERE user_id = ?
       ORDER BY created_at DESC
       LIMIT ?`,
      [userId, limit]
    );
    return rows;
  }
}

module.exports = ShareModel;
