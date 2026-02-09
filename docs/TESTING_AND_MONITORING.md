# Testing & Monitoring Guide - STAKK

Complete guide for testing, error tracking, analytics, and app version management.

## ✅ Completed

### 1. Error Tracking Service ✅
- **File**: `lib/services/error_tracking_service.dart`
- **Features**:
  - Centralized error capture
  - User context tracking
  - Breadcrumb logging
  - Ready for Sentry/Crashlytics integration
  - Debug mode logging

### 2. Analytics Service ✅
- **File**: `lib/services/analytics_service.dart`
- **Features**:
  - Event tracking
  - Screen view tracking
  - User property management
  - Predefined events (signup, login, transactions, etc.)
  - Ready for Firebase Analytics integration

### 3. App Version Service ✅
- **File**: `lib/services/app_version_service.dart`
- **Features**:
  - Version checking
  - Force update detection
  - App store URL management
  - Version comparison logic

### 4. Offline Handler ✅
- **File**: `lib/core/utils/offline_handler.dart`
- **Features**:
  - Connectivity monitoring
  - User-friendly error messages
  - Network error detection

### 5. Force Update Dialog ✅
- **File**: `lib/widgets/force_update_dialog.dart`
- **Features**:
  - Non-dismissible update prompt
  - App store link integration
  - Version display

### 6. Enhanced API Client ✅
- **Updated**: `lib/api/api_client.dart`
- **Features**:
  - Offline detection before requests
  - Error tracking integration
  - User-friendly network error messages

### 7. Smoke Tests ✅
- **File**: `test/smoke_tests.dart`
- **Features**:
  - Basic app initialization test
  - Onboarding display test
  - Test structure for full flows

### 8. Backend Version Check Endpoint ✅
- **File**: `backend/src/routes/app.routes.ts`
- **Features**:
  - `/api/app/version-check` endpoint
  - Returns minimum version and force update flag
  - Configurable via environment variables

## 🔧 Configuration

### Error Tracking Setup (Sentry)

#### Option 1: Sentry (Recommended)

1. **Install package**:
```yaml
# Add to pubspec.yaml
dependencies:
  sentry_flutter: ^8.0.0
```

2. **Get Sentry DSN**:
   - Sign up at https://sentry.io
   - Create a project
   - Copy your DSN

3. **Update `error_tracking_service.dart`**:
```dart
import 'package:sentry_flutter/sentry_flutter.dart';

// In initialize():
await SentryFlutter.init(
  (options) {
    options.dsn = 'YOUR_SENTRY_DSN';
    options.environment = kReleaseMode ? 'production' : 'staging';
    options.tracesSampleRate = 0.2; // 20% of transactions
  },
);
```

4. **Wrap app in main.dart**:
```dart
await SentryFlutter.init(
  (options) { /* config */ },
  appRunner: () => runApp(const StakkApp()),
);
```

#### Option 2: Firebase Crashlytics

1. **Install package**:
```yaml
dependencies:
  firebase_crashlytics: ^4.0.0
```

2. **Update `error_tracking_service.dart`**:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// In captureError():
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'Error in $context',
);
```

### Analytics Setup (Firebase Analytics)

1. **Enable in Firebase Console**:
   - Go to Firebase Console → Analytics
   - Enable Google Analytics (if not already enabled)

2. **Update `analytics_service.dart`**:
```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final _analytics = FirebaseAnalytics.instance;

// In logEvent():
await _analytics.logEvent(
  name: name,
  parameters: parameters,
);
```

3. **Track screen views automatically**:
```dart
// Add to route observers in MaterialApp
navigatorObservers: [
  FirebaseAnalyticsObserver(analytics: _analytics),
],
```

### Force Update Configuration

#### Backend Environment Variables

Add to Railway/production `.env`:
```bash
# App Version Management
MINIMUM_APP_VERSION=1.0.0
LATEST_APP_VERSION=1.0.1
FORCE_APP_UPDATE=false  # Set to true to force updates

