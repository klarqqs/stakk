/**
 * Environment variable validation on startup.
 * Ensures all required environment variables are present and valid.
 */

interface EnvConfig {
  // Database
  DATABASE_URL: string;
  
  // Stellar
  STELLAR_NETWORK: 'testnet' | 'mainnet';
  STELLAR_HORIZON_URL: string;
  TREASURY_SECRET_KEY?: string;
  TREASURY_PUBLIC_KEY?: string;
  
  // JWT
  JWT_SECRET: string;
  
  // Email
  EMAIL_SERVICE: 'resend' | 'sendgrid' | 'gmail';
  RESEND_API_KEY?: string;
  SENDGRID_API_KEY?: string;
  GMAIL_USER?: string;
  GMAIL_APP_PASSWORD?: string;
  EMAIL_FROM: string;
  
  // Flutterwave
  FLUTTERWAVE_SECRET_KEY?: string;
  FLUTTERWAVE_PUBLIC_KEY?: string;
  FLUTTERWAVE_ENCRYPTION_KEY?: string;
  FLUTTERWAVE_SECRET_HASH?: string;
  
  // Paystack
  PAYSTACK_SECRET_KEY?: string;
  PAYSTACK_PUBLIC_KEY?: string;
  
  // Firebase
  FIREBASE_SERVICE_ACCOUNT?: string;
  
  // Google OAuth
  GOOGLE_CLIENT_ID?: string;
  
  // Apple OAuth
  APPLE_CLIENT_ID?: string;
  
  // App
  PORT: string;
  NODE_ENV: 'development' | 'production' | 'test';
  
  // Limits
  MAX_DEPOSIT_NGN?: string;
  MAX_DEPOSIT_PER_USER_NGN?: string;
  MAX_DAILY_DEPOSITS_NGN?: string;
  NGN_USD_RATE?: string;
  DEPOSIT_FEE_RATE?: string;
}

const requiredEnvVars: (keyof EnvConfig)[] = [
  'DATABASE_URL',
  'STELLAR_NETWORK',
  'STELLAR_HORIZON_URL',
  'JWT_SECRET',
  'EMAIL_SERVICE',
  'EMAIL_FROM',
  'PORT',
  'NODE_ENV',
];

const conditionalRequired: Record<string, (env: Partial<EnvConfig>) => boolean> = {
  TREASURY_SECRET_KEY: (env) => env.STELLAR_NETWORK === 'mainnet',
  TREASURY_PUBLIC_KEY: (env) => env.STELLAR_NETWORK === 'mainnet',
  RESEND_API_KEY: (env) => env.EMAIL_SERVICE === 'resend',
  SENDGRID_API_KEY: (env) => env.EMAIL_SERVICE === 'sendgrid',
  GMAIL_USER: (env) => env.EMAIL_SERVICE === 'gmail',
  GMAIL_APP_PASSWORD: (env) => env.EMAIL_SERVICE === 'gmail',
};

