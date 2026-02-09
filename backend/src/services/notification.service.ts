import pool from '../config/database.ts';
import * as deviceTokenService from './device-token.service.ts';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

export interface Notification {
  id: number;
  user_id: number;
  type: string;
  title: string | null;
  message: string | null;
  read: boolean;
  created_at: Date;
}

let firebaseAdmin: any = null;

// Lazy load Firebase Admin SDK
async function getFirebaseAdmin() {
  if (!firebaseAdmin) {
    try {
      const admin = await import('firebase-admin');
      if (!admin.apps.length) {
        const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT;
        if (serviceAccountPath) {
          let serviceAccountJson: any;
          
          // Check if it's a file path (starts with @, /, or .)
          if (serviceAccountPath.startsWith('@') || 
              serviceAccountPath.startsWith('/') || 
              serviceAccountPath.startsWith('./') ||
              serviceAccountPath.startsWith('../')) {
            try {
              // Remove @ prefix if present
              const filePath = serviceAccountPath.startsWith('@') 
                ? serviceAccountPath.substring(1) 
                : serviceAccountPath;
              
              // Resolve absolute path
              const absolutePath = filePath.startsWith('/') 
                ? filePath 
                : resolve(process.cwd(), filePath);
              
              const fileContent = readFileSync(absolutePath, 'utf-8');
              serviceAccountJson = JSON.parse(fileContent);
              console.log('FCM: Loaded service account from file:', absolutePath);
            } catch (fileError) {
              console.error('FCM: Failed to read service account file:', fileError);
              throw fileError;
            }
          } else {
            // Assume it's a JSON string
            try {
              serviceAccountJson = JSON.parse(serviceAccountPath);
              console.log('FCM: Loaded service account from environment variable');
            } catch (parseError) {
              console.error('FCM: Failed to parse service account JSON:', parseError);
              throw parseError;
            }
          }
          
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccountJson),
          });
          console.log('FCM: Firebase Admin initialized successfully');
        } else {
          console.log('FCM: FIREBASE_SERVICE_ACCOUNT not set, push notifications disabled');
        }
      }
      firebaseAdmin = admin;
    } catch (error) {
      console.error('FCM: Firebase Admin initialization error:', error);
      // Continue without FCM push - in-app notifications will still work
    }
  }
  return firebaseAdmin;
}

async function sendFCMPush(
  userId: number,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  try {
    const admin = await getFirebaseAdmin();
    if (!admin) {
      console.log('FCM: Firebase Admin not configured, skipping push notification');
      return;
    }

    const deviceTokens = await deviceTokenService.getUserDeviceTokens(userId);
    if (deviceTokens.length === 0) {
      return;
    }

    const tokens = deviceTokens.map((dt) => dt.token);
    
    const message = {
      notification: {
        title,
        body,
      },
      data: data || {},
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`FCM: Sent ${response.successCount} notifications, ${response.failureCount} failed`);

    // Remove invalid tokens
    if (response.failureCount > 0) {
      const invalidTokens: string[] = [];
      response.responses.forEach((resp: any, idx: number) => {
        if (!resp.success && resp.error?.code === 'messaging/invalid-registration-token') {
          invalidTokens.push(tokens[idx]);
        }
      });
      
      for (const token of invalidTokens) {
        await deviceTokenService.deleteDeviceToken(userId, token);
      }
    }
  } catch (error) {
    console.error('FCM: Failed to send push notification:', error);
    // Don't throw - in-app notification was already created
  }
}

export async function createNotification(
  userId: number,
  type: string,
  title: string,
  message: string,
  sendPush = true
): Promise<Notification> {
  const result = await pool.query(
    `INSERT INTO notifications (user_id, type, title, message)
     VALUES ($1, $2, $3, $4)
     RETURNING *`,
    [userId, type, title, message]
  );
  
  const notification = result.rows[0];

  // Send FCM push notification if enabled
  if (sendPush) {
    await sendFCMPush(userId, title, message, {
      notificationId: notification.id.toString(),
      type,
    });
  }

  return notification;
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
