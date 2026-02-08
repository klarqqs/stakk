# Clean Architecture + Auth Flow Refactor

> Production-grade MVP architecture for Stakk USDC Savings App (Flutter)  
> Inspired by Dayfi Send App • Fintech-ready • Series A–scalable

---

## 1. Clean Architecture Proposal

### 1.1 Feature-First Structure

```
lib/
├── main.dart
├── app.dart
│
├── core/                           # Shared across all features
│   ├── theme/
│   │   ├── app_theme.dart          # Theme data factory
│   │   ├── light_theme.dart
│   │   ├── dark_theme.dart
│   │   ├── theme_extensions.dart   # Custom extensions (colors, text)
│   │   └── tokens/                 # Design tokens (spacing, radius)
│   │
│   ├── components/                # Reusable UI primitives
│   │   ├── buttons/
│   │   │   ├── primary_button.dart
│   │   │   └── secondary_button.dart
│   │   ├── inputs/
│   │   │   ├── app_text_field.dart
│   │   │   └── otp_input.dart
│   │   ├── app_bottom_nav_bar.dart
│   │   └── glassmorphism/
│   │       └── glass_container.dart
│   │
│   ├── navigation/
│   │   ├── app_router.dart         # Central router
│   │   ├── routes.dart            # Route names & paths
│   │   └── guards/
│   │       ├── auth_guard.dart
│   │       └── passcode_guard.dart
│   │
│   ├── utils/
│   │   ├── validators.dart
│   │   └── formatters.dart
│   │
│   └── constants/
│       ├── storage_keys.dart
│       └── api_endpoints.dart
│
├── features/
│   ├── auth/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   ├── check_email_screen.dart
│   │   │   │   ├── login_screen.dart
│   │   │   │   ├── signup_screen.dart
│   │   │   │   ├── verify_email_screen.dart
│   │   │   │   ├── forgot_password_screen.dart
│   │   │   │   ├── reset_password_screen.dart
│   │   │   │   ├── passcode_gate_screen.dart
│   │   │   │   ├── create_passcode_screen.dart
│   │   │   │   ├── reenter_passcode_screen.dart
│   │   │   │   └── complete_profile_screen.dart
│   │   │   ├── widgets/           # Auth-specific UI
│   │   │   │   ├── passcode_pad.dart
│   │   │   │   └── auth_header.dart
│   │   │   └── state/
│   │   │       ├── auth_provider.dart
│   │   │       ├── auth_state.dart
│   │   │       └── auth_notifier.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   └── use_cases/
│   │   │       ├── check_email.dart
│   │   │       ├── login.dart
│   │   │       ├── signup.dart
│   │   │       └── verify_passcode.dart
│   │   └── data/
│   │       ├── repositories/
│   │       │   └── auth_repository.dart
│   │       └── datasources/
│   │           ├── auth_api.dart
│   │           └── auth_local.dart
│   │
│   ├── dashboard/                  # Shell + tab orchestration
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── dashboard_shell.dart
│   │   │   └── widgets/
│   │   │       └── app_bottom_nav_bar.dart   # Wraps core component
│   │   ├── domain/
│   │   └── data/
│   │
│   ├── home/                       # Tab: Home
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   └── home_screen.dart
│   │   │   └── widgets/
│   │   ├── domain/
│   │   └── data/
│   │
│   ├── bills/
│   ├── invest/
│   ├── card/
│   └── more/
│
└── shared/                         # Cross-cutting (optional)
    └── api/
        └── api_client.dart
```

### 1.2 Layer Responsibilities

| Layer | Responsibility | Dependencies |
|-------|----------------|--------------|
| **Presentation** | UI, user input, state display | Domain only |
| **Domain** | Business rules, entities, use cases | None |
| **Data** | API calls, local storage, mappers | Domain |

### 1.3 Why This Scales

- **Feature independence** — Each feature can be developed, tested, and shipped in isolation
- **Clear boundaries** — Presentation never imports Data; Domain has no Flutter imports
- **Testability** — Use cases & repositories are easily mockable
- **Team scalability** — Different devs can own features without merge conflicts
- **Compliance** — Sensitive flows (auth, payments) are isolated and auditable

