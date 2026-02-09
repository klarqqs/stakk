# Sentry Setup Guide - STAKK

Complete guide for setting up Sentry error tracking for both mobile (Flutter) and backend (Node.js).

## 📋 Overview

STAKK needs **two separate Sentry projects**:
1. **Mobile App** (Flutter) - Track errors in the mobile app
2. **Backend API** (Node.js/Express) - Track errors in the API server

This separation helps quickly identify which part of your application errors are coming from.

---

## 🚀 Step 1: Create Sentry Projects

### Option A: Using Sentry Web Dashboard

1. **Go to Sentry**: https://sentry.io/signup/ (or login if you have an account)

2. **Create Mobile Project**:
   - Click "Create Project"
   - **Platform**: Select **"Flutter"**
   - **Project Name**: `stakk-mobile` (or `stakk-flutter`)
   - **Team**: Select your team (or create one)
   - Click "Create Project"
   - **Copy the DSN** (looks like: `https://xxxxx@xxxxx.ingest.sentry.io/xxxxx`)

3. **Create Backend Project**:
   - Click "Create Project" again
   - **Platform**: Select **"Node.js"** or **"Express"**
   - **Project Name**: `stakk-backend` (or `stakk-api`)
   - **Team**: Same team
   - Click "Create Project"
   - **Copy the DSN**

### Option B: Using Sentry CLI (Advanced)

```bash
# Install Sentry CLI
npm install -g @sentry/cli

# Login
sentry-cli login

# Create mobile project
sentry-cli projects create stakk-mobile --platform flutter --team YOUR_TEAM

# Create backend project
sentry-cli projects create stakk-backend --platform node --team YOUR_TEAM
```

---

## 📱 Step 2: Configure Mobile App (Flutter)

### 2.1 Install Sentry Package

Add to `mobile/pubspec.yaml`:

```yaml
dependencies:
  sentry_flutter: ^8.0.0
```

Then run:
```bash
cd mobile
flutter pub get
```

### 2.2 Update Error Tracking Service

Edit `mobile/lib/services/error_tracking_service.dart`:

**Find this section** (around line 20-30):
```dart
if (kDebugMode) {
  debugPrint('Error tracking initialized (debug mode - logging only)');
} else {
  // Production: Initialize Sentry or Firebase Crashlytics
  // Uncomment and configure when ready:
  // await SentryFlutter.init(
  //   (options) {
  //     options.dsn = 'YOUR_SENTRY_DSN';
  //     options.environment = kReleaseMode ? 'production' : 'staging';
  //   },
  //   appRunner: () => runApp(const StakkApp()),
  // );
  debugPrint('Error tracking ready (configure Sentry/Crashlytics for production)');
}
```

**Replace with**:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

if (kDebugMode) {
  debugPrint('Error tracking initialized (debug mode - logging only)');
} else {
  // Production: Initialize Sentry
  final sentryDsn = const String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = kReleaseMode ? 'production' : 'staging';
        options.tracesSampleRate = 0.2; // 20% of transactions
        options.beforeSend = (event, {hint}) {
          // Filter out sensitive data
          if (event.request?.data != null) {
            // Remove sensitive fields
          }
          return event;
        };
      },
    );
    debugPrint('Sentry initialized for production');
  } else {
    debugPrint('Sentry DSN not configured');
  }
}
```

### 2.3 Update main.dart

Edit `mobile/lib/main.dart`:

**Find**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error tracking (wraps app in error boundary)
  await ErrorTrackingService().initialize();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  // ...
  runApp(const StakkApp());
}
```

**Replace with**:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get Sentry DSN from environment or config
  final sentryDsn = const String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  
  // Initialize Sentry if DSN is provided
  if (sentryDsn.isNotEmpty && kReleaseMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.environment = kReleaseMode ? 'production' : 'staging';
        options.tracesSampleRate = 0.2;
      },
      appRunner: () => _runApp(),
    );
  } else {
    // Run app without Sentry (debug mode or DSN not set)
    await ErrorTrackingService().initialize();
    await Firebase.initializeApp();
    await AnalyticsService().initialize();
    await AppVersionService().initialize();
    await OfflineHandler().initialize();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    runApp(const StakkApp());
  }
}

void _runApp() async {
  await ErrorTrackingService().initialize();
  await Firebase.initializeApp();
  await AnalyticsService().initialize();
  await AppVersionService().initialize();
  await OfflineHandler().initialize();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const StakkApp());
}
```

### 2.4 Update Error Tracking Service Methods

Update `captureError` method in `error_tracking_service.dart`:

**Find**:
```dart
} else {
  // Production: Send to Sentry/Crashlytics
  // Sentry.captureException(
  //   error,
  //   stackTrace: stackTrace,
  //   hint: Hint.withMap(context ?? {}),
  // );
}
```

**Replace with**:
```dart
} else {
  // Production: Send to Sentry
  import 'package:sentry_flutter/sentry_flutter.dart';
  
  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    hint: Hint.withMap(context ?? {}),
  );
}
```

Do the same for `captureMessage`, `setUser`, `clearUser`, and `addBreadcrumb`.

### 2.5 Set DSN for Builds

**For iOS/Android builds**, set the DSN as an environment variable:

```bash
# iOS
flutter build ios --dart-define=SENTRY_DSN=YOUR_MOBILE_DSN

