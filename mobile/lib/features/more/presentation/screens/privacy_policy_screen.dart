import 'package:flutter/material.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';

/// Privacy Policy for Stakk. App Store / Play Store compliant.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        title: Text(
          'Privacy Notice',
          style: AppTheme.header(context: context, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 32 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEffectiveDate(context, 'Effective Date: February 7, 2026'),
                    const SizedBox(height: 24),
                    _buildSection(context, '1. Introduction', [
                      'Stakk ("we," "our," or "us") is committed to protecting your privacy. This Privacy Notice explains how we collect, use, share, and safeguard your personal data when you use our Services.',
                      'We are a financial technology platform that enables USDC savings, bill payments, peer-to-peer transfers, and withdrawals. Your trust is important to us, and we take the protection of your personal information seriously.',
                      'This notice applies to all users of our mobile application, website, and related services. By using our Services, you consent to the practices described in this notice.',
                    ]),
                    _buildSection(context, '2. Information We Collect', [
                      'We may collect the following categories of personal data:',
                      'Identity Information: Your full name, email address, phone number, date of birth, and government-issued identification where required for verification.',
                      'Financial Information: Bank account details (for withdrawals), Stellar wallet addresses, transaction history, savings goals, and payment preferences.',
                      'Device and Technical Information: IP address, device type, operating system, unique device identifiers, app version, and usage data (e.g., pages visited, features used).',
                      'Verification Data: Bank Verification Number (BVN), national ID, or other KYC documents as required by regulations.',
                      'Communications: Records of your correspondence with us, including support tickets and feedback.',
                      'Location Data: General location (country/region) inferred from your IP address, where applicable for compliance.',
                    ]),
                    _buildSection(context, '3. How We Collect Information', [
                      'Directly from you: When you register, complete your profile, make transactions, contact support, or participate in surveys.',
                      'Automatically: When you use our app (e.g., device info, analytics, crash reports).',
                      'From third parties: Payment processors (Paystack, Flutterwave), identity verification providers, banking partners, and regulatory databases where permitted.',
                      'From public sources: To verify identity or comply with anti-money laundering (AML) requirements.',
                    ]),
                    _buildSection(context, '4. How We Use Information', [
                      'We use your personal data to:',
                      'Provide and operate our Services: Process USDC savings, bill payments, P2P transfers, and bank withdrawals.',
                      'Verify your identity: Comply with KYC, AML, and anti-fraud regulations.',
                      'Process transactions: Execute deposits, withdrawals, and payments with our partners.',
                      'Communicate with you: Send transactional emails, security alerts, product updates, and respond to inquiries.',
                      'Detect and prevent fraud: Monitor for suspicious activity and protect your account.',
                      'Improve our services: Analyze usage patterns, fix bugs, and develop new features.',
                      'Comply with legal obligations: Respond to regulatory requests, court orders, and applicable laws.',
                      'Marketing (with consent): Send promotional offers; you may opt out at any time.',
                    ]),
                    _buildSection(context, '5. Legal Basis for Processing', [
                      'We process your data based on:',
                      'Contract: To perform our agreement with you (e.g., processing payments).',
                      'Legal obligation: To comply with KYC, AML, tax, and regulatory requirements.',
                      'Legitimate interests: To prevent fraud, improve services, and ensure security.',
                      'Consent: Where required (e.g., marketing communications).',
                    ]),
                    _buildSection(context, '6. How We Share Information', [
                      'We may share your data with:',
                      'Payment and banking partners: To process deposits, withdrawals, and bill payments (e.g., Paystack, Flutterwave, banks).',
                      'Blockchain and wallet providers: Stellar network for USDC transactions.',
                      'Regulatory authorities and law enforcement: When required by law, court order, or to prevent fraud.',
                      'Service providers: Cloud hosting, analytics, customer support, and identity verification (under strict data processing agreements).',
                      'We never sell your personal data to third parties for marketing purposes.',
                    ]),
                    _buildSection(context, '7. Data Retention', [
                      'We retain personal data for as long as your account is active and for a period thereafter as required by law.',
                      'Transaction records: At least 5 years after the transaction or as required by financial regulations.',
                      'Account data: Until account closure, plus retention for legal, regulatory, or dispute resolution purposes.',
                      'KYC/AML records: As required by applicable regulations (typically 5–7 years).',
                      'After retention periods, we securely delete or anonymize your data.',
                    ]),
                    _buildSection(context, '8. Your Rights', [
                      'Depending on your jurisdiction, you may have rights to:',
                      'Access: Request a copy of the personal data we hold about you.',
                      'Rectification: Correct inaccurate or incomplete data.',
                      'Erasure: Request deletion of your data (subject to legal retention requirements).',
                      'Restriction: Limit how we process your data in certain circumstances.',
                      'Objection: Object to processing based on legitimate interests or for marketing.',
                      'Portability: Receive your data in a structured, machine-readable format.',
                      'Withdraw consent: Where processing is based on consent.',
                      'To exercise your rights, email privacy@stakk.com. We will respond within 30 days. You may also have the right to lodge a complaint with a supervisory authority.',
                    ]),
                    _buildSection(context, '9. Security Measures', [
                      'We use industry-standard safeguards to protect your data:',
                      'Encryption: Data in transit (TLS/SSL) and at rest (AES-256 where applicable).',
                      'Access controls: Role-based access, strong authentication, and audit logs.',
                      'Secure storage: Credentials and sensitive data stored using secure enclaves and hashing.',
                      'Monitoring: 24/7 monitoring for suspicious activity and security incidents.',
                      'Staff training: Regular training on data protection and security practices.',
                      'Incident response: We have procedures to detect, respond to, and notify you of data breaches where required.',
                    ]),
                    _buildSection(context, '10. Cookies and Tracking', [
                      'Our app may use cookies, local storage, or similar technologies for:',
                      'Authentication: Keeping you logged in and secure.',
                      'Preferences: Remembering your settings.',
                      'Analytics: Understanding how you use our app (aggregated, anonymized where possible).',
                      'You can manage cookie preferences in your device settings.',
                    ]),
                    _buildSection(context, '11. International Data Transfers', [
                      'Your data may be transferred to and processed in countries outside your residence (e.g., cloud servers, partner services).',
                      'We ensure appropriate safeguards are in place, such as:',
                      'Standard contractual clauses approved by regulators.',
                      'Adequacy decisions where the destination country is deemed adequate.',
                      'Your consent where required.',
                    ]),
                    _buildSection(context, '12. Children\'s Privacy', [
                      'Our Services are not intended for individuals under 18 years of age.',
                      'We do not knowingly collect personal data from children. If you believe we have collected data from a minor, please contact us at privacy@stakk.com and we will take steps to delete it.',
                    ]),
                    _buildSection(context, '13. Updates to this Notice', [
                      'We may update this Privacy Notice to reflect changes in law, regulations, or our practices.',
                      'Material changes will be communicated via in-app notification, email, or prominent notice on our platforms.',
                      'We encourage you to review this notice periodically. Continued use after updates constitutes acceptance.',
                    ]),
                    _buildSection(context, '14. Contact Us', [
                      'For privacy-related questions, requests, or complaints:',
                      'Email: privacy@stakk.com',
                      'Support: support@stakk.com',
                      'We aim to respond to all inquiries within 30 days.',
                    ]),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEffectiveDate(BuildContext context, String date) {
    return Text(
      date,
      style: AppTheme.body(context: context, fontSize: 14).copyWith(fontStyle: FontStyle.italic),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.title(context: context, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...content.map(
          (paragraph) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              paragraph,
              style: AppTheme.body(context: context, fontSize: 15, fontWeight: FontWeight.w400),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
