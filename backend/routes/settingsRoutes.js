const express = require('express');
const { getSettings, updateSettings } = require('../controllers/settingsController');
const { protect, authorize } = require('../middleware/auth');

const router = express.Router();

router.use(protect);

// GET /api/settings — get app settings (any authenticated user)
router.get('/', getSettings);

// PUT /api/settings — update settings (admin only)
router.put('/', authorize('admin'), updateSettings);

module.exports = router;
