const pool = require('../config/db');
const crypto = require('crypto');

class LocationModel {
  /**
   * Start a new tracking session (run/walk).
   * Returns the session id.
   */
  static async startSession(userId) {
    const id = crypto.randomUUID();
    await pool.execute(
      `INSERT INTO location_sessions (id, user_id, started_at)
       VALUES (?, ?, NOW())`,
      [id, userId]
    );
    return id;
  }

  /**
   * End an existing session — calculates total distance & duration.
   */
  static async endSession(sessionId, userId) {
    // Calculate total distance from the recorded points
    const [distRows] = await pool.execute(
      `SELECT
         COALESCE(SUM(dist), 0) AS total_distance_m,
         COUNT(*) AS point_count
       FROM (
         SELECT
           ST_Distance_Sphere(
             POINT(lng, lat),
             POINT(
               LEAD(lng) OVER (ORDER BY recorded_at),
               LEAD(lat) OVER (ORDER BY recorded_at)
             )
           ) AS dist
         FROM location_points
         WHERE session_id = ?
       ) t
       WHERE dist IS NOT NULL`,
      [sessionId]
    );

    const totalDistanceM = distRows[0]?.total_distance_m || 0;

    await pool.execute(
      `UPDATE location_sessions
       SET ended_at    = NOW(),
           distance_m  = ?,
           updated_at  = CURRENT_TIMESTAMP
       WHERE id = ? AND user_id = ?`,
      [totalDistanceM, sessionId, userId]
    );

    return { totalDistanceM };
  }

  /**
   * Record a batch of GPS points for a session.
   * points: [{ lat, lng, altitude?, speed?, recordedAt? }]
   */
  static async addPoints(sessionId, userId, points) {
    if (!points || points.length === 0) return 0;

    // Verify session ownership
    const [sess] = await pool.execute(
      'SELECT id FROM location_sessions WHERE id = ? AND user_id = ? LIMIT 1',
      [sessionId, userId]
    );
    if (sess.length === 0) {
      throw new Error('Session not found or not owned by user');
    }

    const values = [];
    const placeholders = [];

    for (const p of points) {
      const id = crypto.randomUUID();
      const alt = p.altitude ?? null;
      const spd = p.speed ?? null;
      const ts = p.recordedAt ? new Date(p.recordedAt) : new Date();
      values.push(id, sessionId, p.lat, p.lng, alt, spd, ts);
      placeholders.push('(?, ?, ?, ?, ?, ?, ?)');
    }

    await pool.execute(
      `INSERT INTO location_points (id, session_id, lat, lng, altitude, speed, recorded_at)
       VALUES ${placeholders.join(', ')}`,
      values
    );

    return points.length;
  }

  /**
   * Get all points for one session (for drawing route polyline).
   */
  static async getSessionPoints(sessionId, userId) {
    const [rows] = await pool.execute(
      `SELECT lp.lat, lp.lng, lp.altitude, lp.speed, lp.recorded_at
       FROM location_points lp
       JOIN location_sessions ls ON lp.session_id = ls.id
       WHERE lp.session_id = ? AND ls.user_id = ?
       ORDER BY lp.recorded_at ASC`,
      [sessionId, userId]
    );
    return rows;
  }

  /**
   * List all sessions for a user (most recent first).
   */
  static async listSessions(userId, limit = 20) {
    const [rows] = await pool.execute(
      `SELECT id, started_at, ended_at, distance_m,
              TIMESTAMPDIFF(SECOND, started_at, COALESCE(ended_at, NOW())) AS duration_sec
       FROM location_sessions
       WHERE user_id = ?
       ORDER BY started_at DESC
       LIMIT ?`,
      [userId, limit]
    );
    return rows;
  }

  /**
   * Get latest session with its polyline (for map page quick load).
   */
  static async getLatestSession(userId) {
    const [sess] = await pool.execute(
      `SELECT id, started_at, ended_at, distance_m
       FROM location_sessions
       WHERE user_id = ?
       ORDER BY started_at DESC
       LIMIT 1`,
      [userId]
    );
    if (sess.length === 0) return null;

    const session = sess[0];
    const points = await this.getSessionPoints(session.id, userId);
    return { ...session, points };
  }

  /**
   * Delete a session and its points.
   */
  static async deleteSession(sessionId, userId) {
    await pool.execute(
      'DELETE FROM location_points WHERE session_id = ?',
      [sessionId]
    );
    const [result] = await pool.execute(
      'DELETE FROM location_sessions WHERE id = ? AND user_id = ?',
      [sessionId, userId]
    );
    return result.affectedRows > 0;
  }
}

module.exports = LocationModel;
