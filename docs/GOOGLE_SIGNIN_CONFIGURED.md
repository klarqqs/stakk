# Google Sign-In Configuration Complete ✅

## Files Added

- ✅ `ios/Runner/GoogleService-Info.plist` - iOS configuration
- ✅ `android/app/google-services.json` - Android configuration

## iOS Configuration

- ✅ `GIDClientID` added to Info.plist: `126969602302-c1gh1rjlkrnrknnlcu47ktil2ftrs015.apps.googleusercontent.com`
- ✅ URL Scheme added: `com.googleusercontent.apps.126969602302-c1gh1rjlkrnrknnlcu47ktil2ftrs015`

## Android Configuration

- ✅ `google-services.json` placed in `android/app/`
- ✅ Google services plugin added to `settings.gradle.kts`
- ✅ Google services plugin added to `app/build.gradle.kts`

## Next Steps

### 1. Add GoogleService-Info.plist to Xcode Project

**Important**: The file is in the filesystem but needs to be added to Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Right-click `Runner` folder → "Add Files to Runner..."
3. Select `GoogleService-Info.plist`
4. Ensure "Copy items if needed" is checked
5. Ensure "Runner" target is checked
6. Click "Add"

### 2. Get Web Client ID for Backend

**In Firebase Console:**
1. Go to **Authentication** → **Sign-in method** → **Google**
2. Copy the **Web client ID** (looks like: `126969602302-xxxxx.apps.googleusercontent.com`)
3. Add to backend `.env`:
   ```env
   GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```
4. Restart backend server

### 3. Clean Build and Test

```bash
cd /Users/mac/Desktop/usdc-savings-app/mobile
flutter clean
cd ios && pod install && cd ..
flutter pub get
flutter run
```

## Testing

1. Tap "Continue with Google" on onboarding or check email screen
2. Should open Google sign-in flow
3. After sign-in, should route to dashboard or passcode creation

## Troubleshooting

**iOS: "No active configuration"**
- Ensure `GoogleService-Info.plist` is added to Xcode project (not just filesystem)
- Verify `GIDClientID` in Info.plist matches CLIENT_ID from GoogleService-Info.plist

**Android: Build errors**
- Run `cd android && ./gradlew clean` then rebuild
- Verify `google-services.json` is in `android/app/` directory

**Backend: "GOOGLE_CLIENT_ID not configured"**
- Add Web Client ID to `.env` file
- Restart backend server
