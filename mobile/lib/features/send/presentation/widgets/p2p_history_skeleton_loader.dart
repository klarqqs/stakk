import 'package:flutter/material.dart';
import 'package:stakk_savings/core/components/skeleton/shimmer_skeleton.dart';
import 'package:stakk_savings/core/theme/tokens/app_radius.dart';

/// Skeleton loader for P2P history screen.
class P2pHistorySkeletonLoader extends StatelessWidget {
  const P2pHistorySkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          ...List.generate(6, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SkeletonBox(height: 72, borderRadius: AppRadius.lg),
          )),
        ],
      ),
    );
  }
}
