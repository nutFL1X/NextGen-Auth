// models/User.js

const mongoose = require('mongoose');

const DeviceSchema = new mongoose.Schema(
  {
    deviceId: { type: String, required: false },
    deviceName: {
      type: String,
      required: false,
      default: 'Mobile device', // you can override when saving
    },
    publicKey: { type: String, required: false },
    pairedAt: { type: Date, default: Date.now },
  },
  { _id: false }
);

const UserSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },

    email: {
      type: String,
      required: false,
      trim: true,
      default: null,
    },

    // base64 encoded CT_web (cancellable template)
    ctWeb: {
      type: String,
      required: false,
      default: null,
    },

    siteSalt: {
      type: String,
      required: false,
      default: null,
    },

    hasBiometric: {
      type: Boolean,
      default: false,
    },

    // registration is NOT considered complete until phone pairs
    isPaired: {
      type: Boolean,
      default: false,
    },

    devices: {
      type: [DeviceSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

const User = mongoose.model('User', UserSchema);

module.exports = User;
