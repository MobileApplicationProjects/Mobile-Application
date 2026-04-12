const pool = require('../config/db');
const crypto = require('crypto');

class ChallengeModel {
  static async createChallenge(data) {
    const { title, description, target_type, target_value, reward_amount, deadline } = data;
    
    const query = `
      INSERT INTO challenges (title, description, target_type, target_value, reward_amount, deadline)
      VALUES (?, ?, ?, ?, ?, ?)
    `;

    // Process optional date
    let sqlDate = null;
    if (deadline && deadline !== 'No limit date') {
      try {
        if (deadline.includes('/')) {
          const parts = deadline.split(' ')[0].split('/');
          const timePart = deadline.includes(' ') ? deadline.split(' ')[1] : '00:00:00';
          sqlDate = `${parts[2]}-${parts[1]}-${parts[0]} ${timePart}`;
        } else {
          sqlDate = deadline;
        }
      } catch (e) {
        console.error('Date parsing error:', e);
        sqlDate = null;
      }
    }

    const [result] = await pool.execute(query, [
      title,
      description || null,
      target_type || 'Steps',
      target_value || 0,
      reward_amount || 0,
      sqlDate
    ]);
    
    return result.insertId;
  }

  static async updateChallenge(id, data) {
    const { title, description, target_type, target_value, reward_amount, deadline, is_active } = data;
    
    // Process optional date
    let sqlDate = null;
    if (deadline && deadline !== 'No limit date') {
      try {
        if (deadline.includes('/')) {
          const parts = deadline.split(' ')[0].split('/');
          const timePart = deadline.includes(' ') ? deadline.split(' ')[1] : '00:00:00';
          sqlDate = `${parts[2]}-${parts[1]}-${parts[0]} ${timePart}`;
        } else {
          sqlDate = deadline;
        }
      } catch (e) {
        console.error('Date parsing error:', e);
        sqlDate = null;
      }
    }

    const query = `
      UPDATE challenges 
      SET title = ?, description = ?, target_type = ?, target_value = ?, reward_amount = ?, deadline = ?, is_active = ?
      WHERE id = ?
    `;

    const [result] = await pool.execute(query, [
      title,
      description || null,
      target_type || 'Steps',
      target_value || 0,
      reward_amount || 0,
      sqlDate,
      is_active !== undefined ? is_active : 1,
      id
    ]);
    
    return result.affectedRows > 0;
  }

  static async getAllChallenges() {
    const query = `
      SELECT id, title, description, target_type, target_value, reward_amount, deadline, is_active, created_at
      FROM challenges
      WHERE is_active = 1
      ORDER BY id DESC
    `;
    const [rows] = await pool.execute(query);
    return rows;
  }

  static async getLatestChallenge(userId) {
    const query = `
      SELECT c.*, uc.status as user_status, uc.completed_at
      FROM challenges c
      LEFT JOIN user_challenges uc ON c.id = uc.challenge_id AND uc.user_id = ?
      WHERE c.is_active = 1
      ORDER BY c.id DESC
      LIMIT 1
    `;
    const [rows] = await pool.execute(query, [userId]);
    return rows.length > 0 ? rows[0] : null;
  }

  static async claimChallenge(userId, challengeId) {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      // 1. Get Challenge Details
      const [challengeRows] = await connection.execute(
        'SELECT id, reward_amount, title FROM challenges WHERE id = ? AND is_active = 1',
        [challengeId]
      );
      if (challengeRows.length === 0) throw new Error('Challenge not found or inactive');
      const challenge = challengeRows[0];

      // 2. Check if already claimed
      const [userChallengeRows] = await connection.execute(
        'SELECT status FROM user_challenges WHERE user_id = ? AND challenge_id = ?',
        [userId, challengeId]
      );
      
      if (userChallengeRows.length > 0 && userChallengeRows[0].status === 'Claimed') {
        throw new Error('Challenge already claimed');
      }

      // 3. Award Tokens (Update Wallet)
      const [walletRows] = await connection.execute(
        'SELECT current_balance FROM user_wallets WHERE user_id = ? FOR UPDATE',
        [userId]
      );
      
      let newBalance = challenge.reward_amount;
      if (walletRows.length === 0) {
        await connection.execute(
          'INSERT INTO user_wallets (user_id, current_balance, total_earned_lifetime) VALUES (?, ?, ?)',
          [userId, challenge.reward_amount, challenge.reward_amount]
        );
      } else {
        newBalance = walletRows[0].current_balance + challenge.reward_amount;
        await connection.execute(
          'UPDATE user_wallets SET current_balance = ?, total_earned_lifetime = total_earned_lifetime + ? WHERE user_id = ?',
          [newBalance, challenge.reward_amount, userId]
        );
      }

      // 4. Record Transaction
      const transactionId = crypto.randomUUID();
      await connection.execute(
        `INSERT INTO token_transactions (id, user_id, amount, transaction_type, reference_id) 
         VALUES (?, ?, ?, 'Earn_Challenge', ?)`,
        [transactionId, userId, challenge.reward_amount, String(challengeId)]
      );

      // 5. Update or Insert user_challenges status
      if (userChallengeRows.length === 0) {
        await connection.execute(
          'INSERT INTO user_challenges (user_id, challenge_id, progress_value, status, completed_at) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)',
          [userId, challengeId, 100, 'Claimed'] // Using 100 as broad "complete" progress for now
        );
      } else {
        await connection.execute(
          'UPDATE user_challenges SET status = ?, completed_at = CURRENT_TIMESTAMP WHERE user_id = ? AND challenge_id = ?',
          ['Claimed', userId, challengeId]
        );
      }

      await connection.commit();
      return { success: true, reward_amount: challenge.reward_amount, newBalance };
    } catch (error) {
      await connection.rollback();
      throw error;
    } finally {
      connection.release();
    }
  }
}

module.exports = ChallengeModel;
