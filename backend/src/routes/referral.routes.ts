import { Router } from 'express';
import { ReferralController } from '../controllers/referral.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new ReferralController();

router.use(authenticateToken);

router.get('/code', (req, res) => controller.getMyCode(req, res));
router.get('/mine', (req, res) => controller.getMyReferrals(req, res));
router.get('/leaderboard', (req, res) => controller.getLeaderboard(req, res));

export default router;
