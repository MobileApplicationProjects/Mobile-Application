const RoomModel = require('./RoomModel');

class RoomController {
  static async createRoom(req, res) {
    try {
      const userId = req.user.id;
      const { name, duration_days, invites } = req.body;

      if (!name || !duration_days || !invites || invites.length === 0) {
        return res.status(400).json({ message: 'Room name, duration, and at least 1 invite are required.' });
      }

      // Resolve usernames/emails to user IDs
      const memberIds = [];
      const notFound = [];
      for (const identifier of invites) {
        const user = await RoomModel.findUserByEmailOrUsername(identifier);
        if (user) {
          memberIds.push(user.id);
        } else {
          notFound.push(identifier);
        }
      }

      if (memberIds.length === 0) {
        return res.status(400).json({ message: 'None of the invited users were found.', notFound });
      }

      const roomId = await RoomModel.createRoom({
        name,
        duration_days: parseInt(duration_days),
        created_by: userId,
        members: memberIds
      });

      return res.status(201).json({ 
        message: 'Room created successfully', 
        roomId,
        notFound: notFound.length > 0 ? notFound : undefined
      });

    } catch (error) {
      console.error('Error creating room:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async listRooms(req, res) {
    try {
      const userId = req.user.id;
      const rooms = await RoomModel.getRoomsForUser(userId);
      return res.status(200).json({ rooms });
    } catch (error) {
      console.error('Error listing rooms:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async acceptInvite(req, res) {
    try {
      const userId = req.user.id;
      const { id } = req.params;

      const success = await RoomModel.acceptInvite(id, userId);
      if (success) {
        return res.status(200).json({ message: 'Invite accepted' });
      } else {
        return res.status(400).json({ message: 'Could not accept invite (maybe already accepted or not invited)' });
      }
    } catch (error) {
      console.error('Error accepting invite:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }

  static async getLeaderboard(req, res) {
    try {
      const { id } = req.params;
      const data = await RoomModel.getRoomLeaderboard(id);

      if (!data) {
        return res.status(404).json({ message: 'Room not found' });
      }

      return res.status(200).json(data);
    } catch (error) {
      console.error('Error getting leaderboard:', error);
      return res.status(500).json({ message: 'Internal server error', error: error.message });
    }
  }
}

module.exports = RoomController;
