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
router.post('/register-device', (req, res) => controller.registerDevice(req, res));
router.post('/delete-device', (req, res) => controller.deleteDevice(req, res));

export default router;
