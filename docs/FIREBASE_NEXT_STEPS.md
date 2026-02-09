# Firebase Setup - Next Steps After Enabling Google Sign-In

## ✅ Step 1: Enable Google Sign-In (You're Here)

1. **Toggle "Enable"** switch for Google provider
2. **Click "Save"**
3. **Copy the Web Client ID** (you'll need this for backend)

---

## 📱 Step 2: Add iOS App to Firebase

### 2.1 Register iOS App

1. In Firebase Console, click the **gear icon** (⚙️) next to "Project Overview"
2. Click **"Project settings"**
3. Scroll down to **"Your apps"** section
4. Click **"Add app"** → **iOS** icon (🍎)

### 2.2 iOS App Configuration

Fill in the form:
- **iOS bundle ID**: `com.stakk.stakkSavings`
  - This matches your Xcode Bundle Identifier
- **App nickname** (optional): `Stakk iOS`
- **App Store ID**: Leave blank for now
- Click **"Register app"**

### 2.3 Download GoogleService-Info.plist

1. **Download** the `GoogleService-Info.plist` file
2. **Add to Xcode**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into the `Runner` folder (left sidebar)
   - **Important**: Check "Copy items if needed"
   - **Important**: Ensure "Runner" target is checked
   - Click **"Finish"**

### 2.4 Get Values from GoogleService-Info.plist

Open `GoogleService-Info.plist` in a text editor and find:

1. **CLIENT_ID**: 
   - Key: `<key>CLIENT_ID</key>`
   - Value: `123456789-abc.apps.googleusercontent.com`
   - **Use this for Info.plist → GIDClientID**

2. **REVERSED_CLIENT_ID**:
   - Key: `<key>REVERSED_CLIENT_ID</key>`
   - Value: `com.googleusercontent.apps.123456789-abc`
   - **Use this for Info.plist → URL Scheme**

---

## 🤖 Step 3: Add Android App to Firebase

### 3.1 Register Android App

1. Still in **Project settings** → **"Your apps"** section
2. Click **"Add app"** → **Android** icon (🤖)

### 3.2 Android App Configuration

Fill in the form:
- **Android package name**: `com.stakk.stakk_savings`
  - Check your actual value in `android/app/build.gradle.kts` → `applicationId`
- **App nickname** (optional): `Stakk Android`
- **Debug signing certificate SHA-1**: Leave blank for now (can add later)
- Click **"Register app"**

### 3.3 Download google-services.json

1. **Download** the `google-services.json` file
2. **Place in Android project**:
   - Put `google-services.json` in `android/app/` directory
   - Path should be: `android/app/google-services.json`

---

## ⚙️ Step 4: Configure Mobile Apps

### iOS Configuration

**Update Info.plist:**

1. **GIDClientID**:
   - In Xcode: Runner target → **Info** tab
   - Find `GIDClientID` key
   - Replace `YOUR-CLIENT-ID-HERE` with **CLIENT_ID** from GoogleService-Info.plist

2. **URL Scheme**:
   - Still in Info tab → Expand **"URL Types"**
   - Click **"+"** to add new URL Type
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: Paste **REVERSED_CLIENT_ID** from GoogleService-Info.plist

### Android Configuration

**Update build files:**

1. **Update `android/settings.gradle.kts`**:
   Add Google services plugin:
   ```kotlin
   plugins {
       id("dev.flutter.flutter-plugin-loader") version "1.0.0"
       id("com.android.application") version "8.9.1" apply false
       id("org.jetbrains.kotlin.android") version "2.1.0" apply false
       id("com.google.gms.google-services") version "4.4.0" apply false  // Add this
   }
   ```

2. **Update `android/app/build.gradle.kts`**:
   Add plugin:
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services")  // Add this
   }
   ```

---

## 🔧 Step 5: Backend Configuration

1. **Get Web Client ID**:
   - Firebase Console → Authentication → Sign-in method → Google
   - Copy the **Web client ID** (you should have this from Step 1)

2. **Add to Backend `.env`**:
   ```env
   GOOGLE_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```

3. **Restart backend server**

---

## ✅ Step 6: Test

```bash
cd /Users/mac/Desktop/usdc-savings-app/mobile
flutter clean
cd ios && pod install && cd ..
flutter pub get
flutter run
```

Tap "Continue with Google" and it should work! 🎉

---

## 📋 Quick Checklist

- [ ] Google Sign-In enabled in Firebase
- [ ] Web Client ID copied (for backend)
- [ ] iOS app added to Firebase
- [ ] `GoogleService-Info.plist` downloaded and added to Xcode
- [ ] `GIDClientID` updated in Info.plist
- [ ] URL Scheme added to Info.plist
- [ ] Android app added to Firebase
- [ ] `google-services.json` in `android/app/` directory
- [ ] Google services plugin added to Android build files
- [ ] `GOOGLE_CLIENT_ID` added to backend `.env`
- [ ] Backend server restarted
- [ ] Test on device
