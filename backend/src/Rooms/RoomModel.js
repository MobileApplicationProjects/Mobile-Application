const pool = require('../config/db');
const { v4: uuidv4 } = require('uuid');

class RoomModel {
  static async createRoom(roomData) {
    const { name, duration_days, created_by, members } = roomData;
    let connection;

    try {
      connection = await pool.getConnection();
      await connection.beginTransaction();

      const roomId = uuidv4();
      // start_date is automatically CURRENT_TIMESTAMP, end_date will be CURRENT_TIMESTAMP + duration_days
      const roomQuery = `
        INSERT INTO rooms (id, name, duration_days, created_by, end_date)
        VALUES (?, ?, ?, ?, DATE_ADD(CURRENT_TIMESTAMP, INTERVAL ? DAY))
      `;
      await connection.execute(roomQuery, [roomId, name, duration_days, created_by, duration_days]);

      // Add the creator automatically as 'accepted'
      const addCreatorQuery = `
        INSERT INTO room_members (room_id, user_id, status)
        VALUES (?, ?, 'accepted')
      `;
      await connection.execute(addCreatorQuery, [roomId, created_by]);

      // Invite members
      if (members && members.length > 0) {
        const inviteQuery = `
          INSERT IGNORE INTO room_members (room_id, user_id, status)
          VALUES (?, ?, 'invited')
        `;
        for (const userId of members) {
          if (userId !== created_by) {
            await connection.execute(inviteQuery, [roomId, userId]);
          }
        }
      }

      await connection.commit();
      return roomId;
    } catch (error) {
      if (connection) {
        await connection.rollback();
      }
      throw error;
    } finally {
      if (connection) {
        connection.release();
      }
    }
  }

  static async findUserByUsername(username) {
    const query = `SELECT id, username FROM users WHERE username = ? LIMIT 1`;
    const [rows] = await pool.execute(query, [username]);
    return rows[0];
  }
  
  static async findUserByEmailOrUsername(identifier) {
    const query = `SELECT id, username, email FROM users WHERE username = ? OR email = ? LIMIT 1`;
    const [rows] = await pool.execute(query, [identifier, identifier]);
    return rows[0];
  }

  static async getRoomsForUser(userId) {
    const query = `
      SELECT r.id, r.name, r.duration_days, r.start_date, r.end_date, r.created_by, rm.status as member_status, u.username as creator_username
      FROM rooms r
      JOIN room_members rm ON r.id = rm.room_id
      JOIN users u ON r.created_by = u.id
      WHERE rm.user_id = ?
      ORDER BY r.created_at DESC
    `;
    const [rows] = await pool.execute(query, [userId]);
    return rows;
  }

  static async acceptInvite(roomId, userId) {
    const query = `
      UPDATE room_members
      SET status = 'accepted'
      WHERE room_id = ? AND user_id = ?
    `;
    const [result] = await pool.execute(query, [roomId, userId]);
    return result.affectedRows > 0;
  }

  static async getRoomLeaderboard(roomId) {
    // 1. Get room details for dates
    const roomQuery = `SELECT * FROM rooms WHERE id = ?`;
    const [rooms] = await pool.execute(roomQuery, [roomId]);
    if (rooms.length === 0) return null;
    const room = rooms[0];

    // 2. Get sum of steps for all accepted members within the date range
    // Fix: Pass start_date and end_date as params instead of relying on JOIN alias
    const query = `
      SELECT 
        rm.user_id, 
        u.username,
        u.email,
        up.first_name,
        up.last_name,
        up.avatar_url,
        COALESCE(SUM(hd.steps), 0) as total_steps
      FROM room_members rm
      JOIN users u ON rm.user_id = u.id
      LEFT JOIN user_profiles up ON rm.user_id = up.user_id
      LEFT JOIN health_data hd 
          ON rm.user_id = hd.user_id 
          AND hd.date >= DATE(?)
          AND hd.date <= DATE(?)
      WHERE rm.room_id = ? AND rm.status = 'accepted'
      GROUP BY rm.user_id, u.username, u.email, up.first_name, up.last_name, up.avatar_url
      ORDER BY total_steps DESC
    `;
    const [rows] = await pool.execute(query, [room.start_date, room.end_date, roomId]);
    
    return {
      room,
      leaderboard: rows
    };
  }
}

module.exports = RoomModel;
