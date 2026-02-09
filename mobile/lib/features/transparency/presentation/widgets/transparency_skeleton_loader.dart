import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for transparency screen.
class TransparencySkeletonLoader extends StatelessWidget {
  const TransparencySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(width: 200, height: 48),
            const SizedBox(height: 8),
            SkeletonBox(width: 260, height: 18),
            const SizedBox(height: 32),
            SkeletonBox(height: 100, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 100, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 100, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 100, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 100, borderRadius: AppRadius.xl),
          ],
        ),
      ),
    );
  }
}
