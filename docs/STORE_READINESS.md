# Store Readiness Guide - STAKK

Complete checklist and resources for App Store and Google Play Store submission.

## ✅ Completed

### Privacy Policy & Terms
- ✅ Privacy Policy screen implemented (`privacy_policy_screen.dart`)
- ✅ Terms of Service screen implemented (`terms_of_service_screen.dart`)
- ✅ Both screens are comprehensive and store-compliant
- ✅ Accessible from app's "More" tab

### App Icons
- ✅ iOS icons configured (all required sizes)
- ✅ Android icons configured (all density variants)

## 📋 Store Submission Checklist

### App Store (iOS)

#### Required Assets
- [ ] **App Icon**: 1024x1024px (PNG, no transparency)
- [ ] **Screenshots**: 
  - iPhone 6.7" (iPhone 14 Pro Max): 1290 x 2796px
  - iPhone 6.5" (iPhone 11 Pro Max): 1242 x 2688px
  - iPhone 5.5" (iPhone 8 Plus): 1242 x 2208px
  - iPad Pro 12.9": 2048 x 2732px (optional)
- [ ] **App Preview Video**: Optional but recommended (30 seconds max)

#### Required Information
- [ ] **App Name**: STAKK (max 30 characters)
- [ ] **Subtitle**: Save in USDC, protected from inflation (max 30 characters)
- [ ] **Description**: See `STORE_LISTING_CONTENT.md`
- [ ] **Keywords**: See `STORE_LISTING_CONTENT.md`
- [ ] **Privacy Policy URL**: https://stakk.app/privacy (must be live)
- [ ] **Support URL**: https://stakk.app/support or mailto:support@stakk.app
- [ ] **Category**: Finance
- [ ] **Age Rating**: 17+ (due to financial services)
- [ ] **Pricing**: Free

#### App Information
- [ ] **Bundle ID**: `com.stakk.stakkSavings`
- [ ] **Version**: `1.0.0`
- [ ] **Build Number**: `1`
- [ ] **Copyright**: `© 2026 STAKK. All rights reserved.`

### Google Play Store (Android)

#### Required Assets
- [ ] **App Icon**: 512x512px (PNG, no transparency)
- [ ] **Feature Graphic**: 1024 x 500px (banner for store listing)
- [ ] **Screenshots**:
  - Phone: At least 2, max 8 (min 320px, max 3840px height)
  - Tablet: Optional but recommended
  - Recommended: 1080 x 1920px (portrait) or 1920 x 1080px (landscape)
- [ ] **Promo Video**: Optional (YouTube link)

#### Required Information
- [ ] **App Name**: STAKK (max 50 characters)
- [ ] **Short Description**: See `STORE_LISTING_CONTENT.md` (max 80 characters)
- [ ] **Full Description**: See `STORE_LISTING_CONTENT.md` (max 4000 characters)
- [ ] **Privacy Policy URL**: https://stakk.app/privacy (must be live)
- [ ] **Support Email**: support@stakk.app
- [ ] **Category**: Finance
- [ ] **Content Rating**: PEGI 3+ or similar (varies by region)
- [ ] **Pricing**: Free

#### App Information
- [ ] **Package Name**: `com.stakk.stakkSavings`
- [ ] **Version Name**: `1.0.0`
- [ ] **Version Code**: `1`
- [ ] **Target SDK**: Latest (check `android/app/build.gradle.kts`)

## 📸 Screenshots Guide

### Recommended Screenshots (in order)

1. **Onboarding/Hero Screen**
   - Show the modern onboarding with hero icons
   - Highlight "Save in USDC, protected from inflation"

2. **Dashboard/Home Screen**
   - Show USDC balance
   - Display savings goals progress
   - Show recent transactions

3. **Savings Goals**
   - Create/edit savings goal screen
   - Show goal progress visualization
   - Highlight goal achievement

4. **Send/P2P Transfer**
   - Send to Stakk user screen
   - QR code scanning feature
   - Transfer confirmation

