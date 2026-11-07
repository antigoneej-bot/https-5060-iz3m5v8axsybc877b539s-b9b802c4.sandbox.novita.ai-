import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/emotion.dart';
import '../providers/garden_provider.dart';

/// Finch식 "감정 체크인" 데일리 루틴 팝업.
///
/// 매일 앱을 열면(하루에 한 번) 몽이가 먼저 묻는다: "오늘 기분은 어때?"
/// 유저가 실제 감정을 고르면 -> 그 감정이 오늘의 감정 몬스터로 바로 게임에 등장하고
/// -> "현실의 감정 -> 게임 속 캐릭터화"가 완성된다. 15개 감정(부정 10 + 긍정 5) 중
/// 어떤 것이든 잠금 없이 고를 수 있다는 앱의 핵심 가치를 그대로 잇는다.
///
/// 반환값: 사용자가 고른 [Emotion] (건너뛰기를 누르면 null).
class DailyCheckInSheet extends StatelessWidget {
  const DailyCheckInSheet({super.key});

  /// 오늘 아직 체크인하지 않았을 때만 이 시트를 띄운다.
  /// 사용자가 감정을 고르면 [GardenProvider.recordDailyCheckIn]까지 기록한 뒤
  /// 그 감정을 반환한다 (호출부에서 곧바로 게임 선택에 이어 붙일 수 있도록).
  static Future<Emotion?> showIfNeeded(BuildContext context) async {
    final garden = context.read<GardenProvider>();
    if (garden.hasCheckedInToday) return null;
    if (!context.mounted) return null;
    return showModalBottomSheet<Emotion>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const DailyCheckInSheet(),
    );
  }

  Future<void> _choose(BuildContext context, Emotion emotion) async {
    await context.read<GardenProvider>().recordDailyCheckIn(emotion.type);
    if (context.mounted) {
      Navigator.of(context).pop(emotion);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final streakAfter = garden.checkInStreak + 1; // 아직 선택 전이므로 +1 표시(예상치)
    final bestStreak = garden.bestCheckInStreak;
    // 스트릭 가시성 강화(벤치마킹 제안 #4): 엔드리스 모드의 "최고 기록" 패턴을
    // 그대로 차용해, 오늘 체크인하면 신기록인지/아직 최고 기록에 못 미치는지/
    // 스트릭이 끊긴 뒤 재도전 중인지를 매번 다르게 보여준다.
    final String? bestStreakMessage;
    if (garden.checkInStreak == 0 && bestStreak > 0) {
      bestStreakMessage = l10n.dailyCheckInBestStreakRestart(bestStreak);
    } else if (streakAfter > bestStreak) {
      bestStreakMessage = l10n.dailyCheckInBestStreakNewRecord;
    } else if (bestStreak > 0) {
      bestStreakMessage = l10n.dailyCheckInBestStreakCompare(bestStreak);
    } else {
      bestStreakMessage = null;
    }
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: AppColors.bg0,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/mongi/images/cat_idle.png', height: 84),
            const SizedBox(height: 10),
            Text(
              l10n.dailyCheckInCuriousLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dailyCheckInQuestion,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            if (garden.checkInStreak > 0)
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  l10n.dailyCheckInStreakBadge(
                    garden.checkInStreak,
                    streakAfter,
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB5651D),
                  ),
                ),
              ),
            if (bestStreakMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(
                  bestStreakMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              height: 210,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: Emotion.all.length,
                itemBuilder: (context, index) {
                  final e = Emotion.all[index];
                  return _CheckInEmotionButton(
                    emotion: e,
                    onTap: () => _choose(context, e),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                l10n.dailyCheckInSkipButton,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInEmotionButton extends StatelessWidget {
  final Emotion emotion;
  final VoidCallback onTap;

  const _CheckInEmotionButton({required this.emotion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emotion.color.withValues(alpha: 0.16),
              border: Border.all(
                color: emotion.color.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Image.asset(emotion.monsterAsset, height: 34),
          ),
          const SizedBox(height: 4),
          Text(
            emotionLabel(l10n, emotion.type),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
