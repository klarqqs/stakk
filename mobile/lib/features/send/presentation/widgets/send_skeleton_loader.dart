import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader that mimics the send screen layout.
class SendSkeletonLoader extends StatelessWidget {
  const SendSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header "Send" (24px, bold)
            SkeletonBox(width: 80, height: 28),
            const SizedBox(height: 8),
            // Subtitle "Send USDC to friends or withdraw to Stellar"
            SkeletonBox(width: 280, height: 18),
            const SizedBox(height: 24),
            // Quick action grid (2 cards: Send to Stakk User, Send to Stellar)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: List.generate(
                2,
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
            // "Recent Recipients" row + optional "See all"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 160, height: 20),
                SkeletonBox(width: 56, height: 20),
              ],
            ),
            const SizedBox(height: 16),
            // Recent recipient tiles (5 max) - matching _RecentRecipientTile
            SkeletonBox(height: 72, borderRadius: AppRadius.lg),
            const SizedBox(height: 8),
            SkeletonBox(height: 72, borderRadius: AppRadius.lg),
            const SizedBox(height: 8),
            SkeletonBox(height: 72, borderRadius: AppRadius.lg),
            const SizedBox(height: 8),
            SkeletonBox(height: 72, borderRadius: AppRadius.lg),
            const SizedBox(height: 8),
            SkeletonBox(height: 72, borderRadius: AppRadius.lg),
          ],
        ),
      ),
    );
  }
}