export function validateEnvironment(): void {
  const missing: string[] = [];
  const warnings: string[] = [];
  
  // Check required variables
  for (const key of requiredEnvVars) {
    const value = process.env[key];
    if (!value || value.trim() === '') {
      missing.push(key);
    }
  }
  
  // Check conditional required variables
  const env = process.env as Partial<EnvConfig>;
  for (const [key, condition] of Object.entries(conditionalRequired)) {
    if (condition(env) && (!env[key as keyof EnvConfig] || env[key as keyof EnvConfig]?.toString().trim() === '')) {
      missing.push(key);
    }
  }
  
  // Validate JWT_SECRET strength
  if (process.env.JWT_SECRET) {
    if (process.env.JWT_SECRET.length < 32) {
      warnings.push('JWT_SECRET should be at least 32 characters long for production');
    }
    if (process.env.JWT_SECRET === 'change_this_to_a_secure_random_string') {
      warnings.push('JWT_SECRET is still using the default value. Change it immediately!');
    }
  }
  
  // Validate NODE_ENV
  const validEnvs = ['development', 'production', 'test'];
  if (process.env.NODE_ENV && !validEnvs.includes(process.env.NODE_ENV)) {
    warnings.push(`NODE_ENV should be one of: ${validEnvs.join(', ')}`);
  }
  
  // Validate STELLAR_NETWORK
  if (process.env.STELLAR_NETWORK && !['testnet', 'mainnet'].includes(process.env.STELLAR_NETWORK)) {
    warnings.push('STELLAR_NETWORK should be either "testnet" or "mainnet"');
  }
  
  // Validate EMAIL_SERVICE
  const validEmailServices = ['resend', 'sendgrid', 'gmail'];
  if (process.env.EMAIL_SERVICE && !validEmailServices.includes(process.env.EMAIL_SERVICE)) {
    warnings.push(`EMAIL_SERVICE should be one of: ${validEmailServices.join(', ')}`);
  }
  
  // Production-specific checks
  if (process.env.NODE_ENV === 'production') {
    if (!process.env.FLUTTERWAVE_SECRET_KEY && !process.env.PAYSTACK_SECRET_KEY) {
      warnings.push('No payment processor configured (FLUTTERWAVE_SECRET_KEY or PAYSTACK_SECRET_KEY)');
    }
    
    if (process.env.STELLAR_NETWORK === 'mainnet' && !process.env.TREASURY_SECRET_KEY) {
      warnings.push('Mainnet requires TREASURY_SECRET_KEY');
    }
    
    if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
      warnings.push('FIREBASE_SERVICE_ACCOUNT not set - push notifications will be disabled');
    }
  }
  
  // Report errors
  if (missing.length > 0) {
    console.error('❌ Missing required environment variables:');
    missing.forEach(key => console.error(`   - ${key}`));
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
  
  // Report warnings
  if (warnings.length > 0) {
    console.warn('⚠️  Environment configuration warnings:');
    warnings.forEach(warning => console.warn(`   - ${warning}`));
  }
  
  console.log('✅ Environment variables validated successfully');
}

/**
 * Get CORS origins from environment or use defaults
 */
export function getCorsOrigins(): string[] {
  const corsOrigins = process.env.CORS_ORIGINS;
  
  if (corsOrigins) {
    return corsOrigins.split(',').map(origin => origin.trim()).filter(Boolean);
  }
  
  // Default origins based on NODE_ENV
  if (process.env.NODE_ENV === 'production') {
    return [
      'https://stakk.app',
      'https://www.stakk.app',
      'https://app.stakk.app',
    ];
  }
  
  // Development defaults
  return [
    'http://localhost:3000',
    'http://localhost:8080',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:8080',
  ];
}

/**
 * Check if API keys are using placeholder values
 */
export function checkForPlaceholderSecrets(): void {
  const placeholders = [
    { key: 'JWT_SECRET', value: 'change_this_to_a_secure_random_string' },
    { key: 'TREASURY_SECRET_KEY', value: 'S...your_secret_key_from_treasury_wallet' },
    { key: 'FLUTTERWAVE_SECRET_KEY', value: 'FLWSECK-...' },
    { key: 'RESEND_API_KEY', value: 're_xxxx' },
  ];
  
  const found: string[] = [];
  
  for (const { key, value } of placeholders) {
    if (process.env[key] === value) {
      found.push(key);
    }
  }
  
  if (found.length > 0 && process.env.NODE_ENV === 'production') {
    console.error('❌ Placeholder secrets detected in production:');
    found.forEach(key => console.error(`   - ${key}`));
    throw new Error('Cannot use placeholder secrets in production');
  }
  
  if (found.length > 0) {
    console.warn('⚠️  Placeholder secrets detected (update before production):');
    found.forEach(key => console.warn(`   - ${key}`));
  }
}
