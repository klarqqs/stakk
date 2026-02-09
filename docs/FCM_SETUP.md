# Firebase Cloud Messaging (FCM) Setup Guide

This guide will help you set up Firebase Cloud Messaging for push notifications in the Stakk Savings app.

## Overview

FCM enables push notifications to be sent to users' devices. The implementation includes:
- Device token registration on login
- Automatic token refresh handling
- Foreground and background message handling
- Push notification delivery when in-app notifications are created
- Token cleanup on logout

## Prerequisites

1. Firebase project already set up (completed in Auth & Identity setup)
2. `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) already added
3. Backend database access

## Step 1: Run Database Migration

Create the `device_tokens` table:

```bash
cd backend
npm run migrate:device-tokens
```

Or manually run:
```bash
ts-node src/migrations/add-device-tokens.ts
```

## Step 2: Install Mobile Dependencies

The following packages have been added to `pubspec.yaml`:
- `firebase_core: ^3.6.0`
- `firebase_messaging: ^15.1.3`

Run:
```bash
cd mobile
flutter pub get
```

## Step 3: Install Backend Dependencies

Install Firebase Admin SDK:

```bash
cd backend
npm install firebase-admin
```

## Step 4: Configure Firebase Admin SDK

### Option A: Using Service Account JSON (Recommended)

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate new private key"
3. Download the JSON file
4. Add to backend `.env`:

```env
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"your-project-id",...}'
```

**Important**: The entire JSON must be on a single line. You can use a tool to minify it, or use Option B.

### Option B: Using Service Account File Path

1. Download the service account JSON file
2. Store it securely (e.g., `backend/config/firebase-service-account.json`)
3. Update `backend/src/services/notification.service.ts`:

```typescript
// Replace the serviceAccount parsing with:
const serviceAccount = require('../config/firebase-service-account.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
```

**Security Note**: Never commit the service account file to git. Add it to `.gitignore`.

## Step 5: iOS Configuration

### Enable Push Notifications Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes" and enable "Remote notifications"

### Update Info.plist

The app should already have APNs configured if you've set up Firebase. Verify:
- `GoogleService-Info.plist` is in `ios/Runner/`
- Firebase is initialized in `main.dart`

## Step 6: Android Configuration

### Update AndroidManifest.xml

Add notification channel and permissions (if not already present):

```xml
<!-- In android/app/src/main/AndroidManifest.xml -->
<manifest>
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
  
  <application>
    <!-- ... existing code ... -->
    
    <!-- FCM default notification channel -->
    <meta-data
      android:name="com.google.firebase.messaging.default_notification_channel_id"
      android:value="stakk_notifications" />
  </application>
</manifest>
```

### Create Notification Channel (Optional)

The app can create a notification channel programmatically. This is handled by `firebase_messaging` package.

## Step 7: Test the Implementation

### 1. Start Backend Server

```bash
cd backend
npm start
```

### 2. Run Mobile App

```bash
cd mobile
flutter run
```

### 3. Login to App

After logging in, check backend logs for:
```
FCM: Token registered successfully
```

### 4. Send Test Notification

You can test by creating a notification in your backend code:

```typescript
import * as notificationService from './services/notification.service.ts';

// This will create an in-app notification AND send FCM push
await notificationService.createNotification(
  userId,
  'test',
  'Test Notification',
  'This is a test push notification'
);
```

## Step 8: Deep Linking (Optional)

To handle notification taps and navigate to specific screens:

1. Update `FCMService._handleMessageOpened()` in `mobile/lib/services/fcm_service.dart`
2. Use `message.data` to determine which screen to navigate to
3. Example:

```dart
void _handleMessageOpened(RemoteMessage message) {
  final data = message.data;
  final type = data['type'];
  
  if (type == 'transaction') {
    // Navigate to transaction details
  } else if (type == 'goal') {
    // Navigate to goal details
  }
  // etc.
}
```

## Troubleshooting

### iOS: "No valid 'aps-environment' entitlement"

- Ensure Push Notifications capability is enabled in Xcode
- Verify provisioning profile includes push notifications
- Rebuild the app

### Android: Notifications not appearing

- Check that `POST_NOTIFICATIONS` permission is granted (Android 13+)
- Verify `google-services.json` is in `android/app/`
- Check notification channel is created

### Backend: "Firebase Admin not configured"

- Verify `FIREBASE_SERVICE_ACCOUNT` is set in `.env`
- Check service account JSON is valid
- Ensure Firebase Admin SDK is installed: `npm install firebase-admin`

### Token Registration Fails

- Check backend logs for errors
- Verify user is authenticated (token registration requires auth)
- Check network connectivity

## Architecture

### Mobile Flow

1. **App Start**: Firebase initialized in `main.dart`
2. **Login/Signup**: `AuthProvider._setUser()` → `FCMService.initialize()`
3. **Token Registration**: FCM token automatically registered with backend
4. **Token Refresh**: Handled automatically by `firebase_messaging`
5. **Foreground Messages**: Handled by `FirebaseMessaging.onMessage`
6. **Background/Terminated**: Handled by `firebaseMessagingBackgroundHandler`
7. **Logout**: `FCMService.deleteToken()` removes token from backend

### Backend Flow

1. **Create Notification**: `notificationService.createNotification()`
2. **Send FCM Push**: Automatically sends to all user's device tokens
3. **Invalid Tokens**: Automatically removed if FCM reports them as invalid
4. **Device Registration**: `POST /notifications/register-device`
5. **Device Deletion**: `POST /notifications/delete-device`

## Next Steps

- [ ] Test push notifications on both iOS and Android
- [ ] Implement deep linking for notification taps
- [ ] Add notification preferences (users can opt-out)
- [ ] Add notification categories/types
- [ ] Implement notification badges/indicators

## Files Modified/Created

### Mobile
- `lib/main.dart` - Firebase initialization
- `lib/services/fcm_service.dart` - FCM service (NEW)
- `lib/providers/auth_provider.dart` - FCM initialization on login
- `lib/api/api_client.dart` - Device token endpoints
- `pubspec.yaml` - Added firebase packages

### Backend
- `src/migrations/add-device-tokens.ts` - Database migration (NEW)
- `src/services/device-token.service.ts` - Device token CRUD (NEW)
- `src/services/notification.service.ts` - FCM push integration
- `src/controllers/notification.controller.ts` - Device token endpoints
- `src/routes/notification.routes.ts` - Device token routes
- `package.json` - Added firebase-admin dependency

## Security Considerations

1. **Service Account**: Keep Firebase service account credentials secure
2. **Token Storage**: Device tokens are stored securely in database
3. **Token Validation**: Invalid tokens are automatically cleaned up
4. **User Privacy**: Users can delete tokens by logging out
