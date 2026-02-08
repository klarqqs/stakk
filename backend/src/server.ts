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

// Health check (Railway and other platforms)
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Stakk API is running' });
});

// Root redirect for platform health checks
app.get('/', (req, res) => res.redirect('/health'));

// Start server - bind to 0.0.0.0 so Railway can reach it from outside the container
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});