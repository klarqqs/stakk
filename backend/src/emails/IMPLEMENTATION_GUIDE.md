# STAKK Email Templates - Implementation Guide

## 📋 Template Status

### ✅ Completed Templates
- `auth/welcome.html` - Welcome email for new users
- `auth/email-verification.html` - Email verification OTP
- `auth/resend-otp.html` - Generic OTP resend

### 🔄 Templates to Create

All templates follow the same structure as the completed ones. Use the base template structure and adapt content for each use case.

## 📝 Template Creation Pattern

Each template should include:

1. **Header Section** - STAKK logo/branding
2. **Title & Subtitle** - Clear, action-oriented messaging
3. **Greeting** - Personalized with {{firstName}}
4. **Main Content** - Context-specific information
5. **Action Items** (if applicable) - What user can do next
6. **Security Warnings** (if applicable) - For sensitive operations
7. **CTA Button** (if applicable) - Primary action
8. **FAQ Section** - Link to help resources
9. **Footer** - Support links and copyright

## 🎨 Design Guidelines

### Colors
- Primary: `#4F46E5` (Indigo)
- Secondary: `#3B82F6` (Blue)
- Success: `#059669` (Green)
- Error: `#DC2626` (Red)
- Warning: `#F59E0B` (Amber)
- Background: `#F8FAFC` (Light), `#1F2937` (Dark)
- Text Primary: `#0F172A`
- Text Secondary: `#64748B`

### Typography
- Headings: Unbounded (700 weight)
- Body: Inter (400-600 weight)
- Code/Amounts: Unbounded (700 weight, larger size)

### Components
- Verification codes: Large, centered, gradient background
- Transaction details: Card-style with rows
- Success banners: Green gradient with checkmark
- Error banners: Red gradient with X icon
- Security warnings: Yellow gradient with warning icon

## 📧 Template Specifications

### Auth Templates

#### `auth/password-reset-request.html`
- **Subject**: Reset Your STAKK Password
- **Variables**: `firstName`, `otpCode`, `expiryMinutes`
- **Content**: OTP code for password reset, security warning

#### `auth/password-reset-success.html`
- **Subject**: Password Updated Successfully
- **Variables**: `firstName`, `timestamp`
- **Content**: Confirmation message, security warning if not user

#### `auth/login-alert.html`
- **Subject**: New Login Detected on Your STAKK Account
- **Variables**: `firstName`, `deviceInfo`, `location`, `ipAddress`, `timestamp`
- **Content**: Login details, security warning, action to take if suspicious

#### `auth/passcode-created.html`
- **Subject**: Transaction Passcode Set Successfully
- **Variables**: `firstName`, `timestamp`
- **Content**: Confirmation, security reminder

#### `auth/passcode-verification.html`
- **Subject**: Verify Your Identity to Reset Passcode
- **Variables**: `firstName`, `otpCode`, `expiryMinutes`
- **Content**: OTP code, security context

### Wallet Templates

#### `wallet/funding-success.html`
- **Subject**: Wallet Funded Successfully
- **Variables**: `firstName`, `amount`, `currency`, `balance`, `transactionId`, `transactionDate`
- **Content**: Success banner, transaction details, next steps

#### `wallet/funding-failed.html`
- **Subject**: Wallet Funding Failed
- **Variables**: `firstName`, `amount`, `currency`, `failureReason`, `transactionId`
- **Content**: Error banner, failure reason, retry CTA, support link

#### `wallet/funding-confirmation.html`
- **Subject**: Funding Confirmation
- **Variables**: `firstName`, `amount`, `currency`, `paymentMethod`, `transactionId`
- **Content**: Confirmation details, processing status

### Transaction Templates

#### `transactions/transfer-success.html`
- **Subject**: Transfer Completed Successfully
- **Variables**: `firstName`, `amount`, `currency`, `recipientName`, `transactionId`, `transactionDate`
- **Content**: Success banner, transaction summary, receipt link

#### `transactions/transfer-failed.html`
- **Subject**: Transfer Unsuccessful
- **Variables**: `firstName`, `amount`, `currency`, `recipientName`, `failureReason`
- **Content**: Error banner, failure reason, retry CTA

#### `transactions/transfer-received.html`
- **Subject**: You Received USDC
- **Variables**: `firstName`, `amount`, `currency`, `senderName`, `transactionId`, `transactionDate`, `balance`
- **Content**: Success banner, transaction details, new balance

