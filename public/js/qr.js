// qr.js
console.log('qr.js loaded');

const qrContainer = document.getElementById('qrContainer');
const qrStatus    = document.getElementById('qrStatus');
const pairStatus  = document.getElementById('pairStatus');
const pairSpinner = document.getElementById('pairSpinner');

let qrInstance = null;
let pollingInterval = null;
let currentUsername = null;

// Poll backend to check if pairing completed
async function pollPairingStatus() {
  if (!currentUsername) return;

  try {
    const res = await fetch(
      `/api/pairing/status?username=${encodeURIComponent(currentUsername)}`
    );
    const data = await res.json();

    if (data.success && data.isPaired === true) {
      clearInterval(pollingInterval);

      pairStatus.textContent = '✅ Pairing complete! Finalizing registration...';
      pairStatus.style.color = 'lime';
      if (pairSpinner) pairSpinner.style.display = 'none';

      // Redirect after 2 sec
      setTimeout(() => {
        window.location.href = '/login.html';
      }, 2000);
    } else if (data.success) {
      pairStatus.textContent = 'Waiting for mobile app to pair this device...';
      if (pairSpinner) pairSpinner.style.display = 'block';
    }
  } catch (err) {
    console.warn('Polling error:', err);
  }
}

// ask backend for QR payload and render it
async function generateQrForUser(username) {
  currentUsername = username;
  qrStatus.textContent = 'Requesting pairing QR...';
  if (pairSpinner) pairSpinner.style.display = 'none';

  try {
    const res = await fetch(
      `/api/pairing/qr?username=${encodeURIComponent(username)}`
    );
    const data = await res.json();

    if (!res.ok || !data.success) {
      throw new Error(data.error || 'Failed to generate pairing QR');
    }

    const payload = data.payload;

    // COMPACT PAYLOAD for QR (short keys)
    const qrPayload = {
      s: payload.server_url,  // server
      u: payload.user_id,     // user id
      t: payload.pair_token,  // pairing token
      e: payload.expires_at,  // expiry
      i: payload.site_id      // site id
    };

    const qrText = JSON.stringify(qrPayload);

    // Clear previous QR
    qrContainer.innerHTML = '';

    qrInstance = new QRCode(qrContainer, {
      text: qrText,
      width: 260,
      height: 260,
      correctLevel: QRCode.CorrectLevel.L
    });

    qrStatus.textContent =
      'Scan this QR in the mobile app to complete pairing.';
    pairStatus.textContent = 'Waiting for mobile app to pair this device...';
    if (pairSpinner) pairSpinner.style.display = 'block';

    // Start polling every 2 seconds
    if (pollingInterval) clearInterval(pollingInterval);
    pollingInterval = setInterval(pollPairingStatus, 2000);

  } catch (err) {
    console.error('QR error:', err);
    qrStatus.textContent = 'Error: ' + err.message;
    if (pairSpinner) pairSpinner.style.display = 'none';
  }
}

// On page load
(function initFromQuery() {
  const params = new URLSearchParams(window.location.search);
  const uname = params.get('username');

  if (!uname) {
    qrStatus.textContent =
      'Missing username in URL. Please start from the registration page.';
    pairStatus.textContent = '';
    if (pairSpinner) pairSpinner.style.display = 'none';
    return;
  }

  generateQrForUser(uname);
})();