### 1.4 Where Things Live

| Concern | Location |
|---------|----------|
| Screen widgets | `features/<feature>/presentation/screens/` |
| Business logic | `features/<feature>/domain/use_cases/` |
| API calls | `features/<feature>/data/datasources/` |
| State management | `features/<feature>/presentation/state/` |
| Shared UI | `core/components/` |
| Routing | `core/navigation/` |

---

## 2. Auth Flow (Dayfi-Inspired)

### 2.1 Step-by-Step Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            APP LAUNCH                                    │
└────────────────────────────────────────────┬────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          AUTH GATE                                        │
│  • Check token presence                                                   │
│  • Check passcode presence                                                │
└──────────┬──────────────────────────────────────┬────────────────────────┘
           │                                      │
     No token                               Has token
           │                                      │
           ▼                                      ├── Has passcode ──► PASSCODE GATE
┌──────────────────┐                             │
│   ONBOARDING     │                             └── No passcode ───► DASHBOARD (first session)
│   (2–3 slides)   │
└────────┬─────────┘
         │ Get Started
         ▼
┌──────────────────┐
│   CHECK EMAIL    │
│   Single field   │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
Exists?   New?
    │         │
    ▼         ▼
┌────────┐  ┌────────┐
│ LOGIN  │  │ SIGNUP │
│(pwd)   │  │(name,  │
│        │  │email,  │
│        │  │pwd)    │
└───┬────┘  └───┬────┘
    │           │
    │           ▼
    │      ┌─────────────┐
    │      │ VERIFY EMAIL│
    │      │ (OTP)       │
    │      └──────┬──────┘
    │             │
    └──────┬──────┘
           │
           ▼
┌─────────────────────┐
│ COMPLETE PROFILE    │
│ (phone for NGN)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ CREATE PASSCODE     │
│ (4-digit)           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ RE-ENTER PASSCODE   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│    DASHBOARD         │
└─────────────────────┘
```

### 2.2 Branching Logic

| Decision Point | Condition | Next Step |
|----------------|-----------|-----------|
| Auth Gate | Token + passcode | Passcode Gate |
| Auth Gate | Token only | Dashboard |
| Auth Gate | No token | Onboarding |
| Check Email | `exists: true` | Login |
| Check Email | `exists: false` | Sign Up |
| Login | Account unverified | Verify Email (resend OTP) |
| Login | Profile incomplete (no phone) | Complete Profile |
| Login | Profile complete | Create Passcode |
| Sign Up | After submit | Verify Email |
| Verify Email | OTP valid | Complete Profile |
| Complete Profile | After submit | Create Passcode |
| Create Passcode | 4 digits entered | Re-enter Passcode |
| Re-enter Passcode | Match | Dashboard |
| Re-enter Passcode | Mismatch | Stay, clear, error |
| Passcode Gate | Correct | Dashboard |
| Passcode Gate | "Use password" | Check Email |
| Forgot Password | After submit | Reset Password |
| Reset Password | OTP + new pwd | Auto-login → Create Passcode → Dashboard |

### 2.3 Auth States

| State | Meaning | Screen |
|-------|---------|--------|
| `unauthenticated` | No token | Onboarding |
| `email_checked` | Branch known | Login or Sign Up |
| `email_pending` | OTP sent | Verify Email |
| `email_verified` | OTP verified | Complete Profile or Create Passcode |
| `profile_incomplete` | No phone | Complete Profile |
| `passcode_required` | Must create | Create Passcode |
| `authenticated` | Full access | Dashboard |
| `passcode_gate` | Returning user | Passcode Gate |

---

## 3. Auth Feature Responsibilities

### 3.1 Screens (`features/auth/presentation/screens/`)

| Screen | Purpose |
|--------|---------|
| `onboarding_screen` | 2–3 value-proposition slides, CTA to Check Email |
| `check_email_screen` | Single email field, branches to Login/Sign Up |
| `login_screen` | Email + password, Forgot password link |
| `signup_screen` | Name, email, password |
| `verify_email_screen` | 6-digit OTP, resend, timer |
| `forgot_password_screen` | Email only, sends OTP |
| `reset_password_screen` | OTP + new password + confirm |
| `passcode_gate_screen` | 4-digit input, "Use password" fallback |
| `create_passcode_screen` | 4-digit pad, auto-advance |
| `reenter_passcode_screen` | Confirm passcode, persist |
| `complete_profile_screen` | Phone number (required for NGN) |

### 3.2 State Management

**Auth States:**
- `isAuthenticated` — token valid
- `emailVerified` — OTP verified
- `profileComplete` — phone present
- `hasPasscode` — 4-digit stored locally

**Session:**
- Access + refresh tokens in secure storage
- Token refresh on 401
- Logout clears tokens + passcode

**Passcode vs Password:**
- **Password** = server auth (login, reset) — never stored plain
- **Passcode** = local device unlock, stored hashed in secure storage
- "Use password" = navigate to Login, bypass passcode

**Recommended:** Provider or Riverpod for auth state; simple `ChangeNotifier` or `StateNotifier` for MVP. BLoC/Riverpod for larger teams.

---

## 4. Dashboard Architecture

### 4.1 Shell + Tabs

```
┌──────────────────────────────────────────────────────────────────┐
│                     DASHBOARD SHELL                                │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                                                              │  │
│  │                    IndexedStack / PageView                   │  │
│  │                    (Tab content)                             │  │
│  │                                                              │  │
│  │   [Home]  [Bills]  [Invest]  [Card]  [More]                  │  │
│  │                                                              │  │
│  └────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │           GLASSMORPHISM BOTTOM NAV BAR (5 tabs)             │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### 4.2 Tab Features

