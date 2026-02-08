import { Router } from 'express';
import { BillsController } from '../controllers/bills.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new BillsController();

router.get('/categories', authenticateToken, (req, res) =>
  controller.getCategories(req, res)
);
router.post('/validate', authenticateToken, (req, res) =>
  controller.validate(req, res)
);
router.post('/pay', authenticateToken, (req, res) =>
  controller.pay(req, res)
);
router.get('/status/:reference', authenticateToken, (req, res) =>
  controller.getStatus(req, res)
);

export default router;
