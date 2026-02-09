import pool from '../config/database.ts';

export interface DeviceToken {
  id: number;
  user_id: number;
  token: string;
  platform: 'ios' | 'android';
  created_at: Date;
  updated_at: Date;
}

export async function registerDeviceToken(
  userId: number,
  token: string,
  platform: 'ios' | 'android'
): Promise<DeviceToken> {
  const result = await pool.query(
    `INSERT INTO device_tokens (user_id, token, platform, updated_at)
     VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
     ON CONFLICT (user_id, token) 
     DO UPDATE SET updated_at = CURRENT_TIMESTAMP, platform = $3
     RETURNING *`,
    [userId, token, platform]
  );
  return result.rows[0];
}

export async function deleteDeviceToken(
  userId: number,
  token: string
): Promise<boolean> {
  const result = await pool.query(
    'DELETE FROM device_tokens WHERE user_id = $1 AND token = $2',
    [userId, token]
  );
  return (result.rowCount ?? 0) > 0;
}

export async function getUserDeviceTokens(userId: number): Promise<DeviceToken[]> {
  const result = await pool.query(
    'SELECT * FROM device_tokens WHERE user_id = $1',
    [userId]
  );
  return result.rows;
}

export async function deleteAllUserTokens(userId: number): Promise<number> {
  const result = await pool.query(
    'DELETE FROM device_tokens WHERE user_id = $1',
    [userId]
  );
  return result.rowCount ?? 0;
}

export default {
  registerDeviceToken,
  deleteDeviceToken,
  getUserDeviceTokens,
  deleteAllUserTokens
};
