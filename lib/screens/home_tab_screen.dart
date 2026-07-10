import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';
import '../widgets/growth_header.dart';
import '../widgets/stars_background.dart';
import '../widgets/emotion_record_sheet.dart';
import '../widgets/monthly_report_picker_sheet.dart';
import '../widgets/garden_path_card.dart';
import '../providers/emotion_provider.dart';
import 'pet_care_screen.dart';
import 'daily_card_screen.dart';

/// 홈페이지 탭 - '힐링 정원 산책로' 컨셉의 대시보드.
/// 딱딱한 흰 사각 카드를 모두 걷어내고, 오솔길을 걷듯 좌우로 살짝씩 흔들리며
/// 놓인 반투명 알약형 카드들을 순서대로 만나게 됩니다.
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
            color: AppColors.titlePastelGreenSoft,
            letterSpacing: 4,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '고양이 그림자 정원',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 34, color: AppColors.titlePastelGreen),
        ),
        const SizedBox(height: 10),
        Text(
          '36마리 그림자 고양이와 함께하는,\n나의 마음챙김 산책로',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft, height: 1.7),
        ),
        const SizedBox(height: 34),
        _StreakBlob(streak: app.streak),
        const SizedBox(height: 18),
        GrowthHeader(
          level: app.growthLevel,
          points: app.growthPoints,
          elapsedDays: app.growthElapsedDays,
          goalPoints: AppStateProvider.growthGoalPoints,
          windowDays: AppStateProvider.growthWindowDays,
        ),
        const SizedBox(height: 44),
        _PathSignpost(title: '오솔길을 따라 걸어볼까요?'),
        const SizedBox(height: 6),
        GardenPathCard(
          emoji: '🐾',
          title: '오늘의 감정 고양이 만나기',
          subtitle: '지금 내 기분과 닮은 고양이를 골라 편지를 써보세요',
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          alignX: -0.32,
          widthFactor: 0.92,
          floatSeed: 1,
          onTap: onGoToCatSelect,
        ),
        const GardenPathConnector(
          startX: -0.32,
          endX: 0.3,
          decorEmoji: '🦋',
        ),
        GardenPathCard(
          emoji: '🧘',
          title: '명상 · 움직임 둘러보기',
          subtitle: '호흡, 알아차림, 움직임, 표현하기 가이드를 살펴보세요',
          accent: AppColors.blobLavenderAccent,
          background: AppColors.blobLavender,
          alignX: 0.3,
          widthFactor: 0.9,
          floatSeed: 2,
          onTap: onGoToMeditation,
        ),
        const GardenPathConnector(startX: 0.3, endX: -0.28, decorEmoji: '🐾'),
        GardenPathCard(
          emoji: '🌡️',
          title: '마음 온도 기록 보기',
          subtitle: '지난 편지와 마음 온도 변화를 돌아보세요',
          accent: AppColors.blobRoseAccent,
          background: AppColors.blobRose,
          alignX: -0.28,
          widthFactor: 0.9,
          floatSeed: 3,
          onTap: onGoToRecords,
        ),
        const GardenPathConnector(startX: -0.28, endX: 0.26, decorEmoji: '🦋'),
        GardenPathCard(
          emoji: '🐟',
          title: '마음 돌보기',
          subtitle: '몸 돌봄과 호흡·걷기 명상, 마음기록으로 고양이를 함께 키워보세요',
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          alignX: 0.26,
          widthFactor: 0.92,
          floatSeed: 4,
          onTap: () =>
              _pushFullScreen(context, '마음 돌보기', const PetCareScreen()),
        ),
        const GardenPathConnector(startX: 0.26, endX: -0.3, decorEmoji: '🐾'),
        GardenPathCard(
          emoji: '🔮',
          title: '데일리 내면소통',
          subtitle: '오늘의 카드를 뽑아 위로와 지침을 받아보세요',
          accent: AppColors.blobPeriwinkleAccent,
          background: AppColors.blobPeriwinkle,
          alignX: -0.3,
          widthFactor: 0.9,
          floatSeed: 5,
          onTap: () =>
              _pushFullScreen(context, '데일리 내면소통', const DailyCardScreen()),
        ),
        const GardenPathConnector(startX: -0.3, endX: 0.28, decorEmoji: '🦋'),
        GardenPathCard(
          emoji: emotion.hasRecordedToday ? '🌙' : '🌗',
          title: emotion.hasRecordedToday ? '오늘의 감정 다시 기록하기' : '오늘의 감정 기록하기',
          subtitle: '지금 마음을 골라 달빛 정원에 짧게 남겨보세요',
          accent: AppColors.blobLavenderAccent,
          background: AppColors.blobLavender,
          alignX: 0.28,
          widthFactor: 0.9,
          floatSeed: 6,
          onTap: () => EmotionRecordSheet.show(context),
        ),
        const GardenPathConnector(startX: 0.28, endX: -0.26, decorEmoji: '🐾'),
        GardenPathCard(
          emoji: '📖',
          title: '마음 리포트 보기',
          subtitle: '한 달간의 감정 흐름을 따뜻하게 되돌아보세요',
          accent: AppColors.blobButterAccent,
          background: AppColors.blobButter,
          alignX: -0.26,
          widthFactor: 0.9,
          floatSeed: 7,
          onTap: () => MonthlyReportPickerSheet.show(context),
        ),
        const SizedBox(height: 40),
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

/// 오솔길 입구에 세워진 나무 팻말 느낌의 섹션 안내 - 딱딱한 사이드바 대신
/// 손글씨 폰트와 은은한 초록 밑줄로 위계를 드러냅니다.
class _PathSignpost extends StatelessWidget {
  final String title;
  const _PathSignpost({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 20, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.titlePastelGreenSoft,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

/// 며칠째 함께하는지를 보여주는 반투명 유기적 블롭 - 흰 사각 박스를 대체
class _StreakBlob extends StatelessWidget {
  final int streak;
  const _StreakBlob({required this.streak});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFF1D6),
                ),
                child: ClipOval(
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: value,
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment(-0.3, -0.4),
                            colors: [
                              Color(0xFFFFF6DF),
                              AppColors.goldSoft,
                              AppColors.gold,
                            ],
                            stops: [0, 0.55, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          RichText(
            text: TextSpan(
              style: bodyFont(fontSize: 13.5, color: AppColors.moon),
              children: [
                TextSpan(
                  text: '$streak',
                  style: numberFont(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldSoft,
                  ),
                ),
                const TextSpan(text: '일째 함께하는 중'),
              ],
            ),
          ),
        ],
      ),
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

/// 새로운 월간 마음 리포트가 도착했음을 알리는 은은한 달빛 배너
class _MonthlyReportBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _MonthlyReportBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
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
                      style: titleFont(
                        fontSize: 15,
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
            height: 1.8,
          ),
        ),
      ),
    );
  }
}
