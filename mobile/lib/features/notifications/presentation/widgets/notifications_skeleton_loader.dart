import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for notifications screen.
class NotificationsSkeletonLoader extends StatelessWidget {
  const NotificationsSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(8, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SkeletonBox(width: 40, height: 40, borderRadius: AppRadius.full),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 180, height: 16),
                      const SizedBox(height: 8),
                      SkeletonBox(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
