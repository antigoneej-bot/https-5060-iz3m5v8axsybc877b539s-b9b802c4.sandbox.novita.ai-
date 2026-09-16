import '../widgets/subscription_gate.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/reflection_service.dart';
import '../services/subscription_service.dart';
import '../services/weekly_shadow_map_service.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/stars_background.dart';
import 'premium_screen.dart';

/// 감정 통계 · 확장 보기 — 방울 터뜨리기 + 감정체크로 쌓인 감정 데이터를 주
/// 단위로 시각화하는 화면.
///
/// 무료 티어: 이번 주 Top 3 감정 + 간단한 비율 시각화.
/// 프리미엄 티어: 지난 달/분기 비교, 요일·시간대 패턴 인사이트 — 흐릿한
/// 미리보기 + "더 깊이 들여다보기" CTA로 부담 없이 안내합니다.
///
/// 이 화면 전체는 '관찰'의 언어만 씁니다. 감정에 옳고 그름을 매기지 않고,
/// 정원이 나빠졌다/좋아졌다는 판단형 문구는 절대 쓰지 않습니다.
class WeeklyShadowMapScreen extends StatefulWidget {
  const WeeklyShadowMapScreen({super.key});

  @override
  State<WeeklyShadowMapScreen> createState() => _WeeklyShadowMapScreenState();
}

