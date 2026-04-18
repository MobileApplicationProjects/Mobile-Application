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
  static async getStreak(req, res) {
    try {
      const userId = req.user.id;
      const streak = await HealthModel.getStreak(userId);
      return res.status(200).json({ streak });
    } catch (error) {
      console.error('Error in HealthController.getStreak:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
  static async getStatistics(req, res) {
    try {
      const userId = req.user.id;
      const stats = await HealthModel.getStatistics(userId);
      return res.status(200).json(stats);
    } catch (error) {
      console.error('Error in HealthController.getStatistics:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async getGoal(req, res) {
    try {
      const userId = req.user.id;
      const goal = await HealthModel.getGoal(userId);
      return res.status(200).json({ stepGoalDaily: goal });
    } catch (error) {
      console.error('Error in HealthController.getGoal:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async setGoal(req, res) {
    try {
      const userId = req.user.id;
      const { stepGoalDaily } = req.body;
      if (!stepGoalDaily || stepGoalDaily < 500) {
        return res.status(400).json({ message: 'stepGoalDaily must be >= 500' });
      }
      await HealthModel.setGoal(userId, stepGoalDaily);
      return res.status(200).json({ message: 'Goal saved', stepGoalDaily });
    } catch (error) {
      console.error('Error in HealthController.setGoal:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async getSummary(req, res) {
    try {
      const userId = req.user.id;
      const { period } = req.query; // D, W, M, Y
      if (!['D','W','M','Y'].includes(period)) {
        return res.status(400).json({ message: 'period must be one of D, W, M, Y' });
      }
      const data = await HealthModel.getSummary(userId, period);
      return res.status(200).json(data);
    } catch (error) {
      console.error('Error in HealthController.getSummary:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
}

module.exports = HealthController;
