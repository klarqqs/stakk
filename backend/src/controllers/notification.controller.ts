import type { Response } from 'express';
import * as notificationService from '../services/notification.service.ts';
import * as deviceTokenService from '../services/device-token.service.ts';
import type { AuthRequest } from '../middleware/auth.middleware.ts';

export class NotificationController {
  async getNotifications(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const unreadOnly = req.query.unreadOnly === 'true';
      const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);

      const notifications = await notificationService.getUserNotifications(
        userId,
        unreadOnly,
        limit
      );

      const unreadCount = await notificationService.getUnreadCount(userId);

      res.json({ notifications, unreadCount });
    } catch (error) {
      console.error('Notifications list error:', error);
      res.status(500).json({ error: 'Failed to fetch notifications' });
    }
  }

  async markRead(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const notificationId = parseInt(req.params.id);

      if (isNaN(notificationId)) {
        return res.status(400).json({ error: 'Invalid notification ID' });
      }

      const ok = await notificationService.markAsRead(notificationId, userId);
      if (!ok) {
        return res.status(404).json({ error: 'Notification not found' });
      }

      res.json({ success: true });
    } catch (error) {
      console.error('Mark read error:', error);
      res.status(500).json({ error: 'Failed to mark as read' });
    }
  }

  async markAllRead(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const count = await notificationService.markAllAsRead(userId);
      res.json({ success: true, count });
    } catch (error) {
      console.error('Mark all read error:', error);
      res.status(500).json({ error: 'Failed to mark all as read' });
    }
  }

  async getUnreadCount(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const count = await notificationService.getUnreadCount(userId);
      res.json({ count });
    } catch (error) {
      console.error('Unread count error:', error);
      res.status(500).json({ error: 'Failed to get count' });
    }
  }

  async registerDevice(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { token, platform } = req.body;

      if (!token || !platform) {
        return res.status(400).json({ error: 'Token and platform are required' });
      }

      if (platform !== 'ios' && platform !== 'android') {
        return res.status(400).json({ error: 'Platform must be ios or android' });
      }

      await deviceTokenService.registerDeviceToken(userId, token, platform);
      res.json({ success: true });
    } catch (error) {
      console.error('Register device error:', error);
      res.status(500).json({ error: 'Failed to register device' });
    }
  }

  async deleteDevice(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { token } = req.body;

      if (!token) {
        return res.status(400).json({ error: 'Token is required' });
      }

      await deviceTokenService.deleteDeviceToken(userId, token);
      res.json({ success: true });
    } catch (error) {
      console.error('Delete device error:', error);
      res.status(500).json({ error: 'Failed to delete device' });
    }
  }
}
