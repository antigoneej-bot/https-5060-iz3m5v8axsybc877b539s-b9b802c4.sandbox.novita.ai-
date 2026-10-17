import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cat_care_provider.dart';
import '../services/cat_care_service.dart';
import '../services/temperature_insight_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import 'emotion_statistics_screen.dart';

/// Three neutral numeric ranges for the care activity counter.
Color colorForTempTier(TempTier tier) {
  switch (tier) {
    case TempTier.positive:
      return AppColors.blobMintAccent;
    case TempTier.neutral:
      return AppColors.blobButterAccent;
    case TempTier.negative:
      return AppColors.blobRoseAccent;
  }
}

/// "돌봄 온기 기록" - 저장된 활동 보상 값을 최근 7일/30일 단위로 보는
/// 화면. CatCareService.getTempHistory()에 쌓인 날짜별 온도를 그대로
/// 불러와, 선택한 기간만큼만 필터링해서 보여줍니다.
enum _TempHistoryRange { weekly, monthly }

class MindTemperatureHistoryScreen extends StatefulWidget {
  const MindTemperatureHistoryScreen({super.key});

  @override
  State<MindTemperatureHistoryScreen> createState() =>
      _MindTemperatureHistoryScreenState();
}

class _MindTemperatureHistoryScreenState
    extends State<MindTemperatureHistoryScreen> {
  _TempHistoryRange _range = _TempHistoryRange.weekly;
  bool _loading = true;
  List<MapEntry<DateTime, int>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await CatCareService.getTempHistory();
    if (!mounted) return;
    // 히스토리 보정으로 온도 prefs가 바뀌었을 수 있어 홈 온도도 다시 맞춥니다.
    try {
      await context.read<CatCareProvider>().load();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  List<MapEntry<DateTime, int>> get _filtered {
    final days = _range == _TempHistoryRange.weekly ? 7 : 30;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final cutoff = todayStart.subtract(Duration(days: days - 1));
    return _history.where((e) => !e.key.isBefore(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.blobMintAccent),
        ),
      );
    }

    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '돌봄 온기 기록',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 22, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          '활동으로 차곡차곡 모은 온기를 살펴보세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 6),
        Text(
          TemperatureInsightService.activityExplanation,
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 11,
            color: AppColors.inkSoft.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EmotionStatisticsScreen()),
          ),
          icon: const Icon(Icons.auto_stories_outlined),
          label: const Text('내가 남긴 감정과 회고 보기'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _RangeToggleButton(
                label: '최근 7일',
                selected: _range == _TempHistoryRange.weekly,
                onTap: () => setState(() => _range = _TempHistoryRange.weekly),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RangeToggleButton(
                label: '최근 30일',
                selected: _range == _TempHistoryRange.monthly,
                onTap: () => setState(() => _range = _TempHistoryRange.monthly),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Text('🌡️', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 12),
                Text(
                  '아직 저장된 돌봄 온기가 없어요',
                  style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                ),
              ],
            ),
          )
        else ...[
          _TempTierSummaryCard(
            breakdown: TemperatureInsightService.tierBreakdown(filtered),
            rangeLabel: _range == _TempHistoryRange.weekly ? '최근 7일' : '최근 30일',
          ),
          const SizedBox(height: 18),
          GlassBlob(
            accent: AppColors.blobPeachAccent,
            background: AppColors.blobPeach,
            padding: const EdgeInsets.all(18),
            child: _TempHistoryChart(entries: filtered),
          ),
          const SizedBox(height: 18),
          _TempInsightCard(
            insight: TemperatureInsightService.analyze(filtered),
            rangeLabel: _range == _TempHistoryRange.weekly ? '최근 7일' : '최근 30일',
          ),
          const SizedBox(height: 18),
          ...filtered.reversed.map((e) => _TempHistoryRow(entry: e)),
        ],
      ],
    );
  }
}

/// Explains activity records without inferring emotional health.
class _TempInsightCard extends StatefulWidget {
  final TemperatureInsight? insight;
  final String rangeLabel;
  const _TempInsightCard({required this.insight, required this.rangeLabel});

  @override
  State<_TempInsightCard> createState() => _TempInsightCardState();
}

class _TempInsightCardState extends State<_TempInsightCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    if (insight == null) return const SizedBox.shrink();

    return GlassBlob(
      accent: AppColors.catNavy,
      background: AppColors.catNavyBg,
      padding: const EdgeInsets.all(20),
      floatSeed: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Text(insight.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.rangeLabel}, ${insight.bandLabel}',
                        style: pathLabelFont(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight.trendLabel,
                        style: bodyFont(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.inkSoft,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 14),
            _InsightSection(
              icon: '🔍',
              title: '이 기록의 의미',
              body: insight.stateDescription,
            ),
            const SizedBox(height: 12),
            _InsightSection(
              icon: '🌿',
              title: '내 감정을 돌아보려면',
              body: insight.solution,
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  final String icon;
  final String title;
  final String body;
  const _InsightSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg1.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                title,
                style: pathLabelFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.catNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: bodyFont(fontSize: 12.5, color: AppColors.ink, height: 1.65),
          ),
        ],
      ),
    );
  }
}

