import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';
import '../widgets/solution_category_section.dart';

/// 명상 탭 - 카테고리별로 모든 명상/움직임 가이드를 자유롭게 둘러보는 화면
class MeditationLibraryScreen extends StatelessWidget {
  const MeditationLibraryScreen({super.key});

  static const accents = [
    AppColors.blobLavenderAccent,
    AppColors.blobMintAccent,
    AppColors.blobPeachAccent,
    AppColors.blobButterAccent,
    AppColors.blobRoseAccent,
    AppColors.blobPeriwinkleAccent,
  ];
  static const backgrounds = [
    AppColors.blobLavender,
    AppColors.blobMint,
    AppColors.blobPeach,
    AppColors.blobButter,
    AppColors.blobRose,
    AppColors.blobPeriwinkle,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '명상 · 움직임',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 24, color: AppColors.titlePastelGreen),
        ),
        const SizedBox(height: 6),
        Text(
          '마음이 편안해지는 방법들을 자유롭게 둘러보고 실천해보세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 20),
        ...solutionCategories.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SolutionCategorySection(
              category: e.value,
              accent: accents[e.key % accents.length],
              background: backgrounds[e.key % backgrounds.length],
            ),
          ),
        ),
      ],
    );
  }
}
