import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for bills categories screen.
class BillsCategoriesSkeletonLoader extends StatelessWidget {
  const BillsCategoriesSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 60, height: 28),
            const SizedBox(height: 8),
            SkeletonBox(width: 320, height: 18),
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
