const Settings = require('../models/Settings');

// @desc    Get app settings
// @route   GET /api/settings
// @access  Private
const getSettings = async (req, res) => {
    try {
        let settings = await Settings.findOne({ key: 'global' });
        if (!settings) {
            settings = await Settings.create({ key: 'global' });
        }
        res.json(settings);
    } catch (error) {
        console.error('GetSettings error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

// @desc    Update app settings
// @route   PUT /api/settings
// @access  Private/Admin
const updateSettings = async (req, res) => {
    try {
        const allowedFields = [
            'gracePeriodMinutes',
            'geofenceEnabled',
            'geofenceRadius',
            'annualLeaveHours',
            'requireLeaveApproval',
            'minNoticeDays',
            'defaultHourlyRate',
            'overtimeMultiplier',
            'emailNotifications',
            'pushNotifications',
        ];

        let settings = await Settings.findOne({ key: 'global' });
        if (!settings) {
            settings = await Settings.create({ key: 'global' });
        }

        for (const field of allowedFields) {
            if (req.body[field] !== undefined) {
                settings[field] = req.body[field];
            }
        }

        await settings.save();
        res.json(settings);
    } catch (error) {
        console.error('UpdateSettings error:', error.message);
        res.status(500).json({ message: 'Server error' });
    }
};

module.exports = { getSettings, updateSettings };