| Tab | Feature | Responsibility |
|-----|---------|----------------|
| **Home** | USDC balance, recent transactions, fund CTA | Primary savings view |
| **Bills** | Bill payments (placeholder) | Future: pay bills |
| **Invest** | Investment products (placeholder) | Future: invest USDC |
| **Card** | Virtual card (placeholder) | Future: spend USDC |
| **More** | Settings, profile, logout | Account & app settings |

### 4.3 Navigation Stack Isolation

- Each tab has its own `Navigator` (nested) or `PageStorageKey`
- Tab switch preserves stack per tab
- Dashboard shell does **not** own business logic — each tab feature does

### 4.4 Dashboard Responsibilities

- Orchestrate tab switching
- Render `AppBottomNavBar`
- Provide `Scaffold` with `IndexedStack`/`PageView` for tab content
- No API calls, no domain logic

---

## 5. UI System & Components

### 5.1 Components (`core/components/`)

| Component | Purpose |
|-----------|---------|
| `PrimaryButton` | Main CTA (filled, brand color) |
| `SecondaryButton` | Secondary actions (outlined/ghost) |
| `AppTextField` | Text input with label, error, optional suffix |
| `OTPInput` | 6-digit OTP boxes with auto-focus |
| `AppBottomNavBar` | 5-tab bottom nav (glass style) |

### 5.2 Design Tokens

- **Spacing:** `4, 8, 12, 16, 24, 32, 48`
- **Radius:** `8, 12, 16, 24`
- **Typography:** Header (Unbounded), Body (Fustat or similar)
- **Colors:** Primary, surface, error, success — defined in tokens

### 5.3 Reusability

- Auth and dashboard both use `PrimaryButton`, `AppTextField`
- `OTPInput` used in Verify Email and Reset Password
- `AppBottomNavBar` in dashboard shell only

---

## 6. Glassmorphism Bottom Bar

### 6.1 Approach

- **Background:** `BackdropFilter` + `ImageFilter.blur` (sigma ~10–20)
- **Color:** Semi-transparent white (light) / dark (dark mode)
- **Elevation:** Subtle shadow or `Barrier`-style overlay
- **iOS:** `BlurEffect`-style via `Cupertino` or `dart:ui` `ImageFilter`

