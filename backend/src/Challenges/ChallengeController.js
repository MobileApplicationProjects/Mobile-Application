const ChallengeModel = require('./ChallengeModel');

class ChallengeController {
  static async createChallenge(req, res) {
    try {
      const { title, description, target_type, target_value, reward_amount, deadline } = req.body;

      if (!title || reward_amount === undefined) {
        return res.status(400).json({ message: 'Title and reward_amount are required' });
      }

      const insertId = await ChallengeModel.createChallenge({
        title,
        description,
        target_type,
        target_value,
        reward_amount,
        deadline
      });

      return res.status(201).json({ 
        message: 'Challenge created successfully', 
        id: insertId 
      });
    } catch (error) {
      console.error('Error in ChallengeController.createChallenge:', error);
      return res.status(500).json({ 
        message: 'Internal server error', 
        error: error.message 
      });
    }
  }

  static async updateChallenge(req, res) {
    try {
      const { id } = req.params;
      const { title, description, target_type, target_value, reward_amount, deadline, is_active } = req.body;

      if (!title || reward_amount === undefined) {
        return res.status(400).json({ message: 'Title and reward_amount are required' });
      }

      const success = await ChallengeModel.updateChallenge(id, {
        title,
        description,
        target_type,
        target_value,
        reward_amount,
        deadline,
        is_active
      });

      if (!success) {
        return res.status(404).json({ message: 'Challenge not found' });
      }

      return res.status(200).json({ message: 'Challenge updated successfully' });
    } catch (error) {
      console.error('Error in ChallengeController.updateChallenge:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async getChallenges(req, res) {
    try {
      const challenges = await ChallengeModel.getAllChallenges();
      return res.status(200).json(challenges);
    } catch (error) {
      console.error('Error in ChallengeController.getChallenges:', error);
      return res.status(500).json({ 
        message: 'Internal server error', 
        error: error.message 
      });
    }
  }

  static async getLatestChallenge(req, res) {
    try {
      const userId = req.user.id;
      const challenge = await ChallengeModel.getLatestChallenge(userId);
      return res.status(200).json(challenge);
    } catch (error) {
      console.error('Error in ChallengeController.getLatestChallenge:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async claimChallenge(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;
      const result = await ChallengeModel.claimChallenge(userId, id);
      return res.status(200).json(result);
    } catch (error) {
      console.error('Error in ChallengeController.claimChallenge:', error);
      return res.status(400).json({ message: error.message });
    }
  }
}

module.exports = ChallengeController;
