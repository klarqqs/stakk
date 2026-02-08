import 'package:flutter/material.dart';
import '../../theme/tokens/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool enabled;
  final void Function(String)? onChanged;
  final Widget? suffixIcon;
  final String? errorText;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
    this.suffixIcon,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      onChanged: onChanged,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
        errorText: errorText,
        errorStyle: TextStyle(color: AppColors.error),
      ),
    );
  }
}
