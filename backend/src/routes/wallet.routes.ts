import { Router } from 'express';
import { WalletController } from '../controllers/wallet.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';
import { apiLimiter } from '../middleware/rate-limit.ts';

const router = Router();
const walletController = new WalletController();

// Protected routes - require authentication + rate limiting
router.get('/balance', authenticateToken, apiLimiter, (req, res) => walletController.getBalance(req, res));
router.get('/transactions', authenticateToken, apiLimiter, (req, res) => walletController.getTransactions(req, res));
router.post('/bvn', authenticateToken, apiLimiter, (req, res) => walletController.submitBvn(req, res));
router.get('/virtual-account', authenticateToken, apiLimiter, (req, res) => walletController.getVirtualAccount(req, res));

export default router;