const mongoose = require('mongoose');

const leaveSchema = new mongoose.Schema(
  {
    staffId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Staff member is required'],
    },
    leaveType: {
      type: String,
      required: [true, 'Leave type is required'],
      enum: [
        'annual',
        'sick',
        'maternity',
        'paternity',
        'shared_parental',
        'adoption',
        'parental',
        'dependants',
        'compassionate',
        'neonatal',
        'carers',
        'public_duties',
        'study',
        'unpaid',
      ],
    },
    startDate: {
      type: Date,
      required: [true, 'Start date is required'],
    },
    endDate: {
      type: Date,
      required: [true, 'End date is required'],
    },
    totalHours: {
      type: Number,
      required: true,
      default: 0,
    },
    reason: {
      type: String,
      trim: true,
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected', 'cancelled'],
      default: 'pending',
    },
    approvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    rejectedReason: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for fast queries: staff's leave history, pending requests
leaveSchema.index({ staffId: 1, status: 1 });
leaveSchema.index({ status: 1 });

module.exports = mongoose.model('Leave', leaveSchema);
