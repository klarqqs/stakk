import { readFileSync } from 'fs';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export interface EmailVariables {
  // User Information
  firstName?: string;
  lastName?: string;
  fullName?: string;
  email?: string;
  
  // App Information
  appName?: string;
  appUrl?: string;
  supportEmail?: string;
  faqUrl?: string;
  supportUrl?: string;
  logoUrl?: string;
  
  // App Store Links
  googlePlayUrl?: string;
  appStoreUrl?: string;
  
  // Transaction Data
  amount?: string;
  currency?: string;
  balance?: string;
  transactionId?: string;
  transactionDate?: string;
  recipientName?: string;
  senderName?: string;
  transferType?: string;
  
  // Security
  otpCode?: string;
  expiryMinutes?: number;
  deviceInfo?: string;
  location?: string;
  ipAddress?: string;
  timestamp?: string;
  
  // Other
  emailTitle?: string;
  currentDate?: string;
  currentYear?: string;
  failureReason?: string;
  [key: string]: any;
}

/**
 * Replace template variables with actual values
 */
function replaceVariables(template: string, variables: EmailVariables): string {
  let html = template;
  
  // Default values
  const defaults: EmailVariables = {
    appName: 'STAKK',
    appUrl: 'https://stakk.app',
    supportEmail: 'support@stakk.app',
    faqUrl: 'https://stakk.app/faq',
    supportUrl: 'https://stakk.app/support',
    googlePlayUrl: 'https://play.google.com/store/apps/details?id=com.stakk.stakkSavings',
    appStoreUrl: 'https://apps.apple.com/app/stakk/id123456789',
    currentYear: new Date().getFullYear().toString(),
    currentDate: new Date().toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'long', 
      day: 'numeric' 
    }),
    currency: 'USDC',
  };
  
  const allVariables = { ...defaults, ...variables };
  
  // Replace {{variable}} patterns
  html = html.replace(/\{\{(\w+)\}\}/g, (match, key) => {
    const value = allVariables[key];
    return value !== undefined ? String(value) : match;
  });
  
  // Replace {{#if variable}}...{{/if}} patterns (simple conditional)
  html = html.replace(/\{\{#if\s+(\w+)\}\}([\s\S]*?)\{\{\/if\}\}/g, (match, key, content) => {
    const value = allVariables[key];
    return value ? content : '';
  });
  
  return html;
}

/**
 * Load and render an email template
 */
export function renderEmailTemplate(
  templateName: string,
  variables: EmailVariables
): string {
  const templatePath = join(__dirname, '../emails', `${templateName}.html`);
  
  try {
    const template = readFileSync(templatePath, 'utf-8');
    return replaceVariables(template, variables);
  } catch (error) {
    console.error(`Failed to load email template: ${templateName}`, error);
    throw new Error(`Email template not found: ${templateName}`);
  }
}

/**
 * Get email subject for a template
 */
export function getEmailSubject(templateName: string, variables?: EmailVariables): string {
  const subjects: Record<string, string> = {
    'auth/welcome': 'Welcome to STAKK — Start Saving in USDC',
    'auth/email-verification': 'Verify Your Email | STAKK',
    'auth/resend-otp': 'Your Verification Code | STAKK',
    'auth/password-reset-request': 'Reset Your STAKK Password',
    'auth/password-reset-success': 'Password Updated Successfully',
    'auth/login-alert': 'New Login Detected on Your STAKK Account',
    'auth/passcode-created': 'Transaction Passcode Set Successfully',
    'auth/passcode-verification': 'Verify Your Identity to Reset Passcode',
    'wallet/funding-success': 'Wallet Funded Successfully',
    'wallet/funding-failed': 'Wallet Funding Failed',
    'wallet/funding-confirmation': 'Funding Confirmation',
    'transactions/transfer-success': 'Transfer Completed Successfully',
    'transactions/transfer-failed': 'Transfer Unsuccessful',
    'transactions/transfer-received': 'You Received USDC',
    'transactions/transfer-reminder': 'Complete Your Transfer',
    'savings/savings-plan-created': 'Savings Goal Created',
    'savings/savings-contribution': 'Savings Contribution Successful',
    'savings/savings-withdrawal': 'Savings Withdrawal Alert',
    'savings/goal-achieved': 'Congratulations! Goal Achieved',
    'billing/bill-payment-success': 'Bill Payment Successful',
    'billing/bill-payment-failed': 'Bill Payment Failed',
    'billing/subscription-reminder': 'Subscription Renewal Reminder',
    'security/password-changed': 'Password Changed Successfully',
    'security/email-changed': 'Email Address Updated',
    'security/phone-changed': 'Phone Number Updated',
    'security/suspicious-login': 'Suspicious Login Detected',
  };
  
  return subjects[templateName] || 'Notification from STAKK';
}

/**
 * Email template categories
 */
export const EmailCategories = {
  AUTH: 'auth',
  WALLET: 'wallet',
  TRANSACTIONS: 'transactions',
  SAVINGS: 'savings',
  BILLING: 'billing',
  SECURITY: 'security',
} as const;
