// registration.js

console.log('registration.js loaded (BioKeyRotate version)');

const scanBtn =
  document.getElementById('scanBtn') || // new id (if you updated HTML)
  document.getElementById('captureBtn'); // fallback to old id

const fpStatus = document.getElementById('fpStatus');
const fingerprintInput = document.getElementById('fingerprintTemplate');
const registerBtn = document.getElementById('registerBtn');
const form = document.getElementById('registrationForm');
const usernameInput = document.getElementById('username');

// When user clicks "Scan Fingerprint"
scanBtn.addEventListener('click', async () => {
  const username = usernameInput.value.trim();
  if (!username) {
    alert('Please enter a username first.');
    return;
  }

  scanBtn.disabled = true;
  registerBtn.disabled = true;
  fpStatus.textContent = 'You will be asked to scan your finger 3 times. Follow the prompts on the scanner.';

  try {
    // 1) Ask local C# bridge app to capture fingerprint
    const deviceRes = await fetch('http://127.0.0.1:5001/scan', {
      method: 'POST'
    });

    if (!deviceRes.ok) {
      throw new Error('Scanner bridge not responding. Is the bridge app running?');
    }

    const data = await deviceRes.json();
    const templateBase64 = data.templateBase64;

    if (!templateBase64) {
      throw new Error('Scanner failed to capture a fingerprint template.');
    }

    // Store the Base64 template in hidden input
    fingerprintInput.value = templateBase64;

    fpStatus.textContent = 'All 3 scans captured and combined successfully ✅';
    registerBtn.disabled = false; // enable Register button
  } catch (err) {
    console.error('Error during fingerprint capture:', err);
    fpStatus.textContent = 'Error: ' + err.message;
    registerBtn.disabled = true;
  } finally {
    scanBtn.disabled = false;
  }
});

// When form is submitted → send template to backend to create CT_web
form.addEventListener('submit', async (e) => {
  e.preventDefault();

  const username = usernameInput.value.trim();
  const templateBase64 = fingerprintInput.value;

  if (!username) {
    alert('Please enter a username.');
    return;
  }

  if (!templateBase64) {
    alert('Please scan fingerprint before registering.');
    return;
  }

  const payload = {
    username,
    ansiTemplateBase64: templateBase64
  };

  console.log('Submitting enrollment to backend:', payload);

  try {
    const response = await fetch('/api/enroll', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();
    console.log('Response from /api/enroll:', data);

    if (!response.ok || !data.success) {
      throw new Error(data.error || 'Enrollment failed on server');
    }

    // Instead of going to login, go to QR pairing screen
    const uname = data.username || username;
    window.location.href = `qr.html?username=${encodeURIComponent(uname)}`;
  } catch (err) {
    console.error('Error while registering:', err);
    alert('Error while registering: ' + err.message);
  }
});

