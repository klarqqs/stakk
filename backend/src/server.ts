import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import * as Sentry from '@sentry/node';
import { initializeSentry } from './config/sentry.ts';
import authRoutes from './routes/auth.routes.ts';
import walletRoutes from './routes/wallet.routes.ts';
import webhookRoutes from './routes/webhook.routes.ts';
import adminRoutes from './routes/admin.routes.ts';
import withdrawalRoutes from './routes/withdrawal.routes.ts';
import billsRoutes from './routes/bills.routes.ts';
import blendRoutes from './routes/blend.routes.ts';
import p2pRoutes from './routes/p2p.routes.ts';
import goalsRoutes from './routes/goals.routes.ts';
import lockedRoutes from './routes/locked.routes.ts';
import referralRoutes from './routes/referral.routes.ts';
import transparencyRoutes from './routes/transparency.routes.ts';
import notificationRoutes from './routes/notification.routes.ts';
import appRoutes from './routes/app.routes.ts';
import stocksRoutes from './routes/stocks.routes.ts';
import { validateEnvironment, getCorsOrigins, checkForPlaceholderSecrets } from './config/env-validation.ts';

dotenv.config();

// Initialize Sentry BEFORE anything else
initializeSentry();

// Validate environment variables on startup
try {
  validateEnvironment();
  checkForPlaceholderSecrets();
} catch (error) {
  console.error('Environment validation failed:', error);
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 3001;

// Trust proxy - required for Railway and other platforms that use reverse proxies
// This allows express-rate-limit to correctly identify client IPs from X-Forwarded-For headers
app.set('trust proxy', true);

// Note: Sentry v8 auto-instruments Express when initialized
// No need for requestHandler() or tracingHandler() middleware

// CORS configuration
const corsOrigins = getCorsOrigins();
const isProduction = process.env.NODE_ENV === 'production';

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) {
      return callback(null, true);
    }
    
    // In production, only allow whitelisted origins
    if (isProduction) {
      if (corsOrigins.includes(origin)) {
        callback(null, true);
      } else {
        console.warn(`⚠️  Blocked CORS request from: ${origin}`);
        callback(new Error('Not allowed by CORS'));
      }
    } else {
      // In development, allow all origins
      callback(null, true);
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Security headers
app.use((req, res, next) => {
  // Prevent clickjacking
  res.setHeader('X-Frame-Options', 'DENY');
  // Prevent MIME type sniffing
  res.setHeader('X-Content-Type-Options', 'nosniff');
  // XSS protection
  res.setHeader('X-XSS-Protection', '1; mode=block');
  // Referrer policy
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  if (isProduction) {
    // Strict transport security (HTTPS only)
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
  }
  
  next();
});

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Routes
app.use('/webhook', webhookRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/withdrawal', withdrawalRoutes);
app.use('/api/bills', billsRoutes);
app.use('/api/blend', blendRoutes);
app.use('/api/p2p', p2pRoutes);
app.use('/api/goals', goalsRoutes);
app.use('/api/locked', lockedRoutes);
app.use('/api/referrals', referralRoutes);
app.use('/api/transparency', transparencyRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/app', appRoutes);
app.use('/api/stocks', stocksRoutes);

// Health check (Railway and other platforms)
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Stakk API is running' });
});

// Debug: Get server's outbound IP (for Flutterwave whitelist)
app.get('/api/debug/outbound-ip', async (_req, res) => {
  try {
    const r = await fetch('https://api.ipify.org?format=json');
    const json = (await r.json()) as { ip?: string };
    res.json({ ip: json.ip || 'unknown', hint: 'Add this IP to Flutterwave Settings → Whitelisted IP addresses' });
  } catch (e) {
    res.status(500).json({ error: 'Could not fetch IP', detail: String(e) });
  }
});

// Root redirect for platform health checks
app.get('/', (req, res) => res.redirect('/health'));

// Sentry error handler (must be after all routes, before other error handlers)
Sentry.setupExpressErrorHandler(app);

// Custom error handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  // Capture error in Sentry
  Sentry.captureException(err);
  
  console.error('Unhandled error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// Start server - bind to 0.0.0.0 so Railway can reach it from outside the container
app.listen(Number(PORT), '0.0.0.0', async () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 CORS origins: ${corsOrigins.join(', ')}`);
  
  // Log outbound IP for Flutterwave whitelist (Railway, Render, etc.)
  try {
    const r = await fetch('https://api.ipify.org?format=json');
    const json = (await r.json()) as { ip?: string };
    if (json.ip) {
      console.log(`📍 Outbound IP (add to Flutterwave whitelist): ${json.ip}`);
    }
  } catch {
    // ignore
  }
  
  // Start monitoring services
  if (process.env.STELLAR_NETWORK === 'mainnet') {
    import('./services/stellar-monitor.service.ts').then((m) => m.default.startMonitoring());
  }
  
  // Email service validation
  if (process.env.EMAIL_SERVICE === 'resend' && !process.env.RESEND_API_KEY?.trim()) {
    console.warn('⚠️  EMAIL_SERVICE=resend but RESEND_API_KEY is missing. Signup emails will fail.');
  }
  
  console.log('✅ Server initialized successfully');
});