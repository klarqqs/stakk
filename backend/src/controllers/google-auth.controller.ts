import type { Request, Response } from 'express';
import { OAuth2Client } from 'google-auth-library';
import pool from '../config/database.ts';
import {
  createUserWithStellar,
  signInResponse
} from '../services/auth-helpers.ts';

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

export class GoogleAuthController {
  async authenticate(req: Request, res: Response) {
    try {
      const { idToken, referralCode } = req.body;

      if (!idToken) {
        return res.status(400).json({ error: 'ID token is required' });
      }

      const clientId = process.env.GOOGLE_CLIENT_ID;
      if (!clientId) throw new Error('GOOGLE_CLIENT_ID not configured');

      const ticket = await googleClient.verifyIdToken({
        idToken,
        audience: clientId
      });

      const payload = ticket.getPayload();
      if (!payload) {
        return res.status(401).json({ error: 'Invalid Google token' });
      }

      const { sub: googleId, email, email_verified, name, picture } = payload;

      if (!email) {
        return res.status(400).json({ error: 'Email not provided by Google' });
      }

      const normalizedEmail = email.toLowerCase();

      const providerRow = await pool.query(
        `SELECT u.id, u.phone_number, u.email, u.stellar_public_key, u.created_at
         FROM auth_providers ap
         JOIN users u ON u.id = ap.user_id
         WHERE ap.provider = 'google' AND ap.provider_user_id = $1`,
        [googleId]
      );

      let user = providerRow.rows[0];
      let isNewUser = false;

      if (user) {
        await pool.query(
          'UPDATE users SET email = $1, updated_at = NOW() WHERE id = $2',
          [normalizedEmail, user.id]
        );
        user.email = normalizedEmail;
      } else {
        const emailRow = await pool.query(
          'SELECT id, phone_number, email, stellar_public_key, created_at FROM users WHERE LOWER(email) = $1',
          [normalizedEmail]
        );

        if (emailRow.rows.length > 0) {
          user = emailRow.rows[0];
          await pool.query(
            `INSERT INTO auth_providers (user_id, provider, provider_user_id)
             VALUES ($1, 'google', $2)`,
            [user.id, googleId]
          );
        } else {
          const phoneNumber = `google:${googleId}`;
          user = await createUserWithStellar(phoneNumber, normalizedEmail, null, referralCode);
          isNewUser = true;

          await pool.query(
            `INSERT INTO auth_providers (user_id, provider, provider_user_id)
             VALUES ($1, 'google', $2)`,
            [user.id, googleId]
          );
        }
      }

      const tokens = await signInResponse(user, req);

      res.json({
        success: true,
        isNewUser,
        ...tokens
      });
    } catch (error) {
      console.error('Google auth error:', error);
      res.status(401).json({ error: 'Google authentication failed' });
    }
  }
}
