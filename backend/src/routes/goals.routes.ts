import { Router } from 'express';
import { GoalsController } from '../controllers/goals.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new GoalsController();

router.use(authenticateToken);

router.post('/', (req, res) => controller.createGoal(req, res));
router.get('/', (req, res) => controller.getAllGoals(req, res));
router.get('/:id', (req, res) => controller.getGoal(req, res));
router.post('/:id/contribute', (req, res) => controller.addToGoal(req, res));
router.post('/:id/withdraw', (req, res) => controller.withdrawGoal(req, res));
router.delete('/:id', (req, res) => controller.deleteGoal(req, res));

export default router;
