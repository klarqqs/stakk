import { Router } from 'express';
import { LockedController } from '../controllers/locked.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new LockedController();

router.get('/rates', authenticateToken, (req, res) => controller.getAPYRates(req, res));
router.post('/', authenticateToken, (req, res) => controller.lockFunds(req, res));
router.get('/', authenticateToken, (req, res) => controller.getLockedSavings(req, res));
router.post('/:id/withdraw', authenticateToken, (req, res) => controller.withdrawMatured(req, res));

export default router;
