require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const { initDatabase } = require('./db/database');

const authRoutes = require('./routes/auth');
const restaurantsRoutes = require('./routes/restaurants');
const bookingsRoutes = require('./routes/bookings');
const companyRoutes = require('./routes/company');
const mlRoutes = require('./routes/ml');
const paymentsRoutes = require('./routes/payments');
const notificationsRoutes = require('./routes/notifications');

const app = express();
const PORT = process.env.PORT || 3000;

// Security & Middlewares
app.use(helmet({
  contentSecurityPolicy: false // Allows dashboard inline styles & scripts
}));
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Static files for B2B Portal
app.use('/company-portal', express.static(path.join(__dirname, '../public/company')));

// Root route redirect to B2B Portal
app.get('/', (req, res) => {
  res.redirect('/company-portal');
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/restaurants', restaurantsRoutes);
app.use('/api/bookings', bookingsRoutes);
app.use('/api/company', companyRoutes);
app.use('/api/ml', mlRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/notifications', notificationsRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    timestamp: new Date().toISOString(),
    service: 'kucina-backend-engine',
    version: '1.0.0',
    model: 'XGBoost_GBDT_v2.4'
  });
});

async function startServer() {
  try {
    await initDatabase();
    console.log('📦 Database initialized successfully.');

    // Auto-seed if database is empty
    const seed = require('./db/seed');
    await seed.runSeed();

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Kucina Backend running on http://0.0.0.0:${PORT}`);
      console.log(`📊 B2B Portal available at http://localhost:${PORT}/company-portal`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

startServer();
