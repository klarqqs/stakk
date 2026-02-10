import pool from '../config/database.ts';
import stellarService from '../services/stellar.service.ts';
import { applyReferralCode } from '../services/referral.service.ts';
import {
  generateAccessToken,
  generateRefreshToken,
  createRefreshTokenRecord
} from '../utils/jwt.ts';
import type { Request } from 'express';

export interface AuthUser {
  id: number;
  phone_number: string;
  email: string | null;
  stellar_public_key: string;
  created_at: Date;
  first_name?: string | null;
  last_name?: string | null;
}

export async function createUserWithStellar(
  phoneNumber: string,
  email: string | null,
  passwordHash: string | null,
  referralCode?: string | null
): Promise<AuthUser> {
  const wallet = stellarService.createWallet();
  await stellarService.fundNewAccount(wallet.publicKey);
  const encryptedSecret = Buffer.from(wallet.secretKey).toString('base64');

  const result = await pool.query(
    `INSERT INTO users (
      phone_number, email, password_hash,
      stellar_public_key, stellar_secret_key_encrypted
    ) VALUES ($1, $2, $3, $4, $5)
    RETURNING id, phone_number, email, stellar_public_key, created_at`,
    [phoneNumber, email, passwordHash, wallet.publicKey, encryptedSecret]
  );

  const user = result.rows[0];
  
  // For sandbox/testnet: Give new users test USDC balance for testing Dinari
  const isTestnet = process.env.STELLAR_NETWORK === 'testnet';
  const initialUSDCBalance = isTestnet ? '1000' : '0'; // 1000 test USDC for sandbox testing
  
  await pool.query('INSERT INTO wallets (user_id, usdc_balance) VALUES ($1, $2)', [
    user.id,
    initialUSDCBalance
  ]);

  if (isTestnet) {
    console.log(`✅ New testnet user created with ${initialUSDCBalance} test USDC for Dinari testing`);
  }

  if (referralCode && referralCode.trim()) {
    try {
      await applyReferralCode(user.id, referralCode.trim());
    } catch {
      // Ignore referral errors
    }
  }

  return user;
}

export async function signInResponse(
  user: AuthUser,
  req: Request
): Promise<{ accessToken: string; refreshToken: string; user: object }> {
  const accessToken = generateAccessToken(user.id, user.email ?? undefined);
  const refreshToken = generateRefreshToken(user.id);
  const deviceId = req.headers['x-device-id'] as string | undefined;
  await createRefreshTokenRecord(user.id, refreshToken, deviceId);

  return {
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      phone_number: user.phone_number,
      email: user.email,
      stellar_address: user.stellar_public_key,
      created_at: user.created_at,
      first_name: user.first_name ?? null,
      last_name: user.last_name ?? null
    }
  };
}
