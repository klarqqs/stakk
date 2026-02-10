import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for bills providers screen.
class BillsProvidersSkeletonLoader extends StatelessWidget {
  const BillsProvidersSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(width: 140, height: 20),
            const SizedBox(height: 8),
            SkeletonBox(width: 200, height: 16),
            const SizedBox(height: 24),
            ...List.generate(5, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonBox(height: 72, borderRadius: AppRadius.lg),
            )),
          ],
        ),
      ),
    );
  }
}
