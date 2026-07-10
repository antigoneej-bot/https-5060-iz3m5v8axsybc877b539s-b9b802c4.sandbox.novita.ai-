import 'package:flutter/material.dart';
import '../theme.dart';

/// 로그인/회원가입 화면에서 공용으로 쓰는 입력 필드
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: bodyFont(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          style: bodyFont(fontSize: 14, color: AppColors.moon),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bg1,
            hintText: hint,
            hintStyle: bodyFont(fontSize: 13, color: AppColors.inkSoft),
            prefixIcon: Icon(icon, color: AppColors.inkSoft, size: 20),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.goldSoft,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
