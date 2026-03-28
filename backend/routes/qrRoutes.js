const express = require('express');
const {
    generateShiftQR,
    generateShiftQRBase64,
} = require('../controllers/qrController');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.use(protect);

// GET /api/qr/shift/:shiftId — PNG image
router.get('/shift/:shiftId', generateShiftQR);

// GET /api/qr/shift/:shiftId/base64 — JSON with data URL
router.get('/shift/:shiftId/base64', generateShiftQRBase64);

module.exports = router;
