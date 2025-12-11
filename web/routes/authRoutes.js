// routes/authRoutes.js

const express = require('express');
const User = require('../models/User');
const { generateRotatingPassword } = require('../utils/rotatingPassword');
const router = express.Router();

// POST /api/register
// NOTE: Biometric + CT_Web is handled separately via /api/enroll.
// This just creates a base user record if it doesn't exist.
router.post('/register', async (req, res) => {
  try {
    const { username, email } = req.body;

    console.log('Received registration data:', { username, email });

    if (!username) {
      return res.json({
        success: false,
        message: 'Username is required.',
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.json({
        success: false,
        message: 'Username already registered.',
      });
    }

    // Create basic user; ctWeb & pairing come later via /enroll + /pairing
    const newUser = new User({
      username,
      email: email || null,
      ctWeb: null,
      siteSalt: null,
      hasBiometric: false,
      isPaired: false,
      devices: [],
    });

    await newUser.save();

    console.log('New user saved to DB:', newUser);

    return res.json({
      success: true,
      message: 'User registered. Continue with fingerprint enrollment.',
      username: newUser.username,
    });
  } catch (err) {
    console.error('Error in /api/register:', err);
    return res.status(500).json({
      success: false,
      message: 'Server error during registration.',
    });
  }
});

// POST /api/login
// Body: { username, dynamicPassword }
// dynamicPassword is the 8-char rotating password shown in the mobile app.
router.post('/login', async (req, res) => {
  try {
    const { username, dynamicPassword } = req.body;

    console.log('Received login data:', { username, dynamicPassword });

    if (!username || !dynamicPassword) {
      return res.json({
        success: false,
        message: 'Username and dynamic password are required.',
      });
    }

    // 1️⃣ Check if user exists in DB
    const user = await User.findOne({ username });

    if (!user) {
      return res.json({
        success: false,
        message: 'User not found. Please register first.',
      });
    }

    if (!user.ctWeb) {
      return res.json({
        success: false,
        message: 'User has no CT_Web enrolled yet.',
      });
    }

    if (!user.isPaired) {
      return res.json({
        success: false,
        message: 'User is not paired with mobile device yet.',
      });
    }

    // 2️⃣ ROTATING PASSWORD CHECK (must match mobile app logic)
    //   timeWindow = floor(epoch/30)
    //   hash = SHA256(ctWeb + timeWindow) → first 8 chars (uppercased)
    //
    //   Allow ±30s clock drift: check previous, current, next window.
    const now = Math.floor(Date.now() / 1000);

    const current = generateRotatingPassword(user.ctWeb, now);
    const prev = generateRotatingPassword(user.ctWeb, now - 30);
    const next = generateRotatingPassword(user.ctWeb, now + 30);

    const isValid =
      dynamicPassword === current ||
      dynamicPassword === prev ||
      dynamicPassword === next;

    if (!isValid) {
      return res.json({
        success: false,
        message: 'Invalid dynamic password.',
      });
    }

    // 3️⃣ Success
    return res.json({
      success: true,
      message: 'Login successful.',
    });
  } catch (err) {
    console.error('Error in /api/login:', err);
    return res.status(500).json({
      success: false,
      message: 'Server error during login.',
    });
  }
});

module.exports = router;
