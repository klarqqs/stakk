# Security & Configuration Guide - STAKK

Complete security configuration and best practices for production deployment.

## ✅ Completed Security Features

### 1. Environment Variable Validation
- ✅ **Created**: `backend/src/config/env-validation.ts`
- ✅ **Validates**: All required environment variables on startup
- ✅ **Checks**: Conditional requirements (e.g., TREASURY_SECRET_KEY for mainnet)
- ✅ **Warns**: About placeholder secrets and weak configurations
- ✅ **Prevents**: Server startup if critical variables are missing

### 2. CORS Configuration
- ✅ **Production**: Whitelist-based CORS (only allows configured origins)
- ✅ **Development**: Allows all origins for local testing
- ✅ **Configurable**: Via `CORS_ORIGINS` environment variable
- ✅ **Secure**: Blocks unauthorized origins in production

### 3. Rate Limiting
- ✅ **OTP Requests**: 3 requests per 15 minutes
- ✅ **OTP Verification**: 5 attempts per 5 minutes
- ✅ **OAuth**: 10 requests per minute
- ✅ **Login**: 5 attempts per 15 minutes
- ✅ **Password Reset**: 3 requests per hour
- ✅ **P2P Transfers**: 5 requests per minute (strict)
- ✅ **General API**: 100 requests per 15 minutes

### 4. Security Headers
- ✅ **X-Frame-Options**: DENY (prevents clickjacking)
- ✅ **X-Content-Type-Options**: nosniff (prevents MIME sniffing)
- ✅ **X-XSS-Protection**: Enabled
- ✅ **Referrer-Policy**: strict-origin-when-cross-origin
- ✅ **Strict-Transport-Security**: Enabled in production (HTTPS only)

### 5. Secret Management
- ✅ **.env in .gitignore**: Prevents accidental commits
- ✅ **Placeholder Detection**: Warns about default values
- ✅ **Production Checks**: Blocks placeholder secrets in production

## 🔧 Configuration

### Environment Variables

#### Required Variables
```bash
DATABASE_URL=postgresql://...
STELLAR_NETWORK=testnet|mainnet
STELLAR_HORIZON_URL=https://horizon.stellar.org
JWT_SECRET=your_secure_random_string_min_32_chars
EMAIL_SERVICE=resend|sendgrid|gmail
EMAIL_FROM=noreply@stakk.app
PORT=3001
NODE_ENV=production|development|test
```

#### Conditional Required
- **Mainnet**: `TREASURY_SECRET_KEY`, `TREASURY_PUBLIC_KEY`
- **Resend Email**: `RESEND_API_KEY`
- **SendGrid Email**: `SENDGRID_API_KEY`
- **Gmail Email**: `GMAIL_USER`, `GMAIL_APP_PASSWORD`

#### Optional
- `CORS_ORIGINS` - Comma-separated list of allowed origins
- `FIREBASE_SERVICE_ACCOUNT` - For push notifications
- `GOOGLE_CLIENT_ID` - For Google Sign-In
- `APPLE_CLIENT_ID` - For Apple Sign-In

### CORS Configuration

#### Production (Default)
If `CORS_ORIGINS` is not set, production defaults to:
```
https://stakk.app
https://www.stakk.app
https://app.stakk.app
```

#### Custom Origins
Set `CORS_ORIGINS` environment variable:
```bash
CORS_ORIGINS=https://stakk.app,https://admin.stakk.app,https://api.stakk.app
```

#### Development
In development mode (`NODE_ENV=development`), all origins are allowed for easier testing.

### Rate Limiting Configuration

Rate limits are defined in `backend/src/middleware/rate-limit.ts`. Adjust based on your needs:

```typescript
// OTP Request - Prevents spam
otpRequestLimiter: 3 requests / 15 minutes

// OTP Verify - Prevents brute force
otpVerifyLimiter: 5 attempts / 5 minutes

// OAuth - Prevents abuse
oauthLimiter: 10 requests / minute

// Login - Prevents brute force
authLimiter: 5 attempts / 15 minutes

// Password Reset - Prevents abuse
passwordResetLimiter: 3 requests / hour

// General API - Normal usage
apiLimiter: 100 requests / 15 minutes

// Strict - Sensitive operations
strictLimiter: 5 requests / minute
```

## 🔒 Security Best Practices

### 1. API Keys & Secrets

#### ✅ Do's
- Store all secrets in environment variables
- Use strong, random values for `JWT_SECRET` (min 32 characters)
- Rotate secrets regularly
- Use different secrets for development and production
- Never commit `.env` files to git

#### ❌ Don'ts
- Don't hardcode secrets in code
- Don't use placeholder values in production
- Don't share secrets via insecure channels
- Don't log secrets in console output

### 2. CORS Configuration

