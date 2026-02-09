# Apple Sign-In Troubleshooting - Error 1000

## ✅ What's Already Configured

Based on your build settings, the following is **correctly configured**:

- ✅ **Entitlements File**: `Runner/Runner.entitlements` exists and is linked
- ✅ **Code Signing Entitlements**: Set to `Runner/Runner.entitlements` ✓
- ✅ **Bundle Identifier**: `com.stakk.stakkSavings` ✓
- ✅ **Development Team**: `3MCYU3SVQP` ✓

## 🔍 What to Check Next

Since the entitlements file is linked, the issue is likely one of these:

### 1. Check if Capability is Enabled in Xcode

**In Xcode:**
1. Open `ios/Runner.xcworkspace`
2. Select **Runner** project (blue icon) → **Runner** target
3. Go to **"Signing & Capabilities"** tab
4. **Look for "Sign in with Apple"** in the capabilities list

**If it's NOT there:**
- Click **"+ Capability"** button (top left)
- Search for **"Sign in with Apple"**
- Double-click to add it
- It should appear in the list

**If it IS there:**
- Make sure it shows a checkmark ✓
- Verify the entitlements file shows `com.apple.developer.applesignin` with `Default` value

### 2. Verify Apple Developer Portal Configuration

**Go to:** https://developer.apple.com/account/resources/identifiers/list

1. Find your App ID: `com.stakk.stakkSavings`
2. Click to edit it
3. Check if **"Sign in with Apple"** capability is enabled
4. If not enabled:
   - Check the box
   - Click **"Save"**
   - Wait a few minutes for changes to propagate

### 3. Update Provisioning Profiles

After enabling the capability in Apple Developer Portal:

**Option A: Automatic (Recommended)**
- In Xcode → Signing & Capabilities
- Ensure **"Automatically manage signing"** is checked
- Xcode will automatically regenerate profiles with the capability

**Option B: Manual**
- Go to Apple Developer Portal → **Profiles**
- For each profile (Development, Ad Hoc, App Store):
  - Edit the profile
  - Ensure "Sign in with Apple" is included
  - Download and install updated profiles
  - In Xcode, select the updated profile manually

### 4. Clean Build

After making changes:

```bash
cd /Users/mac/Desktop/usdc-savings-app/mobile
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
flutter run
```

### 5. Verify Device Setup

- ✅ Testing on **physical device** (not simulator) ✓
- ✅ Device signed into **iCloud**
- ✅ Device has **Apple ID** signed in
- ✅ **Sign in with Apple** enabled in device Settings → Apple ID

### 6. Check Entitlements File Content

Verify `ios/Runner/Runner.entitlements` contains:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.applesignin</key>
	<array>
		<string>Default</string>
	</array>
</dict>
</plist>
```

## 🎯 Most Likely Issue

Based on your configuration, the **most likely issue** is:

**The "Sign in with Apple" capability is not enabled in Xcode's Signing & Capabilities tab.**

Even though the entitlements file is linked, Xcode needs the capability explicitly added in the UI for it to work properly.

## 📝 Quick Checklist

- [ ] "Sign in with Apple" appears in Xcode → Signing & Capabilities
- [ ] Capability enabled in Apple Developer Portal for `com.stakk.stakkSavings`
- [ ] Provisioning profiles regenerated/updated
- [ ] Clean build performed
- [ ] Testing on physical device (not simulator)
- [ ] Device signed into iCloud
- [ ] Device has Apple ID signed in

## 🆘 Still Not Working?

If you've completed all steps and still get error 1000:

1. **Check Xcode Console** for more detailed error messages
2. **Verify Bundle ID** matches exactly: `com.stakk.stakkSavings`
3. **Try a different device** to rule out device-specific issues
4. **Check Apple Developer account** - ensure it's active and paid
5. **Wait 10-15 minutes** after enabling capability in Developer Portal (propagation delay)

## 📞 Next Steps

1. Open Xcode and verify the capability is visible in Signing & Capabilities
2. If not visible, add it using "+ Capability"
3. Enable it in Apple Developer Portal
4. Clean build and test again

Let me know what you find in the Signing & Capabilities tab!
