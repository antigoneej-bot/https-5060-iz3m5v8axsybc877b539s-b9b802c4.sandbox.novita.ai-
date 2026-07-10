import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// 14일 안에 미션을 10번 완수(하루 1도씩 적립)하면 레벨업되는 진행 상황 표시
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFFFF6DF),
                      AppColors.goldSoft,
                      AppColors.gold,
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
                child: Text(
                  '$level',
                  style: GoogleFonts.poppins(
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
                      style: serifFont(
                        fontSize: 15,
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
              backgroundColor: AppColors.bg0,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}
