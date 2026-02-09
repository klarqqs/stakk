import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for referrals screen.
class ReferralsSkeletonLoader extends StatelessWidget {
  const ReferralsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(height: 140, borderRadius: AppRadius.xl),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 100, borderRadius: AppRadius.xl)),
                const SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 100, borderRadius: AppRadius.xl)),
              ],
            ),
            const SizedBox(height: 32),
            SkeletonBox(width: 120, height: 20),
            const SizedBox(height: 12),
            SkeletonBox(width: 340, height: 48),
            const SizedBox(height: 32),
            SkeletonBox(width: 100, height: 20),
            const SizedBox(height: 12),
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SkeletonBox(height: 56, borderRadius: AppRadius.md),
            )),
          ],
        ),
      ),
    );
  }
}
