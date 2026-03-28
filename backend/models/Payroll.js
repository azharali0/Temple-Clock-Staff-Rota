const mongoose = require('mongoose');

const adjustmentSchema = new mongoose.Schema(
    {
        description: {
            type: String,
            required: true,
            trim: true,
        },
        amount: {
            type: Number,
            required: true,
        },
        addedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
        addedAt: {
            type: Date,
            default: Date.now,
        },
    },
    { _id: true }
);

const payrollSchema = new mongoose.Schema(
    {
        staffId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: [true, 'Staff member is required'],
        },
        month: {
            type: String,
            required: [true, 'Month is required'],
            // Format: "YYYY-MM"
            match: [/^\d{4}-\d{2}$/, 'Month must be in YYYY-MM format'],
        },
        totalHoursWorked: {
            type: Number,
            default: 0,
        },
        overtimeHours: {
            type: Number,
            default: 0,
        },
        hourlyRate: {
            type: Number,
            required: true,
            default: 0,
        },
        grossPay: {
            type: Number,
            default: 0,
        },
        adjustments: [adjustmentSchema],
        finalPay: {
            type: Number,
            default: 0,
        },
        status: {
            type: String,
            enum: ['draft', 'finalized'],
            default: 'draft',
        },
        generatedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
        },
    },
    {
        timestamps: true,
    }
);

// Prevent duplicate payroll: one record per staff per month
payrollSchema.index({ staffId: 1, month: 1 }, { unique: true });
payrollSchema.index({ month: 1 });

module.exports = mongoose.model('Payroll', payrollSchema);
