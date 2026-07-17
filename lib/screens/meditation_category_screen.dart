import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';
import '../widgets/stars_background.dart';
import '../widgets/solution_category_section.dart';

/// 오늘 고른 감정(이모티콘)에 맞는 명상 카테고리 하나만 보여주는 화면.
/// 고양이에게 편지쓰기 플로우의 "명상 추천" 버튼을 누르면 이 화면으로 이동해서,
/// [MeditationLibraryScreen]의 전체 목록이 아니라 지금 감정에 딱 맞는 카테고리만
/// 펼쳐진 상태로 보여줍니다.
class MeditationCategoryScreen extends StatelessWidget {
  final String categoryKey;
  final String? moodEmoji;
  const MeditationCategoryScreen({
    super.key,
    required this.categoryKey,
    this.moodEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final category = solutionCategoryByKey(categoryKey);
    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.ink,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '오늘의 감정에 맞는 명상',
                          style: titleFont(
                            fontSize: 20,
                            color: AppColors.titlePastelGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (moodEmoji != null) _MoodBadge(emoji: moodEmoji!),
                          if (moodEmoji != null) const SizedBox(height: 16),
                          if (category != null)
                            SolutionCategorySection(
                              category: category,
                              accent: AppColors.blobLavenderAccent,
                              background: AppColors.blobLavender,
                              startExpanded: true,
                            )
                          else
                            Text(
                              '지금은 딱히 대처법이 필요 없는 편안한 감정이에요 🌤️',
                              textAlign: TextAlign.center,
                              style: bodyFont(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  final String emoji;
  const _MoodBadge({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.blobLavenderAccent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              '오늘 고른 감정에 맞춰 골라봤어요',
              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
