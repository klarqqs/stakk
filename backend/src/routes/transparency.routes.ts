import { Router } from 'express';
import { TransparencyController } from '../controllers/transparency.controller.ts';

const router = Router();
const controller = new TransparencyController();

// Public - no auth required
router.get('/stats', (req, res) => controller.getPublicStats(req, res));
router.get('/transactions', (req, res) => controller.getRecentTransactions(req, res));

export default router;
