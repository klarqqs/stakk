import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens/app_colors.dart';

/// Amount input with bold number display and optional currency prefix.
/// Theme-aware, rounded, emphasis on amount.
class AmountInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? currencyPrefix;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;

  const AmountInput({
    super.key,
    this.controller,
    this.currencyPrefix,
    this.hintText,
    this.onChanged,
    this.enabled = true,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (currencyPrefix != null && currencyPrefix!.isNotEmpty) ...[
          Text(
            '$currencyPrefix ',
            style: AppTheme.body(
              context: context,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: inputFormatters,
            style: AppTheme.header(
              context: context,
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: hintText ?? '0',
              hintStyle: AppTheme.header(
                context: context,
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
