import type { Request, Response } from 'express';
import * as transparencyService from '../services/transparency.service.ts';

export class TransparencyController {
  async getPublicStats(_req: Request, res: Response) {
    try {
      const stats = await transparencyService.getPublicStats();
      res.json(stats);
    } catch (error) {
      console.error('Transparency stats error:', error);
      res.status(500).json({ error: 'Failed to fetch stats' });
    }
  }

  async getRecentTransactions(_req: Request, res: Response) {
    try {
      const transactions = await transparencyService.getRecentTransactions(10);
      res.json({ transactions });
    } catch (error) {
      console.error('Transparency transactions error:', error);
      res.status(500).json({ error: 'Failed to fetch transactions' });
    }
  }
}
