require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

app.use(cors());
app.use(express.json());

// Serve uploaded images as static files at /uploads/<filename>
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const accountRoutes = require('./src/Account/AccountRoutes');
app.use('/api/account', accountRoutes);

const healthRoutes = require('./src/Health/HealthRoutes');
app.use('/api/health', healthRoutes);

const rewardRoutes = require('./src/Rewards/RewardRoutes');
app.use('/api/rewards', rewardRoutes);

const challengeRoutes = require('./src/Challenges/ChallengeRoutes');
app.use('/api/challenges', challengeRoutes);

const uploadRoutes = require('./src/Upload/UploadRoutes');
app.use('/api/uploads', uploadRoutes);

const roomRoutes = require('./src/Rooms/RoomRoutes');
app.use('/api/rooms', roomRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
