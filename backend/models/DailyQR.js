const mongoose = require('mongoose');
const crypto = require('crypto');

const dailyQRSchema = new mongoose.Schema(
  {
    token: {
      type: String,
      required: true,
      unique: true,
      default: () => crypto.randomBytes(24).toString('hex'),
    },
    generatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    label: {
      type: String,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    expiresAt: {
      type: Date,
      default: null, // null = never expires unless replaced by a new QR
    },
  },
  { timestamps: true }
);

// Index for quick lookup of the active QR
dailyQRSchema.index({ isActive: 1, createdAt: -1 });

module.exports = mongoose.model('DailyQR', dailyQRSchema);
