const Alert = require('../models/Alert');

// @desc    Staff sends a running-late alert to head office
// @route   POST /api/alerts
// @access  Private
const createAlert = async (req, res) => {
    try {
        const { shiftId, alertType, message, estimatedDelay } = req.body;
        const staffId = req.user._id;

        const alert = await Alert.create({
            staffId,
            shiftId: shiftId || undefined,
            alertType: alertType || 'running_late',
            message: message || '',
            estimatedDelay: estimatedDelay || 0,
        });

        await alert.populate('staffId', 'name email');

        res.status(201).json(alert);
    } catch (error) {
        console.error('CreateAlert error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Admin sends an alert/notice to a specific staff member
// @route   POST /api/alerts/send
// @access  Private/Admin
const sendAlertToStaff = async (req, res) => {
    try {
        const { targetStaffId, message } = req.body;
        if (!targetStaffId || !message) {
            return res.status(400).json({ message: 'targetStaffId and message are required' });
        }

        const alert = await Alert.create({
            staffId: req.user._id,         // admin who sent it
            targetStaffId,                  // staff who receives it
            alertType: 'admin_notice',
            message,
            readByAdmin: true,              // admin already knows about it
        });

        await alert.populate('staffId', 'name email');
        await alert.populate('targetStaffId', 'name email');

        res.status(201).json(alert);
    } catch (error) {
        console.error('SendAlertToStaff error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Admin gets all alerts (newest first)
// @route   GET /api/alerts
// @access  Private/Admin
const getAlerts = async (req, res) => {
    try {
        const alerts = await Alert.find()
            .populate('staffId', 'name email department')
            .populate('targetStaffId', 'name email')
            .populate('shiftId', 'date startTime endTime location')
            .sort({ createdAt: -1 })
            .limit(50);

        res.json(alerts);
    } catch (error) {
        console.error('GetAlerts error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Staff gets their own alerts (admin notices sent to them)
// @route   GET /api/alerts/my
// @access  Private
const getMyAlerts = async (req, res) => {
    try {
        const alerts = await Alert.find({ targetStaffId: req.user._id })
            .populate('staffId', 'name email')
            .sort({ createdAt: -1 })
            .limit(30);

        res.json(alerts);
    } catch (error) {
        console.error('GetMyAlerts error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Staff gets their unread alert count
// @route   GET /api/alerts/my/unread-count
// @access  Private
const getMyUnreadCount = async (req, res) => {
    try {
        const count = await Alert.countDocuments({
            targetStaffId: req.user._id,
            readByStaff: false,
        });
        res.json({ count });
    } catch (error) {
        console.error('GetMyUnreadCount error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Staff marks their alert as read
// @route   PUT /api/alerts/:id/read-staff
// @access  Private
const markAlertReadByStaff = async (req, res) => {
    try {
        const alert = await Alert.findById(req.params.id);
        if (!alert) {
            return res.status(404).json({ message: 'Alert not found' });
        }
        alert.readByStaff = true;
        await alert.save();
        res.json(alert);
    } catch (error) {
        console.error('MarkAlertReadByStaff error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Admin marks alert as read
// @route   PUT /api/alerts/:id/read
// @access  Private/Admin
const markAlertRead = async (req, res) => {
    try {
        const alert = await Alert.findById(req.params.id);
        if (!alert) {
            return res.status(404).json({ message: 'Alert not found' });
        }
        alert.readByAdmin = true;
        await alert.save();
        res.json(alert);
    } catch (error) {
        console.error('MarkAlertRead error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Get unread alert count for admin notification badge
// @route   GET /api/alerts/unread-count
// @access  Private/Admin
const getUnreadCount = async (req, res) => {
    try {
        const count = await Alert.countDocuments({ readByAdmin: false });
        res.json({ count });
    } catch (error) {
        console.error('GetUnreadCount error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

module.exports = {
    createAlert,
    sendAlertToStaff,
    getAlerts,
    getMyAlerts,
    getMyUnreadCount,
    markAlertReadByStaff,
    markAlertRead,
    getUnreadCount,
};
