import '../widgets/period_reflection_card.dart';
import 'monthly_shadow_reflection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/letter_entry.dart';
import '../services/emotion_summary_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import 'weekly_shadow_map_screen.dart';
import 'daily_card_screen.dart';
import 'premium_screen.dart';

/// One entry for weekly/monthly statistics. Written feelings and random cards
/// are deliberately separate. Raw records remain available without subscription.
class EmotionStatisticsScreen extends StatefulWidget {
  final bool initialMonthly;
  const EmotionStatisticsScreen({super.key, this.initialMonthly = false});
  @override
  State<EmotionStatisticsScreen> createState() => _EmotionStatisticsScreenState();
}
class _EmotionStatisticsScreenState extends State<EmotionStatisticsScreen> {
  late bool _monthly;
  late DateTime _month;
  late DateTime _week;
  bool _premium = false;
  @override
  void initState() {
    super.initState();
    _monthly = widget.initialMonthly;
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _week = EmotionSummaryService.weekStart(now);
    _loadPremium();
  }
  Future<void> _loadPremium() async {
    final premium = await SubscriptionService().isPremium();
    if (mounted) setState(() => _premium = premium);
  }
  String _label(DateTime date) => '${date.month}/${date.day}';
  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    color: Colors.white,
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Text(title, style: bodyFont(fontSize: 17, color: AppColors.ink, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12), ...children],
    )),
  );
  void _openDay(DateTime day, List<LetterEntry> entries) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true,
      builder: (context) => SafeArea(child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('${_label(day)}의 기록 ${entries.length}개', style: bodyFont(fontSize: 19)),
          const SizedBox(height: 12),
          if (entries.isEmpty) const Text('이날은 남긴 기록이 없어요.'),
          for (final entry in entries) ListTile(
            title: Text('${shadowCatById(entry.catId).keyword} · ${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}'),
            subtitle: Text(entry.letterText.isEmpty ? '감정을 남겼어요.' : entry.letterText),
          ),
        ]),
      )),
    );
  }
  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppStateProvider>().history;
    final today = EmotionSummaryService.day(DateTime.now());
    final currentMonth = DateTime(today.year, today.month);
    final start = _monthly ? _month : _week;
    final lastOfMonth = DateTime(_month.year, _month.month + 1, 0);
    final periodEnd = _monthly ? lastOfMonth : EmotionSummaryService.weekEnd(_week);
    final end = periodEnd.isBefore(today) ? periodEnd : today;
    final records = EmotionSummaryService.entries(history, start, end);
    final ranked = EmotionSummaryService.ranked(records);
    final top = ranked.take(3).toList();
    final byDay = <DateTime, List<LetterEntry>>{};
    for (final entry in records) {
      byDay.putIfAbsent(EmotionSummaryService.day(entry.date), () => []).add(entry);
    }
    final days = end.difference(start).inDays + 1;
    final offset = _monthly ? start.weekday - 1 : 0;
    final calendarDays = _monthly ? lastOfMonth.day : 7;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: const Text('감정 통계')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 8, children: [
          ChoiceChip(label: const Text('주간'), selected: !_monthly,
            onSelected: (_) => setState(() => _monthly = false)),
          ChoiceChip(label: const Text('월간'), selected: _monthly,
            onSelected: (_) => setState(() => _monthly = true)),
        ]),
        if (_monthly) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(tooltip: '이전 달', onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left)),
          Text('${_month.year}년 ${_month.month}월', style: bodyFont(fontSize: 18)),
          IconButton(tooltip: '다음 달', onPressed: _month.isBefore(currentMonth)
            ? () => setState(() => _month = DateTime(_month.year, _month.month + 1)) : null, icon: const Icon(Icons.chevron_right)),
        ]),
        if (!_monthly) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(tooltip: '이전 주', onPressed: () => setState(() => _week = DateTime(_week.year, _week.month, _week.day - 7)), icon: const Icon(Icons.chevron_left)),
          Text('${_label(start)}–${_label(periodEnd)}'),
          IconButton(tooltip: '다음 주', onPressed: periodEnd.isBefore(today)
            ? () => setState(() => _week = DateTime(_week.year, _week.month, _week.day + 7)) : null, icon: const Icon(Icons.chevron_right)),
        ]),
        Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(
          '${start.year}년 ${_label(start)}–${_label(end)} · $days일 중 ${byDay.length}일 기록 · 총 ${records.length}번',
          style: bodyFont(fontSize: 15, color: AppColors.ink))),
        _section(_monthly ? '감정 달력' : '날짜별 기록', [
          const Text('색은 그날의 마지막 기록이에요. 날짜를 누르면 모든 기록을 볼 수 있어요.'),
          const SizedBox(height: 12),
          Row(children: [for (final day in ['월','화','수','목','금','토','일']) Expanded(child: Center(child: Text(day)))]),
          GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 4, mainAxisExtent: 76),
            itemCount: offset + calendarDays,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();
              final date = DateTime(start.year, start.month, start.day + index - offset);
              final entries = byDay[date] ?? <LetterEntry>[];
              final future = date.isAfter(today);
              final cat = entries.isEmpty ? null : shadowCatById(entries.last.catId);
              return Semantics(label: '${_label(date)}, ${entries.length}개 기록', button: !future,
                child: InkWell(onTap: future ? null : () => _openDay(date, entries),
                  child: Container(padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: cat == null ? AppColors.bg0 : CatPalette.backgroundFor(cat.id), borderRadius: BorderRadius.circular(10)),
                    child: Column(children: [Text('${date.day}', style: TextStyle(color: future ? Colors.grey : AppColors.ink)),
                      if (cat != null) Text(cat.emoji),
                      if (entries.length > 1) Text('+${entries.length - 1}', style: const TextStyle(fontSize: 11)),
                    ]),
                  ),
                ));
            }),
          const SizedBox(height: 8),
          const Text('빈칸은 기록이 없는 날이에요. 감정의 좋고 나쁨을 뜻하지 않아요.'),
        ]),
        _section('자주 기록한 감정', [
          if (records.isEmpty) const Text('아직 이 기간에 남긴 기록이 없어요. 편지를 쓰면 이곳에 쌓여요.'),
          for (final item in top) Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${shadowCatById(item.key).keyword} · 전체 ${records.length}번 중 ${item.value}번'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: item.value / records.length, color: CatPalette.accentFor(item.key), backgroundColor: AppColors.bg2, minHeight: 8),
          ])),
          if (ranked.length > 3) Text('그 밖의 감정 ${records.length - top.fold<int>(0, (sum, item) => sum + item.value)}번'),
          if (records.isNotEmpty) const Text('모든 편지의 선택 횟수예요. 감정의 강도나 전체 생활의 비율은 아니에요.'),
        ]),
        if (_monthly) _section('지난달과 나란히 보기', [
          if (!_premium) ...[
            const Text('구독으로 같은 기간의 기록량과 감정을 비교할 수 있어요.'),
            TextButton(onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
              await _loadPremium();
            }, child: const Text('정원 플러스 보기')),
          ] else ..._comparison(history, start, end, records),
        ]),
        PeriodReflectionCard(
          key: ValueKey('${_monthly ? 'month' : 'week'}_${start.toIso8601String()}'),
          periodKey: '${_monthly ? 'month' : 'week'}_${start.toIso8601String()}', monthly: _monthly,
        ),
        if (_monthly && _month == currentMonth && records.isNotEmpty)
          TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MonthlyShadowReflectionScreen())), child: const Text('이번 달 회고와 마무리 편지')),
        TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeeklyShadowMapScreen())), child: const Text('최근 기록의 확장 통계 보기')),
        TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('재미로 뽑는 카드')), body: const SingleChildScrollView(padding: EdgeInsets.all(20), child: DailyCardScreen())))), child: const Text('재미용 카드 따로 보기')),
      ])),
    );
  }
  List<Widget> _comparison(List<LetterEntry> history, DateTime start, DateTime end, List<LetterEntry> current) {
    final previousStart = DateTime(start.year, start.month - 1);
    final previousLast = DateTime(start.year, start.month, 0);
    final candidate = DateTime(previousStart.year, previousStart.month, end.day);
    final previousEnd = candidate.isAfter(previousLast) ? previousLast : candidate;
    final previous = EmotionSummaryService.entries(history, previousStart, previousEnd);
    final ranked = EmotionSummaryService.ranked(previous);
    return [
      Text('이번 기간 ${_label(start)}–${_label(end)}: ${EmotionSummaryService.recordedDays(current)}일, ${current.length}번 기록'),
      Text('지난 기간 ${_label(previousStart)}–${_label(previousEnd)}: ${EmotionSummaryService.recordedDays(previous)}일, ${previous.length}번 기록'),
      const SizedBox(height: 8),
      if (EmotionSummaryService.recordedDays(current) < 3 || EmotionSummaryService.recordedDays(previous) < 3)
        const Text('비교할 기록이 아직 적어요. 지금은 기록량만 살펴봐요.')
      else Text('지난 기간에는 ${shadowCatById(ranked.first.key).keyword}을(를) ${ranked.first.value}번 기록했어요. 기록량이 다르므로 감정이 더 심해졌거나 나아졌다는 뜻은 아니에요.'),
    ];
  }
}
