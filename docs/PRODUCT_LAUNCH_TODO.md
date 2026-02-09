# Product Launch Todo List

Checklist for Stakk USDC Savings App launch readiness.

---

## Auth & Identity

- [x] Google Sign-In UI (check-email, onboarding) ✅
- [x] Apple Sign-In UI (check-email, onboarding) ✅
- [x] Firebase project + Google OAuth client IDs (iOS, Android) ✅
- [x] Apple Developer: Sign in with Apple capability ✅
- [x] iOS: `GoogleService-Info.plist` configured ✅ (needs to be added to Xcode project)
- [x] Android: `google-services.json` configured ✅
- [x] Passcode flow works after social sign-in ✅
- [x] Complete profile / passcode for new social users ✅
- [x] Session expiry auto-logout working ✅

---

## Notifications

- [x] FCM (Firebase Cloud Messaging) setup
- [x] Backend: `device_tokens` table + store FCM token
- [x] Backend: Send push when creating in-app notification
- [x] Mobile: Request notification permission
- [x] Mobile: Register FCM token on login
- [x] Mobile: Handle foreground/background messages
- [x] Clear device token on logout
- [ ] Deep linking: notification tap opens correct screen (basic structure in place, customize as needed)

---

## Email

- [ ] OTP emails (signup, login, password reset) – done
- [ ] Welcome email (after signup + verify)
- [ ] P2P received email
- [ ] P2P sent email
- [ ] Bill payment confirmation email
- [ ] Password changed confirmation
- [ ] (Optional) Goal milestone email
- [ ] (Optional) Blend earnings summary

---

## Store Readiness

- [ ] App icons (all sizes)
- [ ] Screenshots (iOS, Android)
- [ ] App description & keywords
- [ ] Privacy policy URL live
- [ ] Terms of service URL live
- [ ] Support contact (email) in store listing

---

## Security & Config

- [ ] All API keys in env (no secrets in repo)
- [ ] Backend env validated on startup
- [ ] Rate limiting on auth endpoints
- [ ] CORS configured for production domains

---

## Testing

- [ ] Smoke test: signup → verify → passcode → dashboard
- [ ] Smoke test: login → passcode → dashboard
- [ ] Session expiry triggers logout
- [ ] Offline / connectivity handling
- [ ] P2P send flow end-to-end
- [ ] Bill payment flow end-to-end

---

## Monitoring (Optional)

- [ ] Error tracking (e.g. Sentry, Firebase Crashlytics)
- [ ] Basic analytics (signup, login, key actions)
- [ ] App version / force update check
