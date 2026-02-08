import { Router } from 'express';
import { WithdrawalController } from '../controllers/withdrawal.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new WithdrawalController();

router.post('/bank', authenticateToken, (req, res) =>
  controller.withdrawToBank(req, res)
);
router.post('/resolve-account', authenticateToken, (req, res) =>
  controller.resolveAccount(req, res)
);
router.post('/usdc', authenticateToken, (req, res) =>
  controller.withdrawToUSDC(req, res)
);
router.get('/banks', authenticateToken, (req, res) =>
  controller.getBanks(req, res)
);

export default router;
