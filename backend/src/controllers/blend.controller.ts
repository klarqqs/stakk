import type { Response } from 'express';
import blendService from '../services/blend.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class BlendController {
  async getAPY(_req: AuthRequest, res: Response) {
    try {
      const apy = await blendService.getCurrentAPY();
      res.json({ apy: apy.toFixed(2) + '%', raw: apy });
    } catch (error: unknown) {
      console.error('Get APY error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to fetch APY',
      });
    }
  }

  async enableEarning(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { amount } = req.body;
      if (!amount || Number(amount) <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
      }
      const result = await blendService.enableEarning(userId, Number(amount));
      res.json({
        message: `Deposited $${result.amount} USDC to earn ${result.apy}% APY`,
        data: result,
      });
    } catch (error: unknown) {
      console.error('Enable earning error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to enable earning',
      });
    }
  }

  async disableEarning(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { amount } = req.body;
      if (!amount || Number(amount) <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
      }
      const result = await blendService.disableEarning(userId, Number(amount));
      res.json({
        message: `Withdrawn $${result.withdrawn} USDC from Blend`,
        data: result,
      });
    } catch (error: unknown) {
      console.error('Disable earning error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to disable earning',
      });
    }
  }

  async getEarnings(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const earnings = await blendService.getUserEarnings(userId);
      res.json(earnings);
    } catch (error: unknown) {
      console.error('Get earnings error:', error);
      res.status(500).json({
        error: error instanceof Error ? error.message : 'Failed to fetch earnings',
      });
    }
  }
}