# Android
flutter build apk --dart-define=SENTRY_DSN=YOUR_MOBILE_DSN
```

**Or create a config file** (`mobile/lib/config/sentry_config.dart`):

```dart
class SentryConfig {
  static const String dsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '', // Empty in debug, set in production builds
  );
}
```

---

## 🔧 Step 3: Configure Backend (Node.js)

### 3.1 Install Sentry Package

```bash
cd backend
npm install @sentry/node @sentry/profiling-node
```

### 3.2 Create Sentry Configuration

Create `backend/src/config/sentry.ts`:

```typescript
import * as Sentry from '@sentry/node';
import { ProfilingIntegration } from '@sentry/profiling-node';

export function initializeSentry() {
  const dsn = process.env.SENTRY_DSN;
  
  if (!dsn) {
    console.warn('Sentry DSN not configured. Error tracking disabled.');
    return;
  }

  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV || 'development',
    tracesSampleRate: 0.2, // 20% of transactions
    profilesSampleRate: 0.1, // 10% of transactions (if profiling enabled)
    integrations: [
      new ProfilingIntegration(),
    ],
    beforeSend(event, hint) {
      // Filter out sensitive data
      if (event.request?.data) {
        // Remove sensitive fields like passwords, tokens
        const sensitiveFields = ['password', 'token', 'secret', 'apiKey'];
        // ... sanitize event.request.data
      }
      return event;
    },
  });

  console.log('Sentry initialized for backend');
}

export { Sentry };
```

### 3.3 Initialize Sentry in server.ts

Edit `backend/src/server.ts`:

**Add at the top** (before other imports):
```typescript
import { initializeSentry } from './config/sentry.ts';
import * as Sentry from '@sentry/node';

// Initialize Sentry BEFORE anything else
initializeSentry();
```

**Wrap Express app**:
```typescript
// After app creation
app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.tracingHandler());

// ... your routes ...

// Error handler (must be last)
app.use(Sentry.Handlers.errorHandler());

// Optional: Custom error handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  Sentry.captureException(err);
  res.status(500).json({ error: 'Internal server error' });
});
```

### 3.4 Set DSN in Environment

Add to `backend/.env`:

```bash
SENTRY_DSN=https://xxxxx@xxxxx.ingest.sentry.io/xxxxx
```

**For Railway**:
1. Go to your Railway project
2. Add environment variable: `SENTRY_DSN=your_backend_dsn`

---

## 🧪 Step 4: Test Sentry Integration

### Mobile App Test

Add a test button temporarily:

```dart
ElevatedButton(
  onPressed: () {
    throw Exception('Test Sentry error');
  },
  child: Text('Test Sentry'),
)
```

Run the app and click the button. Check Sentry dashboard for the error.

### Backend Test

Add a test route:

```typescript
app.get('/test-sentry', (req, res) => {
  throw new Error('Test Sentry error');
});
```

Visit `/test-sentry` and check Sentry dashboard.

---

## 📊 Step 5: Configure Alerts

### In Sentry Dashboard:

1. **Go to Alerts** → **Create Alert Rule**

2. **Set Alert Conditions**:
   - **When**: "An issue is created"
   - **If**: "The number of events is greater than 10 in 1 minute"
   - **Then**: Send email notification

3. **For High Priority Issues**:
   - **When**: "An issue is created"
   - **If**: "The issue level is fatal or error"
   - **Then**: Send email + Slack/Discord notification

### Recommended Alert Rules:

**Mobile App**:
- Alert on crashes (fatal errors)
- Alert on >50 errors in 5 minutes
- Alert on new error types

**Backend**:
- Alert on 500 errors
- Alert on >100 errors in 5 minutes
- Alert on API endpoint failures

---

## 🔐 Step 6: Security Best Practices

### 1. Filter Sensitive Data

Update `beforeSend` in both mobile and backend to filter:
- Passwords
- API keys
- Tokens
- Credit card numbers
- Personal information

### 2. Use Environment Variables

Never commit DSNs to git. Use environment variables:
- Mobile: `--dart-define=SENTRY_DSN=...`
- Backend: `SENTRY_DSN=...` in `.env`

### 3. Set Release Versions

**Mobile** (`main.dart`):
```dart
options.release = 'stakk-mobile@1.0.0';
```

**Backend** (`sentry.ts`):
```typescript
Sentry.init({
  release: `stakk-backend@${process.env.npm_package_version}`,
  // ...
});
```

---

## 📝 Summary

### Mobile App Setup:
1. ✅ Create Flutter project in Sentry
2. ✅ Install `sentry_flutter` package
3. ✅ Update `error_tracking_service.dart`
4. ✅ Update `main.dart` to initialize Sentry
5. ✅ Set `SENTRY_DSN` in build command

### Backend Setup:
1. ✅ Create Node.js project in Sentry
2. ✅ Install `@sentry/node` package
3. ✅ Create `sentry.ts` config
4. ✅ Initialize in `server.ts`
5. ✅ Set `SENTRY_DSN` in environment

### Next Steps:
- Test error tracking
- Configure alerts
- Set up release tracking
- Monitor errors in Sentry dashboard

---

## 🔗 Resources

- [Sentry Flutter Docs](https://docs.sentry.io/platforms/flutter/)
- [Sentry Node.js Docs](https://docs.sentry.io/platforms/node/)
- [Sentry Alert Rules](https://docs.sentry.io/product/alerts/)

---

**STAKK** - Save in USDC, protected from inflation.
