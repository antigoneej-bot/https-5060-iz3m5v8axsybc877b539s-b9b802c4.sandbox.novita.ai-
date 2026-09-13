import '../services/draft_service.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import 'garden_path_card.dart';

/// 그림자 고양이에게 쓰는 편지 입력 박스.
/// 라벤더 톤 GlassBlob 위에 얹어, 조용히 마음을 적는 공간처럼 느껴지도록
/// 합니다.
class JournalBox extends StatelessWidget {
  final String question;
  final String hint;
  final TextEditingController controller;
  const JournalBox({
    super.key,
    required this.question,
    required this.controller,
    this.hint = '떠오르는 대로, 있는 그대로 적어보세요',
  });

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: pathLabelFont(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: bodyFont(fontSize: 12, color: AppColors.blobLavenderAccent),
          ),
          if (controller is DraftTextController)
            ValueListenableBuilder<String>(
              valueListenable: (controller as DraftTextController).saveStatus,
              builder: (_, status, __) => Text(status, style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
            ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.55),
            ),
            child: TextField(
              controller: controller,
              minLines: 5,
              maxLines: 10,
              style: bodyFont(fontSize: 13.5, color: AppColors.moon),
              decoration: InputDecoration(
                filled: false,
                hintText: '지금 이 마음을 그대로 적어보세요…',
                hintStyle: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.blobLavenderAccent.withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
