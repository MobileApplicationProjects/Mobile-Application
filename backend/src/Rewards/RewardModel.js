const pool = require('../config/db');
const crypto = require('crypto');

class RewardModel {
  static async createReward(data) {
    const { partner_name, title, description, expiry_date, cost_in_tokens, total_stock, image_url, is_donation } = data;
    
    const query = `
      INSERT INTO rewards (partner_name, title, description, cost_in_tokens, total_stock, expiry_date, image_url, is_donation)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    // Process optional date
    let sqlDate = null;
    if (expiry_date) {
      if (expiry_date.includes('/')) {
        const p = expiry_date.split('/');
        sqlDate = `${p[2]}-${p[1]}-${p[0]}`;
      } else {
        sqlDate = expiry_date; // Assumes YYYY-MM-DD
      }
    }

    const safeIsDonation = is_donation === true || is_donation === 'true' ? 1 : 0;
    
    const [result] = await pool.execute(query, [
      partner_name || 'General',
      title, 
      description || null, 
      cost_in_tokens || 0,
      total_stock || 0,
      sqlDate, 
      image_url || null, 
      safeIsDonation
    ]);
    
    return result.insertId;
  }

  static async getAllRewards() {
    const query = `
      SELECT id, partner_name, title, description, cost_in_tokens, total_stock, expiry_date, image_url, is_active, is_donation, created_at
      FROM rewards
      WHERE is_active = 1
      ORDER BY id DESC
    `;
    const [rows] = await pool.execute(query);
    return rows;
  }

  static async redeemReward(userId, rewardId) {
    let connection;
    try {
      connection = await pool.getConnection();
      await connection.beginTransaction();

      // 1. Get Reward details (use FOR UPDATE to lock row if tracking stock)
      const [rewardRows] = await connection.execute(
        `SELECT id, title, cost_in_tokens, total_stock, is_donation, is_active FROM rewards WHERE id = ? FOR UPDATE`,
        [rewardId]
      );
      if (rewardRows.length === 0) throw new Error('Reward not found');
      const reward = rewardRows[0];
      if (reward.is_active === 0) throw new Error('Reward is inactive');

      // 2. Get User Wallet
      const [walletRows] = await connection.execute(
        `SELECT current_balance FROM user_wallets WHERE user_id = ? FOR UPDATE`,
        [userId]
      );
      
      let currentBalance = 0;
      if (walletRows.length === 0) {
        // Auto-create wallet if missing
        await connection.execute(`INSERT INTO user_wallets (user_id, current_balance, total_earned_lifetime) VALUES (?, 0, 0)`, [userId]);
      } else {
        currentBalance = walletRows[0].current_balance;
      }

      // 3. Validation
      if (currentBalance < reward.cost_in_tokens) {
        throw new Error('Not enough tokens');
      }

      // Check stock limit for non-donation items
      if (reward.is_donation === 0 || reward.is_donation === false) {
        if (reward.total_stock <= 0) {
          throw new Error('Out of stock');
        }
      }

      // 4. Deduct Tokens
      const newBalance = currentBalance - reward.cost_in_tokens;
      await connection.execute(
        `UPDATE user_wallets SET current_balance = ? WHERE user_id = ?`,
        [newBalance, userId]
      );

      // 5. Update Stock (if not donation)
      if (reward.is_donation === 0 || reward.is_donation === false) {
        await connection.execute(
          `UPDATE rewards SET total_stock = total_stock - 1 WHERE id = ?`,
          [rewardId]
        );
      }

      // 6. Record Transaction
      const transactionId = crypto.randomUUID();
      await connection.execute(
        `INSERT INTO token_transactions (id, user_id, amount, transaction_type, reference_id) VALUES (?, ?, ?, 'Spend_Reward', ?)`,
        [transactionId, userId, -reward.cost_in_tokens, String(rewardId)]
      );

      await connection.commit();
      return { transactionId, newBalance };
    } catch (error) {
      if (connection) await connection.rollback();
      throw error;
    } finally {
      if (connection) connection.release();
    }
  }
}

module.exports = RewardModel;
