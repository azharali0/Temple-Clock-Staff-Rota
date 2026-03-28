const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema(
    {
        staffId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true,
        },
        targetStaffId: {
            // For admin→staff alerts: who should receive it
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        shiftId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'Shift',
        },
        alertType: {
            type: String,
            enum: ['running_late', 'emergency', 'general', 'admin_notice'],
            default: 'running_late',
        },
        message: {
            type: String,
            trim: true,
            default: '',
        },
        estimatedDelay: {
            type: Number, // minutes
            default: 0,
        },
        readByAdmin: {
            type: Boolean,
            default: false,
        },
        readByStaff: {
            type: Boolean,
            default: false,
        },
    },
    { timestamps: true }
);

alertSchema.index({ readByAdmin: 1, createdAt: -1 });
alertSchema.index({ targetStaffId: 1, readByStaff: 1, createdAt: -1 });

module.exports = mongoose.model('Alert', alertSchema);
