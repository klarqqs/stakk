# STAKK Email Templates

Professional, responsive email templates for STAKK - Save in USDC, protected from inflation.

## 📧 Template Architecture

### Structure
```
emails/
├── base-template.html          # Base template with STAKK branding
├── partials/                    # Reusable components
│   ├── header.html
│   ├── footer.html
│   └── app-buttons.html
├── auth/                        # Authentication & Security
│   ├── welcome.html
│   ├── email-verification.html
│   ├── resend-otp.html
│   ├── password-reset-request.html
│   ├── password-reset-success.html
│   ├── login-alert.html
│   ├── passcode-created.html
│   └── passcode-verification.html
├── wallet/                      # Wallet & Funding
│   ├── funding-success.html
│   ├── funding-failed.html
│   └── funding-confirmation.html
├── transactions/                # Transfers & Payments
│   ├── transfer-success.html
│   ├── transfer-failed.html
│   ├── transfer-received.html
│   └── transfer-reminder.html
├── savings/                     # Savings & Goals
│   ├── savings-plan-created.html
│   ├── savings-contribution.html
│   ├── savings-withdrawal.html
│   └── goal-achieved.html
├── billing/                     # Bills & Services
│   ├── bill-payment-success.html
│   ├── bill-payment-failed.html
│   └── subscription-reminder.html
└── security/                    # Security Alerts
    ├── password-changed.html
    ├── email-changed.html
    ├── phone-changed.html
    └── suspicious-login.html
```

## 🎨 Design Specifications

- **Primary Color**: #4F46E5 (Indigo)
- **Secondary Color**: #3B82F6 (Blue)
- **Background**: #F8FAFC (Light), #1F2937 (Dark)
- **Font**: Inter (body), Unbounded (headings)
- **Style**: Modern, premium, secure fintech aesthetic
- **Layout**: Mobile-first responsive design

## 📱 Responsive Features

- Mobile-first design (320px+)
- Tablet optimization (768px+)
- Desktop layout (1024px+)
- Dark mode compatible
- Accessible (WCAG 2.1 AA)
- Inline CSS for email client compatibility

## 🔧 Template Variables

### Common Variables
```javascript
{
  // User Information
  firstName: "John",
  lastName: "Doe",
  fullName: "John Doe",
  email: "john@example.com",
  
  // App Information
  appName: "STAKK",
  appUrl: "https://stakk.app",
  supportEmail: "support@stakk.app",
  faqUrl: "https://stakk.app/faq",
  supportUrl: "https://stakk.app/support",
  
  // App Store Links
  googlePlayUrl: "https://play.google.com/store/apps/details?id=com.stakk.stakkSavings",
  appStoreUrl: "https://apps.apple.com/app/stakk/id123456789",
  
  // Branding
  logoUrl: "https://stakk.app/assets/logo.png",
  primaryColor: "#4F46E5",
  
  // Dates
  currentDate: "February 7, 2026",
  currentYear: "2026"
}
```

### Transaction Variables
```javascript
{
  amount: "1,000.00",
  currency: "USDC",
  balance: "5,000.00",
  transactionId: "TXN-123456789",
  transactionDate: "February 7, 2026 at 2:30 PM",
  recipientName: "Jane Smith",
  senderName: "John Doe",
  transferType: "USDC Transfer"
}
```

### Security Variables
```javascript
{
  otpCode: "123456",
  expiryMinutes: 10,
  deviceInfo: "iPhone 14 Pro, iOS 17.2",
  location: "Lagos, Nigeria",
  ipAddress: "192.168.1.1",
  timestamp: "February 7, 2026 at 2:30 PM"
}
```

## 🚀 Usage

### Node.js/TypeScript Example

```typescript
import { renderEmailTemplate } from './services/email.service';
import { readFileSync } from 'fs';
import { join } from 'path';

// Load template
const template = readFileSync(
  join(__dirname, 'emails/auth/welcome.html'),
  'utf-8'
);

// Replace variables
const html = renderEmailTemplate(template, {
  firstName: user.firstName,
  lastName: user.lastName,
  appName: 'STAKK',
  supportEmail: 'support@stakk.app',
  faqUrl: 'https://stakk.app/faq',
  googlePlayUrl: 'https://play.google.com/store/apps/details?id=com.stakk.stakkSavings',
  appStoreUrl: 'https://apps.apple.com/app/stakk/id123456789',
});

// Send via Resend/SendGrid/etc
await sendEmail({
  to: user.email,
  subject: 'Welcome to STAKK — Start Saving in USDC',
  html,
});
```

## ✅ Testing Checklist

- [ ] All templates render correctly in Gmail, Outlook, Apple Mail
- [ ] Dynamic variables are properly replaced
- [ ] Images load correctly (logo, app store buttons)
- [ ] Links are functional
- [ ] Mobile responsiveness works (320px, 768px, 1024px)
- [ ] Dark mode compatibility verified
- [ ] Accessibility (screen readers, color contrast)
- [ ] Email client compatibility (Gmail, Outlook, Yahoo, Apple Mail)

## 📞 Support

For questions about template implementation, contact the development team.

---

**STAKK** - Save in USDC, protected from inflation.
