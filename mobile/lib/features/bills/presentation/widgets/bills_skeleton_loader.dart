import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader that mimics the bills screen layout.
class BillsSkeletonLoader extends StatelessWidget {
  const BillsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header "Bills" (24px, bold)
            SkeletonBox(width: 60, height: 28),
            const SizedBox(height: 8),
            // Subtitle "Pay airtime, data, DSTV, electricity with USDC"
            SkeletonBox(width: 320, height: 18),
            const SizedBox(height: 24),
            // "Quick Pay" section title
            SkeletonBox(width: 100, height: 20),
            const SizedBox(height: 12),
            // Quick Pay grid 2x2 (Airtime, Data, DSTV, Electricity)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: List.generate(
                4,
                (_) => LayoutBuilder(
                  builder: (context, constraints) => SkeletonBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    borderRadius: AppRadius.lg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // "Airtime quick amounts" section title
            SkeletonBox(width: 180, height: 20),
            const SizedBox(height: 12),
            // Row of 4 preset chips - full width, 4 equal-width (matching _presets Row)
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: SkeletonBox(height: 44, borderRadius: AppRadius.full),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
            // "All Categories" section title
            SkeletonBox(width: 130, height: 20),
            const SizedBox(height: 12),
            // Category tiles (matching _CategoryTile: padding 16, accent bar, icon, text)
            _CategoryTileSkeleton(),
            const SizedBox(height: 12),
            _CategoryTileSkeleton(),
            const SizedBox(height: 12),
            _CategoryTileSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _CategoryTileSkeleton extends StatelessWidget {
  const _CategoryTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(height: 72, borderRadius: AppRadius.lg);
  }
}
