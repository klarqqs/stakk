import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/tokens/app_colors.dart';
import '../../theme/tokens/app_radius.dart';

/// Shimmer effect wrapper. Theme-aware base/highlight colors.
class ShimmerSkeleton extends StatelessWidget {
  final Widget child;

  const ShimmerSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A1A1E) : AppColors.surfaceVariantLight;
    final highlightColor = isDark ? const Color(0xFF2A2A30) : Colors.white;
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

/// Placeholder box for skeleton layout. Rounded, no content.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF1E1E22) : AppColors.surfaceVariantLight;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
