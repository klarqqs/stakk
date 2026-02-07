import { Router } from 'express';
import { WalletController } from '../controllers/wallet.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const walletController = new WalletController();

// Protected routes - require authentication
router.get('/balance', authenticateToken, (req, res) => walletController.getBalance(req, res));
router.get('/transactions', authenticateToken, (req, res) => walletController.getTransactions(req, res));

export default router;