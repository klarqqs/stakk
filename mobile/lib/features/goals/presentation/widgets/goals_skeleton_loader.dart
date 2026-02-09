import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for goals screen.
class GoalsSkeletonLoader extends StatelessWidget {
  const GoalsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SkeletonBox(height: 104, borderRadius: AppRadius.xl),
          const SizedBox(height: 12),
          SkeletonBox(height: 104, borderRadius: AppRadius.xl),
          const SizedBox(height: 12),
          SkeletonBox(height: 104, borderRadius: AppRadius.xl),
          const SizedBox(height: 16),
          SkeletonBox(height: 56, borderRadius: AppRadius.lg),
        ],
      ),
    );
  }
}
