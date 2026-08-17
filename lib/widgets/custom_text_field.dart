import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;
  /// When true, uses transparent fill and light colors for dark backgrounds (e.g. green login).
  final bool darkBackground;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.darkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = darkBackground;
    final borderColor = isDark ? Colors.white54 : null;
    final fillColor = isDark ? Colors.transparent : null;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: isDark ? const TextStyle(color: Colors.white) : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        fillColor: fillColor,
        filled: isDark,
        labelStyle: isDark ? TextStyle(color: Colors.white.withOpacity(0.9)) : null,
        hintStyle: isDark ? TextStyle(color: Colors.white.withOpacity(0.6)) : null,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark ? Colors.white70 : null,
              )
            : null,
        suffixIcon: suffixIcon,
        border: borderColor != null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              )
            : null,
        enabledBorder: borderColor != null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor, width: 1.5),
              )
            : null,
        focusedBorder: borderColor != null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              )
            : null,
        errorBorder: borderColor != null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              )
            : null,
      ),
    );
  }
}
