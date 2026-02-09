import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton for product list in bills pay sheet.
class BillsPayProductsSkeleton extends StatelessWidget {
  const BillsPayProductsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 100, height: 18),
          const SizedBox(height: 8),
          SkeletonBox(height: 48, borderRadius: AppRadius.sm),
          const SizedBox(height: 8),
          SkeletonBox(height: 48, borderRadius: AppRadius.sm),
          const SizedBox(height: 8),
          SkeletonBox(height: 48, borderRadius: AppRadius.sm),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
