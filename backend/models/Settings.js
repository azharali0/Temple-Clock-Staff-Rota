const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema(
    {
        // There's only one settings document — use a fixed key
        key: {
            type: String,
            default: 'global',
            unique: true,
        },
        gracePeriodMinutes: {
            type: Number,
            default: 10,
        },
        geofenceEnabled: {
            type: Boolean,
            default: true,
        },
        geofenceRadius: {
            type: Number,
            default: 50,
        },
        annualLeaveHours: {
            type: Number,
            default: 224,
        },
        requireLeaveApproval: {
            type: Boolean,
            default: true,
        },
        minNoticeDays: {
            type: Number,
            default: 7,
        },
        defaultHourlyRate: {
            type: Number,
            default: 12,
        },
        overtimeMultiplier: {
            type: Number,
            default: 1.5,
        },
        emailNotifications: {
            type: Boolean,
            default: true,
        },
        pushNotifications: {
            type: Boolean,
            default: true,
        },
    },
    { timestamps: true }
);

module.exports = mongoose.model('Settings', settingsSchema);
