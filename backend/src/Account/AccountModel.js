const pool = require('../config/db');

class AccountModel {
  static async createUser(userData) {
    const { id, email, first_name, last_name, weight_kg, height_cm, gender, password_hash } = userData;
    let connection;

    try {
      // Get a connection from the pool to use for a transaction
      connection = await pool.getConnection();
      await connection.beginTransaction();

      const userQuery = `
        INSERT INTO users (id, email, password_hash)
        VALUES (?, ?, ?)
      `;
      await connection.execute(userQuery, [id, email, password_hash]);

      // Normalize gender formatting
      let formattedGender = 'Other';
      if (gender && (gender.toLowerCase() === 'male' || gender.toLowerCase() === 'ชาย')) formattedGender = 'Male';
      else if (gender && (gender.toLowerCase() === 'female' || gender.toLowerCase() === 'หญิง')) formattedGender = 'Female';

      const profileQuery = `
        INSERT INTO user_profiles (user_id, first_name, last_name, weight_kg, height_cm, gender)
        VALUES (?, ?, ?, ?, ?, ?)
      `;
      await connection.execute(profileQuery, [
        id,
        first_name,
        last_name,
        weight_kg || null,
        height_cm || null,
        formattedGender
      ]);

      await connection.commit();
      return { id }; // return the inserted UUID
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

  static async findByEmail(email) {
    const query = `
      SELECT u.id, u.email, u.password_hash, u.role, p.first_name, p.last_name, p.gender, p.weight_kg, p.height_cm, w.current_balance
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN user_wallets w ON u.id = w.user_id
      WHERE u.email = ? LIMIT 1
    `;
    const [rows] = await pool.execute(query, [email]);
    return rows[0];
  }

  static async findById(id) {
    const query = `
      SELECT u.id, u.email, u.role, p.first_name, p.last_name, p.gender, p.weight_kg, p.height_cm, w.current_balance
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN user_wallets w ON u.id = w.user_id
      WHERE u.id = ? LIMIT 1
    `;
    const [rows] = await pool.execute(query, [id]);
    return rows[0];
  }
}

module.exports = AccountModel;
