import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../providers/app_state_provider.dart';
import '../mongi/providers/garden_provider.dart';
import '../services/unified_emotion_summary_service.dart';
import 'emotion_statistics_screen.dart';

/// Views existing records without copying, migrating or changing private notes.
class EmotionArchiveScreen extends StatefulWidget {
  const EmotionArchiveScreen({super.key, this.calendar = true});
  final bool calendar;
  @override
  State<EmotionArchiveScreen> createState() => _EmotionArchiveScreenState();
}

String? emotionRecordCatAsset(UnifiedEmotionRecord record) {
  const gardenCats = {
    'hate': 'hurtFeelings',
    'anger': 'angry',
    'worry': 'cautious',
    'sadness': 'sad',
    'loneliness': 'lonely',
    'anxiety': 'anxious',
    'shame': 'ashamed',
    'irritation': 'impatient',
    'grievance': 'wronged',
    'fear': 'dread',
    'joy': 'joyful',
    'gratitude': 'grateful',
    'excitement': 'excited',
    'calm': 'serene',
    'confidence': 'proud',
    'tired': 'weary',
    'boredom': 'indifferent',
    'courage': 'proud',
    'thrill': 'excited',
    'happiness': 'content',
  };
  final id = record.source == EmotionRecordSource.letter
      ? record.emotionId
      : gardenCats[record.emotionId];
  for (final cat in shadowCats) {
    if (cat.id == id) return cat.imageAsset;
  }
  return null;
}

class _EmotionArchiveScreenState extends State<EmotionArchiveScreen> {
  late bool calendar = widget.calendar;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  bool loading = true;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) loadGarden();
    });
  }

  Future<void> loadGarden() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      await context.read<GardenProvider>().ensureInitialized();
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? category;
  bool allMonths = false;
  Widget cat(UnifiedEmotionRecord record, double size) {
    final asset = emotionRecordCatAsset(record);
    return Tooltip(
      message: record.label,
      child: SizedBox(
        width: size,
        height: size,
        child: asset == null
            ? Icon(Icons.pets, color: record.color, size: size * .7)
            : Image.asset(
                asset,
                fit: BoxFit.contain,
                cacheWidth: (size * 3).round(),
                semanticLabel: '${record.label} 고양이',
              ),
      ),
    );
  }

  void detail(List<UnifiedEmotionRecord> records) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('이날의 감정 고양이', style: TextStyle(fontSize: 20)),
            for (final record in records)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: cat(record, 140)),
                      Text(
                        record.displayLabel,
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        '${record.date.year}.${record.date.month}.${record.date.day}'
                        '${record.hasTime ? ' · ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}' : ' · 시간 미기록'}',
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        record.note.isEmpty ? '감정을 남겼어요.' : record.note,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = UnifiedEmotionSummaryService.read(
      letters: context.watch<AppStateProvider>().history,
      gardenDiary: context.watch<GardenProvider>().diaryEntries,
    );
    final labels = <String, String>{
      for (final r in history) r.categoryKey: r.displayLabel,
    };
    // Deletions/account changes can remove the selected category.
    final filter = labels.containsKey(category) ? category : null;
    final records =
        history
            .where(
              (r) =>
                  (filter == null || r.categoryKey == filter) &&
                  (!calendar && allMonths ||
                      r.date.year == month.year && r.date.month == month.month),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final days = <int, List<UnifiedEmotionRecord>>{};
    for (final r in records) {
      days.putIfAbsent(r.date.day, () => []).add(r);
    }
    final offset = (month.weekday + 6) % 7;
    final count = DateTime(month.year, month.month + 1, 0).day;
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 마음 보관함'),
        actions: [
          IconButton(
            tooltip: '주간·월간 만화책',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EmotionStatisticsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (loading) const LinearProgressIndicator(),
            if (failed)
              TextButton(
                onPressed: loadGarden,
                child: const Text('정원 기록 불러오기 재시도'),
              ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('감정 캘린더'),
                  selected: calendar,
                  onSelected: (_) => setState(() => calendar = true),
                ),
                ChoiceChip(
                  label: const Text('고양이 카드 모아보기'),
                  selected: !calendar,
                  onSelected: (_) => setState(() => calendar = false),
                ),
                if (!calendar)
                  FilterChip(
                    label: const Text('전체 기간'),
                    selected: allMonths,
                    onSelected: (v) => setState(() => allMonths = v),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: '이전 달',
                  onPressed: () => setState(() {
                    month = DateTime(month.year, month.month - 1);
                    allMonths = false;
                  }),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('${month.year}년 ${month.month}월'),
                IconButton(
                  tooltip: '다음 달',
                  onPressed: () => setState(() {
                    month = DateTime(month.year, month.month + 1);
                    allMonths = false;
                  }),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                isExpanded: true,
                value: filter,
                hint: const Text('모든 감정'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('모든 감정'),
                  ),
                  for (final e in labels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => category = v),
              ),
            ),
            Expanded(
              child: calendar
                  ? ListView(
                      padding: const EdgeInsets.all(8),
                      children: [
                        Row(
                          children: [
                            for (final day in [
                              '월',
                              '화',
                              '수',
                              '목',
                              '금',
                              '토',
                              '일',
                            ])
                              Expanded(child: Center(child: Text(day))),
                          ],
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offset + count,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            // Day/count labels keep their system text scale. A height
                            // based only on column width overflows on narrow screens and
                            // makes date targets needlessly tall in landscape.
                            mainAxisExtent:
                                52 + MediaQuery.textScalerOf(context).scale(22),
                          ),
                          itemBuilder: (context, i) {
                            if (i < offset) return const SizedBox.shrink();
                            final day = i - offset + 1,
                                entries = days[i - offset + 1] ?? [];
                            final timed = entries
                                .where((r) => r.hasTime)
                                .toList();
                            final representative = timed.isNotEmpty
                                ? timed.first
                                : entries.isEmpty
                                ? null
                                : entries.first;
                            return InkWell(
                              key: ValueKey('emotion-calendar-day-$day'),
                              onTap: entries.isEmpty
                                  ? null
                                  : () => detail(entries),
                              child: Column(
                                children: [
                                  Text(
                                    '$day',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (representative != null)
                                    Expanded(
                                      child: FittedBox(
                                        child: cat(representative, 48),
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  if (entries.length > 1)
                                    Text(
                                      '+${entries.length - 1}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            '시간이 있는 기록 중 마지막 감정을 표시해요. 시간이 없는 기록도 날짜를 누르면 함께 볼 수 있어요.',
                          ),
                        ),
                        if (records.isEmpty)
                          const Center(child: Text('이 달에는 아직 남긴 감정이 없어요.')),
                      ],
                    )
                  : records.isEmpty
                  ? const Center(child: Text('아직 보관된 감정 카드가 없어요.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: records.length,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisExtent: 235,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemBuilder: (context, i) {
                        final r = records[i];
                        return Card(
                          child: InkWell(
                            onTap: () => detail([r]),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: FittedBox(child: cat(r, 140)),
                                  ),
                                  Text(
                                    r.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${r.date.year}.${r.date.month}.${r.date.day}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    r.note.isEmpty ? r.sourceLabel : r.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
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
  }
}
