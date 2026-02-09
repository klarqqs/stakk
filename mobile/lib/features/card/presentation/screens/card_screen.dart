import 'package:flutter/material.dart';
import 'package:stakk_savings/core/theme/app_theme.dart';

class CardScreen extends StatelessWidget {
  const CardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.credit_card_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Card',
                style: AppTheme.header(context: context, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Spend USDC anywhere — coming soon',
                style: AppTheme.body(fontSize: 14, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
