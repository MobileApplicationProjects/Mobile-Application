const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const AccountModel = require('./AccountModel');

class AccountController {
  static async register(req, res) {
    try {
      const { email, firstName, lastName, weight, height, gender, password } = req.body;

      if (!email || !password || !firstName || !lastName || !gender) {
        return res.status(400).json({ message: 'Missing required fields' });
      }

      // Check if user already exists
      const existingUser = await AccountModel.findByEmail(email);
      if (existingUser) {
        return res.status(409).json({ message: 'Email already exists' });
      }

      // Hash password
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(password, salt);

      // Generate UUID
      const userId = uuidv4();

      // Save user using transaction
      const userData = {
        id: userId,
        email,
        first_name: firstName,
        last_name: lastName,
        weight_kg: weight,
        height_cm: height,
        gender,
        password_hash: hashedPassword
      };

      await AccountModel.createUser(userData);

      // Create JWT mapped to the string UUID
      const token = jwt.sign(
        { id: userId },
        process.env.JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.status(201).json({
        message: 'Account created successfully',
        token,
        user: { 
          id: userId, 
          email, 
          firstName, 
          lastName 
        }
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async login(req, res) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
      }

      const user = await AccountModel.findByEmail(email);
      if (!user) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      const token = jwt.sign(
        { id: user.id },
        process.env.JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.status(200).json({
        message: 'Login successful',
        token,
        user: { 
          id: user.id, 
          email: user.email, 
          firstName: user.first_name, 
          lastName: user.last_name,
          currentBalance: user.current_balance || 0 
        }
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async getProfile(req, res) {
    try {
      const userId = req.user.id;
      const userProfile = await AccountModel.findById(userId);

      if (!userProfile) {
        return res.status(404).json({ message: 'User profile not found' });
      }

      res.status(200).json({
        message: 'Profile retrieved successfully',
        profile: {
          id: userProfile.id,
          email: userProfile.email,
          role: userProfile.role || 'user',
          firstName: userProfile.first_name,
          lastName: userProfile.last_name,
          gender: userProfile.gender,
          weight: userProfile.weight_kg,
          height: userProfile.height_cm,
          currentBalance: userProfile.current_balance || 0
        }
      });
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
}

module.exports = AccountController;
