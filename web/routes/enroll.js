// routes/enroll.js

const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const User = require('../models/User');
const { generateCtWeb } = require('../config/ctweb');

// POST /api/enroll
// Body: { username, ansiTemplateBase64 }
router.post('/', async (req, res) => {
  try {
    const { username, ansiTemplateBase64 } = req.body;

    if (!username || !ansiTemplateBase64) {
      return res.status(400).json({ error: 'username and ansiTemplateBase64 required' });
    }

    let user = await User.findOne({ username });

    if (!user) {
      user = new User({
        username,
        email: null,
        hasBiometric: false,
        isPaired: false,
        ctWeb: null,
        siteSalt: null,
        devices: [],
      });
    }

    const ansiTemplate = Buffer.from(ansiTemplateBase64, 'base64');

    let siteSalt = user.siteSalt;
    if (!siteSalt) {
      siteSalt = crypto.randomBytes(16).toString('hex');
    }

    const ct = generateCtWeb(ansiTemplate, user._id.toString(), siteSalt);
    const ctBase64 = ct.toString('base64');

    user.ctWeb = ctBase64;
    user.siteSalt = siteSalt;
    user.hasBiometric = true;
    // IMPORTANT: registration not complete yet
    user.isPaired = false;

    await user.save();

    // tell frontend: go to pairing step next
    return res.json({ success: true, next: 'pairing', username: user.username });
  } catch (err) {
    console.error('Enroll error:', err);
    return res.status(500).json({ error: 'Enrollment failed' });
  }
});

module.exports = router;
