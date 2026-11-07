import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/emotion_l10n.dart';
import '../l10n/emotion_trigger_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/monthly_observation_l10n.dart';
import '../l10n/weekday_l10n.dart';
import '../models/emotion.dart';
import '../models/emotion_trigger.dart';
import '../providers/garden_provider.dart';
import '../services/emotion_insight_service.dart';

/// "감정 캘린더" - 한 달간 어떤 감정을 얼마나 마주했는지 한눈에 보여주는
/// GitHub 커밋그래프 스타일의 히트맵. 다이어리에 이미 저장된 [date/emotionType/
/// eatenCount] 데이터를 그대로 재사용하므로 별도 저장 로직이 필요 없다.
///
/// 목적: 재방문 동기 부여 + "이번 달 나는 어떤 감정을 많이 마주했나" 자기 이해.
class EmotionCalendarScreen extends StatefulWidget {
  const EmotionCalendarScreen({super.key});

  @override
  State<EmotionCalendarScreen> createState() => _EmotionCalendarScreenState();
}

class _EmotionCalendarScreenState extends State<EmotionCalendarScreen> {
  late DateTime _displayedMonth;
  bool _insightExpanded = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final byDate = _groupByDate(garden.diaryEntries);
    final insight = EmotionInsightService.buildMonthlyInsight(
      diaryEntries: garden.diaryEntries,
      month: _displayedMonth,
    );
    final weekdayPattern = EmotionInsightService.buildWeekdayPattern(
      diaryEntries: garden.diaryEntries,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F0F5), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      _buildMonthNav(l10n),
                      const SizedBox(height: 12),
                      _buildInsightPanel(l10n, insight, weekdayPattern),
                      const SizedBox(height: 16),
                      _buildCalendarGrid(l10n, byDate),
                      const SizedBox(height: 16),
                      _buildLegend(l10n),
                      const SizedBox(height: 20),
                      _buildMonthSummary(l10n, byDate),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.calendarHeaderTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.ink),
          onPressed: () => setState(() {
            _displayedMonth = DateTime(
              _displayedMonth.year,
              _displayedMonth.month - 1,
              1,
            );
          }),
        ),
        Text(
          l10n.calendarMonthLabel(_displayedMonth.year, _displayedMonth.month),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: AppColors.ink),
          onPressed: () => setState(() {
            _displayedMonth = DateTime(
              _displayedMonth.year,
              _displayedMonth.month + 1,
              1,
            );
          }),
        ),
      ],
    );
  }

  /// "이달의 감정 키워드 / 다양성 지수 / 최장 연속 기록 / 주차별 추이"를
  /// 보여주는 접이식 해석 패널. 기존 캘린더 UI는 그대로 두고, 그 위에
  /// 요약 카드 하나만 얹는 형태로 최소 침습적으로 설계했다.
  Widget _buildInsightPanel(
    AppLocalizations l10n,
    MonthlyEmotionInsight insight,
    WeekdayEmotionPattern weekdayPattern,
  ) {
    if (!insight.hasEnoughData) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          l10n.calendarInsightNotEnoughData,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
      );
    }

    final top = insight.topEmotion;
    final second = insight.secondEmotion;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => setState(() => _insightExpanded = !_insightExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                children: [
                  const Text('📖', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      top != null
                          ? l10n.calendarInsightTitleWithTop(
                              second != null
                                  ? '${emotionLabel(l10n, top.type)} & ${emotionLabel(l10n, second.type)}'
                                  : emotionLabel(l10n, top.type),
                            )
                          : l10n.calendarInsightTitleFallback,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(
                    _insightExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.inkSoft,
                  ),
                ],
              ),
            ),
          ),
          if (_insightExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFF0EAE3)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatChip(
                          icon: '🎨',
                          label: l10n.calendarStatDiversityLabel,
                          value: l10n.calendarStatDiversityValue(
                            insight.uniqueEmotionCount,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatChip(
                          icon: '🔥',
                          label: l10n.calendarStatStreakLabel,
                          value: l10n.calendarStatStreakValue(
                            insight.longestStreak,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.calendarWeeklyTrendTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildWeeklyTrendChart(l10n, insight),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(
                        color: const Color(0xFFF5C244),
                        label: l10n.calendarLegendPositive,
                      ),
                      const SizedBox(width: 14),
                      _LegendDot(
                        color: const Color(0xFF8C9CB4),
                        label: l10n.calendarLegendNegative,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF0EAE3)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.calendarWeekdayTrendTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weekdayObservationText(
                      l10n,
                      weekdayPattern.observationResult,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                  ),
                  if (weekdayPattern.hasEnoughData) ...[
                    const SizedBox(height: 12),
                    _buildWeekdayChart(l10n, weekdayPattern),
                  ],
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF0EAE3)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.calendarMonthDistributionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildEmotionDistribution(l10n, insight),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF0EAE3)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.calendarMonthAnalysisTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    monthlyObservationText(l10n, insight.observationResult),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// "이 달의 감정 수치" - [MonthlyEmotionInsight.emotionRatios]를 감정별
  /// 가로 바 리스트로 시각화한다. 이미 최다/2위 감정만 제목에서 보여주고
  /// 있었으므로, 여기서는 이 달에 등장한 감정 전체(비율 내림차순)를 한눈에
  /// 볼 수 있게 채워준다.
  Widget _buildEmotionDistribution(
    AppLocalizations l10n,
    MonthlyEmotionInsight insight,
  ) {
    final ratios = insight.emotionRatios;
    if (ratios.isEmpty) return const SizedBox.shrink();

    return Column(
      children: ratios.map((entry) {
        final emotion = entry.key;
        final ratio = entry.value;
        final percent = (ratio * 100).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(emotion.gardenIcon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              SizedBox(
                width: 56,
                child: Text(
                  emotionLabel(l10n, emotion.type),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF0EAE3),
                    valueColor: AlwaysStoppedAnimation<Color>(emotion.color),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: Text(
                  l10n.calendarMonthDistributionPercent(percent),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 요일(일~토) 하나당 막대 하나로 긍정/부정 비율을 보여주는 미니 차트.
  /// 데이터가 있는 요일만 진하게, 3회 미만인 요일은 옅게 표시해서 표본이
  /// 적은 요일과 뚜렷한 요일을 시각적으로 구분한다.
  Widget _buildWeekdayChart(
    AppLocalizations l10n,
    WeekdayEmotionPattern pattern,
  ) {
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: pattern.stats.map((stat) {
          final ratio = stat.positiveRatio;
          final hasData = ratio != null;
          final reliable = stat.total >= 3;
          const barMaxHeight = 70.0;
          final positiveHeight = hasData ? barMaxHeight * ratio : 0.0;
          final negativeHeight = hasData ? barMaxHeight * (1 - ratio) : 0.0;
          final opacity = reliable ? 1.0 : 0.4;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!hasData)
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3DCD3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  else ...[
                    Opacity(
                      opacity: opacity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        child: Container(
                          height: positiveHeight.clamp(0, barMaxHeight),
                          color: const Color(0xFFF5C244),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: opacity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(4),
                        ),
                        child: Container(
                          height: negativeHeight.clamp(0, barMaxHeight),
                          color: const Color(0xFF8C9CB4),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    weekdayLabel(l10n, stat.weekdayIndex),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasData
                          ? AppColors.inkSoft
                          : const Color(0xFFBDB3A8),
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

  Widget _buildStatChip({
    required String icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bg0,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon $label',
            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  /// 주차별 긍정/부정 비율을 막대로 보여주는 아주 단순한 커스텀 페인터
  /// 기반 차트. 외부 차트 패키지 없이 가볍게 구현했다.
  Widget _buildWeeklyTrendChart(
    AppLocalizations l10n,
    MonthlyEmotionInsight insight,
  ) {
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(insight.weeklyPositiveRatios.length, (i) {
          final ratio = insight.weeklyPositiveRatios[i];
          final hasData = ratio != null;
          const barMaxHeight = 70.0;
          final positiveHeight = hasData ? barMaxHeight * ratio : 0.0;
          final negativeHeight = hasData ? barMaxHeight * (1 - ratio) : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!hasData)
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3DCD3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      child: Container(
                        height: positiveHeight.clamp(0, barMaxHeight),
                        color: const Color(0xFFF5C244),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(4),
                      ),
                      child: Container(
                        height: negativeHeight.clamp(0, barMaxHeight),
                        color: const Color(0xFF8C9CB4),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    l10n.calendarWeekLabel(i + 1),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendarGrid(
    AppLocalizations l10n,
    Map<String, List<Map<String, dynamic>>> byDate,
  ) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Dart: Monday=1 ... Sunday=7. 캘린더는 일요일 시작으로 보여준다.
    final leadingBlanks = firstDay.weekday % 7;

    final weekdayLabels = List.generate(7, (i) => weekdayLabel(l10n, i));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: weekdayLabels
                .map(
                  (w) => Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: leadingBlanks + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final dateKey =
                  '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final entries = byDate[dateKey] ?? const [];
              return _DayCell(day: day, entries: entries);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(AppLocalizations l10n) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: Emotion.all
          .map(
            (e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: e.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  emotionLabel(l10n, e.type),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget _buildMonthSummary(
    AppLocalizations l10n,
    Map<String, List<Map<String, dynamic>>> byDate,
  ) {
    final monthPrefix =
        '${_displayedMonth.year}-${_displayedMonth.month.toString().padLeft(2, '0')}';
    final monthEntries = byDate.entries
        .where((e) => e.key.startsWith(monthPrefix))
        .expand((e) => e.value)
        .toList();

    if (monthEntries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          l10n.calendarEmptyMonth,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
      );
    }

    final countByType = <String, int>{};
    for (final e in monthEntries) {
      final t = e['emotionType'] as String? ?? '';
      countByType[t] = (countByType[t] ?? 0) + 1;
    }
    final sorted = countByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final topEmotion = Emotion.byTypeName(top.key);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.calendarMonthSummaryTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.calendarMonthSummaryTopEmotion(
              emotionLabel(l10n, topEmotion.type),
              topEmotion.gardenIcon,
            ),
            style: TextStyle(
              fontSize: 13.5,
              color: topEmotion.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.calendarMonthSummaryTotal(monthEntries.length),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> entries,
  ) {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in entries) {
      final date = entry['date'] as String? ?? '';
      result.putIfAbsent(date, () => []).add(entry);
    }
    return result;
  }
}

/// 캘린더 한 칸(하루)을 나타낸다. 그 날 기록이 있으면 대표 감정 색으로
/// 채워지고(진하기=기록 개수), 탭하면 그 날의 기록을 바텀시트로 보여준다.
class _DayCell extends StatelessWidget {
  final int day;
  final List<Map<String, dynamic>> entries;

  const _DayCell({required this.day, required this.entries});

  @override
  Widget build(BuildContext context) {
    final hasEntries = entries.isNotEmpty;
    Color? bgColor;
    String? emoji;
    if (hasEntries) {
      final countByType = <String, int>{};
      for (final e in entries) {
        final t = e['emotionType'] as String? ?? '';
        countByType[t] = (countByType[t] ?? 0) + 1;
      }
      final topType =
          (countByType.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
      final emotion = Emotion.byTypeName(topType);
      final intensity = (entries.length / 3.0).clamp(0.25, 1.0);
      bgColor = emotion.color.withValues(alpha: 0.18 + 0.35 * intensity);
      emoji = emotion.gardenIcon;
    }

    return GestureDetector(
      onTap: hasEntries ? () => _showDayDetail(context) : null,
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.bg0,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 11,
                fontWeight: hasEntries ? FontWeight.w800 : FontWeight.w500,
                color: hasEntries ? AppColors.ink : const Color(0xFFBDB3A8),
              ),
            ),
            if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showDayDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.calendarDayDetailTitle(day),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              ...entries.map((e) {
                final emotion = Emotion.byTypeName(
                  e['emotionType'] as String? ?? '',
                );
                final note = e['note'] as String?;
                final intensity = (e['intensity'] as num?)?.toInt();
                final triggerIds = (e['triggers'] as List?)
                    ?.whereType<String>()
                    .toList();
                final target = e['targetName'] as String?;
                final label = (target != null && target.isNotEmpty)
                    ? l10n.shareNameLabelWithTarget(
                        target,
                        emotionLabel(l10n, emotion.type),
                      )
                    : emotionLabel(l10n, emotion.type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emotion.gardenIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: emotion.color,
                                fontSize: 13,
                              ),
                            ),
                            if (note != null && note.isNotEmpty)
                              Text(
                                note,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            if ((intensity != null &&
                                    intensity >= 1 &&
                                    intensity <= 5) ||
                                (triggerIds != null && triggerIds.isNotEmpty))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 5,
                                  runSpacing: 4,
                                  children: [
                                    if (intensity != null &&
                                        intensity >= 1 &&
                                        intensity <= 5)
                                      Text(
                                        l10n.calendarIntensityLabel(
                                          '${'●' * intensity}${'○' * (5 - intensity)}',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    if (triggerIds != null)
                                      for (final id in triggerIds)
                                        Text(
                                          emotionTriggerDisplay(
                                            l10n,
                                            EmotionTrigger.byId(id),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// 주차별 추이 차트 아래 범례 점 하나(색상 + 라벨).
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
