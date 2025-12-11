// login.js

console.log('login.js loaded');

const loginForm = document.getElementById('loginForm');
const loginMessage = document.getElementById('loginMessage');

loginForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const username = document.getElementById('loginUsername').value.trim();
  const dynamicPassword = document.getElementById('dynamicPassword').value.trim();

  if (!username || !dynamicPassword) {
    loginMessage.textContent = 'Please enter both username and dynamic password.';
    return;
  }

  const payload = { username, dynamicPassword };

  console.log('Sending login payload:', payload);

  try {
    const response = await fetch('/api/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      throw new Error('Network response not ok');
    }

    const data = await response.json();
    console.log('Response from /api/login:', data);

    if (data.success) {
      loginMessage.textContent = 'Login successful! (demo)';
    } else {
      loginMessage.textContent = data.message || 'Login failed.';
    }
  } catch (err) {
    console.error('Error during login:', err);
    loginMessage.textContent = 'Error during login. Check console.';
  }
});
