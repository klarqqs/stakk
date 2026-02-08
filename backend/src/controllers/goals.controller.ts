import type { Response } from 'express';
import * as goalsService from '../services/goals.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class GoalsController {
  async createGoal(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { name, targetAmount, deadline, autoSaveAmount, autoSaveFrequency } = req.body;

      if (!name || !targetAmount) {
        return res.status(400).json({ error: 'Name and target amount are required' });
      }

      const target = parseFloat(targetAmount);
      if (isNaN(target) || target <= 0) {
        return res.status(400).json({ error: 'Invalid target amount' });
      }

      const goal = await goalsService.createGoal(
        userId,
        String(name).trim(),
        target,
        deadline || null,
        autoSaveAmount != null ? parseFloat(autoSaveAmount) : null,
        autoSaveFrequency || null
      );

      res.status(201).json({ goal });
    } catch (error) {
      const msg = error instanceof Error ? error.message : 'Failed to create goal';
      console.error('Goals create error:', error);
      res.status(400).json({ error: msg });
    }
  }

  async getAllGoals(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const goals = await goalsService.getActiveGoals(userId);
      res.json({ goals });
    } catch (error) {
      console.error('Goals list error:', error);
      res.status(500).json({ error: 'Failed to fetch goals' });
    }
  }

  async getGoal(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const goalId = parseInt(req.params.id);
      if (isNaN(goalId)) {
        return res.status(400).json({ error: 'Invalid goal ID' });
      }

      const goal = await goalsService.getGoalById(goalId, userId);
      if (!goal) {
        return res.status(404).json({ error: 'Goal not found' });
      }

      const contributions = await goalsService.getGoalContributions(goalId, userId);
      res.json({ goal, contributions });
    } catch (error) {
      console.error('Goal get error:', error);
      res.status(500).json({ error: 'Failed to fetch goal' });
    }
  }

  async addToGoal(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const goalId = parseInt(req.params.id);
      const { amount } = req.body;

      if (isNaN(goalId)) {
        return res.status(400).json({ error: 'Invalid goal ID' });
      }

      const amt = parseFloat(amount);
      if (isNaN(amt) || amt <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
      }

      const result = await goalsService.contributeToGoal(userId, goalId, amt);
      res.json({ goal: result.goal, contribution: result.contribution });
    } catch (error) {
      const msg = error instanceof Error ? error.message : 'Failed to contribute';
      console.error('Goals contribute error:', error);
      res.status(400).json({ error: msg });
    }
  }

  async withdrawGoal(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const goalId = parseInt(req.params.id);
      const { amount } = req.body;

      if (isNaN(goalId)) {
        return res.status(400).json({ error: 'Invalid goal ID' });
      }

      const amt = parseFloat(amount);
      if (isNaN(amt) || amt <= 0) {
        return res.status(400).json({ error: 'Invalid amount' });
      }

      const goal = await goalsService.withdrawFromGoal(userId, goalId, amt);
      res.json({ goal });
    } catch (error) {
      const msg = error instanceof Error ? error.message : 'Failed to withdraw';
      console.error('Goals withdraw error:', error);
      res.status(400).json({ error: msg });
    }
  }

  async deleteGoal(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const goalId = parseInt(req.params.id);

      if (isNaN(goalId)) {
        return res.status(400).json({ error: 'Invalid goal ID' });
      }

      await goalsService.deleteGoal(userId, goalId);
      res.json({ success: true });
    } catch (error) {
      const msg = error instanceof Error ? error.message : 'Failed to delete';
      console.error('Goals delete error:', error);
      res.status(400).json({ error: msg });
    }
  }
}
