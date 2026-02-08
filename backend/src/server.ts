import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.routes.ts';
import walletRoutes from './routes/wallet.routes.ts';
import webhookRoutes from './routes/webhook.routes.ts';
import adminRoutes from './routes/admin.routes.ts';
import withdrawalRoutes from './routes/withdrawal.routes.ts';
import billsRoutes from './routes/bills.routes.ts';
import blendRoutes from './routes/blend.routes.ts';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/webhook', webhookRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/withdrawal', withdrawalRoutes);
app.use('/api/bills', billsRoutes);
app.use('/api/blend', blendRoutes);

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

// Start server - bind to 0.0.0.0 so Railway can reach it from outside the container
app.listen(Number(PORT), '0.0.0.0', async () => {
  console.log(`Server running on port ${PORT}`);
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
  if (process.env.STELLAR_NETWORK === 'mainnet') {
    import('./services/stellar-monitor.service.ts').then((m) => m.default.startMonitoring());
  }
  if (process.env.EMAIL_SERVICE === 'resend' && !process.env.RESEND_API_KEY?.trim()) {
    console.warn('⚠️  EMAIL_SERVICE=resend but RESEND_API_KEY is missing. Signup emails will fail.');
  }
});