import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader that mimics the home screen layout. Uses shimmer effect.
class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 80, height: 28),
                  SkeletonBox(
                    width: 28,
                    height: 28,
                    borderRadius: AppRadius.full,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SkeletonBox(height: 140, borderRadius: AppRadius.lg),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SkeletonBox(height: 120, borderRadius: AppRadius.xl),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: SkeletonBox(height: 56, borderRadius: AppRadius.lg),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SkeletonBox(height: 56, borderRadius: AppRadius.lg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: SkeletonBox(height: 44, borderRadius: AppRadius.lg),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SkeletonBox(height: 44, borderRadius: AppRadius.lg),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SkeletonBox(height: 44, borderRadius: AppRadius.lg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 120, height: 20),
                  SkeletonBox(width: 50, height: 20),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => SkeletonBox(
                  width: 156,
                  height: 120,
                  borderRadius: AppRadius.lg,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SkeletonBox(width: 100, height: 20),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SkeletonBox(height: 60, borderRadius: AppRadius.md),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SkeletonBox(height: 60, borderRadius: AppRadius.md),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SkeletonBox(height: 60, borderRadius: AppRadius.md),
            ),
          ],
        ),
      ),
    );
  }
}
