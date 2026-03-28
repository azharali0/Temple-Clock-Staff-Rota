const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');

// Load environment variables (override system env vars with .env values)
const path = require('path');
dotenv.config({ path: path.resolve(__dirname, '../.env'), override: true });

// Connect to MongoDB
connectDB();

const app = express();

// --------------- Middleware ---------------

// Allow requests from Flutter app (any origin in dev)
app.use(cors());

// Parse JSON request bodies (10mb limit for base64 image uploads)
app.use(express.json({ limit: '10mb' }));

// --------------- Routes ---------------

app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/settings', require('./routes/settingsRoutes'));
app.use('/api/shifts', require('./routes/shiftRoutes'));
app.use('/api/attendance', require('./routes/attendanceRoutes'));
app.use('/api/leave', require('./routes/leaveRoutes'));
app.use('/api/payroll', require('./routes/payrollRoutes'));
app.use('/api/reports', require('./routes/reportRoutes'));
app.use('/api/alerts', require('./routes/alertRoutes'));
app.use('/api/qr', require('./routes/qrRoutes'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'CareShift API is running' });
});

// --------------- Error Handler ---------------

// Handle 404 - route not found
app.use((req, res) => {
  res.status(404).json({ message: `Route ${req.originalUrl} not found` });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    message: 'Something went wrong on the server',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// --------------- Start Server ---------------

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`\n=================================`);
  console.log(`  CareShift API Server`);
  console.log(`  Port: ${PORT}`);
  console.log(`  Mode: ${process.env.NODE_ENV || 'development'}`);
  console.log(`=================================\n`);
});
