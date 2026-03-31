const DailyQR = require('../models/DailyQR');

// @desc    Generate a new daily QR code (expires all previous ones)
// @route   POST /api/qr/generate
// @access  Private/Admin
const generateDailyQR = async (req, res) => {
  try {
    const { label } = req.body;

    // Expire all existing active QR codes
    await DailyQR.updateMany({ isActive: true }, { isActive: false });

    // Create a new active QR
    const qr = await DailyQR.create({
      generatedBy: req.user._id,
      label: label || `QR – ${new Date().toLocaleDateString('en-GB')}`,
    });

    await qr.populate('generatedBy', 'name email');

    res.status(201).json(qr);
  } catch (error) {
    console.error('generateDailyQR error:', error.message);
    res.status(500).json({ message: 'Failed to generate QR code' });
  }
};

// @desc    Get the current active QR code
// @route   GET /api/qr/active
// @access  Private (admin sees full detail, staff just verifies)
const getActiveQR = async (req, res) => {
  try {
    const qr = await DailyQR.findOne({ isActive: true })
      .sort({ createdAt: -1 })
      .populate('generatedBy', 'name email');

    if (!qr) {
      return res.status(404).json({ message: 'No active QR code found' });
    }

    res.json(qr);
  } catch (error) {
    console.error('getActiveQR error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Verify a QR token scanned by staff
// @route   POST /api/qr/verify
// @access  Private
const verifyQR = async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ message: 'QR token is required' });
    }

    const qr = await DailyQR.findOne({ token, isActive: true });

    if (!qr) {
      return res
        .status(403)
        .json({ message: 'Invalid or expired QR code. Please ask your admin for the latest QR.' });
    }

    res.json({ valid: true, qrId: qr._id });
  } catch (error) {
    console.error('verifyQR error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Get QR history (admin only)
// @route   GET /api/qr/history
// @access  Private/Admin
const getQRHistory = async (req, res) => {
  try {
    const history = await DailyQR.find()
      .sort({ createdAt: -1 })
      .limit(30)
      .populate('generatedBy', 'name email');

    res.json(history);
  } catch (error) {
    console.error('getQRHistory error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

// @desc    Expire (deactivate) a specific QR code
// @route   PUT /api/qr/:id/expire
// @access  Private/Admin
const expireQR = async (req, res) => {
  try {
    const qr = await DailyQR.findById(req.params.id);
    if (!qr) {
      return res.status(404).json({ message: 'QR code not found' });
    }

    qr.isActive = false;
    await qr.save();

    res.json({ message: 'QR code expired', qr });
  } catch (error) {
    console.error('expireQR error:', error.message);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  generateDailyQR,
  getActiveQR,
  verifyQR,
  getQRHistory,
  expireQR,
};
