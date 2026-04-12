const RewardModel = require('./RewardModel');

class RewardController {
  static async createReward(req, res) {
    try {
      const { partner_name, title, description, expiry_date, cost_in_tokens, total_stock, image_url, is_donation } = req.body;

      if (!title || cost_in_tokens === undefined) {
        return res.status(400).json({ message: 'Title and cost_in_tokens are required' });
      }

      const insertId = await RewardModel.createReward({
        partner_name,
        title,
        description,
        expiry_date,
        cost_in_tokens,
        total_stock,
        image_url,
        is_donation
      });

      return res.status(201).json({ message: 'Reward created successfully', id: insertId });
    } catch (error) {
      console.error('Error in RewardController.createReward:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async getRewards(req, res) {
    try {
      const rewards = await RewardModel.getAllRewards();
      return res.status(200).json(rewards);
    } catch (error) {
      console.error('Error in RewardController.getRewards:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async redeemReward(req, res) {
    try {
      const { rewardId } = req.body;
      const userId = req.user.id; // From verifyToken middleware

      if (!rewardId) {
        return res.status(400).json({ message: 'Reward ID is required' });
      }

      const result = await RewardModel.redeemReward(userId, rewardId);
      
      return res.status(200).json({
        message: 'แลกของรางวัลสำเร็จ!',
        transactionId: result.transactionId,
        newBalance: result.newBalance
      });
    } catch (error) {
      console.error('Error in RewardController.redeemReward:', error);
      
      // Handle known operational errors (e.g., insufficient funds, no stock)
      if (error.message.includes('Not enough') || error.message.includes('Out of stock') || error.message.includes('not found')) {
        return res.status(400).json({ message: error.message });
      }
      
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
}

module.exports = RewardController;
