# Sentry Configuration Complete ✅

Both backend and mobile app are now configured with your Sentry DSNs.

## 📋 DSNs Configured

### Backend (Express)
- **DSN**: `https://37d9314029b683d8af1d50295cfab8a6@o4510855989297152.ingest.de.sentry.io/4510856008106064`
- **Status**: ✅ Configured in `backend/src/config/sentry.ts`
- **Fallback**: Uses default DSN if `SENTRY_DSN` env var not set

### Mobile App (Flutter)
- **DSN**: `https://2225e6ac042734539c8b3f688eb9c3a6@o4510855989297152.ingest.de.sentry.io/4510856011907152`
- **Status**: ✅ Configured in `mobile/lib/config/sentry_config.dart`
- **Fallback**: Uses default DSN if `--dart-define=SENTRY_DSN` not provided

---

## 🚀 Next Steps

### 1. Install Mobile Package

```bash
cd mobile
flutter pub get
```

### 2. Install Backend Packages

```bash
cd backend
npm install
```

### 3. Test Error Tracking

#### Backend Test

Add this test route temporarily to `backend/src/server.ts`:

```typescript
app.get('/test-sentry', (req, res) => {
  throw new Error('Test Sentry error from backend');
});
```

Visit `http://localhost:3001/test-sentry` and check Sentry dashboard.

#### Mobile Test

Add this button temporarily to any screen:

```dart
ElevatedButton(
  onPressed: () {
    throw StateError('Test Sentry error from mobile');
  },
  child: const Text('Test Sentry'),
)
```

Tap the button and check Sentry dashboard.

---

## 📊 View Errors

1. Go to https://sentry.io
2. Select your project:
   - **Backend**: `stakk-backend` (or your project name)
   - **Mobile**: `stakk-mobile` (or your project name)
3. View errors in the **Issues** tab

---

## 🔧 Environment Variables (Optional)

### Backend

You can override the DSN via environment variable:

```bash
# Railway or .env
SENTRY_DSN=https://your-custom-dsn@sentry.io/project-id
SENTRY_RELEASE=stakk-backend@1.0.0
```

### Mobile

You can override the DSN when building:

```bash
flutter build apk --dart-define=SENTRY_DSN=your-custom-dsn
```

**Note**: The default DSNs are already configured, so this is optional unless you want to use different DSNs for different environments.

---

## ✅ What's Configured

### Backend (`backend/src/config/sentry.ts`)
- ✅ Sentry initialization
- ✅ Error handler middleware
- ✅ Request tracing
- ✅ Sensitive data filtering
- ✅ Environment detection

### Mobile (`mobile/lib/services/error_tracking_service.dart`)
- ✅ Sentry initialization
- ✅ Error capture
- ✅ Message capture
- ✅ User context tracking
- ✅ Breadcrumb logging
- ✅ Sensitive data filtering

### Integration Points
- ✅ `backend/src/server.ts` - Sentry handlers added
- ✅ `mobile/lib/main.dart` - Error boundary configured
- ✅ `mobile/lib/providers/auth_provider.dart` - User context set on login

---

## 🧪 Verify Setup

### Check Backend Logs

When you start the backend, you should see:

```
✅ Sentry initialized for backend (development)
```

### Check Mobile Logs

When you run the mobile app in release mode, you should see:

```
✅ Sentry initialized for production
```

---

## 🔔 Set Up Alerts (Recommended)

1. Go to Sentry → **Alerts** → **Create Alert Rule**
2. **When**: "An issue is created"
3. **If**: "The number of events is greater than 10 in 1 minute"
4. **Then**: Send email notification

---

## 📝 Files Modified

### Backend
- ✅ `src/config/sentry.ts` - Sentry configuration with DSN
- ✅ `src/server.ts` - Sentry handlers integrated
- ✅ `package.json` - Sentry packages added
- ✅ `.env.example` - Sentry config documented

### Mobile
- ✅ `lib/config/sentry_config.dart` - Sentry DSN configuration
- ✅ `lib/services/error_tracking_service.dart` - Sentry integration
- ✅ `pubspec.yaml` - `sentry_flutter` package added
- ✅ `lib/main.dart` - Error boundary configured

---

## 🎉 You're All Set!

Sentry is now fully configured and will automatically track errors in both your backend and mobile app. Errors will appear in your Sentry dashboard within seconds of occurring.

---

**STAKK** - Save in USDC, protected from inflation.
