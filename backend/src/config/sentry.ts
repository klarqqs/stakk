import * as Sentry from '@sentry/node';
import { ProfilingIntegration } from '@sentry/profiling-node';

/**
 * Initialize Sentry for error tracking and performance monitoring.
 * 
 * Set SENTRY_DSN environment variable to enable.
 * If not set, Sentry will be disabled (useful for local development).
 */
export function initializeSentry() {
  // Use environment variable or fallback to default DSN
  const dsn = process.env.SENTRY_DSN || 'https://37d9314029b683d8af1d50295cfab8a6@o4510855989297152.ingest.de.sentry.io/4510856008106064';
  
  if (!dsn || dsn.trim() === '') {
    console.warn('⚠️  Sentry DSN not configured. Error tracking disabled.');
    return;
  }

  const environment = process.env.NODE_ENV || 'development';
  const release = process.env.SENTRY_RELEASE || `stakk-backend@${process.env.npm_package_version || 'unknown'}`;

  Sentry.init({
    dsn,
    environment,
    release,
    tracesSampleRate: 0.2, // 20% of transactions for performance monitoring
    profilesSampleRate: environment === 'production' ? 0.1 : 1.0, // 10% in prod, 100% in dev
    integrations: [
      new ProfilingIntegration(),
    ],
    beforeSend(event, hint) {
      // Filter out sensitive data
      if (event.request?.data) {
        const data = event.request.data as Record<string, unknown>;
        const sensitiveFields = ['password', 'token', 'secret', 'apiKey', 'accessToken', 'refreshToken'];
        
        const sanitized = { ...data };
        for (const field of sensitiveFields) {
          if (sanitized[field]) {
            sanitized[field] = '[REDACTED]';
          }
        }
        event.request.data = sanitized;
      }
      
      // Remove sensitive headers
      if (event.request?.headers) {
        const headers = event.request.headers as Record<string, string>;
        const sensitiveHeaders = ['authorization', 'cookie', 'x-api-key'];
        for (const header of sensitiveHeaders) {
          if (headers[header]) {
            headers[header] = '[REDACTED]';
          }
        }
      }
      
      return event;
    },
  });

  console.log(`✅ Sentry initialized for backend (${environment})`);
}

export { Sentry };
