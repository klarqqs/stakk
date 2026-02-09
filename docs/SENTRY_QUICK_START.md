# Sentry Quick Start Guide - STAKK

Quick reference for setting up Sentry error tracking.

## 🎯 Quick Steps

### 1. Create Sentry Projects

Go to https://sentry.io and create **two projects**:

**Project 1: Mobile App**
- Platform: **Flutter**
- Name: `stakk-mobile`
- Copy the **DSN** (looks like: `https://xxxxx@xxxxx.ingest.sentry.io/xxxxx`)

**Project 2: Backend API**
- Platform: **Node.js**
- Name: `stakk-backend`
- Copy the **DSN**

---

## 📱 Mobile App Setup

### Step 1: Install Package

```bash
cd mobile
flutter pub add sentry_flutter
```

### Step 2: Update pubspec.yaml

The package is already added. Now update `lib/services/error_tracking_service.dart`:

**Uncomment Sentry code** and replace `YOUR_SENTRY_DSN` with your mobile DSN.

### Step 3: Build with DSN

```bash
# iOS
flutter build ios --dart-define=SENTRY_DSN=your_mobile_dsn_here

# Android
flutter build apk --dart-define=SENTRY_DSN=your_mobile_dsn_here
```

---

## 🔧 Backend Setup

### Step 1: Install Packages

```bash
cd backend
npm install @sentry/node @sentry/profiling-node
```

### Step 2: Add DSN to Environment

Add to Railway environment variables or `.env`:

```bash
SENTRY_DSN=https://xxxxx@xxxxx.ingest.sentry.io/xxxxx
SENTRY_RELEASE=stakk-backend@1.0.0
```

### Step 3: Restart Server

Sentry is already integrated in `server.ts`. Just restart:

```bash
npm run dev
```

---

## ✅ Verify Setup

### Test Mobile App

Add this temporarily to test:

```dart
ElevatedButton(
  onPressed: () {
    throw Exception('Test Sentry error');
  },
  child: Text('Test Sentry'),
)
```

Click the button and check Sentry dashboard.

### Test Backend

Visit: `http://localhost:3001/test-sentry` (if you add the test route)

Or trigger any error and check Sentry dashboard.

---

## 📊 View Errors

1. Go to https://sentry.io
2. Select your project (`stakk-mobile` or `stakk-backend`)
3. View errors in the "Issues" tab

---

## 🔔 Set Up Alerts

1. Go to **Alerts** → **Create Alert Rule**
2. Set condition: "An issue is created"
3. Set threshold: "More than 10 occurrences in 1 minute"
4. Choose notification: Email

---

## 📝 Files to Update

### Mobile:
- ✅ `lib/services/error_tracking_service.dart` - Uncomment Sentry code
- ✅ `lib/main.dart` - Already integrated
- ✅ `lib/config/sentry_config.dart` - Created

### Backend:
- ✅ `src/config/sentry.ts` - Created
- ✅ `src/server.ts` - Already integrated
- ✅ `.env.example` - Updated

---

## 🚀 Production Checklist

- [ ] Created Flutter project in Sentry
- [ ] Created Node.js project in Sentry
- [ ] Installed `sentry_flutter` in mobile
- [ ] Installed `@sentry/node` in backend
- [ ] Added mobile DSN to build command
- [ ] Added backend DSN to Railway environment
- [ ] Tested error tracking
- [ ] Configured alerts

---

**STAKK** - Save in USDC, protected from inflation.
