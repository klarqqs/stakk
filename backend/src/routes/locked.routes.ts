import { Router } from 'express';
import { LockedController } from '../controllers/locked.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';
import { strictLimiter, apiLimiter } from '../middleware/rate-limit.ts';

const router = Router();
const controller = new LockedController();

router.get('/rates', authenticateToken, apiLimiter, (req, res) => controller.getAPYRates(req, res));
router.post('/', authenticateToken, strictLimiter, (req, res) => controller.lockFunds(req, res));
router.get('/', authenticateToken, apiLimiter, (req, res) => controller.getLockedSavings(req, res));
router.post('/:id/withdraw', authenticateToken, strictLimiter, (req, res) => controller.withdrawMatured(req, res));

export default router;
