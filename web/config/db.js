// config/db.js

const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    // Replace URL later with your actual MongoDB URI if needed
    const mongoURI = 'mongodb://127.0.0.1:27017/nextgenauth';

    // Newer Mongoose versions don't need extra options
    await mongoose.connect(mongoURI);

    console.log('📦 MongoDB connected successfully');
  } catch (err) {
    console.error('❌ MongoDB connection failed:', err.message);
    process.exit(1); // Stop server if DB cannot connect
  }
};

module.exports = connectDB;
