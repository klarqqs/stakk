import type { Response } from 'express';
import * as lockedService from '../services/locked.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class LockedController {
  async lockFunds(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { amount, duration, autoRenew } = req.body;

      const amt = parseFloat(amount);
      const dur = parseInt(duration);

      if (isNaN(amt) || amt <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
      }

      if (![30, 60, 90].includes(dur)) {
        return res.status(400).json({ error: 'Duration must be 30, 60, or 90 days' });
      }

      const lock = await lockedService.createLockedSavings(userId, amt, dur, !!autoRenew);
      res.status(201).json({ lock });
    } catch (error) {
      const msg = error instanceof Error ? error.message : 'Failed to lock funds';
      console.error('Locked create error:', error);
      res.status(400).json({ error: msg });
    }
  }

  async getLockedSavings(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const locks = await lockedService.getUserLockedSavings(userId);
      res.json({ locks });
    } catch (error) {
      console.error('Locked list error:', error);
      res.status(500).json({ error: 'Failed to fetch locked savings' });
    }
  }

  async withdrawMatured(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const lockId = parseInt(req.params.id);

      if (isNaN(lockId)) {
        return res.status(400).json({ error: 'Invalid lock ID' });
      }

      const lock = await lockedService.withdrawMatured(userId, lockId);
      res.json({ lock });
    } catch (error) {
      const msg = error instanceof Error ? error.message : 'Failed to withdraw';
      console.error('Locked withdraw error:', error);
      res.status(400).json({ error: msg });
    }
  }

  async getAPYRates(_req: AuthRequest, res: Response) {
    try {
      const rates = await lockedService.getAPYRates();
      res.json({ rates });
    } catch (error) {
      console.error('APY rates error:', error);
      res.status(500).json({ error: 'Failed to fetch rates' });
    }
  }
}
