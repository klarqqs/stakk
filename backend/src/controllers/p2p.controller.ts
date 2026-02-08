import type { Response } from 'express';
import * as p2pService from '../services/p2p.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class P2pController {
  async searchUser(req: AuthRequest, res: Response) {
    try {
      const query = (req.query.query as string)?.trim();
      if (!query || query.length < 3) {
        return res.status(400).json({ error: 'Enter at least 3 characters to search' });
      }

      const user = await p2pService.searchUser(query);
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json({ user });
    } catch (error) {
      console.error('P2P search error:', error);
      res.status(500).json({ error: 'Search failed' });
    }
  }

  async sendMoney(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { receiver, amount, note } = req.body;

      if (!receiver || !amount) {
        return res.status(400).json({ error: 'Receiver and amount are required' });
      }

      const amountUsdc = parseFloat(amount);
      if (isNaN(amountUsdc) || amountUsdc <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
      }

      const result = await p2pService.transferToUser(
        userId,
        String(receiver).trim(),
        amountUsdc,
        note
      );

      res.json({
        success: true,
        message: `Successfully sent $${amountUsdc.toFixed(2)} to ${result.receiverName}`,
        transferId: result.transferId
      });
    } catch (error) {
      const msg = error instanceof Error ? error.message : 'Transfer failed';
      console.error('P2P send error:', error);
      res.status(400).json({ error: msg });
    }
  }

  async getTransferHistory(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
      const transfers = await p2pService.getUserTransferHistory(userId, limit);
      res.json({ transfers });
    } catch (error) {
      console.error('P2P history error:', error);
      res.status(500).json({ error: 'Failed to fetch transfer history' });
    }
  }
}
