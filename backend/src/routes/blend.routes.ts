import { Router } from 'express';
import { BlendController } from '../controllers/blend.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new BlendController();

router.get('/apy', (req, res) => controller.getAPY(req, res));
router.post('/enable', authenticateToken, (req, res) => controller.enableEarning(req, res));
router.post('/disable', authenticateToken, (req, res) => controller.disableEarning(req, res));
router.get('/earnings', authenticateToken, (req, res) => controller.getEarnings(req, res));

export default router;
