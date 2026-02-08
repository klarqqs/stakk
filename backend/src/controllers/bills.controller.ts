import type { Response } from 'express';
import billsService from '../services/bills.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class BillsController {
  async getCategories(_req: AuthRequest, res: Response) {
    try {
      const categories = await billsService.getCategories();
      res.json({ categories });
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : 'Failed to fetch categories';
      console.error('Bills categories error:', error);
      res.status(500).json({ error: msg });
    }
  }

  async validate(req: AuthRequest, res: Response) {
    try {
      const { item_code, code, customer } = req.body;
      if (!item_code || !code || !customer) {
        return res.status(400).json({ error: 'item_code, code, and customer are required' });
      }
      const validation = await billsService.validate(item_code, code, customer);
      res.json({ validation });
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : 'Validation failed';
      console.error('Bills validate error:', error);
      res.status(400).json({ error: msg });
    }
  }

  async pay(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { customer, amount, type } = req.body;

      if (!customer || !amount || !type) {
        return res.status(400).json({
          error: 'customer, amount, and type are required',
        });
      }

      const amt = Number(amount);
      if (!Number.isFinite(amt) || amt < 1) {
        return res.status(400).json({ error: 'Invalid amount' });
      }

      const reference = `STAKK-BILL-${userId}-${Date.now()}`;

      const result = await billsService.payBill(
        userId,
        String(customer).trim(),
        amt,
        String(type).trim(),
        reference
      );

      res.json({
        message: 'Bill payment successful',
        data: result,
      });
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : 'Bill payment failed';
      console.error('Bills pay error:', error);
      res.status(500).json({ error: msg });
    }
  }

  async getStatus(req: AuthRequest, res: Response) {
    try {
      const reference = typeof req.params.reference === 'string'
        ? req.params.reference
        : req.params.reference?.[0];
      if (!reference) {
        return res.status(400).json({ error: 'reference is required' });
      }
      const status = await billsService.getStatus(reference);
      res.json({ status });
    } catch (error: unknown) {
      const msg = error instanceof Error ? error.message : 'Failed to fetch status';
      console.error('Bills status error:', error);
      res.status(500).json({ error: msg });
    }
  }
}
