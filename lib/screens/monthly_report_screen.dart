import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/emotion_entry.dart';
import '../models/monthly_report.dart';
import '../data/solutions_data.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/garden_path_card.dart';
import '../services/subscription_service.dart';
import 'premium_screen.dart';

/// 월간 감정 리포트 - '힐링 정원' 낮 무드로 한 달의 마음 흐름을 되돌아보는 화면
/// 순서: 한 줄 요약 → 그래프(원형/막대/선) → 따뜻한 해석 → 조언 → 추천 명상
///
/// 한 줄 요약 + 감정 비율(원형 그래프)는 무료로 누구나 볼 수 있고,
/// 그 아래 상세 그래프 · 분석 · 조언 · 명상 추천은 '정원 플러스' 구독자만
/// 볼 수 있는 프리미엄 영역입니다(비구독자에게는 잠금 카드로 안내).
class MonthlyReportScreen extends StatefulWidget {
  final MonthlyEmotionReport report;
  const MonthlyReportScreen({super.key, required this.report});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  bool _isPremium = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final premium = await SubscriptionService().isPremium();
    if (!mounted) return;
    setState(() {
      _isPremium = premium;
      _loading = false;
    });
  }

  MonthlyEmotionReport get report => widget.report;

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
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
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
                          '${report.monthLabel} 마음 리포트',
                          style: pathLabelFont(
                            fontSize: 15,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : report.isEmpty
                        ? _EmptyReportView(monthLabel: report.monthLabel)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SummaryHero(report: report),
                                const SizedBox(height: 28),
                                const _SectionLabel(
                                  icon: '🌷',
                                  label: '이번 달 감정 비율',
                                ),
                                const SizedBox(height: 14),
                                _EmotionPieCard(report: report),
                                const SizedBox(height: 28),
                                if (_isPremium) ...[
                                  const _SectionLabel(
                                    icon: '✨',
                                    label: '날짜별 감정 흐름',
                                  ),
                                  const SizedBox(height: 14),
                                  _DailyFlowLineCard(report: report),
                                  const SizedBox(height: 24),
                                  const _SectionLabel(
                                    icon: '🌼',
                                    label: '감정 빈도',
                                  ),
                                  const SizedBox(height: 14),
                                  _EmotionBarCard(report: report),
                                  const SizedBox(height: 24),
                                  const _SectionLabel(
                                    icon: '🌤️',
                                    label: '긍정 · 부정 흐름',
                                  ),
                                  const SizedBox(height: 14),
                                  _ValenceCompareCard(report: report),
                                  const SizedBox(height: 28),
                                  const _SectionLabel(
                                    icon: '🐈',
                                    label: '정원 고양이의 속삭임',
                                  ),
                                  const SizedBox(height: 14),
                                  _AnalysisCard(text: report.analysisText),
                                  const SizedBox(height: 24),
                                  const _SectionLabel(
                                    icon: '🕊️',
                                    label: '이 달의 다정한 조언',
                                  ),
                                  const SizedBox(height: 14),
                                  _AdviceCard(text: report.adviceText),
                                  const SizedBox(height: 24),
                                  const _SectionLabel(
                                    icon: '🧘',
                                    label: '지금 필요한 명상',
                                  ),
                                  const SizedBox(height: 14),
                                  _RecommendedMeditationCard(report: report),
                                ] else
                                  _PremiumLockedSection(onUpgraded: _load),
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

/// 비구독자에게 "상세 그래프 · 분석 · 조언 · 명상 추천"이 잠겨있음을 알리고
/// 정원 플러스 구독 화면으로 안내하는 카드.
class _PremiumLockedSection extends StatelessWidget {
  final VoidCallback onUpgraded;
  const _PremiumLockedSection({required this.onUpgraded});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      child: Column(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 14),
          Text(
            '여기부터는 정원 플러스\n멤버십 전용이에요',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            '날짜별 감정 흐름, 감정 빈도, 긍정·부정 비교,\n'
            '정원 고양이의 속삭임과 다정한 조언, 맞춤 명상 추천을\n'
            '정원 플러스에서 모두 확인할 수 있어요',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
                onUpgraded();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 13,
                ),
                child: Text(
                  '정원 플러스 알아보기',
                  style: serifFont(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: pathLabelFont(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.titlePastelGreen,
          ),
        ),
      ],
    );
  }
}

