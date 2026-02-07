import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const adminController = new AdminController();

// All admin routes require authentication
router.get('/deposits/pending', authenticateToken, (req, res) => 
  adminController.getPendingDeposits(req, res)
);

router.post('/deposits/process', authenticateToken, (req, res) => 
  adminController.processDeposit(req, res)
);

export default router;