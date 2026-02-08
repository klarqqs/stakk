import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/tokens/app_colors.dart';

/// OTP input with N boxes. Parent provides controllers and focus nodes.
class OTPInput extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String)? onComplete;
  final String? errorText;

  const OTPInput({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.onComplete,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(controllers.length, (i) {
            return SizedBox(
              width: 48,
              child: TextField(
                controller: controllers[i],
                focusNode: focusNodes[i],
                keyboardType: TextInputType.number,
                maxLength: 1,
                textAlign: TextAlign.center,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty && i < controllers.length - 1) {
                    focusNodes[i + 1].requestFocus();
                  }
                  if (i == controllers.length - 1 && v.isNotEmpty) {
                    final code = controllers.map((c) => c.text).join();
                    if (code.length == controllers.length) {
                      onComplete?.call(code);
                    }
                  }
                },
              ),
            );
          }),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.errorBorder),
            ),
            child: Text(
              errorText!,
              style: const TextStyle(fontSize: 14, color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}
