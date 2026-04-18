const pool = require('../config/db');

class AccountModel {
  static async createUser(userData) {
    const { id, email, username, first_name, last_name, weight_kg, height_cm, gender, password_hash } = userData;
    let connection;

    try {
      // Get a connection from the pool to use for a transaction
      connection = await pool.getConnection();
      await connection.beginTransaction();

      const userQuery = `
        INSERT INTO users (id, email, username, password_hash)
        VALUES (?, ?, ?, ?)
      `;
      await connection.execute(userQuery, [id, email, username || null, password_hash]);

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
      SELECT u.id, u.email, u.username, u.password_hash, u.role, p.first_name, p.last_name, p.gender, p.weight_kg, p.height_cm, p.avatar_url, p.birth_date, p.address_street, p.address_district, w.current_balance
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN user_wallets w ON u.id = w.user_id
      WHERE u.email = ? LIMIT 1
    `;
    const [rows] = await pool.execute(query, [email]);
    return rows[0];
  }

  static async findByUsername(username) {
    const query = `
      SELECT id, username FROM users WHERE username = ? LIMIT 1
    `;
    const [rows] = await pool.execute(query, [username]);
    return rows[0];
  }

  static async findById(id) {
    const query = `
      SELECT u.id, u.email, u.username, u.role, p.first_name, p.last_name, p.gender, p.weight_kg, p.height_cm, p.avatar_url, p.birth_date, p.address_street, p.address_district, w.current_balance
      FROM users u
      LEFT JOIN user_profiles p ON u.id = p.user_id
      LEFT JOIN user_wallets w ON u.id = w.user_id
      WHERE u.id = ? LIMIT 1
    `;
    const [rows] = await pool.execute(query, [id]);
    return rows[0];
  }

  static async updateAvatar(userId, avatarUrl) {
    const query = `
      UPDATE user_profiles SET avatar_url = ? WHERE user_id = ?
    `;
    await pool.execute(query, [avatarUrl, userId]);
  }

  static async updateProfile(userId, profileData) {
    const { first_name, last_name, weight_kg, height_cm, gender, birth_date, address_street, address_district } = profileData;
    
    // Normalize gender formatting
    let formattedGender = 'Other';
    if (gender) {
      if (gender.toLowerCase() === 'male' || gender.toLowerCase() === 'ชาย') formattedGender = 'Male';
      else if (gender.toLowerCase() === 'female' || gender.toLowerCase() === 'หญิง') formattedGender = 'Female';
    }

    const query = `
      UPDATE user_profiles 
      SET 
        first_name = COALESCE(?, first_name),
        last_name = COALESCE(?, last_name),
        weight_kg = COALESCE(?, weight_kg),
        height_cm = COALESCE(?, height_cm),
        gender = COALESCE(?, gender),
        birth_date = COALESCE(?, birth_date),
        address_street = COALESCE(?, address_street),
        address_district = COALESCE(?, address_district)
      WHERE user_id = ?
    `;

    const values = [
      first_name !== undefined ? first_name : null,
      last_name !== undefined ? last_name : null,
      weight_kg !== undefined ? weight_kg : null,
      height_cm !== undefined ? height_cm : null,
      gender !== undefined ? formattedGender : null,
      birth_date !== undefined ? birth_date : null,
      address_street !== undefined ? address_street : null,
      address_district !== undefined ? address_district : null,
      userId
    ];

    await pool.execute(query, values);
  }

  static async getTransactions(userId) {
    const query = `
      SELECT id, amount, transaction_type, created_at, reference_id
      FROM token_transactions
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT 100
    `;
    const [rows] = await pool.execute(query, [userId]);
    return rows;
  }

  static async getBalance(userId) {
    const [rows] = await pool.execute(
      'SELECT current_balance FROM user_wallets WHERE user_id = ? LIMIT 1',
      [userId]
    );
    return rows.length > 0 ? (rows[0].current_balance ?? 0) : 0;
  }
}

module.exports = AccountModel;
