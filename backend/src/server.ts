import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.routes.ts';
import walletRoutes from './routes/wallet.routes.ts';
import webhookRoutes from './routes/webhook.routes.ts';
import adminRoutes from './routes/admin.routes.ts';

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

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', message: 'USDC Savings API is running' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔐 Auth: http://localhost:${PORT}/api/auth/*`);
  console.log(`💰 Wallet: http://localhost:${PORT}/api/wallet/*`);
  console.log(`🔗 Webhook: http://localhost:${PORT}/webhook/*`);
  console.log(`   Flutterwave: POST /webhook/flutterwave`);
  console.log(`   ngrok: run "npm run ngrok" then use https://<your-id>.ngrok-free.app/webhook/flutterwave`);
});