// login.js
console.log('login.js loaded');

const form = document.getElementById('loginForm');
const loginStatus = document.getElementById('loginMessage');
const loginBtn = document.getElementById('loginBtn');
const successOverlay = document.getElementById('successOverlay');

form.addEventListener('submit', async (e) => {
  e.preventDefault();

  const username = document.getElementById('loginUsername').value.trim();
  const dynamicPassword = document
    .getElementById('dynamicPassword')
    .value
    .trim()
    .toUpperCase(); // app shows uppercase

  if (!username || !dynamicPassword) {
    loginStatus.textContent = 'Please fill in both fields.';
    loginStatus.style.color = 'red';
    return;
  }

  loginBtn.disabled = true;
  loginStatus.textContent = 'Verifying...';
  loginStatus.style.color = '';

  try {
    const res = await fetch('/api/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ username, dynamicPassword }),
    });

    const data = await res.json();
    console.log('Login response:', data);

    if (data.success) {
      // Text feedback under form
      loginStatus.textContent = '✅ Login successful!';
      loginStatus.style.color = 'lime';

      // Show success overlay animation
      if (successOverlay) {
        successOverlay.classList.add('show');
      }

      // Optional: redirect to a protected/demo page after animation
      // setTimeout(() => {
      //   window.location.href = '/home.html';
      // }, 1800);
    } else {
      loginStatus.textContent = data.message || 'Login failed.';
      loginStatus.style.color = 'red';
    }
  } catch (err) {
    console.error('Error during login:', err);
    loginStatus.textContent = 'Server error during login.';
    loginStatus.style.color = 'red';
  } finally {
    loginBtn.disabled = false;
  }
});
