import { Router } from 'express';
import { BillsController } from '../controllers/bills.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';
import { strictLimiter, apiLimiter } from '../middleware/rate-limit.ts';

const router = Router();
const controller = new BillsController();

router.get('/categories', authenticateToken, apiLimiter, (req, res) =>
  controller.getCategories(req, res)
);
router.get('/categories/top', authenticateToken, apiLimiter, (req, res) =>
  controller.getTopCategories(req, res)
);
router.get('/categories/:code/providers', authenticateToken, apiLimiter, (req, res) =>
  controller.getProviders(req, res)
);
router.get('/providers/:code/products', authenticateToken, apiLimiter, (req, res) =>
  controller.getProducts(req, res)
);
router.post('/validate', authenticateToken, apiLimiter, (req, res) =>
  controller.validate(req, res)
);
router.post('/pay', authenticateToken, strictLimiter, (req, res) =>
  controller.pay(req, res)
);
router.get('/status/:reference', authenticateToken, apiLimiter, (req, res) =>
  controller.getStatus(req, res)
);

export default router;
