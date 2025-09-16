const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const passport = require('passport');
require('dotenv').config();

// Optional: Initialize Prisma Client only if DB is enabled
const DB_ENABLED = (process.env.DB_ENABLED || 'false').toLowerCase() === 'true';
let prisma = null;
if (DB_ENABLED) {
  try {
    const { PrismaClient } = require('@prisma/client');
    prisma = new PrismaClient();
  } catch (e) {
    console.warn('Prisma not available. Ensure @prisma/client is installed and schema is generated.');
  }
}

// Load route modules only when DB is enabled to avoid importing Prisma-dependent code
let authRoutes, userRoutes, propertyRoutes, bookingRoutes;
if (DB_ENABLED) {
  authRoutes = require('./src/routes/auth');
  userRoutes = require('./src/routes/users');
  propertyRoutes = require('./src/routes/properties');
  bookingRoutes = require('./src/routes/bookings');
}

// Import passport strategies only when DB is enabled
if (DB_ENABLED) {
  require('./src/config/passport');
} else {
  console.log('ℹ️  DB_ENABLED=false, skipping passport strategy initialization');
}

const app = express();
const PORT = process.env.PORT || 5000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Passport middleware
app.use(passport.initialize());

// Database connection
async function connectDatabase() {
  if (!DB_ENABLED || !prisma) {
    console.log('ℹ️  DB_ENABLED=false, skipping database connection');
    return;
  }
  try {
    await prisma.$connect();
    console.log('✅ Connected to PostgreSQL');
  } catch (error) {
    console.error('❌ PostgreSQL connection error:', error);
    process.exit(1);
  }
}

connectDatabase();

// Routes
if (DB_ENABLED) {
  app.use('/api/auth', authRoutes);
  app.use('/api/users', userRoutes);
  app.use('/api/properties', propertyRoutes);
  app.use('/api/bookings', bookingRoutes);
} else {
  app.get('/api', (req, res) => {
    res.json({
      status: 'OK',
      message: 'API running without database. Set DB_ENABLED=true and configure .env to enable full API.'
    });
  });
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Rentally Backend API is running!',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Route not found',
    message: `Cannot ${req.method} ${req.originalUrl}`
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Rentally Backend running on port ${PORT}`);
  console.log(`📱 Health check: http://localhost:${PORT}/api/health`);
});
