# Firebase Setup Guide for Google/Apple Sign-In

## Overview

This guide covers setting up Firebase for Google Sign-In and Apple Sign-In in the Stakk mobile app.

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or select existing project
3. Enter project name: `stakk-savings` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Click **"Create project"**

---

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click **"Add app"** → iOS icon
2. **Bundle ID**: Get from Xcode → Runner target → General tab → Bundle Identifier
   - Example: `com.yourcompany.stakk` or `ng.com.stakk.savings`
3. **App nickname**: `Stakk iOS` (optional)
4. **App Store ID**: Leave blank for now
5. Click **"Register app"**
6. Download `GoogleService-Info.plist`
7. **Add to Xcode**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into `Runner` folder (make sure "Copy items if needed" is checked)
   - Ensure it's added to the Runner target

---

## Step 3: Add Android App to Firebase

1. In Firebase Console, click **"Add app"** → Android icon
2. **Package name**: Get from `android/app/build.gradle.kts` → `applicationId`
   - Example: `com.yourcompany.stakk` or `ng.com.stakk.savings`
3. **App nickname**: `Stakk Android` (optional)
4. **Debug signing certificate SHA-1** (optional for now)
5. Click **"Register app"**
6. Download `google-services.json`
7. **Add to Android project**:
   - Place `google-services.json` in `android/app/`
   - Ensure `android/build.gradle.kts` has Google services plugin (see below)

---

## Step 4: Configure Google Sign-In

### iOS Configuration

1. **In Firebase Console**:
   - Go to Authentication → Sign-in method
   - Enable **Google** sign-in
   - Add iOS bundle ID if prompted

2. **In Xcode**:
   - Open `ios/Runner.xcworkspace`
   - Select Runner target → **Signing & Capabilities**
   - Add **"Sign in with Apple"** capability (if not already added)
   - Ensure **Bundle Identifier** matches Firebase

3. **Add URL Scheme** (for Google Sign-In redirect):
   - In Xcode: Runner target → Info tab → URL Types
   - Add URL Type:
     - Identifier: `GoogleSignIn`
     - URL Schemes: `com.googleusercontent.apps.YOUR-CLIENT-ID` (get from GoogleService-Info.plist → `REVERSED_CLIENT_ID`)

### Android Configuration

1. **In Firebase Console**:
   - Go to Authentication → Sign-in method
   - Enable **Google** sign-in
   - Add Android package name if prompted

2. **Update `android/build.gradle.kts`**:
   ```kotlin
   buildscript {
       dependencies {
           classpath("com.google.gms:google-services:4.4.0")
       }
   }
   ```

3. **Update `android/app/build.gradle.kts`**:
   ```kotlin
   plugins {
       id("com.android.application")
       id("com.google.gms.google-services")  // Add this
   }
   ```

---

## Step 5: Configure Apple Sign-In

### iOS Only (Apple Sign-In)

1. **Apple Developer Account**:
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Certificates, Identifiers & Profiles → Identifiers
   - Select your App ID → Enable **"Sign in with Apple"** capability
   - Save changes

2. **In Xcode**:
   - Runner target → Signing & Capabilities
   - Add **"Sign in with Apple"** capability (if not already added)

3. **In Firebase Console**:
   - Authentication → Sign-in method → Apple
   - Enable Apple sign-in
   - Add your Apple App ID (Bundle Identifier)

---

## Step 6: Get OAuth Client IDs

### For Google Sign-In

1. **Firebase Console** → Authentication → Sign-in method → Google
2. Copy the **Web client ID** (not iOS/Android client IDs)
3. This will be used in your backend `.env`:
   ```
   GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```

### For Apple Sign-In

1. **Apple Developer Portal** → Certificates, Identifiers & Profiles
2. Create a **Services ID** (if needed for web)
3. For mobile, the Bundle ID is sufficient

---

## Step 7: Update Flutter Dependencies

Already added in `pubspec.yaml`:
- `google_sign_in: ^6.2.2`
- `sign_in_with_apple: ^6.1.3`

Run:
```bash
flutter pub get
```

---

## Step 8: Configure Google Sign-In in Flutter (iOS)

1. **Get iOS Client ID**:
   - Open `ios/Runner/GoogleService-Info.plist`
   - Find `CLIENT_ID` value
   - Example: `123456789-abc.apps.googleusercontent.com`

2. **Update `ios/Runner/Info.plist`**:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleTypeRole</key>
           <string>Editor</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
           </array>
       </dict>
   </array>
   ```
   Replace `YOUR-CLIENT-ID` with the reversed client ID from `GoogleService-Info.plist` → `REVERSED_CLIENT_ID`

---

## Step 9: Test Setup

### Test Google Sign-In

1. Run app on device/simulator
2. Tap "Continue with Google"
3. Should open Google sign-in flow
4. After sign-in, should route to passcode/create-passcode

### Test Apple Sign-In

1. Run app on **physical iOS device** (simulator may not work)
2. Tap "Continue with Apple"
3. Should open Apple sign-in flow
4. After sign-in, should route to passcode/create-passcode

---

## Troubleshooting

### Google Sign-In Issues

- **"Sign in failed"**: Check that `REVERSED_CLIENT_ID` URL scheme is correct in Info.plist
- **"Invalid client"**: Verify Web client ID in backend matches Firebase
- **iOS redirect fails**: Ensure URL scheme matches `REVERSED_CLIENT_ID` exactly

### Apple Sign-In Issues

- **"Not available"**: Must test on physical device, not simulator
- **"Invalid client"**: Verify Bundle ID matches Apple Developer Portal
- **Capability missing**: Add "Sign in with Apple" in Xcode → Signing & Capabilities

### Firebase Issues

- **`GoogleService-Info.plist` not found**: Ensure file is in `ios/Runner/` and added to target
- **`google-services.json` not found**: Ensure file is in `android/app/`
- **Build errors**: Run `flutter clean` then `flutter pub get`

---

## Environment Variables (Backend)

Add to your backend `.env`:

```env
# Google OAuth (from Firebase Console → Authentication → Google → Web client ID)
GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com

# Apple (optional, if using Apple web flow)
APPLE_CLIENT_ID=your.app.bundle.id
```

---

## Next Steps

After Firebase setup:
1. Test Google sign-in on iOS and Android
2. Test Apple sign-in on iOS device
3. Verify backend receives tokens correctly
4. Ensure passcode flow works after social sign-in
