import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';
import '../widgets/streak_header.dart';
import '../widgets/growth_header.dart';
import '../widgets/stars_background.dart';
import '../widgets/emotion_record_sheet.dart';
import '../widgets/monthly_report_picker_sheet.dart';
import '../providers/emotion_provider.dart';
import 'pet_care_screen.dart';
import 'daily_card_screen.dart';

/// 홈페이지 탭 - 앱 전체 현황을 한눈에 보여주는 대시보드
class HomeTabScreen extends StatelessWidget {
  final VoidCallback onGoToCatSelect;
  final VoidCallback onGoToMeditation;
  final VoidCallback onGoToRecords;
  const HomeTabScreen({
    super.key,
    required this.onGoToCatSelect,
    required this.onGoToMeditation,
    required this.onGoToRecords,
  });

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final emotion = context.watch<EmotionProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (emotion.hasNewReport) ...[
          _MonthlyReportBanner(
            onTap: () async {
              final key = emotion.newReportKey;
              await MonthlyReportPickerSheet.show(context);
              if (key != null && context.mounted) {
                context.read<EmotionProvider>().markReportSeen(key);
              }
            },
          ),
          const SizedBox(height: 24),
        ],
        Text(
          'CAT SHADOW GARDEN',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 12,
            color: AppColors.goldSoft,
            letterSpacing: 3.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '고양이 그림자 정원',
          textAlign: TextAlign.center,
          style: titleFont(
            fontSize: 32,
            color: AppColors.titlePastelGreen,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '36마리 그림자 고양이와 함께하는, 나의 마음챙김 저널',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 13.5,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        StreakHeader(streak: app.streak),
        const SizedBox(height: 28),
        GrowthHeader(
          level: app.growthLevel,
          points: app.growthPoints,
          elapsedDays: app.growthElapsedDays,
          goalPoints: AppStateProvider.growthGoalPoints,
          windowDays: AppStateProvider.growthWindowDays,
        ),
        const SizedBox(height: 52),
        _SectionHeading(title: '무엇을 해볼까요?'),
        const SizedBox(height: 24),
        _ActionCard(
          emoji: '🐾',
          title: '오늘의 감정 고양이 만나기',
          subtitle: '지금 내 기분과 닮은 고양이를 골라 편지를 써보세요',
          color: const CategoryColor(AppColors.catPeach, AppColors.catPeachBg),
          onTap: onGoToCatSelect,
        ),
        const SizedBox(height: 20),
        _ActionCard(
          emoji: '🧘',
          title: '명상 · 움직임 둘러보기',
          subtitle: '호흡, 알아차림, 움직임, 표현하기 가이드를 살펴보세요',
          color: const CategoryColor(
            AppColors.catLavender,
            AppColors.catLavenderBg,
          ),
          onTap: onGoToMeditation,
        ),
        const SizedBox(height: 20),
        _ActionCard(
          emoji: '🌡️',
          title: '마음 온도 기록 보기',
          subtitle: '지난 편지와 마음 온도 변화를 돌아보세요',
          color: const CategoryColor(
            AppColors.catDustyRose,
            AppColors.catDustyRoseBg,
          ),
          onTap: onGoToRecords,
        ),
        const SizedBox(height: 20),
        _ActionCard(
          emoji: '🐟',
          title: '마음 돌보기',
          subtitle: '몸 돌봄과 호흡·걷기 명상, 마음기록으로 고양이를 함께 키워보세요',
          color: const CategoryColor(AppColors.catSage, AppColors.catSageBg),
          onTap: () =>
              _pushFullScreen(context, '마음 돌보기', const PetCareScreen()),
        ),
        const SizedBox(height: 20),
        _ActionCard(
          emoji: '🔮',
          title: '데일리 내면소통',
          subtitle: '오늘의 카드를 뽑아 위로와 지침을 받아보세요',
          color: const CategoryColor(AppColors.catNavy, AppColors.catNavyBg),
          onTap: () =>
              _pushFullScreen(context, '데일리 내면소통', const DailyCardScreen()),
        ),
        const SizedBox(height: 20),
        _ActionCard(
          emoji: emotion.hasRecordedToday ? '🌙' : '🌗',
          title: emotion.hasRecordedToday ? '오늘의 감정 다시 기록하기' : '오늘의 감정 기록하기',
          subtitle: '지금 마음을 골라 달빛 정원에 짧게 남겨보세요',
          color: const CategoryColor(
            AppColors.catLavender,
            AppColors.catLavenderBg,
          ),
          onTap: () => EmotionRecordSheet.show(context),
        ),
        const SizedBox(height: 20),
        _ActionCard(
          emoji: '📖',
          title: '마음 리포트 보기',
          subtitle: '한 달간의 감정 흐름을 따뜻하게 되돌아보세요',
          color: const CategoryColor(
            AppColors.catDustyRose,
            AppColors.catDustyRoseBg,
          ),
          onTap: () => MonthlyReportPickerSheet.show(context),
        ),
        const SizedBox(height: 36),
        _GardenHintCaption(),
      ],
    );
  }
}

void _pushFullScreen(BuildContext context, String title, Widget child) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _SimpleFeatureScaffold(title: title, child: child),
    ),
  );
}

/// 섹션 제목 - 왼쪽에 작은 포인트 바를 두어 위계를 명확히 드러냅니다.
class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: serifFont(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

/// 홈 대시보드에서 새로운 기능(마음 돌보기 / 데일리 내면소통)으로 진입할 때 쓰는
/// 공용 화면 래퍼 - 기존 탭들과 톤을 맞춘 배경과 뒤로가기 버튼을 제공합니다.
class _SimpleFeatureScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _SimpleFeatureScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
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
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: child,
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

class _ActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final CategoryColor color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg1,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: serifFont(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: bodyFont(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color.accent,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 새로운 월간 마음 리포트가 도착했음을 알리는 은은한 달빛 배너
class _MonthlyReportBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _MonthlyReportBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E3652), Color(0xFF1B2138)],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Text('🌙', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '이번 달 마음 리포트가 도착했어요',
                      style: serifFont(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '지난 한 달의 감정 흐름을 함께 돌아볼까요?',
                      style: bodyFont(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카드가 아니라, 화면 가장자리에서 조용히 살아가는 그림자 고양이들의 존재를
/// 은은하게 알려주는 짧은 캡션. 장식이 아니라 '함께 있음'을 상기시키는 문구입니다.
class _GardenHintCaption extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '🐈‍⬛  그림자 고양이들이 정원 어딘가에서\n조용히 당신의 마음을 지켜보고 있어요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 11.5,
            color: AppColors.inkSoft,
            height: 1.7,
          ),
        ),
      ),
    );
  }
}
