# Immediate Fixes for Xcode Issues

Based on your Xcode screenshot, here are the **exact steps** to fix both issues:

## 🔴 Issue 1: Apple Sign-In Capability (Do This First)

**What you see:** Grayed-out "Sign in with Apple" section with text saying "Add capabilities by clicking the '+' button above"

**Fix (in Xcode):**
1. In the **"Signing & Capabilities"** tab (where you are now)
2. Look for the **"+ Capability"** button at the top left (above the "Automatically manage signing" checkbox)
3. **Click "+ Capability"**
4. A search box will appear - type: **"Sign in with Apple"**
5. **Double-click** "Sign in with Apple" to add it
6. It should now appear properly configured (not grayed out)

---

## 🔴 Issue 2: Google Sign-In GIDClientID Missing

**Error:** `No active configuration. Make sure GIDClientID is set in Info.plist.`

**You need to:**

### Option A: Set Up Firebase (Recommended - Required for Production)

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Create/Select Project**: Create a project called "stakk-savings" (or select existing)
3. **Add iOS App**:
   - Click "Add app" → iOS icon
   - Bundle ID: `com.stakk.stakkSavings` (matches your Xcode setting)
   - App nickname: `Stakk iOS`
   - Click "Register app"
4. **Download GoogleService-Info.plist**:
   - Download the file
   - **Add to Xcode**: Drag it into the `Runner` folder in Xcode
   - Ensure "Copy items if needed" is checked
   - Ensure "Runner" target is checked
5. **Get CLIENT_ID**:
   - Open `GoogleService-Info.plist` in a text editor
   - Find `<key>CLIENT_ID</key>`
   - Copy the `<string>` value (looks like: `123456789-abc.apps.googleusercontent.com`)
6. **Update Info.plist**:
   - In Xcode: Runner target → **Info** tab
   - Find `GIDClientID` key (I've added a placeholder)
   - Replace `YOUR-CLIENT-ID-HERE` with the actual CLIENT_ID from step 5
7. **Add URL Scheme**:
   - Still in Info tab → Expand **"URL Types"**
   - Click **"+"** to add new URL Type
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: Get from `GoogleService-Info.plist` → `REVERSED_CLIENT_ID` value
     - It looks like: `com.googleusercontent.apps.123456789-abc`

### Option B: Temporary Placeholder (For Testing Only)

If you want to test the app structure without Firebase setup:

1. In Xcode: Runner target → **Info** tab
2. Find `GIDClientID` (I've added it with placeholder)
3. Replace `YOUR-CLIENT-ID-HERE` with any placeholder (e.g., `placeholder-client-id`)
4. **Note**: Google Sign-In won't actually work until you set up Firebase

---

## ✅ After Fixes

1. **Clean Build**:
   ```bash
   cd /Users/mac/Desktop/usdc-savings-app/mobile
   flutter clean
   cd ios && pod install && cd ..
   flutter run
   ```

2. **Verify**:
   - Apple Sign-In: Should work after adding capability
   - Google Sign-In: Will work after Firebase setup + CLIENT_ID added

---

## 📋 Quick Checklist

- [ ] Clicked "+ Capability" → Added "Sign in with Apple" in Xcode
- [ ] Set up Firebase project (or use placeholder)
- [ ] Downloaded `GoogleService-Info.plist` from Firebase
- [ ] Added `GoogleService-Info.plist` to Xcode Runner folder
- [ ] Updated `GIDClientID` in Info.plist with actual CLIENT_ID
- [ ] Added URL Scheme with REVERSED_CLIENT_ID
- [ ] Clean build and test

---

## 🎯 Priority Order

1. **First**: Fix Apple Sign-In capability (click + Capability)
2. **Second**: Set up Firebase and add GIDClientID (for Google Sign-In)

The Apple Sign-In fix is quick (just clicking a button). The Google Sign-In requires Firebase setup, which takes a few minutes.