#### Production
- **Always** whitelist specific origins
- **Never** use `cors()` without options in production
- **Verify** origins match your actual domains
- **Test** CORS with your mobile app

#### Development
- Allow all origins for local testing
- Use `NODE_ENV=development` for permissive CORS

### 3. Rate Limiting

#### Adjust Based on:
- **Traffic patterns**: Monitor and adjust limits
- **User behavior**: Balance security vs UX
- **Attack patterns**: Tighten limits if under attack

#### Monitoring
- Check rate limit headers in responses
- Monitor blocked requests in logs
- Adjust limits based on legitimate usage

### 4. Environment Validation

The validation runs on server startup and:
- **Blocks startup** if required variables are missing
- **Warns** about weak configurations
- **Prevents** placeholder secrets in production
- **Validates** variable formats and values

## 🚀 Production Checklist

Before deploying to production:

- [ ] All environment variables set in Railway/production environment
- [ ] `JWT_SECRET` is strong (32+ characters, random)
- [ ] `CORS_ORIGINS` includes your production domains
- [ ] `NODE_ENV=production` is set
- [ ] No placeholder secrets (check validation warnings)
- [ ] Database connection string is secure
- [ ] Payment processor keys are configured
- [ ] Email service is configured and tested
- [ ] Firebase service account is configured (for push notifications)
- [ ] Rate limits are appropriate for your traffic
- [ ] Security headers are enabled
- [ ] HTTPS is enforced (via Railway/production platform)

## 📊 Monitoring

### Environment Validation Output

On startup, you'll see:
```
✅ Environment variables validated successfully
🚀 Server running on port 3001
📦 Environment: production
🌐 CORS origins: https://stakk.app, https://www.stakk.app
✅ Server initialized successfully
```

### Warnings to Watch For

- `⚠️ Placeholder secrets detected` - Update before production
- `⚠️ JWT_SECRET should be at least 32 characters` - Use stronger secret
- `⚠️ No payment processor configured` - Configure Flutterwave or Paystack
- `⚠️ Blocked CORS request from: [origin]` - Add origin to CORS_ORIGINS

## 🔍 Troubleshooting

### Server Won't Start

**Error**: "Missing required environment variables"
- **Solution**: Check `.env` file or Railway environment variables
- **Check**: All required variables from `env-validation.ts`

### CORS Errors in Production

**Error**: "Not allowed by CORS"
- **Solution**: Add your domain to `CORS_ORIGINS`
- **Check**: Verify domain matches exactly (including https://)

### Rate Limit Errors

**Error**: "Too many requests"
- **Solution**: Wait for rate limit window to reset
- **Adjust**: Modify limits in `rate-limit.ts` if needed

### Environment Validation Warnings

**Warning**: Placeholder secrets detected
- **Solution**: Update environment variables with real values
- **Check**: Ensure no default/placeholder values remain

## 📝 Railway Configuration

### Setting Environment Variables

1. Go to Railway Dashboard → Your Service → Variables
2. Add each variable from `.env.example`
3. Use Railway's secret management for sensitive values
4. Verify all variables are set before deploying

### Recommended Railway Variables

```bash
# Required
DATABASE_URL=<railway_postgres_url>
STELLAR_NETWORK=mainnet
JWT_SECRET=<generate_strong_random_string>
EMAIL_SERVICE=resend
RESEND_API_KEY=<your_resend_key>
EMAIL_FROM=noreply@stakk.app
NODE_ENV=production
PORT=3001

# CORS (adjust to your domains)
CORS_ORIGINS=https://stakk.app,https://www.stakk.app

# Payment & Services
FLUTTERWAVE_SECRET_KEY=<your_key>
FLUTTERWAVE_PUBLIC_KEY=<your_key>
FIREBASE_SERVICE_ACCOUNT=<minified_json>
GOOGLE_CLIENT_ID=<your_client_id>
APPLE_CLIENT_ID=com.stakk.stakkSavings
```

## 🔐 Generating Secure Secrets

### JWT_SECRET
```bash
# Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Using OpenSSL
openssl rand -hex 32

# Using Python
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### Other Secrets
- Use strong, random values (32+ characters)
- Use different values for each environment
- Store securely (Railway secrets, environment variables)
- Never commit to git

## ✅ Security Checklist

- [x] Environment validation on startup
- [x] CORS configured for production
- [x] Rate limiting on all auth endpoints
- [x] Rate limiting on sensitive operations
- [x] Security headers enabled
- [x] Secret management (no hardcoded secrets)
- [x] Placeholder detection
- [x] Production-specific checks

## 📞 Support

For security concerns:
- **Email**: security@stakk.app (if configured)
- **Support**: support@stakk.app

---

**STAKK** - Save in USDC, protected from inflation.
