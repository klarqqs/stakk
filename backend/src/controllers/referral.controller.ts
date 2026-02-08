import type { Response } from 'express';
import * as referralService from '../services/referral.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class ReferralController {
  async getMyCode(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const code = await referralService.getOrCreateReferralCode(userId);
      res.json({ code });
    } catch (error) {
      console.error('Referral code error:', error);
      res.status(500).json({ error: 'Failed to get referral code' });
    }
  }

  async getMyReferrals(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const stats = await referralService.getReferralStats(userId);
      res.json(stats);
    } catch (error) {
      console.error('Referral stats error:', error);
      res.status(500).json({ error: 'Failed to fetch referral stats' });
    }
  }

  async getLeaderboard(_req: AuthRequest, res: Response) {
    try {
      const leaderboard = await referralService.getLeaderboard(10);
      res.json({ leaderboard });
    } catch (error) {
      console.error('Leaderboard error:', error);
      res.status(500).json({ error: 'Failed to fetch leaderboard' });
    }
  }
}
