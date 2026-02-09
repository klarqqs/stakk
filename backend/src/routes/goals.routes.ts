import { Router } from 'express';
import { GoalsController } from '../controllers/goals.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';
import { strictLimiter, apiLimiter } from '../middleware/rate-limit.ts';

const router = Router();
const controller = new GoalsController();

router.use(authenticateToken);

router.post('/', apiLimiter, (req, res) => controller.createGoal(req, res));
router.get('/', apiLimiter, (req, res) => controller.getAllGoals(req, res));
router.get('/:id', apiLimiter, (req, res) => controller.getGoal(req, res));
router.post('/:id/contribute', strictLimiter, (req, res) => controller.addToGoal(req, res));
router.post('/:id/withdraw', strictLimiter, (req, res) => controller.withdrawGoal(req, res));
router.delete('/:id', apiLimiter, (req, res) => controller.deleteGoal(req, res));

export default router;
