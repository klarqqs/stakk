import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for lock savings screen.
class LockSkeletonLoader extends StatelessWidget {
  const LockSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(width: 140, height: 20),
            const SizedBox(height: 12),
            SkeletonBox(height: 88, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 88, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 88, borderRadius: AppRadius.xl),
            const SizedBox(height: 24),
            SkeletonBox(width: 100, height: 20),
            const SizedBox(height: 12),
            SkeletonBox(height: 88, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 88, borderRadius: AppRadius.xl),
          ],
        ),
      ),
    );
  }
}
