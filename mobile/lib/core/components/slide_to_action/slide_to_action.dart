import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tokens/app_colors.dart';
import '../../theme/tokens/app_radius.dart';

/// Slide-to-send style interaction. User drags handle to complete.
/// Triggers [onComplete] when slid to threshold. No new logic — only UI.
class SlideToAction extends StatefulWidget {
  final String label;
  final VoidCallback onComplete;
  final bool disabled;
  final bool isLoading;

  const SlideToAction({
    super.key,
    required this.label,
    required this.onComplete,
    this.disabled = false,
    this.isLoading = false,
  });

  @override
  State<SlideToAction> createState() => _SlideToActionState();
}

class _SlideToActionState extends State<SlideToAction>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  bool _hasCompleted = false;
  static const double _handleSize = 56;
  static const double _threshold = 0.85;

  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  void _onComplete() {
    if (_hasCompleted) return;
    _hasCompleted = true;
    HapticFeedback.mediumImpact();
    _successController.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final surface = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    if (widget.isLoading) {
      return Container(
        height: _handleSize + 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = (constraints.maxWidth - _handleSize - 24).clamp(0.0, 400.0);

        return Opacity(
          opacity: widget.disabled ? 0.6 : 1,
          child: GestureDetector(
            onHorizontalDragStart: widget.disabled
                ? null
                : (_) {
                    HapticFeedback.selectionClick();
                  },
          onHorizontalDragUpdate: widget.disabled
              ? null
              : (d) {
                  setState(() {
                    _dragOffset = (_dragOffset + d.delta.dx).clamp(0.0, maxDrag);
                    if (_dragOffset >= maxDrag * _threshold) _onComplete();
                  });
                },
          onHorizontalDragEnd: widget.disabled
              ? null
              : (_) {
                  if (!_hasCompleted && _dragOffset < maxDrag * _threshold) {
                    setState(() => _dragOffset = 0);
                  }
                },
          child: AnimatedBuilder(
            animation: _successController,
            builder: (context, child) {
              final successScale = 1.0 - (_successController.value * 0.1);
              return Transform.scale(
                scale: successScale,
                child: child,
              );
            },
            child: Container(
              height: _handleSize + 16,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Center(
                    child: AnimatedOpacity(
                      opacity: _dragOffset > 8 ? 0.5 : 1,
                      duration: const Duration(milliseconds: 150),
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: EdgeInsets.only(left: 12 + _dragOffset),
                    child: Container(
                      width: _handleSize,
                      height: _handleSize,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}