class _WeeklyShadowMapScreenState extends State<WeeklyShadowMapScreen> {
  bool _loadingPremium = true;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremium();
  }

  Future<void> _loadPremium() async {
    final premium = await SubscriptionService().isPremium();
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _loadingPremium = false;
    });
  }

  @override
  Widget build(BuildContext context) => SubscriptionGate(
    message: '상세 주간 분석은 마음냥 구독으로 이용해요. 기본 주간 통계는 무료예요.',
    builder: (_) => _content(context),
  );

  Widget _content(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final hasData = app.weeklyEntryCount > 0;

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
                        const SizedBox(width: 4),
                        Text(
                          '감정 통계 · 확장 보기',
                          style: titleFont(
                            fontSize: 19,
                            color: AppColors.titlePastelGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                      child: !hasData
                          ? const _NoWeeklyMapDataYet()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _MapIntroCaption(),
                                const SizedBox(height: 18),
                                _TopEmotionsCard(
                                  topEmotions: app.weeklyTopEmotions,
                                  total: app.weeklyEntryCount,
                                  last7Days: app.last7DaysCatIds(),
                                ),
                                const SizedBox(height: 22),
                                _DeeperInsightSection(
                                  isPremium: true,
                                  loading: false,
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

class _NoWeeklyMapDataYet extends StatelessWidget {
  const _NoWeeklyMapDataYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text(
            '아직 이번 주 기록이 없어요',
            style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 6),
          Text(
            '감정체크나 방울 터뜨리기를 하면\n이곳에서 이번 주 감정 지도를 볼 수 있어요',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// 데이터 시각화임을 은은하게 알려주는 짧은 안내(장식이 아니라 '내 감정
/// 패턴이 보이는 지도'라는 인식을 주기 위한 캡션).
class _MapIntroCaption extends StatelessWidget {
  const _MapIntroCaption();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '방울 터뜨리기와 감정체크로 쌓인 기록을\n지도처럼 펼쳐본 모습이에요',
        textAlign: TextAlign.center,
        style: bodyFont(fontSize: 12, color: AppColors.inkSoft, height: 1.6),
      ),
    );
  }
}

/// 무료 티어 — 이번 주 요일별 감정 색상 타일 + Top 3 비율 시각화.
class _TopEmotionsCard extends StatelessWidget {
  final List<(String, int)> topEmotions;
  final int total;
  final List<MapEntry<DateTime, String?>> last7Days;
  const _TopEmotionsCard({
    required this.topEmotions,
    required this.total,
    required this.last7Days,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      floatSeed: 41,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 7일, 날짜별 기록',
            style: pathLabelFont(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '하루 마지막 기록의 색이에요. 순위는 모든 편지를 세어요',
            style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          _WeekdayColorTiles(days: last7Days),
          const SizedBox(height: 22),
          Text(
            '자주 마주한 감정 Top 3',
            style: pathLabelFont(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '가장 자주 등장한 순서대로 보여드려요',
            style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 18),
          if (total > 0) _ProportionBar(topEmotions: topEmotions, total: total),
          const SizedBox(height: 18),
          for (int i = 0; i < topEmotions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TopEmotionRow(
                rank: i + 1,
                catId: topEmotions[i].$1,
                count: topEmotions[i].$2,
                total: total,
              ),
            ),
        ],
      ),
    );
  }
}

/// 요일별 감정 색상 타일(무료 티어의 '간단한 시각화' 옵션). 각 칸은 그날
/// 대표 감정의 브랜드 컬러로 채워지고, 기록이 없는 날은 중립 회색입니다.
/// 판단형 색상 매핑(좋다/나쁘다)은 쓰지 않습니다.
class _WeekdayColorTiles extends StatelessWidget {
  final List<MapEntry<DateTime, String?>> days;
  const _WeekdayColorTiles({required this.days});

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: entry.value != null
                          ? CatPalette.accentFor(
                              entry.value!,
                            ).withValues(alpha: 0.85)
                          : CatPalette.emptyDay,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _weekdayLabels[entry.key.weekday - 1],
                    style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 파이차트 대신, 손쉽게 구현 가능한 가로 비율 바(간단한 시각화)로
/// Top 3의 비중을 한눈에 보여줍니다.
class _ProportionBar extends StatelessWidget {
  final List<(String, int)> topEmotions;
  final int total;
  const _ProportionBar({required this.topEmotions, required this.total});

  @override
  Widget build(BuildContext context) {
    final otherCount = topEmotions.isEmpty
        ? 0
        : total - topEmotions.fold<int>(0, (a, e) => a + e.$2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 16,
        child: Row(
          children: [
            for (final e in topEmotions)
              Expanded(
                flex: e.$2,
                child: Container(color: CatPalette.accentFor(e.$1)),
              ),
            if (otherCount > 0)
              Expanded(
                flex: otherCount,
                child: Container(color: CatPalette.emptyDay),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopEmotionRow extends StatelessWidget {
  final int rank;
  final String catId;
  final int count;
  final int total;
  const _TopEmotionRow({
    required this.rank,
    required this.catId,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final accent = CatPalette.accentFor(catId);
    final name = ReflectionService.catNameFor(catId);
    final percent = total == 0 ? 0 : (count / total * 100).round();
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.85),
          ),
          child: Text(
            '$rank',
            style: numberFont(fontSize: 12, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: pathLabelFont(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        Text(
          '$count번 · $percent%',
          style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

/// 프리미엄 인사이트 섹션(비교 그래프, 요일/시간대 패턴). 무료 유저에게는
/// 흐릿한 미리보기 + "더 깊이 들여다보기" CTA를, 프리미엄 유저에게는 실제
/// 내용을 보여줍니다.
class _DeeperInsightSection extends StatelessWidget {
  final bool isPremium;
  final bool loading;
  const _DeeperInsightSection({required this.isPremium, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) return const SizedBox.shrink();
    if (!isPremium) {
      return _DeeperInsightLockedPreview(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
        },
      );
    }
    return const _DeeperInsightContent();
  }
}

/// 실제 프리미엄 인사이트 콘텐츠(비교 문장 + 요일/시간대 패턴 + 다시
/// 떠오른 감정). 그래프 라이브러리 없이, 문장형 관찰 + 간단한 막대
/// 비교로 구성합니다.
class _DeeperInsightContent extends StatelessWidget {
  const _DeeperInsightContent();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final (thisMonth, lastMonth) = app.monthVsLastMonthFrequency;
    final (thisQuarter, lastQuarter) = app.quarterVsLastQuarterFrequency;

    final monthSentence = WeeklyShadowMapService.periodComparisonSentence(
      currentFreq: thisMonth,
      previousFreq: lastMonth,
      catNameFor: ReflectionService.catNameFor,
      periodLabel: '이번 달',
      previousLabel: '지난 달',
    );
    final quarterSentence = WeeklyShadowMapService.periodComparisonSentence(
      currentFreq: thisQuarter,
      previousFreq: lastQuarter,
      catNameFor: ReflectionService.catNameFor,
      periodLabel: '이번 분기',
      previousLabel: '지난 분기',
    );
    final weekdayInsight = WeeklyShadowMapService.weekdayTimeInsightSentence(
      app.history,
      catNameFor: ReflectionService.catNameFor,
    );
    final resurfaced = WeeklyShadowMapService.buriedResurfaceTrendSentence(
      app.buriedEmotionEntries,
      catNameFor: ReflectionService.catNameFor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassBlob(
          accent: AppColors.blobPeriwinkleAccent,
          background: AppColors.blobPeriwinkle,
          floatSeed: 42,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📊', style: TextStyle(fontSize: 26)),
              const SizedBox(height: 10),
              Text(
                '지난 기간과 비교해보기',
                style: pathLabelFont(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _ComparisonBars(
                currentFreq: thisMonth,
                previousFreq: lastMonth,
                currentLabel: '이번 달',
                previousLabel: '지난 달',
              ),
              const SizedBox(height: 10),
              Text(
                monthSentence ?? '아직 비교할 만큼의 기록이 쌓이지 않았어요.',
                style: bodyFont(
                  fontSize: 12.5,
                  color: AppColors.moon,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              _ComparisonBars(
                currentFreq: thisQuarter,
                previousFreq: lastQuarter,
                currentLabel: '이번 분기',
                previousLabel: '지난 분기',
              ),
              const SizedBox(height: 10),
              Text(
                quarterSentence ?? '아직 분기 단위로 비교할 기록이 쌓이지 않았어요.',
                style: bodyFont(
                  fontSize: 12.5,
                  color: AppColors.moon,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassBlob(
          accent: AppColors.blobLavenderAccent,
          background: AppColors.blobLavender,
          floatSeed: 43,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🕰️', style: TextStyle(fontSize: 26)),
              const SizedBox(height: 10),
              Text(
                '요일 · 시간대 패턴',
                style: pathLabelFont(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                weekdayInsight ?? '아직 뚜렷한 요일·시간대 패턴을 찾기엔\n기록이 조금 더 필요해요.',
                style: bodyFont(
                  fontSize: 13,
                  color: AppColors.moon,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassBlob(
          accent: AppColors.blobRoseAccent,
          background: AppColors.blobRose,
          floatSeed: 44,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌗', style: TextStyle(fontSize: 26)),
              const SizedBox(height: 10),
              Text(
                '다시 떠오른 감정',
                style: pathLabelFont(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                resurfaced ??
                    '아직 다시 떠오른 감정이 없어요.\n무거운 마음이 있을 때 방울을 잠시 묻어두면,\n며칠 뒤 새싹으로 다시 만날 수 있어요.',
                style: bodyFont(
                  fontSize: 13,
                  color: AppColors.moon,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 두 기간의 Top 감정 빈도를 나란히 놓고 비교하는 간단한 가로 막대.
/// 차트 라이브러리 없이 Container 폭 비율만으로 구현합니다.
class _ComparisonBars extends StatelessWidget {
  final Map<String, int> currentFreq;
  final Map<String, int> previousFreq;
  final String currentLabel;
  final String previousLabel;
  const _ComparisonBars({
    required this.currentFreq,
    required this.previousFreq,
    required this.currentLabel,
    required this.previousLabel,
  });

  @override
  Widget build(BuildContext context) {
    final currentTotal = currentFreq.values.fold<int>(0, (a, b) => a + b);
    final previousTotal = previousFreq.values.fold<int>(0, (a, b) => a + b);
    final maxTotal = [
      currentTotal,
      previousTotal,
    ].fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SingleBarRow(
          label: previousLabel,
          value: previousTotal,
          maxValue: maxTotal,
          color: AppColors.inkSoft,
        ),
        const SizedBox(height: 8),
        _SingleBarRow(
          label: currentLabel,
          value: currentTotal,
          maxValue: maxTotal,
          color: AppColors.blobPeriwinkleAccent,
        ),
      ],
    );
  }
}

class _SingleBarRow extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  const _SingleBarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 14,
                    width: constraints.maxWidth * ratio.clamp(0.03, 1.0),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: numberFont(fontSize: 12, color: AppColors.moon),
          ),
        ),
      ],
    );
  }
}

/// 무료 유저에게 보이는 프리미엄 인사이트 미리보기 카드.
/// '잠금 해제'가 아니라 "더 깊이 들여다보기"라는 부담 없는 표현을 씁니다.
class _DeeperInsightLockedPreview extends StatelessWidget {
  final VoidCallback onTap;
  const _DeeperInsightLockedPreview({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: GlassBlob(
              accent: AppColors.blobPeriwinkleAccent,
              background: AppColors.blobPeriwinkle,
              floatSeed: 42,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: Column(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 28)),
                  const SizedBox(height: 12),
                  Text(
                    '지난 달과 비교하면,\n요일마다 다른 감정의 흐름이 보여요',
                    textAlign: TextAlign.center,
                    style: titleFont(
                      fontSize: 17,
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '지난 달/분기 비교, 요일·시간대 패턴,\n다시 떠오른 감정까지 함께 살펴볼 수 있어요.',
                    textAlign: TextAlign.center,
                    style: bodyFont(
                      fontSize: 13,
                      color: AppColors.moon,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.blobPeriwinkleAccent,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '더 깊이 들여다보기',
                    style: bodyFont(
                      fontSize: 13,
                      color: AppColors.blobPeriwinkleAccent,
                      fontWeight: FontWeight.w700,
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
