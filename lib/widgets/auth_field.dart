import 'package:flutter/material.dart';
import '../theme.dart';

/// 로그인/회원가입 화면에서 공용으로 쓰는 입력 필드.
/// 딱딱한 사각 테두리 대신, 알약처럼 둥근 반투명 필드로 부드럽게 표시합니다.
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
          style: pathLabelFont(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.blobMint.withValues(alpha: 0.45),
            border: Border.all(
              color: AppColors.blobMintAccent.withValues(alpha: 0.22),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onSubmitted: onSubmitted,
            style: bodyFont(fontSize: 14, color: AppColors.moon),
            decoration: InputDecoration(
              filled: false,
              hintText: hint,
              hintStyle: bodyFont(fontSize: 13, color: AppColors.inkSoft),
              prefixIcon: Icon(icon, color: AppColors.blobMintAccent, size: 20),
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: AppColors.blobMintAccent.withValues(alpha: 0.5),
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