class _EmptyReportView extends StatelessWidget {
  final String monthLabel;
  const _EmptyReportView({required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 16),
            Text(
              '$monthLabel에는 아직\n기록된 마음이 없어요',
              textAlign: TextAlign.center,
              style: titleFont(fontSize: 19, color: AppColors.ink, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              '매일 조금씩 감정을 남겨두면\n다음 리포트에서 마음의 흐름을 만날 수 있어요',
              textAlign: TextAlign.center,
              style: bodyFont(
                fontSize: 12.5,
                color: AppColors.inkSoft,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  final MonthlyEmotionReport report;
  const _SummaryHero({required this.report});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobPeachAccent,
      background: AppColors.blobPeach,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌞', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 14),
          Text(
            report.oneLineSummary,
            style: titleFont(fontSize: 19, color: AppColors.ink, height: 1.5),
          ),
          if (report.dominantEmotion != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  report.dominantEmotion!.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  '이 달의 대표 감정 · ${report.dominantEmotion!.label}',
                  style: bodyFont(
                    fontSize: 12,
                    color: AppColors.blobPeachAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 감정 비율 원형 그래프
class _EmotionPieCard extends StatelessWidget {
  final MonthlyEmotionReport report;
  const _EmotionPieCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final sortedEntries = report.emotionRatios.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      child: Row(
        children: [
          SizedBox(
            width: 128,
            height: 128,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2.5,
                centerSpaceRadius: 34,
                sections: sortedEntries.map((e) {
                  final pct = (e.value * 100);
                  return PieChartSectionData(
                    value: e.value,
                    color: e.key.color,
                    radius: 30,
                    showTitle: pct >= 12,
                    title: pct >= 12 ? '${pct.round()}%' : '',
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sortedEntries.map((e) {
                final pct = (e.value * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: e.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${e.key.emoji} ${e.key.label}',
                          style: bodyFont(fontSize: 12, color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: bodyFont(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 날짜별 감정 흐름 선 그래프 (부호 있는 점수: -5~+5)
class _DailyFlowLineCard extends StatelessWidget {
  final MonthlyEmotionReport report;
  const _DailyFlowLineCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (int i = 0; i < report.dailyScores.length; i++)
        FlSpot(
          report.dailyScores[i].key.day.toDouble(),
          report.dailyScores[i].value,
        ),
    ];

    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            minY: -5.5,
            maxY: 5.5,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (v) => FlLine(
                color: AppColors.ink.withValues(alpha: 0.08),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: 5,
                  getTitlesWidget: (v, meta) {
                    String label;
                    if (v == 5) {
                      label = '긍정';
                    } else if (v == -5) {
                      label = '부정';
                    } else if (v == 0) {
                      label = '0';
                    } else {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      label,
                      style: TextStyle(fontSize: 9.5, color: AppColors.inkSoft),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 5,
                  getTitlesWidget: (v, meta) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${v.toInt()}일',
                      style: TextStyle(fontSize: 9.5, color: AppColors.inkSoft),
                    ),
                  ),
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.28,
                color: AppColors.blobLavenderAccent,
                barWidth: 2.4,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.blobLavenderAccent.withValues(alpha: 0.28),
                      AppColors.blobLavenderAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.white.withValues(alpha: 0.92),
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        '${s.x.toInt()}일 · ${s.y.toStringAsFixed(1)}',
                        TextStyle(color: AppColors.ink, fontSize: 11),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 감정 빈도 막대 그래프
class _EmotionBarCard extends StatelessWidget {
  final MonthlyEmotionReport report;
  const _EmotionBarCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final sorted = EmotionType.values.toList();
    final maxCount = report.emotionCounts.values.isEmpty
        ? 1
        : report.emotionCounts.values.reduce((a, b) => a > b ? a : b);

    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.fromLTRB(14, 20, 18, 14),
      child: SizedBox(
        height: 160,
        child: BarChart(
          BarChartData(
            maxY: (maxCount + 1).toDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: AppColors.ink.withValues(alpha: 0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= sorted.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        sorted[idx].emoji,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < sorted.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (report.emotionCounts[sorted[i]] ?? 0).toDouble(),
                      color: sorted[i].color,
                      width: 16,
                      borderRadius: BorderRadius.circular(6),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: (maxCount + 1).toDouble(),
                        color: AppColors.ink.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 긍정/부정 감정 비교 (은은한 이중 바)
class _ValenceCompareCard extends StatelessWidget {
  final MonthlyEmotionReport report;
  const _ValenceCompareCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final total = report.positiveCount + report.negativeCount;
    final posPct = total == 0 ? 0.0 : report.positiveCount / total;
    final negPct = total == 0 ? 0.0 : report.negativeCount / total;

    return GlassBlob(
      accent: AppColors.blobRoseAccent,
      background: AppColors.blobRose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _valenceRow('🌤️ 긍정 감정', posPct, AppColors.blobButterAccent),
          const SizedBox(height: 14),
          _valenceRow('🌧️ 부정 감정', negPct, AppColors.blobPeriwinkleAccent),
          const SizedBox(height: 16),
          Text(
            report.avgIntensityFirstHalf > 0 &&
                    report.avgIntensitySecondHalf > 0
                ? '평균 감정 강도 · 월초 ${report.avgIntensityFirstHalf.toStringAsFixed(1)} → 월말 ${report.avgIntensitySecondHalf.toStringAsFixed(1)}'
                : '평균 감정 강도가 아직 충분히 쌓이지 않았어요',
            style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _valenceRow(String label, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: bodyFont(fontSize: 12.5, color: AppColors.ink)),
            Text(
              '${(pct * 100).round()}%',
              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: AppColors.ink.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String text;
  const _AnalysisCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobPeriwinkleAccent,
      background: AppColors.blobPeriwinkle,
      child: Text(
        text,
        style: bodyFont(fontSize: 13.5, color: AppColors.ink, height: 1.75),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String text;
  const _AdviceCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobPeachAccent,
      background: AppColors.blobPeach,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🕯️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: bodyFont(
                fontSize: 13.5,
                color: AppColors.ink,
                height: 1.7,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedMeditationCard extends StatefulWidget {
  final MonthlyEmotionReport report;
  const _RecommendedMeditationCard({required this.report});

  @override
  State<_RecommendedMeditationCard> createState() =>
      _RecommendedMeditationCardState();
}

class _RecommendedMeditationCardState
    extends State<_RecommendedMeditationCard> {
  String? _expandedKey;

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.recommendationReason,
            style: bodyFont(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          ...report.recommendedMeditationKeys.map((key) {
            final guide = breathingGuide[key];
            if (guide == null) return const SizedBox.shrink();
            final expanded = _expandedKey == key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          setState(() => _expandedKey = expanded ? null : key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: expanded ? 0.68 : 0.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.blobMintAccent.withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              guide.icon,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    guide.title,
                                    style: pathLabelFont(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    guide.subtitle,
                                    style: bodyFont(
                                      fontSize: 11,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.blobMintAccent,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 8),
                    _ReportGuideSteps(guide: guide),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 낮 정원 톤에 맞춘 명상 단계 안내 (GuideSteps를 리포트용으로 재구성)
class _ReportGuideSteps extends StatelessWidget {
  final SolutionGuide guide;
  const _ReportGuideSteps({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.blobMintAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: guide.steps.asMap().entries.map((entry) {
          return Padding(
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
                    style: bodyFont(fontSize: 12.5, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
