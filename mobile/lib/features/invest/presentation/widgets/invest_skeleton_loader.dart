import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for invest/earn screen.
class InvestSkeletonLoader extends StatelessWidget {
  const InvestSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(width: 80, height: 28),
            const SizedBox(height: 8),
            SkeletonBox(width: 220, height: 18),
            const SizedBox(height: 32),
            SkeletonBox(height: 140, borderRadius: AppRadius.lg),
            const SizedBox(height: 24),
            SkeletonBox(width: 120, height: 18),
            const SizedBox(height: 8),
            SkeletonBox(height: 56, borderRadius: AppRadius.md),
            const SizedBox(height: 16),
            SkeletonBox(height: 56, borderRadius: AppRadius.lg),
            const SizedBox(height: 32),
            SkeletonBox(height: 100, borderRadius: AppRadius.md),
          ],
        ),
      ),
    );
  }
}
