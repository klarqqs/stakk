# Quick Fix for Xcode Issues

## Issue 1: Apple Sign-In Capability Not Enabled

**In Xcode (what you're seeing):**
- The "Sign in with Apple" section shows grayed-out text
- It says "Add capabilities by clicking the '+' button above"

**Fix:**
1. In Xcode, in the **"Signing & Capabilities"** tab
2. Click the **"+ Capability"** button (top left, above the signing section)
3. Search for **"Sign in with Apple"**
4. Double-click it to add
5. It should now appear properly configured in the capabilities list

---

## Issue 2: Google Sign-In Missing GIDClientID

**Error you're seeing:**
```
No active configuration. Make sure GIDClientID is set in Info.plist.
```

**Fix Steps:**

### Step 1: Get GoogleService-Info.plist from Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create one if you don't have it)
3. Click the **iOS app** (or add iOS app if not added)
4. Download **`GoogleService-Info.plist`**
5. Add it to Xcode:
   - Drag `GoogleService-Info.plist` into the `Runner` folder in Xcode
   - Ensure "Copy items if needed" is checked
   - Ensure "Runner" target is checked

### Step 2: Get CLIENT_ID from GoogleService-Info.plist

1. Open `GoogleService-Info.plist` in a text editor
2. Find the `<key>CLIENT_ID</key>` entry
3. Copy the `<string>` value (it looks like: `123456789-abc.apps.googleusercontent.com`)

### Step 3: Add GIDClientID to Info.plist

**In Xcode:**
1. Select **Runner** target → **Info** tab
2. Expand **"Custom iOS Target Properties"**
3. Right-click → **"Add Row"**
4. Key: `GIDClientID` (or search for it)
5. Type: `String`
6. Value: Paste the CLIENT_ID from GoogleService-Info.plist

**OR manually edit Info.plist:**

Add this before `</dict>`:
```xml
<key>GIDClientID</key>
<string>YOUR-CLIENT-ID-FROM-GOOGLESERVICE-INFO.PLIST</string>
```

### Step 4: Add URL Scheme (for Google Sign-In redirect)

1. In Xcode: Runner target → **Info** tab
2. Expand **"URL Types"**
3. Click **"+"** to add a new URL Type
4. Set:
   - **Identifier**: `GoogleSignIn`
   - **URL Schemes**: Get from `GoogleService-Info.plist` → `REVERSED_CLIENT_ID` value
     - It looks like: `com.googleusercontent.apps.123456789-abc`

---

## Quick Checklist

- [ ] Clicked "+ Capability" and added "Sign in with Apple" in Xcode
- [ ] Downloaded `GoogleService-Info.plist` from Firebase
- [ ] Added `GoogleService-Info.plist` to Xcode Runner folder
- [ ] Added `GIDClientID` to Info.plist with CLIENT_ID value
- [ ] Added URL Scheme with REVERSED_CLIENT_ID value
- [ ] Clean build: `flutter clean && flutter run`

---

## If You Don't Have Firebase Set Up Yet

You can temporarily use a placeholder, but **Google Sign-In won't work** until Firebase is configured:

1. Add to Info.plist:
```xml
<key>GIDClientID</key>
<string>YOUR-CLIENT-ID-HERE</string>
```

2. Get the CLIENT_ID from:
   - Firebase Console → Project Settings → Your iOS App → CLIENT_ID
   - OR from `GoogleService-Info.plist` → CLIENT_ID key

---

## After Making Changes

```bash
cd /Users/mac/Desktop/usdc-savings-app/mobile
flutter clean
cd ios && pod install && cd ..
flutter run
```
