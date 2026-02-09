import { Router } from 'express';
import { WithdrawalController } from '../controllers/withdrawal.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';
import { strictLimiter, apiLimiter } from '../middleware/rate-limit.ts';

const router = Router();
const controller = new WithdrawalController();

// Sensitive operations use strict rate limiting
router.post('/bank', authenticateToken, strictLimiter, (req, res) =>
  controller.withdrawToBank(req, res)
);
router.post('/resolve-account', authenticateToken, apiLimiter, (req, res) =>
  controller.resolveAccount(req, res)
);
router.post('/usdc', authenticateToken, strictLimiter, (req, res) =>
  controller.withdrawToUSDC(req, res)
);
router.get('/banks', authenticateToken, apiLimiter, (req, res) =>
  controller.getBanks(req, res)
);

export default router;
