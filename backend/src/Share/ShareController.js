const ShareModel = require('./ShareModel');

class ShareController {
  /**
   * GET /share/today
   * Returns the "Today Summary" card data for the share page.
   */
  static async getTodaySummary(req, res) {
    try {
      const userId = req.user.id;
      const summary = await ShareModel.getTodaySummary(userId);
      return res.status(200).json(summary);
    } catch (error) {
      console.error('Error in ShareController.getTodaySummary:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  /**
   * POST /share/log
   * Log that the user shared their summary to a platform.
   * Body: { platform: "instagram" | "save" | "copy_link" | "more", data?: {} }
   */
  static async logShare(req, res) {
    try {
      const userId = req.user.id;
      const { platform, data } = req.body;

      if (!platform) {
        return res.status(400).json({ message: 'platform is required' });
      }

      const logId = await ShareModel.logShareEvent(userId, platform, data);
      return res.status(201).json({ message: 'Share logged', logId });
    } catch (error) {
      console.error('Error in ShareController.logShare:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  /**
   * GET /share/history
   * Get user's share history (for analytics).
   */
  static async getShareHistory(req, res) {
    try {
      const userId = req.user.id;
      const limit = parseInt(req.query.limit) || 10;
      const history = await ShareModel.getShareHistory(userId, limit);
      return res.status(200).json({ shares: history });
    } catch (error) {
      console.error('Error in ShareController.getShareHistory:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
}

module.exports = ShareController;
