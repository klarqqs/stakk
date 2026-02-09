import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader that mimics the save screen layout.
class SaveSkeletonLoader extends StatelessWidget {
  const SaveSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header "Save" (24px, bold)
            SkeletonBox(width: 60, height: 28),
            const SizedBox(height: 8),
            // Subtitle "Goals, lock savings & group savings"
            SkeletonBox(width: 260, height: 18),
            const SizedBox(height: 24),
            // Create goal button (gradient card, icon + "Create Goal" + "Save towards a target")
            SkeletonBox(height: 104, borderRadius: AppRadius.xl),
            const SizedBox(height: 32),
            // "Savings Goals" section title
            SkeletonBox(width: 130, height: 20),
            const SizedBox(height: 12),
            // Savings goal cards (up to 3 shown)
            SkeletonBox(height: 104, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 104, borderRadius: AppRadius.xl),
            const SizedBox(height: 12),
            SkeletonBox(height: 104, borderRadius: AppRadius.xl),
            const SizedBox(height: 32),
            // "Lock Savings" section title
            SkeletonBox(width: 120, height: 20),
            const SizedBox(height: 12),
            // Lock savings card
            SkeletonBox(height: 104, borderRadius: AppRadius.xl),
            const SizedBox(height: 32),
            // "Group Savings (Ajo)" section title
            SkeletonBox(width: 170, height: 20),
            const SizedBox(height: 12),
            // Ajo card (taller, has "Coming soon" badge)
            SkeletonBox(height: 120, borderRadius: AppRadius.xl),
          ],
        ),
      ),
    );
  }
}
