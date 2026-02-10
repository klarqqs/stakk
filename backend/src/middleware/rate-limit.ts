import rateLimit from 'express-rate-limit';

/**
 * Rate limiters for different endpoints.
 * Adjust limits based on your needs and traffic patterns.
 * 
 * Note: validate.trustProxy is set to false to suppress warnings when trust proxy is enabled.
 * Railway and other platforms require trust proxy for correct IP detection, but express-rate-limit
 * warns about this. We disable the validation since we're using Railway's reverse proxy correctly.
 */

// OTP Request Limiter - Prevents spam OTP requests
export const otpRequestLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 3, // 3 requests per 15 minutes
  message: { error: 'Too many OTP requests. Please try again in 15 minutes.' },
  standardHeaders: true, // Return rate limit info in `RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  skipSuccessfulRequests: false, // Count all requests, including successful ones
  validate: { trustProxy: false }, // Suppress warning - Railway requires trust proxy for correct IP detection
});

// OTP Verify Limiter - Prevents brute force attempts
export const otpVerifyLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 5, // 5 attempts per 5 minutes
  message: { error: 'Too many verification attempts. Please request a new code.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { trustProxy: false },
});

// OAuth Limiter - Prevents abuse of social sign-in
export const oauthLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 requests per minute
  message: { error: 'Too many requests. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { trustProxy: false },
});

// General Auth Limiter - For login endpoints
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 login attempts per 15 minutes
  message: { error: 'Too many login attempts. Please try again in 15 minutes.' },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Don't count successful logins
  validate: { trustProxy: false },
});

// Password Reset Limiter - Prevents abuse
export const passwordResetLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 password reset requests per hour
  message: { error: 'Too many password reset requests. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { trustProxy: false },
});

// General API Limiter - For authenticated endpoints
// Very high limit to prevent 429s during normal app usage:
// - Home screen: ~7 requests per load
// - Navigation between tabs: ~14 requests per cycle
// - Pull-to-refresh and background updates
// - Multiple users, rapid navigation, etc.
// 1000 requests per 15 minutes = ~66 requests per minute = very generous for normal usage
// This prevents legitimate users from hitting rate limits while still protecting against abuse
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // 1000 requests per 15 minutes (very generous to prevent user-facing errors)
  message: { error: 'Too many requests. Please try again in a moment.' },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: false, // Count all requests
  validate: { trustProxy: false },
});

// Strict Limiter - For sensitive operations (withdrawals, transfers)
export const strictLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // 5 requests per minute
  message: { error: 'Too many requests. Please wait a moment before trying again.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { trustProxy: false },
});
