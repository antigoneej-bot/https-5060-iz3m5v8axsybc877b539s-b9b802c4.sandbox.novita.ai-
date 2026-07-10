import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/emotion_entry.dart';
import '../models/monthly_report.dart';
import '../data/solutions_data.dart';
import '../theme.dart';
import '../widgets/moonlit_report_background.dart';

/// 월간 감정 리포트 - '밤의 정원' 무드로 한 달의 마음 흐름을 되돌아보는 화면
/// 순서: 한 줄 요약 → 그래프(원형/막대/선) → 따뜻한 해석 → 조언 → 추천 명상
class MonthlyReportScreen extends StatelessWidget {
  final MonthlyEmotionReport report;
  const MonthlyReportScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MoonlitReportBackground(
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
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${report.monthLabel} 마음 리포트',
                          style: bodyFont(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: report.isEmpty
                        ? _EmptyReportView(monthLabel: report.monthLabel)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SummaryHero(report: report),
                                const SizedBox(height: 28),
                                _NightSectionLabel(
                                  icon: '🌙',
                                  label: '이번 달 감정 비율',
                                ),
                                const SizedBox(height: 14),
                                _EmotionPieCard(report: report),
                                const SizedBox(height: 24),
                                _NightSectionLabel(
                                  icon: '✨',
                                  label: '날짜별 감정 흐름',
                                ),
                                const SizedBox(height: 14),
                                _DailyFlowLineCard(report: report),
                                const SizedBox(height: 24),
                                _NightSectionLabel(icon: '🌌', label: '감정 빈도'),
                                const SizedBox(height: 14),
                                _EmotionBarCard(report: report),
                                const SizedBox(height: 24),
                                _NightSectionLabel(
                                  icon: '🕯️',
                                  label: '긍정 · 부정 흐름',
                                ),
                                const SizedBox(height: 14),
                                _ValenceCompareCard(report: report),
                                const SizedBox(height: 28),
                                _NightSectionLabel(
                                  icon: '🐈‍⬛',
                                  label: '그림자 정원의 속삭임',
                                ),
                                const SizedBox(height: 14),
                                _AnalysisCard(text: report.analysisText),
                                const SizedBox(height: 24),
                                _NightSectionLabel(
                                  icon: '🕊️',
                                  label: '이 달의 다정한 조언',
                                ),
                                const SizedBox(height: 14),
                                _AdviceCard(text: report.adviceText),
                                const SizedBox(height: 24),
                                _NightSectionLabel(
                                  icon: '🧘',
                                  label: '지금 필요한 명상',
                                ),
                                const SizedBox(height: 14),
                                _RecommendedMeditationCard(report: report),
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

class _NightSectionLabel extends StatelessWidget {
  final String icon;
  final String label;
  const _NightSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 8),
        Text(
          label,
          style: serifFont(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

/// 밤 정원 톤의 공용 카드 컨테이너 (은은한 반투명 유리 느낌)
class _NightCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _NightCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: child,
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
            const Text('🌙', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 16),
            Text(
              '$monthLabel에는 아직\n기록된 마음이 없어요',
              textAlign: TextAlign.center,
              style: serifFont(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '매일 조금씩 감정을 남겨두면\n다음 리포트에서 마음의 흐름을 만날 수 있어요',
              textAlign: TextAlign.center,
              style: bodyFont(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.55),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🌘', style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 14),
          Text(
            report.oneLineSummary,
            style: serifFont(
              fontSize: 17.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.55,
            ),
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
                    color: Colors.white.withValues(alpha: 0.6),
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

    return _NightCard(
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
                          style: bodyFont(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: bodyFont(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.55),
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

    return _NightCard(
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
                color: Colors.white.withValues(alpha: 0.08),
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
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
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
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
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
                color: AppColors.gold,
                barWidth: 2.4,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.gold.withValues(alpha: 0.28),
                      AppColors.gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF2E3652),
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        '${s.x.toInt()}일 · ${s.y.toStringAsFixed(1)}',
                        const TextStyle(color: Colors.white, fontSize: 11),
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

    return _NightCard(
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
                color: Colors.white.withValues(alpha: 0.06),
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
                    if (idx < 0 || idx >= sorted.length)
                      return const SizedBox.shrink();
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
                        color: Colors.white.withValues(alpha: 0.04),
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

    return _NightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _valenceRow('🌤️ 긍정 감정', posPct, const Color(0xFFE7B65C)),
          const SizedBox(height: 14),
          _valenceRow('🌧️ 부정 감정', negPct, const Color(0xFF7C93B8)),
          const SizedBox(height: 16),
          Text(
            report.avgIntensityFirstHalf > 0 &&
                    report.avgIntensitySecondHalf > 0
                ? '평균 감정 강도 · 월초 ${report.avgIntensityFirstHalf.toStringAsFixed(1)} → 월말 ${report.avgIntensitySecondHalf.toStringAsFixed(1)}'
                : '평균 감정 강도가 아직 충분히 쌓이지 않았어요',
            style: bodyFont(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
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
            Text(
              label,
              style: bodyFont(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${(pct * 100).round()}%',
              style: bodyFont(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
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
    return _NightCard(
      child: Text(
        text,
        style: bodyFont(
          fontSize: 13.5,
          color: Colors.white.withValues(alpha: 0.85),
          height: 1.75,
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String text;
  const _AdviceCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gold.withValues(alpha: 0.22),
            AppColors.gold.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
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
                color: Colors.white.withValues(alpha: 0.92),
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
    return _NightCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.recommendationReason,
            style: bodyFont(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.7),
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
                      borderRadius: BorderRadius.circular(14),
                      onTap: () =>
                          setState(() => _expandedKey = expanded ? null : key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
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
                                    style: bodyFont(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    guide.subtitle,
                                    style: bodyFont(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              expanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 8),
                    _NightGuideSteps(guide: guide),
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

/// 밤 정원 톤에 맞춘 명상 단계 안내 (GuideSteps를 다크 배경용으로 재구성)
class _NightGuideSteps extends StatelessWidget {
  final SolutionGuide guide;
  const _NightGuideSteps({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
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
                    color: AppColors.gold.withValues(alpha: 0.85),
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
                    style: bodyFont(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
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
