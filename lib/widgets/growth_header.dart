import 'package:flutter/material.dart';
import '../theme.dart';
import 'garden_path_card.dart';

/// 14일 안에 미션을 10번 완수(하루 1도씩 적립)하면 레벨업되는 진행 상황 표시.
/// 딱딱한 흰 사각 박스 대신, 반투명 파스텔 블롭(GlassBlob) 위에 얹어
/// 바로 위 '며칠째 함께하는 중' 블롭과 톤이 이어지도록 합니다.
class GrowthHeader extends StatelessWidget {
  final int level;
  final int points; // 적립된 온도(=완수 일수)
  final int elapsedDays; // 도전 시작 후 지난 일수 (0이면 도전 전)
  final int goalPoints;
  final int windowDays;
  const GrowthHeader({
    super.key,
    required this.level,
    required this.points,
    required this.elapsedDays,
    required this.goalPoints,
    required this.windowDays,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (points / goalPoints).clamp(0.0, 1.0);
    final dayLabel = elapsedDays == 0
        ? '아직 도전 전'
        : '$elapsedDays / $windowDays일째';
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
                  '$level',
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
                      '성장 $level단계',
                      style: pathLabelFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '마음 온도 $points° / $goalPoints°  ·  $dayLabel',
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
