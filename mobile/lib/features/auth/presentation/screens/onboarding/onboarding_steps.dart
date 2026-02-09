import 'package:flutter/material.dart';
import 'onboarding_strings.dart';

/// Single onboarding step. Add new steps here to extend the flow.
class OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// All onboarding steps. Modify this list to add/remove/reorder steps.
List<OnboardingStep> get onboardingSteps => [
      OnboardingStep(
        title: OnboardingStrings.step1Title,
        subtitle: OnboardingStrings.step1Subtitle,
        icon: Icons.savings_outlined,
      ),
      OnboardingStep(
        title: OnboardingStrings.step2Title,
        subtitle: OnboardingStrings.step2Subtitle,
        icon: Icons.account_balance_wallet_outlined,
      ),
      OnboardingStep(
        title: OnboardingStrings.step3Title,
        subtitle: OnboardingStrings.step3Subtitle,
        icon: Icons.send_outlined,
      ),
      OnboardingStep(
        title: OnboardingStrings.step4Title,
        subtitle: OnboardingStrings.step4Subtitle,
        icon: Icons.receipt_long_outlined,
      ),
      OnboardingStep(
        title: OnboardingStrings.step5Title,
        subtitle: OnboardingStrings.step5Subtitle,
        icon: Icons.trending_up_outlined,
      ),
      OnboardingStep(
        title: OnboardingStrings.step6Title,
        subtitle: OnboardingStrings.step6Subtitle,
        icon: Icons.check_circle_outline,
      ),
    ];
