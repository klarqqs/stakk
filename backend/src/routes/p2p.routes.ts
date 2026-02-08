import { Router } from 'express';
import { P2pController } from '../controllers/p2p.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';
import rateLimit from 'express-rate-limit';

const router = Router();
const controller = new P2pController();

const p2pLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: { error: 'Too many P2P transfers. Try again in an hour.' }
});

router.get('/search', authenticateToken, (req, res) => controller.searchUser(req, res));
router.post('/send', authenticateToken, p2pLimiter, (req, res) => controller.sendMoney(req, res));
router.get('/history', authenticateToken, (req, res) => controller.getTransferHistory(req, res));

export default router;
