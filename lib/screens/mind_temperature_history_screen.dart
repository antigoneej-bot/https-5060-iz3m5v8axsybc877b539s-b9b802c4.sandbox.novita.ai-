import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/cat_care_service.dart';
import '../services/temperature_insight_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';

/// "마음온도기록" - 그동안 기록했던 마음 온도를 주간/월간 단위로 볼 수 있는
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
          '마음온도기록',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 22, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          '그동안 기록했던 마음 온도의 흐름을 살펴보세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 6),
        Text(
          '마음돌보기 임무를 완수하거나, 앱에 출석하거나,\n오늘의 약속을 지킬 때마다 온도가 기록돼요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 11,
            color: AppColors.inkSoft.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _RangeToggleButton(
                label: '주간',
                selected: _range == _TempHistoryRange.weekly,
                onTap: () => setState(() => _range = _TempHistoryRange.weekly),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _RangeToggleButton(
                label: '월간',
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
                  '아직 기록된 마음 온도가 없어요',
                  style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                ),
              ],
            ),
          )
        else ...[
          GlassBlob(
            accent: AppColors.blobPeachAccent,
            background: AppColors.blobPeach,
            padding: const EdgeInsets.all(18),
            child: _TempHistoryChart(entries: filtered),
          ),
          const SizedBox(height: 18),
          _TempInsightCard(
            insight: TemperatureInsightService.analyze(filtered),
            rangeLabel: _range == _TempHistoryRange.weekly ? '이번 주' : '이번 달',
          ),
          const SizedBox(height: 18),
          ...filtered.reversed.map((e) => _TempHistoryRow(entry: e)),
        ],
      ],
    );
  }
}

/// "마음 온도 심리 해석" 카드 - 칼 융의 그림자 심리학 관점에서 지금의
/// 온도 흐름이 어떤 상태인지, 어떻게 하면 좋을지, 위로와 응원, 명상법을
/// 함께 풀어서 보여줍니다. 숫자만 있던 화면에 "글로 풀어낸 마음"을
/// 더하기 위한 섹션입니다.
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
                        style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
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
              title: '지금은 이런 상태예요',
              body: insight.stateDescription,
            ),
            const SizedBox(height: 12),
            _InsightSection(
              icon: '🌿',
              title: '이렇게 해보면 좋아요',
              body: insight.solution,
            ),
            const SizedBox(height: 12),
            _InsightSection(
              icon: '💛',
              title: '위로와 응원의 말',
              body: insight.comfort,
            ),
            const SizedBox(height: 12),
            _InsightSection(
              icon: '🧘',
              title: '지금 상태에 맞는 명상법',
              body: insight.meditation,
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

/// 아주 단순한 막대형 온도 그래프. 별도 차트 패키지 없이 Row + 막대로만
/// 표현합니다.
class _TempHistoryChart extends StatelessWidget {
  final List<MapEntry<DateTime, int>> entries;
  const _TempHistoryChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final maxBars = entries.length > 14 ? 14 : entries.length;
    final shown = entries.length > maxBars
        ? entries.sublist(entries.length - maxBars)
        : entries;
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: shown.map((e) {
          final heightFactor = (e.value / 100).clamp(0.04, 1.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${e.value}',
                    style: bodyFont(
                      fontSize: 8.5,
                      color: AppColors.blobPeachAccent,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FractionallySizedBox(
                    heightFactor: heightFactor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.blobPeachAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
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
              '${entry.value}°',
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
