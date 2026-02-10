import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for transaction history screen.
class TransactionHistorySkeletonLoader extends StatelessWidget {
  const TransactionHistorySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          ...List.generate(6, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: SkeletonBox(height: 56, borderRadius: AppRadius.sm),
            ),
          )),
        ],
      ),
    );
  }
}
