# Google Sign-In Setup Guide

## Overview

This guide will help you set up Google Sign-In for both iOS and Android. The backend is already configured - we just need to set up Firebase and configure the mobile apps.

---

## Step 1: Firebase Project Setup

### 1.1 Create/Select Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or select existing project
3. Enter project name: `stakk-savings` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Click **"Create project"**

### 1.2 Enable Google Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Google**
3. Toggle **Enable** switch
4. Enter **Project support email** (your email)
5. Click **Save**

---

## Step 2: Add iOS App to Firebase

### 2.1 Register iOS App

1. In Firebase Console, click **"Add app"** → **iOS** icon
2. **Bundle ID**: `com.stakk.stakkSavings` (matches your Xcode Bundle Identifier)
3. **App nickname**: `Stakk iOS` (optional)
4. **App Store ID**: Leave blank for now
5. Click **"Register app"**

### 2.2 Download GoogleService-Info.plist

1. Download the `GoogleService-Info.plist` file
2. **Add to Xcode**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into the `Runner` folder (left sidebar)
   - **Important**: Check "Copy items if needed"
   - **Important**: Ensure "Runner" target is checked
   - Click **"Finish"**

### 2.3 Get Required Values

Open `GoogleService-Info.plist` in a text editor and find:

1. **CLIENT_ID**: 
   - Key: `<key>CLIENT_ID</key>`
   - Value: Looks like `123456789-abc.apps.googleusercontent.com`
   - **This goes in Info.plist as GIDClientID**

2. **REVERSED_CLIENT_ID**:
   - Key: `<key>REVERSED_CLIENT_ID</key>`
   - Value: Looks like `com.googleusercontent.apps.123456789-abc`
   - **This goes in Info.plist as URL Scheme**

---

## Step 3: Configure iOS Info.plist

### 3.1 Add GIDClientID

**In Xcode:**
1. Select **Runner** target → **Info** tab
2. Expand **"Custom iOS Target Properties"**
3. Right-click → **"Add Row"**
4. Key: `GIDClientID` (or search for it)
5. Type: `String`
6. Value: Paste the **CLIENT_ID** from `GoogleService-Info.plist`

**OR manually edit Info.plist:**
- Find the placeholder: `<string>YOUR-CLIENT-ID-HERE</string>`
- Replace with actual CLIENT_ID from `GoogleService-Info.plist`

### 3.2 Add URL Scheme

**In Xcode:**
1. Still in **Info** tab → Expand **"URL Types"**
2. Click **"+"** to add a new URL Type
3. Set:
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: Paste the **REVERSED_CLIENT_ID** from `GoogleService-Info.plist`
     - Example: `com.googleusercontent.apps.123456789-abc`

**OR manually edit Info.plist:**
Add before `</dict>`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>REVERSED_CLIENT_ID_FROM_GOOGLESERVICE-INFO.PLIST</string>
        </array>
    </dict>
</array>
```

---

## Step 4: Add Android App to Firebase

### 4.1 Register Android App

1. In Firebase Console, click **"Add app"** → **Android** icon
2. **Package name**: Get from `android/app/build.gradle.kts` → `applicationId`
   - Should be: `com.stakk.stakkSavings` (or check your actual value)
3. **App nickname**: `Stakk Android` (optional)
4. **Debug signing certificate SHA-1**: Optional for now
5. Click **"Register app"**

### 4.2 Download google-services.json

1. Download the `google-services.json` file
2. **Add to Android project**:
   - Place `google-services.json` in `android/app/` directory
   - Ensure it's at: `android/app/google-services.json`

### 4.3 Configure Android Build Files

**Update `android/build.gradle.kts`:**

Find the `buildscript` section and add Google services classpath:

```kotlin
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("com.google.gms:google-services:4.4.0")  // Add this line
    }
}
```

**Update `android/app/build.gradle.kts`:**

At the top, add the plugin:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this line
}
```

---

## Step 5: Backend Configuration

### 5.1 Get Web Client ID from Firebase

1. In Firebase Console → **Authentication** → **Sign-in method** → **Google**
2. Click on **Web client ID** (or get it from Firebase Console → Project Settings → Your Web App)
3. Copy the Client ID (looks like: `123456789-abc.apps.googleusercontent.com`)

### 5.2 Add to Backend .env

Add to your backend `.env` file:

```env
GOOGLE_CLIENT_ID=your-web-client-id-from-firebase.apps.googleusercontent.com
```

**Important**: This should be the **Web Client ID**, not the iOS Client ID.

---

## Step 6: Verify Setup

### iOS Checklist:
- [ ] Firebase project created
- [ ] iOS app added to Firebase
- [ ] `GoogleService-Info.plist` downloaded and added to Xcode Runner folder
- [ ] `GIDClientID` added to Info.plist with CLIENT_ID value
- [ ] URL Scheme added with REVERSED_CLIENT_ID value
- [ ] Google Sign-In enabled in Firebase Authentication

### Android Checklist:
- [ ] Android app added to Firebase
- [ ] `google-services.json` placed in `android/app/` directory
- [ ] Google services plugin added to `android/build.gradle.kts`
- [ ] Google services plugin added to `android/app/build.gradle.kts`

### Backend Checklist:
- [ ] `GOOGLE_CLIENT_ID` added to `.env` file (Web Client ID)

---

## Step 7: Clean Build and Test

### iOS:
```bash
cd /Users/mac/Desktop/usdc-savings-app/mobile
flutter clean
cd ios && pod install && cd ..
flutter run
```

### Android:
```bash
cd /Users/mac/Desktop/usdc-savings-app/mobile
flutter clean
flutter pub get
flutter run
```

---

## Troubleshooting

### iOS Error: "No active configuration. Make sure GIDClientID is set in Info.plist"
- **Fix**: Ensure `GIDClientID` is set in Info.plist with the CLIENT_ID from GoogleService-Info.plist
- **Fix**: Ensure `GoogleService-Info.plist` is added to Xcode and included in Runner target

### iOS Error: Google Sign-In redirect fails
- **Fix**: Ensure URL Scheme is set correctly with REVERSED_CLIENT_ID
- **Fix**: Verify URL Scheme matches exactly (no extra characters)

### Android Error: "Default FirebaseApp is not initialized"
- **Fix**: Ensure `google-services.json` is in `android/app/` directory
- **Fix**: Ensure Google services plugin is added to both build.gradle.kts files

### Backend Error: "GOOGLE_CLIENT_ID not configured"
- **Fix**: Add `GOOGLE_CLIENT_ID` to backend `.env` file
- **Fix**: Ensure it's the Web Client ID, not iOS/Android Client ID
- **Fix**: Restart backend server after adding to .env

---

## Testing

1. **Test on iOS device**:
   - Tap "Continue with Google"
   - Should open Google sign-in flow
   - After sign-in, should route to dashboard or passcode creation

2. **Test on Android device**:
   - Tap "Continue with Google"
   - Should open Google sign-in flow
   - After sign-in, should route to dashboard or passcode creation

3. **Verify backend**:
   - Check backend logs for successful Google authentication
   - Verify user is created/linked in database
   - Verify tokens are returned correctly

---

## Next Steps

After completing setup:
1. Test Google Sign-In on both iOS and Android
2. Verify user accounts are created correctly
3. Test sign-in flow (new user vs existing user)
4. Verify Stellar wallet is created for new users

Good luck! 🚀
