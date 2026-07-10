import 'package:flutter/material.dart';
import '../theme.dart';

/// 그림자 고양이에게 쓰는 편지 입력 박스
class JournalBox extends StatelessWidget {
  final String question;
  final String hint;
  final TextEditingController controller;
  const JournalBox({
    super.key,
    required this.question,
    required this.controller,
    this.hint = '떠오르는 대로, 편하게 적어보세요',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: serifFont(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(hint, style: bodyFont(fontSize: 12, color: AppColors.goldSoft)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 10,
            style: bodyFont(fontSize: 13.5, color: AppColors.moon),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bg0,
              hintText: '고양이에게 편지를 적어보세요…',
              hintStyle: bodyFont(fontSize: 13, color: AppColors.inkSoft),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.goldSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
