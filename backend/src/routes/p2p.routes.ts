import { Router } from 'express';
import { P2pController } from '../controllers/p2p.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';
import { strictLimiter, apiLimiter } from '../middleware/rate-limit.ts';

const router = Router();
const controller = new P2pController();

router.get('/search', authenticateToken, apiLimiter, (req, res) => controller.searchUser(req, res));
router.post('/send', authenticateToken, strictLimiter, (req, res) => controller.sendMoney(req, res));
router.get('/history', authenticateToken, apiLimiter, (req, res) => controller.getTransferHistory(req, res));

export default router;
