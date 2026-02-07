import jwt, { type SignOptions } from 'jsonwebtoken';
import pool from '../config/database.ts';

const signOptions: SignOptions = { expiresIn: '15m' };

export function generateAccessToken(userId: number, email?: string): string {
  return jwt.sign(
    { userId, email },
    process.env.JWT_SECRET!,
    signOptions
  );
}

export function generateRefreshToken(userId: number): string {
  return jwt.sign(
    { userId, type: 'refresh' },
    process.env.JWT_SECRET!,
    { expiresIn: '30d' } as SignOptions
  );
}

export function verifyAccessToken(token: string): { userId: number } {
  const decoded = jwt.verify(token, process.env.JWT_SECRET!) as { userId: number };
  return decoded;
}

export async function createRefreshTokenRecord(
  userId: number,
  token: string,
  deviceId?: string
): Promise<void> {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 30);
  await pool.query(
    `INSERT INTO refresh_tokens (user_id, token, device_id, expires_at)
     VALUES ($1, $2, $3, $4)`,
    [userId, token, deviceId || null, expiresAt]
  );
}

export async function revokeRefreshToken(token: string): Promise<void> {
  await pool.query(
    'UPDATE refresh_tokens SET revoked = true WHERE token = $1',
    [token]
  );
}

export async function validateRefreshToken(token: string): Promise<{ userId: number } | null> {
  const row = await pool.query(
    `SELECT user_id FROM refresh_tokens 
     WHERE token = $1 AND revoked = false AND expires_at > NOW()`,
    [token]
  );
  if (row.rows.length === 0) return null;
  return { userId: row.rows[0].user_id };
}
