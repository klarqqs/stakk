import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for goal detail screen. Matches layout: circular progress card, buttons, contributions.
class GoalDetailSkeletonLoader extends StatelessWidget {
  const GoalDetailSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Goal card with circular progress (120x120)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                children: [
                  SkeletonBox(width: 120, height: 120, borderRadius: AppRadius.full),
                  const SizedBox(height: 20),
                  SkeletonBox(width: 120, height: 24),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 140, height: 18),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Add Money / Withdraw buttons
            Row(
              children: [
                Expanded(child: SkeletonBox(height: 48, borderRadius: AppRadius.lg)),
                const SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 48, borderRadius: AppRadius.lg)),
              ],
            ),
            const SizedBox(height: 32),
            SkeletonBox(width: 120, height: 20),
            const SizedBox(height: 12),
            SkeletonBox(height: 60, borderRadius: AppRadius.md),
            const SizedBox(height: 8),
            SkeletonBox(height: 60, borderRadius: AppRadius.md),
            const SizedBox(height: 8),
            SkeletonBox(height: 60, borderRadius: AppRadius.md),
          ],
        ),
      ),
    );
  }
}
