const pool = require('../config/db');

const isAdmin = async (req, res, next) => {
  try {
    // req.user is set by authMiddleware
    if (!req.user || !req.user.id) {
      return res.status(401).json({ message: 'Unauthorized: User not found in request' });
    }

    const userId = req.user.id;
    const [rows] = await pool.execute('SELECT role FROM users WHERE id = ? LIMIT 1', [userId]);

    if (rows.length === 0) {
      return res.status(404).json({ message: 'User not found in database' });
    }

    const role = rows[0].role;
    if (role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden: Admin privileges required' });
    }

    next();
  } catch (error) {
    console.error('Error in adminMiddleware:', error);
    return res.status(500).json({ message: 'Internal server error during admin validation' });
  }
};

module.exports = isAdmin;
