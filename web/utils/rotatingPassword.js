// utils/rotatingPassword.js
const crypto = require("crypto");

/**
 * Generate rotating password from CT-Web and epoch timestamp.
 * If epochSec is not supplied, uses current time.
 *
 * Formula:
 *   timeWindow = floor(epochSec / 30)
 *   hash = SHA256(ctWeb + timeWindow)
 *   return first 8 HEX chars
 */
function generateRotatingPassword(ctWeb, epochSec = null) {
  if (epochSec == null) {
    epochSec = Math.floor(Date.now() / 1000);
  }

  const timeWindow = Math.floor(epochSec / 30);
  const raw = Buffer.from(`${ctWeb}${timeWindow}`, "utf8");
  const hash = crypto
    .createHash("sha256")
    .update(raw)
    .digest("hex")
    .toUpperCase();

  return hash.substring(0, 8); // first 8 chars like your Flutter app
}

module.exports = { generateRotatingPassword };
