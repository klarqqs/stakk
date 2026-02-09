# Store Deployment Checklist - STAKK

Pre-launch checklist before uploading to App Store and Google Play.

## 📱 Before Uploading to Stores

### 1. App Version Configuration

**Current Version** (from `pubspec.yaml`):
```yaml
version: 1.0.0+1  # Format: version+build
```

**Backend Configuration** (Railway environment variables):
```bash
# Set these BEFORE first release
MINIMUM_APP_VERSION=1.0.0
FORCE_APP_UPDATE=false

# ⚠️ DO NOT set these yet - wait until apps are published
# IOS_APP_STORE_URL=placeholder
# ANDROID_PLAY_STORE_URL=placeholder
```

**Why?**
- `FORCE_APP_UPDATE=false` - No force updates needed for first release
- `MINIMUM_APP_VERSION=1.0.0` - Matches your first release version
- Store URLs - You don't have these yet! Wait until apps are approved.

---

## 🍎 iOS App Store

### Step 1: Upload to App Store Connect

1. Build for release:
   ```bash
   cd mobile
   flutter build ios --release
   ```

2. Archive in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Product → Archive
   - Distribute App → App Store Connect

3. Submit for review in App Store Connect

### Step 2: After Approval

Once your app is **approved and published**:

1. **Get your App Store URL**:
   - Go to App Store Connect
   - Your app → App Information
   - Copy the App Store URL (looks like: `https://apps.apple.com/app/id123456789`)
   - **Note the App ID** (the number after `/id`)

2. **Update Backend**:
   ```bash
   # In Railway environment variables
   IOS_APP_STORE_URL=https://apps.apple.com/app/idYOUR_ACTUAL_ID
   ```

3. **Update Mobile Code** (optional fallback):
   Edit `mobile/lib/services/app_version_service.dart`:
   ```dart
   static const String _defaultIosUrl = 'https://apps.apple.com/app/idYOUR_ACTUAL_ID';
   ```

---

## 🤖 Google Play Store

### Step 1: Upload to Google Play Console

1. Build release APK/AAB:
   ```bash
   cd mobile
   flutter build appbundle --release  # Recommended (AAB)
   # OR
   flutter build apk --release  # APK format
   ```

2. Upload to Google Play Console:
   - Go to Google Play Console
   - Create app (if first time)
   - Production → Create new release → Upload AAB/APK
   - Submit for review

### Step 2: After Approval

Once your app is **approved and published**:

1. **Get your Play Store URL**:
   - Go to Google Play Console
   - Your app → Store presence → Main store listing
   - Copy the Play Store URL (looks like: `https://play.google.com/store/apps/details?id=com.stakk.stakkSavings`)

2. **Update Backend**:
   ```bash
   # In Railway environment variables
   ANDROID_PLAY_STORE_URL=https://play.google.com/store/apps/details?id=com.stakk.stakkSavings
   ```

3. **Update Mobile Code** (optional fallback):
   Edit `mobile/lib/services/app_version_service.dart`:
   ```dart
   static const String _defaultAndroidUrl = 'https://play.google.com/store/apps/details?id=com.stakk.stakkSavings';
   ```

---

## ✅ Recommended Pre-Launch Settings

### Railway Environment Variables (Set Now)

```bash
# Version Management
MINIMUM_APP_VERSION=1.0.0
FORCE_APP_UPDATE=false

# ⚠️ Leave these EMPTY or commented out until apps are published
# IOS_APP_STORE_URL=
# ANDROID_PLAY_STORE_URL=
```

**Why?**
- `FORCE_APP_UPDATE=false` - Users won't be forced to update (normal for first release)
- `MINIMUM_APP_VERSION=1.0.0` - Matches your first version
- Store URLs empty - Force update dialog won't work until URLs are set (which is fine for first release)

---

## 🔄 After Apps Are Published

### Update Backend Configuration

1. **Get Real URLs** from App Store Connect and Google Play Console

2. **Add to Railway**:
   ```bash
   IOS_APP_STORE_URL=https://apps.apple.com/app/idYOUR_ACTUAL_ID
   ANDROID_PLAY_STORE_URL=https://play.google.com/store/apps/details?id=com.stakk.stakkSavings
   ```

3. **Test Force Update** (optional):
   - Set `MINIMUM_APP_VERSION=1.0.1` (higher than current)
   - Set `FORCE_APP_UPDATE=true`
   - Verify dialog appears and links work

---

## 📋 Complete Pre-Launch Checklist

### App Configuration
- [ ] Version number set in `pubspec.yaml` (e.g., `1.0.0+1`)
- [ ] Build number incremented for each release
- [ ] App icons configured (1024x1024 for iOS, various sizes for Android)
- [ ] App name, description, screenshots ready
- [ ] Privacy policy URL configured
- [ ] Terms of service URL configured

### Backend Configuration
- [ ] `MINIMUM_APP_VERSION=1.0.0` (matches first release)
- [ ] `FORCE_APP_UPDATE=false` (no force updates for first release)
- [ ] Store URLs left empty (will update after publication)
- [ ] All other environment variables configured

### Testing
- [ ] Test app in release mode
- [ ] Verify no force update dialog appears (since `FORCE_APP_UPDATE=false`)
- [ ] Test all critical flows
- [ ] Verify error tracking (Sentry) works
- [ ] Verify analytics (Firebase) works

### Store Submission
- [ ] iOS: Upload to App Store Connect
- [ ] Android: Upload to Google Play Console
- [ ] Wait for approval
- [ ] **After approval**: Update store URLs in Railway

---

## 🚨 Important Notes

1. **Don't use placeholder URLs** - They won't work and will confuse users
2. **Force update is optional** - You can leave it disabled for first release
3. **Version matching** - `MINIMUM_APP_VERSION` should match your `pubspec.yaml` version
4. **Update URLs after publication** - You can't get real URLs until apps are approved

---

## 📝 Example Timeline

**Week 1: Pre-Launch**
- Set `MINIMUM_APP_VERSION=1.0.0`
- Set `FORCE_APP_UPDATE=false`
- Leave store URLs empty
- Upload apps to stores

**Week 2: Waiting for Approval**
- Apps under review
- No changes needed to backend

**Week 3: After Approval**
- Get real App Store URL
- Get real Play Store URL
- Update Railway environment variables
- Test force update (optional)

**Future Releases:**
- Increment version in `pubspec.yaml`
- Update `MINIMUM_APP_VERSION` if you want to force updates
- Set `FORCE_APP_UPDATE=true` for critical updates

---

**STAKK** - Save in USDC, protected from inflation.
