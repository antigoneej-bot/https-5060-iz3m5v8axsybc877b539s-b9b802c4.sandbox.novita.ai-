import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/cat_care_state.dart';
import 'garden_path_card.dart';

/// 마음 온도(0~100도)와 성장 단계(30일 출석 단위)를 함께 보여주는 헤더.
/// - 위쪽 원형 배지: 현재 성장 단계 번호(0~3단계)
/// - 진행 바: 지금 마음 온도(0~100도)
/// - 하단 문구: 다음 단계까지 남은 출석일수
class GrowthHeader extends StatelessWidget {
  final CatCareState state;
  const GrowthHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final progress = (state.temperature / 100).clamp(0.0, 1.0);
    final remain = state.daysUntilNextStage;
    final attended = state.growthDays;
    final dayLabel = remain == null
        ? '가장 높은 단계까지 자랐어요'
        : attended <= 0
            ? '다음 단계까지 출석 $remain일 남음'
            : '출석 ${attended}일째 · 다음 단계까지 $remain일';
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [
                      Color(0xFFEFFAF3),
                      AppColors.blobMintAccent,
                      AppColors.blobMintAccent,
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
                child: Text(
                  '${state.growthLevelNumber}',
                  style: numberFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.growthStageLabel,
                      style: pathLabelFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '마음 온도 ${state.temperature}° / 100°  ·  $dayLabel',
                      style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation(
                AppColors.blobMintAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
