import { Router } from 'express';
import { EmailOtpController } from '../controllers/email-otp.controller.ts';
import { EmailAuthController } from '../controllers/email-auth.controller.ts';
import { GoogleAuthController } from '../controllers/google-auth.controller.ts';
import { AppleAuthController } from '../controllers/apple-auth.controller.ts';
import { authenticateToken } from '../middleware/auth.middleware.ts';
import {
  otpRequestLimiter,
  otpVerifyLimiter,
  oauthLimiter,
  authLimiter,
  passwordResetLimiter,
} from '../middleware/rate-limit.ts';
import {
  revokeRefreshToken,
  validateRefreshToken,
  generateAccessToken,
  generateRefreshToken,
  createRefreshTokenRecord
} from '../utils/jwt.ts';
import pool from '../config/database.ts';

const router = Router();
const emailOtpController = new EmailOtpController();
const emailAuthController = new EmailAuthController();
const googleAuthController = new GoogleAuthController();
const appleAuthController = new AppleAuthController();

// Email-first flow (Dayfi-style)
router.post('/check-email', (req, res) => emailAuthController.checkEmail(req, res));
router.post('/register-email', otpRequestLimiter, (req, res) => emailAuthController.registerEmail(req, res));
router.post('/verify-email', otpVerifyLimiter, (req, res) => emailAuthController.verifyEmailSignup(req, res));
router.post('/resend-verify-otp', otpRequestLimiter, (req, res) => emailAuthController.resendVerifyOtp(req, res));
router.post('/login-email', authLimiter, (req, res) => emailAuthController.loginEmail(req, res));
router.patch('/profile', authenticateToken, (req, res) => emailAuthController.updateProfile(req, res));
router.post('/forgot-password', passwordResetLimiter, (req, res) => emailAuthController.forgotPassword(req, res));
router.post('/reset-password', otpVerifyLimiter, (req, res) => emailAuthController.resetPassword(req, res));

// Email OTP (passwordless)
router.post(
  '/email/request-otp',
  otpRequestLimiter,
  (req, res) => emailOtpController.requestOtp(req, res)
);
router.post(
  '/email/verify-otp',
  otpVerifyLimiter,
  (req, res) => emailOtpController.verifyOtp(req, res)
);

// Google OAuth
router.post(
  '/google',
  oauthLimiter,
  (req, res) => googleAuthController.authenticate(req, res)
);

// Apple OAuth
router.post(
  '/apple',
  oauthLimiter,
  (req, res) => appleAuthController.authenticate(req, res)
);

// Token refresh
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    const decoded = await validateRefreshToken(refreshToken);
    if (!decoded) {
      return res.status(401).json({ error: 'Invalid or expired refresh token' });
    }

    const userRow = await pool.query(
      'SELECT id, phone_number, email, stellar_public_key, created_at, first_name, last_name FROM users WHERE id = $1',
      [decoded.userId]
    );

    if (userRow.rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }

    // Revoke the old refresh token
    await revokeRefreshToken(refreshToken);

    const user = userRow.rows[0];
    const accessToken = generateAccessToken(user.id, user.email);
    let newRefreshToken = generateRefreshToken(user.id);
    const deviceId = req.headers['x-device-id'] as string | undefined;
    
    // Create new refresh token record (handles duplicates gracefully with ON CONFLICT)
    // If somehow a duplicate still occurs, generate a new token and retry
    try {
      await createRefreshTokenRecord(user.id, newRefreshToken, deviceId);
    } catch (error: any) {
      // If duplicate token error still occurs (shouldn't with ON CONFLICT, but handle edge cases),
      // generate a new token and try again once
      if (error?.code === '23505') {
        newRefreshToken = generateRefreshToken(user.id);
        await createRefreshTokenRecord(user.id, newRefreshToken, deviceId);
      } else {
        throw error;
      }
    }

    res.json({
      accessToken,
      refreshToken: newRefreshToken,
      user: {
        id: user.id,
        phone_number: user.phone_number,
        email: user.email,
        stellar_address: user.stellar_public_key,
        created_at: user.created_at,
        first_name: user.first_name ?? null,
        last_name: user.last_name ?? null
      }
    });
  } catch (error) {
    console.error('Refresh error:', error);
    res.status(500).json({ error: 'Token refresh failed' });
  }
});

// Logout (revoke refresh token)
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await revokeRefreshToken(refreshToken);
    }
    res.json({ success: true, message: 'Logged out' });
  } catch (error) {
    res.json({ success: true });
  }
});

export default router;
