const HealthModel = require('./HealthModel');

class HealthController {
  static async syncData(req, res) {
    try {
      const userId = req.user.id; // from Auth Middleware
      const { date, steps, calories, distance } = req.body;

      if (!date) {
        return res.status(400).json({ message: 'Date is required (DD/MM/YYYY)' });
      }

      await HealthModel.upsertDailyData(userId, date, steps, calories, distance);

      return res.status(200).json({ message: 'Health data synced successfully' });
    } catch (error) {
      console.error('Error in HealthController.syncData:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async getMetrics(req, res) {
    try {
      const userId = req.user.id;
      const { date, startDate, endDate } = req.query;

      if (date) {
        const data = await HealthModel.getDailyData(userId, date);
        if (!data) {
          return res.status(200).json({ 
            date, 
            steps: 0, 
            calories: 0, 
            distance: 0 
          });
        }
        return res.status(200).json({
          date: data.dateFormatted,
          steps: data.steps,
          calories: data.calories,
          distance: data.distance
        });
      } else if (startDate && endDate) {
        const data = await HealthModel.getWeeklyData(userId, startDate, endDate);
        return res.status(200).json(data);
      } else {
        return res.status(400).json({ message: 'Please provide date or startDate/endDate' });
      }
    } catch (error) {
      console.error('Error in HealthController.getMetrics:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async getYearlyMetrics(req, res) {
    try {
      const userId = req.user.id;
      const { year } = req.query;

      if (!year) {
        return res.status(400).json({ message: 'Year is required' });
      }

      const data = await HealthModel.getYearlyData(userId, parseInt(year));
      return res.status(200).json(data);
    } catch (error) {
      console.error('Error in HealthController.getYearlyMetrics:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
}

module.exports = HealthController;
