const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const cloudinary = require('cloudinary').v2;
const verifyToken = require('../middleware/authMiddleware');

const router = express.Router();

// Configure Cloudinary using the keys from your .env
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// Ensure uploads directory exists for temporary caching
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer config - temporarily store on disk
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const uniqueName = `${Date.now()}-${Math.round(Math.random() * 1e6)}${ext}`;
    cb(null, uniqueName);
  },
});

const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only JPEG, PNG, and WebP images are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
});

// POST /api/uploads/image
// Requires auth. Returns the secure URL from Cloudinary.
router.post('/image', verifyToken, upload.single('image'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ message: 'No image file provided' });
  }

  try {
    // 1. Send the file from local uploads folder up to Cloudinary
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: 'gao_app_profiles',
    });

    // 2. We no longer need the local file, clean it up!
    fs.unlinkSync(req.file.path);

    // 3. Inform the frontend of the permanent URL
    return res.status(200).json({
      message: 'Image uploaded to Cloudinary successfully',
      url: result.secure_url,
      filename: result.public_id,
    });
  } catch (error) {
    console.error('Cloudinary upload err:', error);
    // Cleanup local cache on error just in case
    if (fs.existsSync(req.file.path)) {
      fs.unlinkSync(req.file.path);
    }
    return res.status(500).json({ message: 'Failed to upload via Cloudinary', error: error.message });
  }
});

module.exports = router;
