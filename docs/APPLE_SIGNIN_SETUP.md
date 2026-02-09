# Apple Sign-In Setup Guide

## Error 1000 (AuthorizationErrorCode.unknown) - Fix Steps

Error 1000 typically occurs due to missing entitlements or configuration. Follow these steps:

### Step 1: Create Entitlements File ✅

The `Runner.entitlements` file has been created at:
```
ios/Runner/Runner.entitlements
```

### Step 2: Configure Xcode

1. **Open Xcode**:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Add Entitlements File to Project**:
   - In Xcode, right-click on `Runner` folder
   - Select "Add Files to Runner..."
   - Navigate to `ios/Runner/Runner.entitlements`
   - Check "Copy items if needed" (if not already in project)
   - Click "Add"

3. **Enable Sign in with Apple Capability**:
   - Select the `Runner` project in the navigator
   - Select the `Runner` target
   - Go to **Signing & Capabilities** tab
   - Click **"+ Capability"**
   - Search for and add **"Sign in with Apple"**
   - Ensure the entitlements file is selected in the "Code Signing Entitlements" field

4. **Verify Bundle Identifier**:
   - In **Signing & Capabilities**, ensure your Bundle Identifier matches your Apple Developer account
   - Example: `com.yourcompany.stakk` or `ng.com.stakk.savings`

### Step 3: Apple Developer Portal Configuration

1. **Go to Apple Developer Portal**: https://developer.apple.com/account/

2. **Enable Sign in with Apple**:
   - Navigate to **Certificates, Identifiers & Profiles**
   - Select **Identifiers**
   - Find your App ID (matches Bundle Identifier)
   - Click **Edit**
   - Enable **"Sign in with Apple"** capability
   - Click **Save**

3. **Create/Update Provisioning Profiles**:
   - Go to **Profiles**
   - For each profile (Development, Ad Hoc, App Store):
     - Edit the profile
     - Ensure "Sign in with Apple" capability is included
     - Download and install the updated profiles
   - In Xcode, go to **Signing & Capabilities** → **Automatically manage signing** (or manually select profiles)

### Step 4: Testing Requirements

**Important**: Apple Sign-In has limitations:

1. **Physical Device Required**:
   - Sign in with Apple **does NOT work on iOS Simulator**
   - You **MUST test on a physical iOS device**

2. **iCloud Sign-In Required**:
   - The device must be signed into iCloud
   - Go to **Settings** → **Sign in to your iPhone** → Ensure iCloud is signed in

3. **Apple ID Required**:
   - The device must have an Apple ID signed in
   - Go to **Settings** → **Apple ID** (top of settings)

### Step 5: Verify Setup

After completing the above steps:

1. **Clean Build**:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter clean
   flutter pub get
   ```

2. **Build and Run on Physical Device**:
   ```bash
   flutter run --release
   ```
   Or use Xcode to build and run on a connected device.

### Common Issues & Solutions

#### Issue: "Sign in with Apple is not available"
- **Solution**: Ensure device is signed into iCloud and has an Apple ID

#### Issue: Error 1000 persists
- **Solution**: 
  1. Verify entitlements file is added to Xcode project
  2. Check that "Sign in with Apple" capability is enabled in Xcode
  3. Ensure provisioning profiles include the capability
  4. Try on a different physical device
  5. Ensure you're not testing on simulator

#### Issue: "Invalid client"
- **Solution**: Verify Bundle ID matches Apple Developer Portal configuration

#### Issue: Capability not showing in Xcode
- **Solution**: 
  1. Ensure you have a paid Apple Developer account
  2. Verify Bundle ID is registered in Apple Developer Portal
  3. Try restarting Xcode

### Code Implementation

The app now includes:
- ✅ Entitlements file created
- ✅ Error handling for all Apple Sign-In error codes
- ✅ User-friendly error messages
- ✅ Availability check before attempting sign-in

### Testing Checklist

- [ ] Entitlements file added to Xcode project
- [ ] "Sign in with Apple" capability enabled in Xcode
- [ ] Bundle ID matches Apple Developer Portal
- [ ] Provisioning profiles updated with capability
- [ ] Testing on physical iOS device (not simulator)
- [ ] Device signed into iCloud
- [ ] Device has Apple ID signed in

### Next Steps

1. Complete Xcode configuration (Steps 2-3)
2. Test on a physical device
3. If errors persist, check Apple Developer Portal configuration
4. Verify all provisioning profiles include the capability
