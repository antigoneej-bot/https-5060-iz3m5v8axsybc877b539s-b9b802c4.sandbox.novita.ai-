import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/solutions_data.dart';

/// 명상/움직임 가이드의 단계별 안내를 보여주는 위젯 (여러 화면에서 재사용)
/// 딱딱한 흰 박스 대신, 반투명한 민트빛 카드로 부드럽게 표시합니다.
class GuideSteps extends StatelessWidget {
  final SolutionGuide guide;
  const GuideSteps({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(guide.title),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.blobMint.withValues(alpha: 0.55),
        border: Border.all(
          color: AppColors.blobMintAccent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(guide.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  guide.title,
                  style: pathLabelFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...guide.steps.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(right: 8, top: 1),
                    decoration: BoxDecoration(
                      color: AppColors.blobMintAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: bodyFont(fontSize: 12.5, color: AppColors.moon),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
