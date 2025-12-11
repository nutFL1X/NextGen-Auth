// routes/loginCode.js

const express = require('express');
const crypto = require('crypto');
const router = express.Router();
const User = require('../models/User');

// POST /api/login-code
// Body: { username, code }  // code = rotating password from app
router.post('/', async (req, res) => {
  try {
    const { username, code } = req.body;
    if (!username || !code) {
      return res.status(400).json({ error: 'username and code required' });
    }

    const user = await User.findOne({ username });
    if (!user || !user.ctWeb || !user.siteSalt) {
      return res.status(400).json({ error: 'User has no biometric token' });
    }

    const ct = Buffer.from(user.ctWeb, 'base64');
    const siteSaltBuf = Buffer.from(user.siteSalt, 'hex');

    const now = Math.floor(Date.now() / 1000);
    const windowSize = 30; // 30s steps
    const alphabet = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'; // no I/O confusions

    function codeFromTimeStep(tStep) {
      // ct || siteSalt || timeStep(8 bytes BE)
      const timeBuf = Buffer.alloc(8);
      timeBuf.writeBigInt64BE(BigInt(tStep));

      const data = Buffer.concat([ct, siteSaltBuf, timeBuf]);
      const hash = crypto.createHash('sha256').update(data).digest();

      // HOTP-style truncation
      let num = BigInt('0x' + hash.toString('hex'));
      let generated = '';
      for (let i = 0; i < 8; i++) {
        const idx = Number(num % BigInt(alphabet.length));
        generated += alphabet[idx];
        num /= BigInt(alphabet.length);
      }
      return generated;
    }

    const currentStep = Math.floor(now / windowSize);

    // allow drift: previous, current, next step
    const candidates = [
      codeFromTimeStep(currentStep - 1),
      codeFromTimeStep(currentStep),
      codeFromTimeStep(currentStep + 1),
    ];

    if (candidates.includes(code)) {
      // TODO: create a real session / JWT etc.
      return res.json({ success: true });
    } else {
      return res.status(401).json({ error: 'Invalid code' });
    }
  } catch (err) {
    console.error('login-code error:', err);
    return res.status(500).json({ error: 'Login failed' });
  }
});

module.exports = router;
