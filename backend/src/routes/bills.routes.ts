import { Router } from 'express';
import { BillsController } from '../controllers/bills.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new BillsController();

router.get('/categories', authenticateToken, (req, res) =>
  controller.getCategories(req, res)
);
router.get('/categories/top', authenticateToken, (req, res) =>
  controller.getTopCategories(req, res)
);
router.get('/categories/:code/providers', authenticateToken, (req, res) =>
  controller.getProviders(req, res)
);
router.get('/providers/:code/products', authenticateToken, (req, res) =>
  controller.getProducts(req, res)
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
