import type { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import pool from '../config/database.ts';
import stellarService from '../services/stellar.service.ts';

export class AuthController {
  // Register new user
  async register(req: Request, res: Response) {
    try {
      const { phone_number, email, password } = req.body;

      // Validation
      if (!phone_number || !password) {
        return res.status(400).json({ error: 'Phone number and password required' });
      }

      // Check if user exists
      const existingUser = await pool.query(
        'SELECT id FROM users WHERE phone_number = $1',
        [phone_number]
      );

      if (existingUser.rows.length > 0) {
        return res.status(409).json({ error: 'User already exists' });
      }

      // Create Stellar wallet
      const wallet = stellarService.createWallet();
      
      // Fund testnet account (only for testing, remove in production)
      await stellarService.fundTestnetAccount(wallet.publicKey);

      // Hash password
      const passwordHash = await bcrypt.hash(password, 10);

      // Encrypt secret key (basic encryption for MVP)
      const encryptedSecret = Buffer.from(wallet.secretKey).toString('base64');

      // Insert user
      const result = await pool.query(
        `INSERT INTO users (
          phone_number, email, password_hash, 
          stellar_public_key, stellar_secret_key_encrypted
        ) VALUES ($1, $2, $3, $4, $5)
        RETURNING id, phone_number, email, stellar_public_key, created_at`,
        [phone_number, email, passwordHash, wallet.publicKey, encryptedSecret]
      );

      const user = result.rows[0];

      // Create wallet record
      await pool.query(
        'INSERT INTO wallets (user_id, usdc_balance) VALUES ($1, $2)',
        [user.id, 0]
      );

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, phone: user.phone_number },
        process.env.JWT_SECRET!,
        { expiresIn: '7d' }
      );

      res.status(201).json({
        message: 'User registered successfully',
        user: {
          id: user.id,
          phone_number: user.phone_number,
          email: user.email,
          stellar_address: user.stellar_public_key,
          created_at: user.created_at
        },
        token
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({ error: 'Registration failed' });
    }
  }

  // Login user
  async login(req: Request, res: Response) {
    try {
      const { phone_number, password } = req.body;

      // Validation
      if (!phone_number || !password) {
        return res.status(400).json({ error: 'Phone number and password required' });
      }

      // Find user
      const result = await pool.query(
        'SELECT id, phone_number, email, password_hash, stellar_public_key FROM users WHERE phone_number = $1',
        [phone_number]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      const user = result.rows[0];

      // Verify password
      const validPassword = await bcrypt.compare(password, user.password_hash);
      if (!validPassword) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, phone: user.phone_number },
        process.env.JWT_SECRET!,
        { expiresIn: '7d' }
      );

      res.json({
        message: 'Login successful',
        user: {
          id: user.id,
          phone_number: user.phone_number,
          email: user.email,
          stellar_address: user.stellar_public_key
        },
        token
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ error: 'Login failed' });
    }
  }
}