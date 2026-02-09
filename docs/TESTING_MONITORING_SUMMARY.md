# Testing & Monitoring - Implementation Summary

## ✅ Completed

### 1. Error Tracking Service
- **File**: `lib/services/error_tracking_service.dart`
- Centralized error capture with Sentry/Crashlytics integration ready
- User context tracking
- Breadcrumb logging
- Integrated into `main.dart` and `api_client.dart`

### 2. Analytics Service
- **File**: `lib/services/analytics_service.dart`
- Firebase Analytics integration ready
- Predefined events (signup, login, transactions, etc.)
- Screen view tracking
- Integrated into `auth_provider.dart` for key user actions

### 3. App Version Service
- **File**: `lib/services/app_version_service.dart`
- Version checking from backend
- Force update detection
- App store URL management
- Integrated into `dashboard_shell.dart`

### 4. Offline Handler
- **File**: `lib/core/utils/offline_handler.dart`
- Connectivity monitoring
- User-friendly network error messages
- Integrated into `api_client.dart`

### 5. Force Update Dialog
- **File**: `lib/widgets/force_update_dialog.dart`
- Non-dismissible update prompt
- App store link integration

### 6. Smoke Tests
- **File**: `test/smoke_tests.dart`
- Basic app initialization test
- Test structure for full flows

### 7. Backend Version Check Endpoint
- **File**: `backend/src/routes/app.routes.ts`
- `/api/app/version-check` endpoint
- Configurable via environment variables

## 📦 Dependencies Added

```yaml
firebase_analytics: ^11.3.3
package_info_plus: ^8.1.1
```

## 🔧 Configuration Required

### 1. Firebase Analytics
- Already enabled in Firebase Console
- Will start collecting automatically once app is deployed

### 2. Error Tracking (Sentry - Optional)
1. Sign up at https://sentry.io
2. Create Flutter project
3. Get DSN
4. Update `error_tracking_service.dart` with DSN
5. Uncomment Sentry initialization code

### 3. Force Update Backend Config
Add to Railway `.env`:
```bash
MINIMUM_APP_VERSION=1.0.0
LATEST_APP_VERSION=1.0.1
FORCE_APP_UPDATE=false
IOS_APP_STORE_URL=https://apps.apple.com/app/stakk/id123456789
ANDROID_PLAY_STORE_URL=https://play.google.com/store/apps/details?id=com.stakk.stakkSavings
```

## 📊 Analytics Events Tracked

- `sign_up` - User signs up (method: email/google/apple)
- `login` - User logs in (method: email/google/apple)
- `wallet_funded` - Wallet funding
- `p2p_transfer` - P2P transfer
- `bill_payment` - Bill payment
- `goal_created` - Savings goal created
- `goal_achieved` - Goal achieved
- `withdrawal` - Withdrawal
- `error_occurred` - Error tracked

## 🧪 Testing Checklist

### Manual Testing
- [ ] App initializes without crashing
- [ ] Session expiry triggers logout
- [ ] Offline banner displays when no internet
- [ ] Network errors show user-friendly messages
- [ ] Force update dialog shows when required
- [ ] Analytics events logged (check Firebase Console)

### Automated Tests
```bash
flutter test test/smoke_tests.dart
```

## 📝 Next Steps

1. **Enable Sentry** (optional but recommended):
   - Sign up and configure DSN
   - Uncomment Sentry code in `error_tracking_service.dart`

2. **Update App Store URLs**:
   - Update URLs in backend `.env` when app is published
   - Update default URLs in `app_version_service.dart`

3. **Monitor Analytics**:
   - Check Firebase Console for event tracking
   - Set up custom dashboards

4. **Test Force Update**:
   - Set `FORCE_APP_UPDATE=true` in backend
   - Set `MINIMUM_APP_VERSION` higher than current
   - Verify dialog appears and cannot be dismissed

---

**STAKK** - Save in USDC, protected from inflation.