class _RangeToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : AppColors.bg1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.gold : AppColors.line),
        ),
        child: Text(
          label,
          style: pathLabelFont(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

/// Counts stored days per numeric range, not positive/negative moods.
class _TempTierSummaryCard extends StatelessWidget {
  final TempTierBreakdown breakdown;
  final String rangeLabel;
  const _TempTierSummaryCard({
    required this.breakdown,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final total = breakdown.totalDays;
    return GlassBlob(
      accent: AppColors.blobMintAccent,
      background: AppColors.blobMint,
      padding: const EdgeInsets.all(20),
      floatSeed: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$rangeLabel 온기 구간',
            style: pathLabelFont(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '저장된 $total일의 온기 값을 숫자 구간으로 나눴어요',
            style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          // 누적 비율 막대: 전체를 100%로 두고 세 구간이 차지하는 비율을
          // 한 줄로 보여줘, "숫자를 몰라도 색 길이만 보면 감이 온다"를
          // 목표로 합니다.
          if (total > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    if (breakdown.positiveDays > 0)
                      Expanded(
                        flex: breakdown.positiveDays,
                        child: Container(
                          color: colorForTempTier(TempTier.positive),
                        ),
                      ),
                    if (breakdown.neutralDays > 0)
                      Expanded(
                        flex: breakdown.neutralDays,
                        child: Container(
                          color: colorForTempTier(TempTier.neutral),
                        ),
                      ),
                    if (breakdown.negativeDays > 0)
                      Expanded(
                        flex: breakdown.negativeDays,
                        child: Container(
                          color: colorForTempTier(TempTier.negative),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TierCountBox(
                  tier: TempTier.positive,
                  days: breakdown.positiveDays,
                  percent: breakdown.positivePercent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TierCountBox(
                  tier: TempTier.neutral,
                  days: breakdown.neutralDays,
                  percent: breakdown.neutralPercent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TierCountBox(
                  tier: TempTier.negative,
                  days: breakdown.negativeDays,
                  percent: breakdown.negativePercent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '구간은 마음의 좋고 나쁨을 뜻하지 않아요. 하루의 마지막 온기 값을 표시하며, '
              '보상 적립 후 0부터 다시 쌓인 날도 포함돼요.',
              style: bodyFont(fontSize: 11, color: AppColors.moon, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCountBox extends StatelessWidget {
  final TempTier tier;
  final int days;
  final double percent;
  const _TierCountBox({
    required this.tier,
    required this.days,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorForTempTier(tier);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(tier.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            tier.label,
            style: pathLabelFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$days일',
            style: numberFont(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            '${percent.round()}%',
            style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Daily activity-counter values, with neutral range labels.
class _TempHistoryChart extends StatelessWidget {
  final List<MapEntry<DateTime, int>> entries;
  const _TempHistoryChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final maxBars = entries.length > 14 ? 14 : entries.length;
    final shown = entries.length > maxBars
        ? entries.sublist(entries.length - maxBars)
        : entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜별 돌봄 온기 (0~100)',
          style: pathLabelFont(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: shown.map((e) {
              // Column은 non-flex 자식에게 maxHeight=무한을 넘긴다.
              // 그 안에서 FractionallySizedBox(heightFactor:)를 쓰면
              // ∞ × factor → 자식 Container 높이가 0이 되어 막대가 안 보인다.
              // Expanded로 유한 높이를 준 뒤, 그 비율만큼 실제 height를 계산한다.
              final heightFactor = (e.value / 100).clamp(0.04, 1.0);
              final tierColor = colorForTempTier(
                TemperatureInsightService.tierFor(e.value),
              );
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Text(
                        '${e.value}',
                        style: bodyFont(fontSize: 8.5, color: tierColor),
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barHeight =
                                (constraints.maxHeight * heightFactor).clamp(
                                  2.0,
                                  constraints.maxHeight,
                                );
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: barHeight,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: tierColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _ChartLegendDot(
              color: colorForTempTier(TempTier.positive),
              label: '67~100',
            ),
            _ChartLegendDot(
              color: colorForTempTier(TempTier.neutral),
              label: '34~66',
            ),
            _ChartLegendDot(
              color: colorForTempTier(TempTier.negative),
              label: '0~33',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '최근 ${shown.length}개의 저장 값을 표시해요. 색은 온기 값의 구간이에요. '
          '보상 적립으로 값이 줄어들 수 있어 감정의 변화로 해석하지 않아요.',
          style: bodyFont(
            fontSize: 10.5,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft)),
      ],
    );
  }
}

class _TempHistoryRow extends StatelessWidget {
  final MapEntry<DateTime, int> entry;
  const _TempHistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(entry.key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateStr,
                style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ),
            Text(
              '${entry.value}',
              style: numberFont(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.blobPeachAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