#### `transactions/transfer-reminder.html`
- **Subject**: Complete Your Transfer
- **Variables**: `firstName`, `amount`, `currency`, `recipientName`
- **Content**: Reminder message, complete transfer CTA

### Savings Templates

#### `savings/savings-plan-created.html`
- **Subject**: Savings Goal Created
- **Variables**: `firstName`, `goalName`, `targetAmount`, `currency`, `targetDate`
- **Content**: Goal details, encouragement message

#### `savings/savings-contribution.html`
- **Subject**: Savings Contribution Successful
- **Variables**: `firstName`, `amount`, `currency`, `goalName`, `progress`, `balance`
- **Content**: Contribution confirmation, progress update

#### `savings/savings-withdrawal.html`
- **Subject**: Savings Withdrawal Alert
- **Variables**: `firstName`, `amount`, `currency`, `goalName`, `balance`, `transactionId`
- **Content**: Withdrawal confirmation, balance update

#### `savings/goal-achieved.html`
- **Subject**: Congratulations! Goal Achieved
- **Variables**: `firstName`, `goalName`, `targetAmount`, `currency`, `achievedDate`
- **Content**: Celebration message, achievement details, next steps

### Billing Templates

#### `billing/bill-payment-success.html`
- **Subject**: Bill Payment Successful
- **Variables**: `firstName`, `amount`, `currency`, `billType`, `billProvider`, `transactionId`
- **Content**: Success confirmation, bill details

#### `billing/bill-payment-failed.html`
- **Subject**: Bill Payment Failed
- **Variables**: `firstName`, `amount`, `currency`, `billType`, `failureReason`
- **Content**: Error message, retry CTA

#### `billing/subscription-reminder.html`
- **Subject**: Subscription Renewal Reminder
- **Variables**: `firstName`, `subscriptionType`, `amount`, `currency`, `renewalDate`
- **Content**: Reminder message, renewal details

### Security Templates

#### `security/password-changed.html`
- **Subject**: Password Changed Successfully
- **Variables**: `firstName`, `timestamp`, `deviceInfo`, `location`
- **Content**: Confirmation, security warning if not user

#### `security/email-changed.html`
- **Subject**: Email Address Updated
- **Variables**: `firstName`, `oldEmail`, `newEmail`, `timestamp`
- **Content**: Change confirmation, security warning

#### `security/phone-changed.html`
- **Subject**: Phone Number Updated
- **Variables**: `firstName`, `oldPhone`, `newPhone`, `timestamp`
- **Content**: Change confirmation, security warning

#### `security/suspicious-login.html`
- **Subject**: Suspicious Login Detected
- **Variables**: `firstName`, `deviceInfo`, `location`, `ipAddress`, `timestamp`
- **Content**: Alert message, security actions, support link

## 🚀 Quick Template Generator

Use this pattern for creating new templates:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <!-- Copy head section from auth/welcome.html -->
</head>
<body>
    <div class="email-wrapper">
        <div class="email-container">
            <div class="email-header-logo">
                <div class="email-header-logo-text">STAKK</div>
            </div>
            <div class="email-content">
                <h1 class="email-title">Your Title Here</h1>
                <p class="email-subtitle">Your subtitle</p>
                
                <p class="greeting">Hello {{firstName}},</p>
                
                <p class="main-content">
                    Your main message here.
                </p>
                
                <!-- Add transaction details, verification codes, etc. as needed -->
                
                <div class="closing">
                    <p>Closing message</p>
                    <p class="team-signature">The STAKK Team</p>
                </div>
            </div>
            <div class="footer">
                <!-- Copy footer from auth/welcome.html -->
            </div>
        </div>
    </div>
</body>
</html>
```

## 📦 Next Steps

1. Create remaining templates using the patterns above
2. Test each template with sample data
3. Verify rendering in major email clients
4. Update email service to use all templates
5. Integrate with Resend/SendGrid

## 🔍 Testing

For each template:
1. Replace all variables with sample data
2. Test in Gmail, Outlook, Apple Mail
3. Verify mobile responsiveness
4. Check accessibility (color contrast, alt text)
5. Validate HTML structure

---

**Note**: All templates should maintain STAKK's premium, secure, modern fintech aesthetic while being clear and actionable.
