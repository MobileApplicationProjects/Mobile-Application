const LocationModel = require('./LocationModel');

class LocationController {
  /**
   * POST /location/sessions
   * Start a new tracking session.
   */
  static async startSession(req, res) {
    try {
      const userId = req.user.id;
      const sessionId = await LocationModel.startSession(userId);
      return res.status(201).json({ sessionId });
    } catch (error) {
      console.error('Error in LocationController.startSession:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  /**
   * PUT /location/sessions/:sessionId/end
   * End a tracking session and compute total distance.
   */
  static async endSession(req, res) {
    try {
      const userId = req.user.id;
      const { sessionId } = req.params;
      const result = await LocationModel.endSession(sessionId, userId);
      return res.status(200).json({ message: 'Session ended', ...result });
    } catch (error) {
      console.error('Error in LocationController.endSession:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  /**
   * POST /location/sessions/:sessionId/points
   * Upload a batch of GPS data points.
   * Body: { points: [{ lat, lng, altitude?, speed?, recordedAt? }] }
   */
  static async addPoints(req, res) {
    try {
      const userId = req.user.id;
      const { sessionId } = req.params;
      const { points } = req.body;

      if (!Array.isArray(points) || points.length === 0) {
        return res.status(400).json({ message: 'points array is required' });
      }

      const inserted = await LocationModel.addPoints(sessionId, userId, points);
      return res.status(201).json({ message: `${inserted} points saved` });
    } catch (error) {
      console.error('Error in LocationController.addPoints:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  /**
   * GET /location/sessions/:sessionId/points
   * Retrieve all GPS points for a specific session (for polyline rendering).
   */
  static async getSessionPoints(req, res) {
    try {
      const userId = req.user.id;
      const { sessionId } = req.params;
      const points = await LocationModel.getSessionPoints(sessionId, userId);
      return res.status(200).json({ points });
    } catch (error) {
      console.error('Error in LocationController.getSessionPoints:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  /**
   * GET /location/sessions
   * List user's tracking sessions (with metadata).
   */
  static async listSessions(req, res) {
    try {
      const userId = req.user.id;
      const limit = parseInt(req.query.limit) || 20;
      const sessions = await LocationModel.listSessions(userId, limit);
      return res.status(200).json({ sessions });
    } catch (error) {
      console.error('Error in LocationController.listSessions:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  /**
   * GET /location/sessions/latest
   * Get the latest session with its route (polyline) for map preview.
   */
  static async getLatestSession(req, res) {
    try {
      const userId = req.user.id;
      const session = await LocationModel.getLatestSession(userId);
      if (!session) {
        return res.status(200).json({ session: null });
      }
      return res.status(200).json({ session });
    } catch (error) {
      console.error('Error in LocationController.getLatestSession:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  /**
   * DELETE /location/sessions/:sessionId
   * Delete a tracking session.
   */
  static async deleteSession(req, res) {
    try {
      const userId = req.user.id;
      const { sessionId } = req.params;
      const deleted = await LocationModel.deleteSession(sessionId, userId);
      if (!deleted) {
        return res.status(404).json({ message: 'Session not found' });
      }
      return res.status(200).json({ message: 'Session deleted' });
    } catch (error) {
      console.error('Error in LocationController.deleteSession:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
}

module.exports = LocationController;
