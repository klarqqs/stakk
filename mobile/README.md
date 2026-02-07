# Stakk – Mobile App

Flutter mobile app for Stakk. Uses **Fustat** font and connects to the production backend at `stakk-production.up.railway.app`.

## Features

- Login / Register
- Dashboard with USDC balance
- Transaction history
- Secure token storage (flutter_secure_storage)
- Pull-to-refresh on dashboard

## Setup

```bash
cd mobile
flutter pub get
```

## Run

```bash
# iOS
flutter run

# Android
flutter run

# Specify device
flutter devices
flutter run -d <device_id>
```

## Backend

The app talks to: `https://stakk-production.up.railway.app/api`

- `POST /api/auth/register` – phone, email, password
- `POST /api/auth/login` – phone, password
- `GET /api/wallet/balance` – Bearer token
- `GET /api/wallet/transactions` – Bearer token

## Build

```bash
# Android APK
flutter build apk --release

# iOS (requires Mac + Xcode)
flutter build ios --release
```

## Architecture

- `lib/api/` – API client
- `lib/config/` – Environment
- `lib/providers/` – Auth state
- `lib/screens/` – Auth, Dashboard
- `lib/theme/` – Fustat theme