# App Store URLs
IOS_APP_STORE_URL=https://apps.apple.com/app/stakk/id123456789
ANDROID_PLAY_STORE_URL=https://play.google.com/store/apps/details?id=com.stakk.stakkSavings
```

#### How It Works

1. App checks `/api/app/version-check` on startup
2. Compares current version with minimum version
3. Shows `ForceUpdateDialog` if update required
4. User must update to continue using app

## 📊 Analytics Events

### Predefined Events

The `AnalyticsService` includes these events:

**Authentication**:
- `sign_up` - User signs up (method: email/google/apple)
- `login` - User logs in (method: email/google/apple)

**Transactions**:
- `wallet_funded` - Wallet funding (amount, method)
- `p2p_transfer` - P2P transfer (amount)
- `bill_payment` - Bill payment (category, amount)
- `withdrawal` - Withdrawal (amount, type)

**Savings**:
- `goal_created` - Savings goal created (target_amount)
- `goal_achieved` - Goal achieved (amount)

**Errors**:
- `error_occurred` - Error tracked (error, screen, context)

### Custom Events

Track custom events:
```dart
AnalyticsService().logEvent(
  'custom_event_name',
  parameters: {
    'param1': 'value1',
    'param2': 123,
  },
);
```

### Screen Views

Track screen navigation:
```dart
AnalyticsService().logScreenView('home_screen');
```

## 🧪 Testing

### Smoke Tests

Run smoke tests:
```bash
flutter test test/smoke_tests.dart
```

### Manual Testing Checklist

#### Signup Flow
- [ ] Enter email → OTP sent
- [ ] Verify OTP → Profile creation
- [ ] Create passcode → Dashboard loads
- [ ] Analytics: `sign_up` event logged

#### Login Flow
- [ ] Enter credentials → Dashboard loads
- [ ] Analytics: `login` event logged
- [ ] Error tracking: User context set

#### Session Expiry
- [ ] Trigger 401/403 response
- [ ] User logged out automatically
- [ ] Navigated to login screen
- [ ] Error tracking: Session expiry logged

#### Offline Behavior
- [ ] Turn off internet
- [ ] Make API request
- [ ] See offline banner
- [ ] Get user-friendly error message
- [ ] Retry works when online

#### Force Update
- [ ] Set `FORCE_APP_UPDATE=true` in backend
- [ ] Set `MINIMUM_APP_VERSION` higher than current
- [ ] App shows update dialog
- [ ] Dialog cannot be dismissed
- [ ] App store link works

## 📈 Monitoring Dashboard

### Key Metrics to Track

**User Acquisition**:
- Signups by method (email/google/apple)
- Signup completion rate
- Onboarding completion

**Engagement**:
- Daily/Monthly Active Users (DAU/MAU)
- Screen views
- Feature usage

**Transactions**:
- Wallet funding volume
- P2P transfer volume
- Bill payment volume
- Withdrawal volume

**Errors**:
- Error rate
- Crash rate
- Most common errors
- Error by screen

**Performance**:
- API response times
- App startup time
- Screen load times

## 🔍 Error Tracking Best Practices

### When to Track Errors

1. **Always track**:
   - Unhandled exceptions
   - API errors (non-200 responses)
   - Authentication failures
   - Payment processing errors

2. **Track with context**:
   - User ID
   - Screen/feature
   - User actions leading to error
   - Device/platform info

3. **Don't track**:
   - Expected errors (e.g., validation failures)
   - User cancellations
   - Network timeouts (track as events, not errors)

### Example Error Tracking

```dart
try {
  await performAction();
} catch (e, stackTrace) {
  ErrorTrackingService().captureError(
    e,
    stackTrace: stackTrace,
    context: {
      'action': 'performAction',
      'screen': 'home_screen',
      'user_id': user.id.toString(),
    },
  );
  // Show user-friendly error
}
```

## 🚀 Production Checklist

### Error Tracking
- [ ] Sentry/Crashlytics configured
- [ ] DSN/API key set in environment
- [ ] Error tracking initialized in `main.dart`
- [ ] User context set on login
- [ ] User context cleared on logout

### Analytics
- [ ] Firebase Analytics enabled
- [ ] Analytics initialized in `main.dart`
- [ ] Screen views tracked
- [ ] Key events tracked
- [ ] User properties set

### Force Update
- [ ] Backend endpoint configured
- [ ] Environment variables set
- [ ] App store URLs configured
- [ ] Version check tested
- [ ] Update dialog tested

### Offline Handling
- [ ] Connectivity monitoring active
- [ ] Offline banner displays
- [ ] User-friendly error messages
- [ ] Retry logic works

## 📝 Files Created/Modified

### New Files
- `lib/services/error_tracking_service.dart`
- `lib/services/analytics_service.dart`
- `lib/services/app_version_service.dart`
- `lib/core/utils/offline_handler.dart`
- `lib/widgets/force_update_dialog.dart`
- `test/smoke_tests.dart`
- `backend/src/routes/app.routes.ts`

### Modified Files
- `lib/main.dart` - Added error tracking, analytics, version check initialization
- `lib/api/api_client.dart` - Added offline detection and error tracking
- `lib/providers/auth_provider.dart` - Added analytics and error tracking
- `lib/features/dashboard/presentation/screens/dashboard_shell.dart` - Added force update check
- `pubspec.yaml` - Added `firebase_analytics` and `package_info_plus`

## 🔗 Integration Steps

### 1. Enable Firebase Analytics

1. Go to Firebase Console
2. Enable Google Analytics (if not already)
3. Analytics will start collecting automatically

### 2. Set Up Sentry (Optional but Recommended)

1. Create account at https://sentry.io
2. Create Flutter project
3. Get DSN
4. Update `error_tracking_service.dart` with DSN
5. Uncomment Sentry initialization code

### 3. Configure Force Update

1. Set environment variables in Railway:
   ```bash
   MINIMUM_APP_VERSION=1.0.0
   FORCE_APP_UPDATE=false
   ```
2. Update when you release new version
3. Set `FORCE_APP_UPDATE=true` for critical updates

## 📊 Monitoring Queries

### Firebase Analytics

**User Acquisition**:
- Signups by method
- Signup completion funnel
- Onboarding completion rate

**Engagement**:
- Daily active users
- Screen views
- Session duration

**Transactions**:
- Wallet funding events
- P2P transfer events
- Bill payment events

### Sentry/Crashlytics

**Error Rate**:
- Errors per day
- Error rate by screen
- Most common errors

**Performance**:
- Slow API calls
- App crashes
- ANR (Android)

---

**STAKK** - Save in USDC, protected from inflation.
