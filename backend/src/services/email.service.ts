import nodemailer from 'nodemailer';
import { Resend } from 'resend';

/** Send OTP email - uses Resend (HTTP API) or SMTP providers */
export async function sendOTPEmail(email: string, code: string, purpose: 'signup' | 'login' | 'password_reset'): Promise<void> {
  const subject = purpose === 'signup'
    ? 'Welcome to Stakk - Verify your email'
    : purpose === 'password_reset'
      ? 'Reset your Stakk password'
      : 'Your Stakk login code';

  const subtitle = purpose === 'signup'
    ? 'Verify your email'
    : purpose === 'password_reset'
      ? 'Reset your password'
      : 'Your login code';

  const html = `
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><style>
body{font-family:system-ui,sans-serif;line-height:1.6;color:#333;margin:0;padding:20px}
.container{max-width:400px;margin:0 auto;background:#fff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.1)}
.header{background:linear-gradient(135deg,#4F46E5,#7C3AED);color:#fff;padding:24px;text-align:center}
.code{font-size:32px;font-weight:700;letter-spacing:8px;color:#4F46E5;text-align:center;padding:24px;background:#f8fafc;margin:16px}
.expiry{font-size:14px;color:#6b7280;text-align:center;padding:16px}
</style></head>
<body><div class="container">
<div class="header"><h1 style="margin:0">Stakk</h1><p style="margin:8px 0 0">${subtitle}</p></div>
<div class="code">${code}</div>
<div class="expiry">This code expires in 5 minutes. Never share it with anyone.</div>
</div></body></html>`;

  const from = process.env.EMAIL_FROM || 'onboarding@resend.dev';

  // Resend - HTTP API, no SMTP, works reliably from Railway
  if (process.env.EMAIL_SERVICE === 'resend') {
    const apiKey = process.env.RESEND_API_KEY?.trim();
    if (!apiKey || apiKey.length < 10) {
      throw new Error('RESEND_API_KEY is missing or invalid. Add it in Railway Variables (exact name: RESEND_API_KEY). Get free key at resend.com');
    }
    const resend = new Resend(apiKey);
    const { error } = await resend.emails.send({
      from: `Stakk <${from}>`,
      to: email,
      subject,
      html,
    });
    if (error) throw new Error(`Resend: ${error.message}`);
    return;
  }

  // SendGrid SMTP
  if (process.env.EMAIL_SERVICE === 'sendgrid') {
    const transporter = nodemailer.createTransport({
      host: 'smtp.sendgrid.net',
      port: 587,
      auth: {
        user: 'apikey',
        pass: process.env.SENDGRID_API_KEY,
      },
    });
    await transporter.sendMail({ from: `Stakk <${from}>`, to: email, subject, html });
    return;
  }

  // Gmail or custom SMTP
  const transporter = nodemailer.createTransport(
    process.env.EMAIL_SERVICE === 'gmail'
      ? {
          service: 'gmail',
          auth: {
            user: process.env.GMAIL_USER,
            pass: process.env.GMAIL_APP_PASSWORD,
          },
        }
      : {
          host: process.env.SMTP_HOST || 'smtp.gmail.com',
          port: Number(process.env.SMTP_PORT) || 587,
          auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASSWORD,
          },
        }
  );
  await transporter.sendMail({
    from: `Stakk <${from}>`,
    to: email,
    subject,
    html,
  });
}
