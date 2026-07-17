import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_care_provider.dart';
import '../models/cat_achievement.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';

/// 뱃지 컬렉션 화면 - 출석/졸업/수집/애정표현 등 다양한 활동으로 모을 수
/// 있는 도전과제를 한눈에 보여줍니다. 달성한 뱃지는 색이 채워지고, 아직
/// 달성하지 못한 뱃지는 흐릿하게 표시되며 진행 상황("3/7일")이 함께 보여요.
class CatAchievementsScreen extends StatelessWidget {
  const CatAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();
    final stats = care.achievementStats;
    final unlockedCount = catAchievements
        .where((a) => a.isUnlocked(stats))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassBlob(
          accent: AppColors.blobButterAccent,
          background: AppColors.blobButter,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Text('🎖️', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '뱃지 컬렉션',
                      style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                    ),
                    Text(
                      '함께한 시간이 모여 뱃지가 돼요',
                      style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              Text(
                '$unlockedCount/${catAchievements.length}',
                style: numberFont(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.blobButterAccent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: catAchievements.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, i) {
            final a = catAchievements[i];
            final unlocked = a.isUnlocked(stats);
            return _AchievementBadgeTile(
              achievement: a,
              unlocked: unlocked,
              progress: a.progressLabel(stats),
            );
          },
        ),
      ],
    );
  }
}

class _AchievementBadgeTile extends StatelessWidget {
  final CatAchievement achievement;
  final bool unlocked;
  final String progress;
  const _AchievementBadgeTile({
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final accent = unlocked ? AppColors.blobButterAccent : AppColors.inkSoft;
    final background = unlocked ? AppColors.blobButter : AppColors.blobLavender;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background.withValues(alpha: unlocked ? 0.75 : 0.35),
            background.withValues(alpha: unlocked ? 0.45 : 0.2),
          ],
        ),
        border: Border.all(
          color: accent.withValues(alpha: unlocked ? 0.35 : 0.2),
          width: 1.1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: unlocked ? 0.85 : 0.55),
            ),
            child: Opacity(
              opacity: unlocked ? 1.0 : 0.35,
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: pathLabelFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: unlocked ? AppColors.ink : AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: bodyFont(fontSize: 9.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              unlocked ? '달성 완료 ✓' : progress,
              style: numberFont(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
