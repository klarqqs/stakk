import type { Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';
import pool from '../config/database.ts';
import {
  createUserWithStellar,
  signInResponse
} from '../services/auth-helpers.ts';

const appleJwks = jwksClient({
  jwksUri: 'https://appleid.apple.com/auth/keys',
  cache: true
});

function getAppleKey(header: jwt.JwtHeader): Promise<string> {
  return new Promise((resolve, reject) => {
    if (!header.kid) {
      reject(new Error('No kid in header'));
      return;
    }
    appleJwks.getSigningKey(header.kid, (err, key) => {
      if (err) reject(err);
      else resolve(key?.getPublicKey() ?? '');
    });
  });
}

export class AppleAuthController {
  async authenticate(req: Request, res: Response) {
    try {
      const { identityToken, user: appleUser, referralCode } = req.body;

      if (!identityToken) {
        return res.status(400).json({ error: 'Identity token is required' });
      }

      const decoded = jwt.decode(identityToken, { complete: true });
      if (!decoded || typeof decoded === 'string') {
        return res.status(401).json({ error: 'Invalid Apple token' });
      }

      const appleKey = await getAppleKey(decoded.header);
      const payload = jwt.verify(identityToken, appleKey, {
        algorithms: ['RS256'],
        audience: process.env.APPLE_CLIENT_ID,
        issuer: 'https://appleid.apple.com'
      }) as { sub: string; email?: string; email_verified?: string };

      const appleId = payload.sub;
      let email = payload.email;

      if (!email && appleUser?.email) {
        email = appleUser.email;
      }

      if (!email) {
        return res.status(400).json({ error: 'Email not provided by Apple' });
      }

      const normalizedEmail = email.toLowerCase();
      let fullName: string | null = null;
      if (appleUser?.name) {
        const { firstName, lastName } = appleUser.name;
        fullName = [firstName, lastName].filter(Boolean).join(' ') || null;
      }

      const providerRow = await pool.query(
        `SELECT u.id, u.phone_number, u.email, u.stellar_public_key, u.created_at
         FROM auth_providers ap
         JOIN users u ON u.id = ap.user_id
         WHERE ap.provider = 'apple' AND ap.provider_user_id = $1`,
        [appleId]
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
             VALUES ($1, 'apple', $2)`,
            [user.id, appleId]
          );
        } else {
          const phoneNumber = `apple:${appleId}`;
          user = await createUserWithStellar(phoneNumber, normalizedEmail, null, referralCode);
          isNewUser = true;

          await pool.query(
            `INSERT INTO auth_providers (user_id, provider, provider_user_id)
             VALUES ($1, 'apple', $2)`,
            [user.id, appleId]
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
      console.error('Apple auth error:', error);
      res.status(401).json({ error: 'Apple authentication failed' });
    }
  }
}