5. **Bill Payments**
   - Bill categories screen
   - Bill payment flow
   - Payment confirmation

6. **Lock Savings**
   - Lock savings creation
   - Lock savings dashboard
   - Earnings visualization

7. **Security Features**
   - Passcode setup
   - Transaction security
   - Account settings

### Screenshot Best Practices

- **Use real data**: Show realistic balances and transactions (use test data)
- **Highlight key features**: Each screenshot should showcase one main feature
- **Consistent design**: Use same theme (light or dark) across all screenshots
- **Add text overlays**: Optional - add brief captions explaining features
- **Show value**: Emphasize benefits (security, ease of use, savings goals)
- **Remove sensitive info**: Blur or remove any real personal information

### Tools for Screenshots

- **iOS**: Xcode Simulator → Device → Screenshot
- **Android**: Android Studio Emulator → Extended Controls → Screenshot
- **Design Tools**: Figma, Sketch (for mockups with overlays)
- **Annotation**: Canva, Figma (for adding text/captions)

## 🌐 Web-Hosted Privacy Policy & Terms

### Requirements

Both Apple App Store and Google Play Store require **publicly accessible URLs** for:
- Privacy Policy
- Terms of Service (optional but recommended)

### Options

#### Option 1: Host on Your Website
1. Create HTML versions of privacy policy and terms
2. Host at:
   - `https://stakk.app/privacy`
   - `https://stakk.app/terms`
3. Ensure pages are mobile-responsive
4. Update app screens to link to these URLs (optional)

#### Option 2: Use GitHub Pages
1. Create `docs/privacy.html` and `docs/terms.html`
2. Enable GitHub Pages
3. Access at:
   - `https://[username].github.io/[repo]/privacy.html`
   - `https://[username].github.io/[repo]/terms.html`

#### Option 3: Use a Simple Hosting Service
- Netlify, Vercel, or similar
- Upload static HTML files
- Get free HTTPS URLs

### HTML Template Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy | STAKK</title>
    <style>
        /* Add your styles */
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <h1>Privacy Policy</h1>
    <!-- Copy content from privacy_policy_screen.dart -->
</body>
</html>
```

## 📝 Store Listing Content

See `STORE_LISTING_CONTENT.md` for:
- App descriptions
- Keywords
- Feature highlights
- Marketing copy

## 🔍 Pre-Submission Checklist

### iOS App Store
- [ ] TestFlight build tested on physical devices
- [ ] All required screenshots uploaded
- [ ] App icon meets requirements (1024x1024, no transparency)
- [ ] Privacy Policy URL is live and accessible
- [ ] Support contact information is correct
- [ ] Age rating is appropriate (17+)
- [ ] App complies with App Store Review Guidelines
- [ ] No placeholder content in app
- [ ] All features work as described

### Google Play Store
- [ ] Internal testing track tested
- [ ] All required screenshots uploaded
- [ ] Feature graphic created (1024x500)
- [ ] App icon meets requirements (512x512)
- [ ] Privacy Policy URL is live and accessible
- [ ] Support email is correct
- [ ] Content rating questionnaire completed
- [ ] App complies with Google Play Policies
- [ ] No placeholder content in app
- [ ] All features work as described

## 🚀 Submission Steps

### iOS App Store
1. Archive app in Xcode
2. Upload to App Store Connect
3. Fill in app information in App Store Connect
4. Upload screenshots and metadata
5. Submit for review

### Google Play Store
1. Build release APK/AAB
2. Create app listing in Google Play Console
3. Upload APK/AAB to production track
4. Fill in store listing details
5. Complete content rating questionnaire
6. Submit for review

## 📞 Support

For questions about store submission:
- **iOS**: Check [App Store Connect Help](https://help.apple.com/app-store-connect/)
- **Android**: Check [Google Play Console Help](https://support.google.com/googleplay/android-developer/)

---

**STAKK** - Save in USDC, protected from inflation.
