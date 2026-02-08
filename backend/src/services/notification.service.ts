import pool from '../config/database.ts';

export interface Notification {
  id: number;
  user_id: number;
  type: string;
  title: string | null;
  message: string | null;
  read: boolean;
  created_at: Date;
}

export async function createNotification(
  userId: number,
  type: string,
  title: string,
  message: string
): Promise<Notification> {
  const result = await pool.query(
    `INSERT INTO notifications (user_id, type, title, message)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [userId, type, title, message]
  );
  return result.rows[0];
}

export async function getUserNotifications(
  userId: number,
  unreadOnly = false,
  limit = 50
): Promise<Notification[]> {
  const query = unreadOnly
    ? `SELECT * FROM notifications WHERE user_id = $1 AND read = false ORDER BY created_at DESC LIMIT $2`
    : `SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2`;

  const result = await pool.query(query, [userId, limit]);
  return result.rows;
}

export async function markAsRead(notificationId: number, userId: number): Promise<boolean> {
  const result = await pool.query(
    'UPDATE notifications SET read = true WHERE id = $1 AND user_id = $2 RETURNING id',
    [notificationId, userId]
  );
  return result.rowCount !== null && result.rowCount > 0;
}

export async function markAllAsRead(userId: number): Promise<number> {
  const result = await pool.query(
    'UPDATE notifications SET read = true WHERE user_id = $1 RETURNING id',
    [userId]
  );
  return result.rowCount ?? 0;
}

export async function getUnreadCount(userId: number): Promise<number> {
  const result = await pool.query(
    'SELECT COUNT(*) as cnt FROM notifications WHERE user_id = $1 AND read = false',
    [userId]
  );
  return parseInt(result.rows[0]?.cnt || 0, 10);
}

export default {
  createNotification,
  getUserNotifications,
  markAsRead,
  markAllAsRead,
  getUnreadCount
};
