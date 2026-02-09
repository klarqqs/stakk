# Google Sign-In Quick Start Guide

## 🎯 What You Need to Do

### Part 1: Firebase Setup (5 minutes)

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Create/Select Project**: Create "stakk-savings" or select existing
3. **Enable Google Auth**:
   - Authentication → Sign-in method → Google → Enable → Save

### Part 2: iOS Setup (10 minutes)

#### 2.1 Add iOS App to Firebase
1. Firebase Console → "Add app" → iOS
2. Bundle ID: `com.stakk.stakkSavings`
3. Download `GoogleService-Info.plist`
4. **Add to Xcode**: Drag into `Runner` folder, check "Copy items" and "Runner" target

#### 2.2 Configure Info.plist

**Get values from GoogleService-Info.plist:**
- Open `GoogleService-Info.plist` in text editor
- Find `<key>CLIENT_ID</key>` → Copy the `<string>` value
- Find `<key>REVERSED_CLIENT_ID</key>` → Copy the `<string>` value

**In Xcode:**
1. Runner target → **Info** tab
2. Find `GIDClientID` (I've added placeholder)
3. Replace `YOUR-CLIENT-ID-HERE` with **CLIENT_ID** from GoogleService-Info.plist
4. Expand **URL Types** → Click **"+"**
5. **Identifier**: `GoogleSignIn`
6. **URL Schemes**: Paste **REVERSED_CLIENT_ID** from GoogleService-Info.plist

### Part 3: Android Setup (5 minutes)

#### 3.1 Add Android App to Firebase
1. Firebase Console → "Add app" → Android
2. Package name: `com.stakk.stakk_savings` (check your actual value in `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place in: `android/app/google-services.json`

#### 3.2 Update Android Build Files

**Update `android/settings.gradle.kts`:**
Add Google services plugin to plugins block:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false  // Add this
}
```

**Update `android/app/build.gradle.kts`:**
Add plugin at top:

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Add this
}
```

### Part 4: Backend Setup (2 minutes)

1. **Get Web Client ID**:
   - Firebase Console → Authentication → Sign-in method → Google
   - Copy the **Web client ID** (or get from Project Settings → Your Web App)

2. **Add to Backend `.env`**:
   ```env
   GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```

3. **Restart backend server**

---

## ✅ Quick Checklist

### iOS:
- [ ] Firebase project created
- [ ] iOS app added to Firebase
- [ ] `GoogleService-Info.plist` downloaded and added to Xcode
- [ ] `GIDClientID` updated in Info.plist
- [ ] URL Scheme added with REVERSED_CLIENT_ID

### Android:
- [ ] Android app added to Firebase
- [ ] `google-services.json` in `android/app/` directory
- [ ] Google services plugin added to `settings.gradle.kts`
- [ ] Google services plugin added to `app/build.gradle.kts`

### Backend:
- [ ] `GOOGLE_CLIENT_ID` added to `.env` (Web Client ID)
- [ ] Backend server restarted

---

## 🚀 Test

```bash
cd /Users/mac/Desktop/usdc-savings-app/mobile
flutter clean
cd ios && pod install && cd ..
flutter pub get
flutter run
```

Tap "Continue with Google" and it should work! 🎉

---

## 📝 Current Status

- ✅ Backend Google auth controller ready (`/auth/google`)
- ✅ Mobile app Google sign-in code ready
- ⏳ Need: Firebase setup + configuration files

---

## 🆘 Common Issues

**iOS: "No active configuration"**
- Fix: Ensure `GIDClientID` is set correctly in Info.plist

**Android: "Default FirebaseApp not initialized"**
- Fix: Ensure `google-services.json` is in `android/app/`
- Fix: Ensure plugins are added correctly

**Backend: "GOOGLE_CLIENT_ID not configured"**
- Fix: Add to `.env` and restart server
