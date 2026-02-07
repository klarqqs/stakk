import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport(
  process.env.EMAIL_SERVICE === 'sendgrid'
    ? {
        host: 'smtp.sendgrid.net',
        port: 587,
        auth: {
          user: 'apikey',
          pass: process.env.SENDGRID_API_KEY
        }
      }
    : process.env.EMAIL_SERVICE === 'gmail'
      ? {
          service: 'gmail',
          auth: {
            user: process.env.GMAIL_USER,
            pass: process.env.GMAIL_APP_PASSWORD
          }
        }
      : {
          host: process.env.SMTP_HOST || 'smtp.gmail.com',
          port: Number(process.env.SMTP_PORT) || 587,
          auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASSWORD
          }
        }
);

export async function sendOTPEmail(email: string, code: string, purpose: 'signup' | 'login'): Promise<void> {
  const subject = purpose === 'signup'
    ? 'Welcome to KLYNG - Verify your email'
    : 'Your KLYNG login code';

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
<div class="header"><h1 style="margin:0">KLYNG</h1><p style="margin:8px 0 0">${purpose === 'signup' ? 'Verify your email' : 'Your login code'}</p></div>
<div class="code">${code}</div>
<div class="expiry">This code expires in 5 minutes. Never share it with anyone.</div>
</div></body></html>`;

  await transporter.sendMail({
    from: `"KLYNG" <${process.env.EMAIL_FROM || 'noreply@klyng.ng'}>`,
    to: email,
    subject,
    html
  });
}
