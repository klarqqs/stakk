# Apple Developer Portal - Sign in with Apple Setup

## ✅ Current Status

You're in the Apple Developer Portal configuring Sign in with Apple for:
- **Bundle ID**: `com.stakk.stakkSavings`
- **Team**: Kolawole Oluwafemi (3MCYU3SVQP)

## 🎯 Configuration Steps

### Step 1: Enable as Primary App ID

**In the dialog you're seeing:**

1. **Select**: ✅ **"Enable as a primary App ID"** (since this is a new app)
2. **Server-to-Server Notification Endpoint**: 
   - Leave **blank** for now (optional, can add later)
   - You only need this if you want to receive notifications about user account changes
3. Click **"Save"**

### Step 2: Verify It's Enabled

After saving, you should see:
- ✅ **"Sign In with Apple"** with an **"Edit"** button next to it
- It should show as **enabled** in the capabilities list

### Step 3: Regenerate Provisioning Profiles

After enabling the capability:

**Option A: Automatic (Recommended)**
- Go back to Xcode
- In **Signing & Capabilities** tab
- Ensure **"Automatically manage signing"** is checked
- Xcode will automatically regenerate profiles with the new capability
- You may see a brief "Processing..." message

**Option B: Manual**
- In Apple Developer Portal → **Profiles**
- For each profile (Development, Ad Hoc, App Store):
  - Edit the profile
  - Ensure "Sign in with Apple" capability is included
  - Download and install updated profiles
  - In Xcode, manually select the updated profile

### Step 4: Verify in Xcode

1. **Open Xcode**: `open ios/Runner.xcworkspace`
2. **Select Runner target** → **Signing & Capabilities** tab
3. **Verify**:
   - ✅ "Sign in with Apple" appears in capabilities list
   - ✅ No grayed-out text
   - ✅ Shows checkmark/enabled status

### Step 5: Clean Build and Test

```bash
cd /Users/mac/Desktop/usdc-savings-app/mobile
flutter clean
cd ios && pod install && cd ..
flutter run
```

## 📝 What "Primary App ID" Means

- **Primary App ID**: Use this for a standalone app (your case - Stakk Savings)
- **Group with existing**: Only use if you have multiple apps (iOS + macOS + web) that should share the same Sign in with Apple identity

Since Stakk Savings is a standalone app, **"Enable as a primary App ID"** is correct.

## 🔔 Server-to-Server Notifications (Optional)

You can leave this blank for now. You only need it if you want to:
- Receive notifications when users delete their Apple account
- Receive notifications when users change email forwarding preferences
- Handle account deletion on your backend

For basic Sign in with Apple functionality, this is **not required**.

## ✅ Checklist

- [ ] Selected "Enable as a primary App ID"
- [ ] Left Server-to-Server endpoint blank (or added if needed)
- [ ] Clicked "Save"
- [ ] Verified capability shows as enabled in portal
- [ ] Regenerated provisioning profiles (automatic or manual)
- [ ] Verified in Xcode Signing & Capabilities tab
- [ ] Clean build and test

## 🎯 Next Steps After This

1. Complete the Apple Developer Portal setup (you're doing this now)
2. Verify in Xcode that capability is properly enabled
3. Test Apple Sign-In on physical device
4. Set up Firebase for Google Sign-In (separate issue)

After completing these steps, Apple Sign-In should work! 🎉
