const mongoose = require('mongoose');
const crypto = require('crypto');

const clientSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Client/Location name is required'],
      trim: true,
    },
    address: {
      type: String,
      required: [true, 'Address is required'],
      trim: true,
    },
    coordinates: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true },
    },
    qrToken: {
      type: String,
      required: true,
      unique: true,
      default: () => crypto.randomBytes(24).toString('hex'),
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

// Index to optimize getClients query which filters by isActive and sorts by createdAt descending
clientSchema.index({ isActive: 1, createdAt: -1 });

module.exports = mongoose.model('Client', clientSchema);
