// config/ctweb.js
// Cancellable template generation from ANSI template bytes

const crypto = require('crypto');

/**
 * ansiTemplate: Buffer (raw ANSI-378 template from scanner)
 * userId: string
 * siteSalt: string (hex / string)
 * returns: Buffer (ct_web vector)
 */
function generateCtWeb(ansiTemplate, userId, siteSalt) {
  // 1) Derive deterministic seed from user + siteSalt
  const seedHash = crypto
    .createHash('sha256')
    .update(userId + siteSalt)
    .digest();

  // 32-bit seed from first 4 bytes
  let seed =
    (seedHash[0] << 24) |
    (seedHash[1] << 16) |
    (seedHash[2] << 8) |
    seedHash[3];

  if (seed < 0) seed = -seed;

  // Simple xorshift PRNG (deterministic)
  function nextRand() {
    seed ^= seed << 13;
    seed ^= seed >>> 17;
    seed ^= seed << 5;
    seed |= 0; // force 32-bit
    return (seed >>> 0) / 0xffffffff;
  }

  const len = ansiTemplate.length;

  // 2) Create permutation of indices [0..len-1]
  const indices = Array.from({ length: len }, (_, i) => i);
  for (let i = len - 1; i > 0; i--) {
    const j = Math.floor(nextRand() * (i + 1));
    [indices[i], indices[j]] = [indices[j], indices[i]];
  }

  // 3) Apply permutation
  const shuffled = Buffer.alloc(len);
  for (let i = 0; i < len; i++) {
    shuffled[i] = ansiTemplate[indices[i]];
  }

  // 4) Window compression: 32-byte windows → 1 byte (index of max)
  const windowSize = 32;
  const numWindows = Math.floor(len / windowSize);
  const ct = Buffer.alloc(numWindows);

  for (let w = 0; w < numWindows; w++) {
    let maxVal = -1;
    let maxIndex = 0;
    const start = w * windowSize;

    for (let i = 0; i < windowSize; i++) {
      const v = shuffled[start + i];
      if (v > maxVal) {
        maxVal = v;
        maxIndex = i;
      }
    }

    ct[w] = maxIndex; // 0–31
  }

  // This ct buffer is your cancellable template vector (CT_web)
  return ct;
}

module.exports = {
  generateCtWeb,
};