### 6.2 Architecture

- Component lives in `core/components/app_bottom_nav_bar.dart`
- Wraps `BottomNavigationBar` or custom `Row` of nav items
- Uses `ClipRect` + `BackdropFilter` for blur
- Theme-aware: opacity & color from `Theme.of(context)`

### 6.3 Production Notes

- Test on low-end devices (blur can be costly)
- Fallback: opaque background if blur unsupported
- Safe area insets for devices with home indicator

---

## 7. Theming (Light & Dark)

### 7.1 Structure

```
core/theme/
├── app_theme.dart       # Main factory, selects light/dark
├── light_theme.dart     # Light ThemeData
├── dark_theme.dart     # Dark ThemeData
├── theme_extensions.dart
└── tokens/
    ├── colors.dart
    ├── spacing.dart
    └── typography.dart
```

### 7.2 Light Theme

- Primary: Indigo/purple (e.g. `#4F46E5`)
- Surface: White / light gray
- OnSurface: Dark gray / black
- Error: Red

### 7.3 Dark Theme

- Primary: Lighter indigo
- Surface: Dark gray (#1F2937)
- OnSurface: White / light gray
- Error: Lighter red

### 7.4 Theme Switching

- Store preference in `SharedPreferences` or `SecureStorage`
- `ThemeMode.system` | `ThemeMode.light` | `ThemeMode.dark`
- `MaterialApp(themeMode: themeMode)` driven by provider/notifier
- Switching in More tab → Settings

### 7.5 Theme Tokens

- Define in `tokens/` — single source of truth
- `light_theme.dart` and `dark_theme.dart` consume tokens
- Extensions: `Theme.of(context).extension<AppColors>()` for custom colors

---

## 8. Navigation Strategy

### 8.1 Auth → Dashboard Transition

```
Auth flow completes (Re-enter Passcode success)
    │
    ▼
Navigator.pushNamedAndRemoveUntil('/dashboard', (r) => false)
    │
    ▼
Dashboard shell with 5 tabs
```

### 8.2 Passcode Gate Overlay

- **Not an overlay** — Passcode Gate is a **full-screen route** before Dashboard
- Auth Gate decides: token + passcode → Passcode Gate; token only → Dashboard
- Passcode Gate success → `pushNamedAndRemoveUntil('/dashboard', ...)`

### 8.3 Deep Links

| Link | Handling |
|------|----------|
| Email verify | `/auth/verify-email?email=x&token=y` — parse, pre-fill email, validate token |
| Reset password | `/auth/reset-password?email=x&token=y` — same pattern |
| Implementation: `go_router` or `MaterialApp.onGenerateRoute` with query parsing |

### 8.4 Guarded Routes

| Guard | Protects | Logic |
|-------|----------|-------|
| `AuthGuard` | Dashboard, tabs | Redirect to Onboarding if no token |
| `PasscodeGuard` | Dashboard | Redirect to Passcode Gate if token but no passcode / session locked |
| Implementation: Middleware in router or wrapper widget that checks auth state |

### 8.5 Route Registry

```
/                     → AuthGate (redirects)
/onboarding           → Onboarding
/auth/check-email     → Check Email
/auth/login           → Login
/auth/signup          → Sign Up
/auth/verify-email     → Verify Email
/auth/forgot-password  → Forgot Password
/auth/reset-password   → Reset Password
/auth/passcode        → Passcode Gate
/auth/create-passcode → Create Passcode
/auth/reenter-passcode→ Re-enter Passcode
/auth/complete-profile→ Complete Profile
/dashboard            → Dashboard Shell
```

---

## 9. Optional Next Steps (Do Not Implement Yet)

- **State machine** — Formalize auth states (e.g. `flutter_bloc` + `bloc` or `state_notifier`)
- **API mapping** — Document each auth screen → backend endpoint
- **Biometric auth** — Option in Passcode Gate (Face ID / fingerprint)
- **Device trust** — Track trusted devices, require re-auth on new device

---

*Document version: 1.0 | Stakk USDC Savings App | MVP → Series A*
