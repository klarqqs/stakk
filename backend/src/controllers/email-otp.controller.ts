import type { Request, Response } from 'express';
import crypto from 'crypto';
import bcrypt from 'bcrypt';
import pool from '../config/database.ts';
import { sendOTPEmail } from '../services/email.service.ts';
import {
  createUserWithStellar,
  signInResponse
} from '../services/auth-helpers.ts';

const OTP_EXPIRY_MINUTES = 5;
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export class EmailOtpController {
  async requestOtp(req: Request, res: Response) {
    try {
      const { email, purpose = 'login' } = req.body;

      if (!email || typeof email !== 'string') {
        return res.status(400).json({ error: 'Email is required' });
      }

      const normalizedEmail = email.trim().toLowerCase();
      if (!EMAIL_REGEX.test(normalizedEmail)) {
        return res.status(400).json({ error: 'Invalid email format' });
      }

      if (purpose === 'signup') {
        const existing = await pool.query(
          'SELECT id FROM users WHERE LOWER(email) = $1',
          [normalizedEmail]
        );
        if (existing.rows.length > 0) {
          return res.status(409).json({ error: 'User with this email already exists' });
        }
      } else {
        const existing = await pool.query(
          'SELECT id FROM users WHERE LOWER(email) = $1',
          [normalizedEmail]
        );
        if (existing.rows.length === 0) {
          return res.status(404).json({ error: 'No account found with this email' });
        }
      }

      const code = crypto.randomInt(100000, 999999).toString();
      const codeHash = await bcrypt.hash(code, 10);
      const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

      await pool.query(
        `INSERT INTO otp_codes (email, code_hash, purpose, expires_at)
         VALUES ($1, $2, $3, $4)`,
        [normalizedEmail, codeHash, purpose, expiresAt]
      );

      await sendOTPEmail(normalizedEmail, code, purpose as 'signup' | 'login');

      res.json({
        success: true,
        message: 'OTP sent to your email',
        expiresIn: OTP_EXPIRY_MINUTES * 60
      });
    } catch (error) {
      console.error('Request OTP error:', error);
      res.status(500).json({ error: 'Failed to send OTP' });
    }
  }

  async verifyOtp(req: Request, res: Response) {
    try {
      const { email, code } = req.body;

      if (!email || !code) {
        return res.status(400).json({ error: 'Email and code are required' });
      }

      const normalizedEmail = email.trim().toLowerCase();
      const codeStr = String(code).trim();

      const otpRow = await pool.query(
        `SELECT id, code_hash, expires_at, attempts FROM otp_codes
         WHERE email = $1 AND verified = false
         ORDER BY created_at DESC LIMIT 1`,
        [normalizedEmail]
      );

      if (otpRow.rows.length === 0) {
        return res.status(400).json({ error: 'No valid OTP found. Please request a new code.' });
      }

      const otp = otpRow.rows[0];
      if (new Date() > new Date(otp.expires_at)) {
        return res.status(400).json({ error: 'OTP has expired' });
      }

      if (otp.attempts >= 5) {
        return res.status(400).json({ error: 'Too many attempts. Please request a new code.' });
      }

      const valid = await bcrypt.compare(codeStr, otp.code_hash);
      if (!valid) {
        await pool.query(
          'UPDATE otp_codes SET attempts = attempts + 1 WHERE id = $1',
          [otp.id]
        );
        return res.status(400).json({ error: 'Invalid OTP code' });
      }

      await pool.query('UPDATE otp_codes SET verified = true WHERE id = $1', [otp.id]);

      let userRow = await pool.query(
        `SELECT id, phone_number, email, stellar_public_key, created_at
         FROM users WHERE LOWER(email) = $1`,
        [normalizedEmail]
      );

      let user = userRow.rows[0];
      let isNewUser = false;

      if (!user) {
        const phoneNumber = `email:${normalizedEmail}`;
        user = await createUserWithStellar(phoneNumber, normalizedEmail, null);
        isNewUser = true;

        await pool.query(
          `INSERT INTO auth_providers (user_id, provider, provider_user_id)
           VALUES ($1, 'email', $2)`,
          [user.id, normalizedEmail]
        );
      }

      const tokens = await signInResponse(user, req);

      res.json({
        success: true,
        isNewUser,
        ...tokens
      });
    } catch (error) {
      console.error('Verify OTP error:', error);
      res.status(500).json({ error: 'Verification failed' });
    }
  }
}
