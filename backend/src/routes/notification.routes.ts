import { Router } from 'express';
import { NotificationController } from '../controllers/notification.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';

const router = Router();
const controller = new NotificationController();

router.use(authenticateToken);

router.get('/', (req, res) => controller.getNotifications(req, res));
router.get('/unread-count', (req, res) => controller.getUnreadCount(req, res));
router.post('/read-all', (req, res) => controller.markAllRead(req, res));
router.post('/:id/read', (req, res) => controller.markRead(req, res));

export default router;
