// routes/pairing.js

const express = require('express');
const crypto = require('crypto');
const router = express.Router();
const User = require('../models/User');
const sites = require('../config/sites'); // 🔹 site displayName + logoUrl map

// In-memory store of pending pairings: pairToken -> { userId, expiresAt, siteId }
const pendingPairs = new Map();

/**
 * GET /api/pairing/qr?username=demo1
 * Called by website to generate QR for a given username.
 */
router.get('/qr', async (req, res) => {
  try {
    const { username } = req.query;
    if (!username) {
      return res.status(400).json({ error: 'username is required' });
    }

    const user = await User.findOne({ username });
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (!user.ctWeb || !user.siteSalt || !user.hasBiometric) {
      return res
        .status(400)
        .json({ error: 'User has no CT_web enrolled yet' });
    }

    // Site ID for this demo (could vary in future)
    const siteId = 'nextgen_demo';

    // Create ephemeral pairing token (valid ~5 min)
    const pairToken = crypto.randomBytes(16).toString('hex');
    const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minutes

    pendingPairs.set(pairToken, {
      userId: user._id.toString(),
      expiresAt,
      siteId,
    });

    const payload = {
      server_url: 'http://192.168.137.1:8000', // adjust for real deployment
      user_id: user._id.toString(),
      username: user.username,
      site_id: siteId,
      pair_token: pairToken,
      expires_at: expiresAt,
    };

    return res.json({ success: true, payload });
  } catch (err) {
    console.error('QR pairing error:', err);
    return res.status(500).json({ error: 'Failed to create pairing QR' });
  }
});

/**
 * POST /api/pairing/confirm
 * Called by the MOBILE APP after scanning the QR.
 * Body: { pairToken, deviceId, devicePublicKey }
 * Returns encrypted (or raw) ctWeb so phone can store it.
 */
router.post('/confirm', async (req, res) => {
  try {
    const { pairToken, deviceId, devicePublicKey } = req.body;
    if (!pairToken || !deviceId || !devicePublicKey) {
      return res
        .status(400)
        .json({ error: 'pairToken, deviceId, devicePublicKey are required' });
    }

    const record = pendingPairs.get(pairToken);
    if (!record) {
      return res.status(400).json({ error: 'Invalid or expired pairing token' });
    }

    if (Date.now() > record.expiresAt) {
      pendingPairs.delete(pairToken);
      return res.status(400).json({ error: 'Pairing token has expired' });
    }

    const user = await User.findById(record.userId);
    if (!user || !user.ctWeb || !user.siteSalt) {
      return res.status(400).json({ error: 'User not ready for pairing' });
    }

    // Save device (public key) on server (for future crypto / revocation, etc.)
    user.devices.push({
      deviceId,
      publicKey: devicePublicKey,
    });
    await user.save();

    pendingPairs.delete(pairToken);

    // Encrypt ctWeb with devicePublicKey (RSA). For demo, if it fails, fallback.
    let encryptedCtWebBase64;
    try {
      const ctBuf = Buffer.from(user.ctWeb, 'base64');
      const encrypted = crypto.publicEncrypt(
        {
          key: devicePublicKey,
          padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256',
        },
        ctBuf
      );
      encryptedCtWebBase64 = encrypted.toString('base64');
    } catch (e) {
      console.warn(
        'publicEncrypt failed, returning plain ctWeb for now:',
        e.message
      );
      encryptedCtWebBase64 = user.ctWeb; // fallback for demo
    }

    // 🔹 Site branding based on siteId we stored in pendingPairs
    const siteId = record.siteId || 'nextgen_demo';
    const siteInfo = sites[siteId] || {
      displayName: 'Next-Gen Auth Demo',
      logoUrl: '/css/logo.png',
    };

    return res.json({
      success: true,
      encrypted_ct_web: encryptedCtWebBase64,
      site_salt: user.siteSalt,
      display_name: siteInfo.displayName,
      logo_url: siteInfo.logoUrl,
      user_id: user._id.toString(),
      site_id: siteId,
      username: user.username || '',
    });
  } catch (err) {
    console.error('Pairing confirm error:', err);
    return res.status(500).json({ error: 'Pairing failed' });
  }
});

/**
 * POST /api/pairing/complete
 * Called by the MOBILE APP AFTER it successfully decrypted & stored ct_web.
 * Body: { userId, deviceId }
 * This is where we mark registration as fully paired.
 */
router.post('/complete', async (req, res) => {
  try {
    const { userId, deviceId } = req.body;
    if (!userId || !deviceId) {
      return res
        .status(400)
        .json({ error: 'userId and deviceId are required' });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const device = user.devices.find((d) => d.deviceId === deviceId);
    if (!device) {
      return res
        .status(400)
        .json({ error: 'Device not registered for this user' });
    }

    // ✅ REGISTRATION COMPLETE
    user.isPaired = true;
    await user.save();

    return res.json({ success: true });
  } catch (err) {
    console.error('Pairing complete error:', err);
    return res.status(500).json({ error: 'Failed to complete pairing' });
  }
});

/**
 * GET /api/pairing/status?username=demo1
 * Called by the WEBSITE (qr.html) to check if phone has completed pairing.
 * Registration is “finished” when isPaired === true.
 */
router.get('/status', async (req, res) => {
  try {
    const { username } = req.query;
    if (!username) {
      return res
        .status(400)
        .json({ success: false, error: 'username is required' });
    }

    const user = await User.findOne({ username });
    if (!user) {
      return res
        .status(404)
        .json({ success: false, error: 'User not found' });
    }

    // 🔹 Only pairing state — DO NOT reference encryptedCtWebBase64 here
    return res.json({
      success: true,
      isPaired: !!user.isPaired,
      hasBiometric: !!user.hasBiometric,
      hasCtWeb: !!user.ctWeb,
    });
  } catch (err) {
    console.error('Pairing status error:', err);
    return res
      .status(500)
      .json({ success: false, error: 'Status check failed' });
  }
});

module.exports = router;
