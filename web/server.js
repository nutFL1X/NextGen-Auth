console.log('server.js is running with Express...');

const express = require('express');
const cors = require('cors');
const path = require('path');

const authRoutes = require('./routes/authRoutes');
const enrollRoutes = require('./routes/enroll');      
const pairingRoutes = require('./routes/pairing');    
const loginCodeRoutes = require('./routes/loginCode'); 

const connectDB = require('./config/db');

const app = express();

// ===== Middleware =====
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ===== Static folder =====
app.use(express.static(path.join(__dirname, 'public')));

// ===== API Routes =====

// Auth (existing password-based, keep it for fallback)
app.use('/api', authRoutes);

// Fingerprint template enrollment from Scanner
app.use('/api/enroll', enrollRoutes);

// Pairing QR + Confirm pairing from App
app.use('/api/pairing', pairingRoutes);

// Passwordless rotating code login from App
app.use('/api/login-code', loginCodeRoutes);

// ===== Health Check =====
app.get('/api/health', (req, res) => {
  res.json({ status: "OK", message: "Express server running successfully" });
});

// ===== Connect Database =====
connectDB();

// ===== Start Server =====
const PORT = 8000;
app.listen(PORT, () => {
  console.log(`Express server started on http://localhost:${PORT}`);
});
