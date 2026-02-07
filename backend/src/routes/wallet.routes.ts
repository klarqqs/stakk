import { Router } from 'express';
import { WalletController } from '../controllers/wallet.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const walletController = new WalletController();

// Protected routes - require authentication
router.get('/balance', authenticateToken, (req, res) => walletController.getBalance(req, res));
router.get('/transactions', authenticateToken, (req, res) => walletController.getTransactions(req, res));
router.post('/bvn', authenticateToken, (req, res) => walletController.submitBvn(req, res));
router.get('/virtual-account', authenticateToken, (req, res) => walletController.getVirtualAccount(req, res));

export default router;