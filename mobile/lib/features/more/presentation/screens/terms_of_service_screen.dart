import 'package:flutter/material.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';
import 'package:stakk_savings/core/theme/tokens/app_colors.dart';

/// Terms of Service for Stakk. App Store / Play Store compliant.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Use',
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
                    _buildEffectiveDate(context, 'Effective Date: February 7, 2025'),
                    const SizedBox(height: 24),
                    _buildSection(context, '1. Introduction', [
                      'Welcome to Stakk ("we," "our," or "us"). These Terms of Use ("Terms") govern your access to and use of our products and services, including the Stakk mobile application, website, and related platforms (collectively, the "Services").',
                      'By creating an account, accessing, or using our Services, you agree to be bound by these Terms. If you do not agree with any part of these Terms, you must not use our Services.',
                      'These Terms form a legally binding agreement between you and Stakk. Please read them carefully and keep a copy for your records.',
                    ]),
                    _buildSection(context, '2. Eligibility', [
                      'To use our Services, you must:',
                      'Be at least 18 years old (or the legal age of majority in your jurisdiction).',
                      'Have the legal capacity to enter into a binding contract.',
                      'Not be located in, or a resident or citizen of, any country subject to comprehensive sanctions (e.g., Iran, North Korea, Syria, or countries designated by relevant authorities).',
                      'Pass all required identity verification (KYC) and anti-money laundering (AML) checks where applicable.',
                      'Not have been previously banned or suspended from our Services.',
                      'Comply with all applicable laws in your jurisdiction regarding the use of financial and digital asset services.',
                    ]),
                    _buildSection(context, '3. Account Registration and Security', [
                      'To access the Services, you must create an account and provide accurate, current, and complete information (e.g., name, email, phone number).',
                      'You are responsible for maintaining the confidentiality of your account credentials (password, passcode, or biometrics). You agree to notify us immediately of any unauthorized access.',
                      'You agree to promptly update your information if it changes. We may suspend or terminate your account if you provide false, incomplete, or misleading information.',
                      'You may only hold one account unless we explicitly approve otherwise. Creating multiple accounts to circumvent limits or restrictions is prohibited.',
                    ]),
                    _buildSection(context, '4. Services Overview', [
                      'Stakk provides a platform for USDC savings, bill payments, and transfers. Our key services include:',
                      'USDC Savings: Hold and save USDC (a stablecoin on the Stellar network) in your Stakk wallet.',
                      'Savings Goals: Create and fund savings goals with target amounts and deadlines.',
                      'Lock Savings: Lock USDC for a fixed period (30–180 days) to earn higher APY.',
                      'Bill Payments: Pay for airtime, data, DSTV, electricity, and other bills using USDC.',
                      'P2P Transfers: Send USDC to other Stakk users or Stellar wallet addresses.',
                      'Bank Withdrawals: Withdraw USDC to Nigerian bank accounts (NGN) via our partners.',
                      'Blend Earnings: Earn APY on idle USDC through the Blend Protocol integration.',
                      'Service availability, features, and limits may vary by region and verification level.',
                    ]),
                    _buildSection(context, '5. Prohibited Uses', [
                      'You agree not to use the Services for:',
                      'Money laundering, terrorist financing, tax evasion, or other illegal activities.',
                      'Transactions involving sanctioned individuals, entities, or countries.',
                      'Fraud, scams, phishing, or misrepresentation.',
                      'Interference with the security, integrity, or availability of our systems or networks.',
                      'Circumventing our security measures, limits, or verification requirements.',
                      'Using the Services in violation of any applicable law or regulation.',
                      'We may suspend or terminate your account, freeze funds, and report activity to regulators or law enforcement if prohibited use is detected. We are not obligated to provide advance notice in such cases.',
                    ]),
                    _buildSection(context, '6. Fees and Charges', [
                      'Stakk may charge transaction fees, withdrawal fees, or other service-related fees. All applicable fees will be clearly disclosed before you confirm a transaction.',
                      'By confirming a transaction, you agree to pay all applicable fees. Fees are non-refundable unless otherwise required by law.',
                      'We may change our fee structure from time to time. Material fee changes will be communicated via in-app notification or email. Continued use after such changes constitutes acceptance.',
                      'Third-party fees (e.g., network fees, bank charges) may apply and are separate from our fees.',
                    ]),
                    _buildSection(context, '7. Transaction Limits', [
                      'We may set daily, monthly, or per-transaction limits based on your verification level, applicable laws, and risk assessment.',
                      'Limits may be adjusted at our discretion without prior notice. Higher limits may require additional verification.',
                      'We are not obligated to process transactions that exceed your limits or that we deem high-risk.',
                    ]),
                    _buildSection(context, '8. Risk Disclosure', [
                      'Digital assets and blockchain transactions carry inherent risks. By using our Services, you acknowledge and accept that:',
                      'Transactions may be irreversible once processed on the blockchain. We cannot reverse completed transactions.',
                      'USDC is a stablecoin pegged to the US dollar, but regulatory changes, smart contract risks, or issuer issues could affect its value or availability.',
                      'Cryptocurrency and blockchain technology are subject to regulatory uncertainty. Laws may change and affect our Services.',
                      'We rely on third-party partners (e.g., payment processors, banks) for some services. Delays or failures by third parties may affect your transactions.',
                      'You are solely responsible for understanding and accepting these risks.',
                    ]),
                    _buildSection(context, '9. Privacy', [
                      'Your use of our Services is also governed by our Privacy Notice, which explains how we collect, use, store, and protect your personal data.',
                      'By using our Services, you consent to the practices described in our Privacy Notice. We encourage you to read it carefully.',
                    ]),
                    _buildSection(context, '10. Intellectual Property', [
                      'All content, trademarks, logos, and technology used in the Services are owned by Stakk or our licensors. You are granted a limited, non-exclusive, non-transferable license to use the Services for lawful purposes only.',
                      'You may not copy, modify, distribute, reverse engineer, or create derivative works from our Services without our written consent.',
                    ]),
                    _buildSection(context, '11. Account Termination', [
                      'You may close your account at any time by contacting support. Outstanding balances must be withdrawn before closure.',
                      'We may suspend or terminate your access at any time if: (a) you violate these Terms; (b) we are required by regulatory authorities; (c) we deem it necessary for risk, security, or legal reasons; or (d) we discontinue the Services.',
                      'Upon termination, your right to use the Services ceases immediately. We may retain your data as required by law.',
                    ]),
                    _buildSection(context, '12. Limitation of Liability', [
                      'To the maximum extent permitted by law:',
                      'Stakk is not liable for indirect, incidental, consequential, special, or punitive damages (including loss of profits, data, or goodwill).',
                      'Our total liability is limited to the amount of fees you paid to us in the 3 months preceding the event giving rise to the claim, or NGN 100,000, whichever is less.',
                      'We are not liable for delays, failures, or errors caused by third parties, blockchain networks, or circumstances beyond our reasonable control.',
                      'Some jurisdictions do not allow certain limitations; in such cases, our liability is limited to the maximum extent permitted by law.',
                    ]),
                    _buildSection(context, '13. Indemnification', [
                      'You agree to indemnify, defend, and hold harmless Stakk, its affiliates, officers, directors, employees, and agents from any claims, damages, losses, or expenses (including legal fees) arising from your use of the Services, violation of these Terms, or violation of any law or third-party rights.',
                    ]),
                    _buildSection(context, '14. Governing Law and Disputes', [
                      'These Terms are governed by the laws of the Federal Republic of Nigeria.',
                      'Any disputes arising from these Terms or the Services shall first be resolved through good-faith negotiation. If negotiation fails, disputes may be resolved through arbitration in accordance with Nigerian arbitration law, or through the competent courts of Nigeria.',
                      'You agree to submit to the exclusive jurisdiction of Nigerian courts for any legal proceedings.',
                    ]),
                    _buildSection(context, '15. Changes to Terms', [
                      'We may update these Terms from time to time to reflect changes in law, our practices, or the Services.',
                      'Material changes will be communicated via in-app notification, email, or prominent notice. We will give you at least 30 days\' notice where practicable.',
                      'Continued use of the Services after the effective date of changes constitutes acceptance of the updated Terms. If you do not agree, you must stop using the Services and close your account.',
                    ]),
                    _buildSection(context, '16. General Provisions', [
                      'Severability: If any provision of these Terms is held invalid, the remaining provisions will remain in effect.',
                      'Waiver: Our failure to enforce any right does not constitute a waiver of that right.',
                      'Entire agreement: These Terms, together with our Privacy Notice and any other referenced policies, constitute the entire agreement between you and Stakk.',
                    ]),
                    _buildSection(context, '17. Contact Us', [
                      'For questions about these Terms or our Services:',
                      'Email: support@stakk.com',
                      'We aim to respond to all inquiries within 48 hours.',
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
