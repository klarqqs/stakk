import type { Request, Response } from 'express';
import type { AuthRequest } from '../middleware/auth.middleware.ts';
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

export class EmailAuthController {
  /** Check if email exists - routes to Login or Sign Up */
  async checkEmail(req: Request, res: Response) {
    try {
      const { email } = req.body;
      if (!email || typeof email !== 'string') {
        return res.status(400).json({ error: 'Email is required' });
      }
      const normalizedEmail = email.trim().toLowerCase();
      if (!EMAIL_REGEX.test(normalizedEmail)) {
        return res.status(400).json({ error: 'Invalid email format' });
      }

      const result = await pool.query(
        'SELECT id FROM users WHERE LOWER(email) = $1',
        [normalizedEmail]
      );

      res.json({ exists: result.rows.length > 0 });
    } catch (error) {
      console.error('Check email error:', error);
      res.status(500).json({ error: 'Failed to check email' });
    }
  }

  /** Sign up with email, password, name - creates user, sends OTP */
  async registerEmail(req: Request, res: Response) {
    let userId: number | null = null;
    let normalizedEmail: string | null = null;
    try {
      const { email, password, firstName, lastName } = req.body;

      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
      }

      normalizedEmail = email.trim().toLowerCase();
      if (!normalizedEmail || !EMAIL_REGEX.test(normalizedEmail)) {
        return res.status(400).json({ error: 'Invalid email format' });
      }

      if (password.length < 8) {
        return res.status(400).json({ error: 'Password must be at least 8 characters' });
      }

      const existing = await pool.query(
        'SELECT id FROM users WHERE LOWER(email) = $1',
        [normalizedEmail]
      );
      if (existing.rows.length > 0) {
        return res.status(409).json({ error: 'User with this email already exists' });
      }

      const passwordHash = await bcrypt.hash(password, 10);
      const phoneNumber = `email:${normalizedEmail}`;

      const user = await createUserWithStellar(
        phoneNumber,
        normalizedEmail,
        passwordHash
      );
      userId = user.id;

      await pool.query(
        `UPDATE users SET first_name = $1, last_name = $2, email_verified = FALSE
         WHERE id = $3`,
        [firstName || null, lastName || null, user.id]
      );

      const code = crypto.randomInt(100000, 999999).toString();
      const codeHash = await bcrypt.hash(code, 10);
      const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

      await pool.query(
        `INSERT INTO otp_codes (email, code_hash, purpose, expires_at)
         VALUES ($1, $2, $3, $4)`,
        [normalizedEmail, codeHash, 'email_verification', expiresAt]
      );

      // Send email BEFORE returning success - if it fails, rollback user creation
      await sendOTPEmail(normalizedEmail!, code, 'signup');

      res.json({
        success: true,
        message: 'Verification code sent to your email',
        expiresIn: OTP_EXPIRY_MINUTES * 60
      });
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      console.error('Register email error:', error);

      // Rollback: delete user if created but email failed (prevents half-registered users)
      if (userId != null) {
        try {
          await pool.query('DELETE FROM wallets WHERE user_id = $1', [userId]);
          if (normalizedEmail) {
            await pool.query('DELETE FROM otp_codes WHERE email = $1 AND purpose = $2', [normalizedEmail, 'email_verification']);
          }
          await pool.query('DELETE FROM users WHERE id = $1', [userId]);
        } catch (rollbackErr) {
          console.error('Rollback failed:', rollbackErr);
        }
      }

      let userMessage: string;
      if (msg.includes('TREASURY_SECRET_KEY') || msg.includes('required for mainnet')) {
        userMessage = 'Stellar config: Set STELLAR_NETWORK=testnet in Railway, or add TREASURY_SECRET_KEY for mainnet.';
      } else if (msg.includes('Unable to fund') || msg.includes('Treasury may be low')) {
        userMessage = 'Stellar treasury is low on XLM. Fund your treasury wallet or use STELLAR_NETWORK=testnet.';
      } else if (msg.includes('RESEND_API_KEY') || msg.includes('Resend:')) {
        userMessage = 'Email (Resend): Add RESEND_API_KEY in Railway. Get free key at resend.com';
      } else if (msg.includes('nodemailer') || msg.includes('SMTP') || msg.includes('sendMail') || msg.includes('Invalid Login') ||
          msg.includes('ENETUNREACH') || msg.includes('ESOCKET') || msg.includes('connection timeout') || msg.includes('connect ECONNREFUSED')) {
        userMessage = 'Email failed. Use Resend: set EMAIL_SERVICE=resend and RESEND_API_KEY in Railway (free at resend.com)';
      } else if (msg.length < 120) {
        userMessage = msg;
      } else {
        userMessage = `Registration failed: ${msg.slice(0, 80)}...`;
      }
      res.status(500).json({ error: userMessage });
    }
  }

  /** Resend verification OTP */
  async resendVerifyOtp(req: Request, res: Response) {
    try {
      const { email } = req.body;
      if (!email || typeof email !== 'string') {
        return res.status(400).json({ error: 'Email is required' });
      }
      const normalizedEmail = email.trim().toLowerCase();

      const userRow = await pool.query(
        'SELECT id, email_verified FROM users WHERE LOWER(email) = $1',
        [normalizedEmail]
      );
      if (userRow.rows.length === 0) {
        return res.status(404).json({ error: 'User not found' });
      }
      if (userRow.rows[0].email_verified) {
        return res.status(400).json({ error: 'Email already verified' });
      }

      const code = crypto.randomInt(100000, 999999).toString();
      const codeHash = await bcrypt.hash(code, 10);
      const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

      await pool.query(
        `INSERT INTO otp_codes (email, code_hash, purpose, expires_at)
         VALUES ($1, $2, $3, $4)`,
        [normalizedEmail, codeHash, 'email_verification', expiresAt]
      );

      await sendOTPEmail(normalizedEmail, code, 'signup');

      res.json({
        success: true,
        message: 'New code sent to your email',
        expiresIn: OTP_EXPIRY_MINUTES * 60
      });
    } catch (error) {
      console.error('Resend OTP error:', error);
      res.status(500).json({ error: 'Failed to send code' });
    }
  }

  /** Verify email OTP after signup - marks verified, returns tokens */
  async verifyEmailSignup(req: Request, res: Response) {
    try {
      const { email, code } = req.body;

      if (!email || !code) {
        return res.status(400).json({ error: 'Email and code are required' });
      }

      const normalizedEmail = email.trim().toLowerCase();
      const codeStr = String(code).trim();

      const otpRow = await pool.query(
        `SELECT id, code_hash, expires_at, attempts FROM otp_codes
         WHERE email = $1 AND purpose = 'email_verification' AND verified = false
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
      await pool.query(
        'UPDATE users SET email_verified = TRUE WHERE LOWER(email) = $1',
        [normalizedEmail]
      );

      const userRow = await pool.query(
        `SELECT id, phone_number, email, stellar_public_key, created_at
         FROM users WHERE LOWER(email) = $1`,
        [normalizedEmail]
      );

      if (userRow.rows.length === 0) {
        return res.status(500).json({ error: 'User not found' });
      }

      const user = userRow.rows[0];
      const tokens = await signInResponse(user, req);

      res.json({
        success: true,
        isNewUser: true,
        ...tokens
      });
    } catch (error) {
      console.error('Verify email error:', error);
      res.status(500).json({ error: 'Verification failed' });
    }
  }

  /** Login with email + password */
  async loginEmail(req: Request, res: Response) {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
      }

      const normalizedEmail = email.trim().toLowerCase();

      const result = await pool.query(
        `SELECT id, phone_number, email, password_hash, stellar_public_key,
                email_verified, first_name, last_name, created_at
         FROM users WHERE LOWER(email) = $1`,
        [normalizedEmail]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const user = result.rows[0];

      if (!user.password_hash) {
        return res.status(401).json({
          error: 'Please use email verification to sign in',
          requiresOtp: true
        });
      }

      const valid = await bcrypt.compare(password, user.password_hash);
      if (!valid) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      if (!user.email_verified) {
        return res.status(401).json({
          error: 'Please activate your account. Check your email for a verification code.',
          requiresVerification: true
        });
      }

      const tokens = await signInResponse(user, req);

      res.json({
        success: true,
        isNewUser: false,
        ...tokens
      });
    } catch (error) {
      console.error('Login email error:', error);
      res.status(500).json({ error: 'Login failed' });
    }
  }

  /** Update profile (phone) - authenticated */
  async updateProfile(req: AuthRequest, res: Response) {
    try {
      const userId = req.userId!;
      const { phoneNumber } = req.body;

      if (!phoneNumber || typeof phoneNumber !== 'string') {
        return res.status(400).json({ error: 'Phone number is required' });
      }

      const cleaned = phoneNumber.replace(/\D/g, '');
      if (cleaned.length < 10) {
        return res.status(400).json({ error: 'Invalid phone number' });
      }

      const formatted = cleaned.startsWith('234')
        ? cleaned
        : cleaned.startsWith('0')
          ? cleaned
          : cleaned.length === 10
            ? `0${cleaned}`
            : cleaned;

      await pool.query(
        'UPDATE users SET phone_number = $1, updated_at = NOW() WHERE id = $2',
        [formatted, userId]
      );

      res.json({ success: true, message: 'Profile updated' });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({ error: 'Failed to update profile' });
    }
  }

  /** Request OTP for password reset */
  async forgotPassword(req: Request, res: Response) {
    try {
      const { email } = req.body;

      if (!email || typeof email !== 'string') {
        return res.status(400).json({ error: 'Email is required' });
      }

      const normalizedEmail = email.trim().toLowerCase();
      if (!EMAIL_REGEX.test(normalizedEmail)) {
        return res.status(400).json({ error: 'Invalid email format' });
      }

      const existing = await pool.query(
        'SELECT id FROM users WHERE LOWER(email) = $1',
        [normalizedEmail]
      );
      if (existing.rows.length === 0) {
        return res.status(404).json({ error: 'No account found with this email' });
      }

      const code = crypto.randomInt(100000, 999999).toString();
      const codeHash = await bcrypt.hash(code, 10);
      const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

      await pool.query(
        `INSERT INTO otp_codes (email, code_hash, purpose, expires_at)
         VALUES ($1, $2, $3, $4)`,
        [normalizedEmail, codeHash, 'password_reset', expiresAt]
      );

      await sendOTPEmail(normalizedEmail, code, 'login');

      res.json({
        success: true,
        message: 'Verification code sent to your email',
        expiresIn: OTP_EXPIRY_MINUTES * 60
      });
    } catch (error) {
      console.error('Forgot password error:', error);
      res.status(500).json({ error: 'Failed to send code' });
    }
  }

  /** Reset password after OTP verification */
  async resetPassword(req: Request, res: Response) {
    try {
      const { email, code, password } = req.body;

      if (!email || !code || !password) {
        return res.status(400).json({ error: 'Email, code, and password are required' });
      }

      const normalizedEmail = email.trim().toLowerCase();
      const codeStr = String(code).trim();

      const otpRow = await pool.query(
        `SELECT id, code_hash, expires_at, attempts FROM otp_codes
         WHERE email = $1 AND purpose = 'password_reset' AND verified = false
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

      const valid = await bcrypt.compare(codeStr, otp.code_hash);
      if (!valid) {
        await pool.query(
          'UPDATE otp_codes SET attempts = attempts + 1 WHERE id = $1',
          [otp.id]
        );
        return res.status(400).json({ error: 'Invalid OTP code' });
      }

      if (password.length < 8) {
        return res.status(400).json({ error: 'Password must be at least 8 characters' });
      }

      const passwordHash = await bcrypt.hash(password, 10);

      await pool.query('UPDATE otp_codes SET verified = true WHERE id = $1', [otp.id]);
      await pool.query(
        'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE LOWER(email) = $2',
        [passwordHash, normalizedEmail]
      );

      const userRow = await pool.query(
        `SELECT id, phone_number, email, stellar_public_key, created_at
         FROM users WHERE LOWER(email) = $1`,
        [normalizedEmail]
      );

      if (userRow.rows.length === 0) {
        return res.status(500).json({ error: 'User not found' });
      }

      const user = userRow.rows[0];
      const tokens = await signInResponse(user, req);

      res.json({
        success: true,
        message: 'Password reset successfully',
        ...tokens
      });
    } catch (error) {
      console.error('Reset password error:', error);
      res.status(500).json({ error: 'Password reset failed' });
    }
  }
}
