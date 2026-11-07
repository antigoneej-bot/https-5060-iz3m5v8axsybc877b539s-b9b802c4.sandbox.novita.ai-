import '../l10n/app_language.dart';
import '../widgets/emotion_cat_thumbnail.dart';
import '../services/cat_care_service.dart';
import '../services/garden_personal_gallery_store.dart';
import '../widgets/private_memory_links.dart';
import '../mongi/widgets/garden_keepsake_sheets.dart';
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
  final owner = CatCareService.localOwner;
  Set<String> favorites = {};
  bool favoritesOnly = false, favoriteBusy = false, favoritesReady = false;
  bool favoritesFailed = false;
  String query = '';
  Future<void> loadFavorites({bool showError = false}) async {
    try {
      final data = await GardenPersonalGalleryStore.read(owner);
      if (mounted && owner == CatCareService.localOwner)
        setState(() {
          favorites = Set<String>.from(data['favorites'] as List);
          favoritesReady = true;
          favoritesFailed = false;
        });
    } catch (_) {
      if (mounted) {
        setState(() => favoritesFailed = true);
        if (showError)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr("간직한 카드 목록을 불러오지 못했어요.")),
              action: SnackBarAction(
                label: tr("재시도"),
                onPressed: () => loadFavorites(showError: true),
              ),
            ),
          );
      }
    }
  }

  Future<void> toggleFavorite(UnifiedEmotionRecord record) async {
    if (favoriteBusy || !favoritesReady || owner != CatCareService.localOwner)
      return;
    setState(() => favoriteBusy = true);
    try {
      await GardenPersonalGalleryStore.favorite(
        owner,
        record.id,
        !favorites.contains(record.id),
      );
      await loadFavorites();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr("간직하기를 저장하지 못했어요."))));
    } finally {
      if (mounted) setState(() => favoriteBusy = false);
    }
  }

  Future<void> search() async {
    final controller = TextEditingController(text: query);
    final route = DialogRoute<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr("감정 카드 찾기")),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(
            labelText: tr("기록 내용·감정·날짜"),
            hintText: tr("예: 산책, 기쁨, 2026-11"),
          ),
          onSubmitted: (v) => Navigator.pop(c, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, ''),
            child: Text(tr("검색 지우기")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: Text(tr("찾기")),
          ),
        ],
      ),
    );
    final value = await Navigator.of(context).push(route);
    await route.completed;
    controller.dispose();
    if (value != null && mounted)
      setState(() {
        query = value.trim();
        calendar = false;
        allMonths = true;
      });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        loadGarden();
        loadFavorites();
      }
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
                semanticLabel: tr("{0} 고양이", [record.label]),
              ),
      ),
    );
  }

  void detail(List<UnifiedEmotionRecord> records) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: ListView(
            key: const Key('emotion-day-record-list'),
            padding: const EdgeInsets.all(20),
            children: [
              Text(tr("이날의 감정 고양이"), style: TextStyle(fontSize: 20)),
              for (final record in records)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: cat(
                            record,
                            (MediaQuery.sizeOf(context).width - 80).clamp(
                              120,
                              260,
                            ),
                          ),
                        ),
                        Text(
                          record.displayLabel,
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          '${record.date.year}.${record.date.month}.${record.date.day}'
                          '${record.hasTime ? ' · ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}' : tr(" · 시간 미기록")}',
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          record.note.isEmpty ? tr("감정을 남겼어요.") : record.note,
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (GardenPersonalGalleryStore.stableRecord(
                              record.id,
                            ))
                              TextButton.icon(
                                onPressed: !favoritesReady || favoriteBusy
                                    ? null
                                    : () async {
                                        final pending = toggleFavorite(record);
                                        update(() {});
                                        await pending;
                                        if (context.mounted) update(() {});
                                      },
                                icon: Icon(
                                  favorites.contains(record.id)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                label: Text(
                                  favorites.contains(record.id)
                                      ? tr("간직하기 해제")
                                      : tr("간직하기"),
                                ),
                              ),
                            if ((record.id.startsWith('letter:saved:') ||
                                    record.id.startsWith('garden:saved:')) &&
                                record.note.trim().isNotEmpty)
                              TextButton.icon(
                                onPressed: () async {
                                  if (owner != CatCareService.localOwner)
                                    return;
                                  await attachLetterQuoteToPlant(
                                    context,
                                    sourceLetterId:
                                        record.id.startsWith('garden:saved:')
                                        ? 'garden-diary:${record.id.substring('garden:saved:'.length)}'
                                        : record.id.substring(
                                            'letter:saved:'.length,
                                          ),
                                    quote: record.note,
                                  );
                                },
                                icon: const Icon(Icons.park_outlined),
                                label: Text(tr("나무에 연결")),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => showMemoryTree(context),
                                icon: const Icon(Icons.park_outlined),
                                label: Text(tr("기억의 나무 열기")),
                              ),
                          ],
                        ),
                        if (!GardenPersonalGalleryStore.stableRecord(record.id))
                          Text(tr("이전 형식의 기록은 간직하기를 지원하지 않아요.")),
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

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
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
                  (!favoritesOnly ||
                      favorites.contains(r.id) &&
                          owner == CatCareService.localOwner) &&
                  (query.isEmpty ||
                      ('${r.note} ${r.displayLabel} ${r.date.toIso8601String().substring(0, 10)} ${r.date.year}.${r.date.month}.${r.date.day}')
                          .toLowerCase()
                          .contains(query.toLowerCase())) &&
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
        title: Text(tr("나의 마음 보관함")),
        actions: [
          IconButton(
            tooltip: query.isEmpty ? tr("감정 카드 검색") : tr("검색 중: {0}", [query]),
            onPressed: search,
            icon: Icon(query.isEmpty ? Icons.search : Icons.manage_search),
          ),
          IconButton(
            tooltip: favoritesFailed
                ? tr("간직한 카드 불러오기 재시도")
                : favoritesOnly
                ? tr("모든 카드 보기")
                : tr("간직한 카드만 보기"),
            onPressed: favoritesReady
                ? () => setState(() => favoritesOnly = !favoritesOnly)
                : () => loadFavorites(showError: true),
            icon: Icon(
              favoritesFailed
                  ? Icons.error_outline
                  : favoritesOnly
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
          IconButton(
            tooltip: tr("주간·월간 만화책"),
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
                child: Text(tr("정원 기록 불러오기 재시도")),
              ),
            if (query.isNotEmpty || favoritesOnly)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (query.isNotEmpty)
                      InputChip(
                        label: Text(tr("검색: {0}", [query])),
                        onDeleted: () => setState(() => query = ''),
                      ),
                    if (favoritesOnly)
                      InputChip(
                        label: Text(tr("간직한 카드")),
                        onDeleted: () => setState(() => favoritesOnly = false),
                      ),
                  ],
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(tr("감정 캘린더")),
                  selected: calendar,
                  onSelected: (_) => setState(() => calendar = true),
                ),
                ChoiceChip(
                  label: Text(tr("고양이 카드 모아보기")),
                  selected: !calendar,
                  onSelected: (_) => setState(() => calendar = false),
                ),
                if (!calendar)
                  FilterChip(
                    label: Text(tr("전체 기간")),
                    selected: allMonths,
                    onSelected: (v) => setState(() => allMonths = v),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: tr("이전 달"),
                  onPressed: () => setState(() {
                    month = DateTime(month.year, month.month - 1);
                    allMonths = false;
                  }),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(tr("{0}년 {1}월", [month.year, month.month])),
                IconButton(
                  tooltip: tr("다음 달"),
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
                hint: Text(tr("모든 감정")),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(tr("모든 감정")),
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
                              tr("월"),
                              tr("화"),
                              tr("수"),
                              tr("목"),
                              tr("금"),
                              tr("토"),
                              tr("일"),
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
                            // Reserve a full column-width square for the cat. Count is
                            // an overlay, so extra records no longer shrink the artwork.
                            mainAxisExtent:
                                ((MediaQuery.sizeOf(context).width - 16) / 7)
                                    .clamp(40.0, 96.0)
                                    .toDouble() +
                                MediaQuery.textScalerOf(context).scale(16) +
                                12,
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
                            return Semantics(
                              label: tr("{0}월 {1}일, {2}", [
                                month.month,
                                day,
                                entries.isEmpty
                                    ? tr("기록 없음")
                                    : tr("{0}, {1}개 기록", [
                                        representative!.label,
                                        entries.length,
                                      ]),
                              ]),
                              button: entries.isNotEmpty,
                              child: InkWell(
                                key: ValueKey('emotion-calendar-day-$day'),
                                onTap: entries.isEmpty
                                    ? null
                                    : () => detail(entries),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  margin: const EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: representative == null
                                        ? null
                                        : representative.background.withValues(
                                            alpha: .35,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$day',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Expanded(
                                        child: representative == null
                                            ? const SizedBox.expand()
                                            : Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(1),
                                                    child:
                                                        emotionRecordCatAsset(
                                                              representative,
                                                            ) ==
                                                            null
                                                        ? cat(
                                                            representative,
                                                            96,
                                                          )
                                                        : EmotionCatThumbnail(
                                                            asset:
                                                                emotionRecordCatAsset(
                                                                  representative,
                                                                )!,
                                                            label:
                                                                representative
                                                                    .label,
                                                          ),
                                                  ),
                                                  if (entries.length > 1)
                                                    Positioned(
                                                      right: 1,
                                                      bottom: 1,
                                                      child: DecoratedBox(
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xF5FCF9F3,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 3,
                                                              ),
                                                          child: Text(
                                                            '+${entries.length - 1}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 10,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            tr(
                              "시간이 있는 기록 중 마지막 감정을 표시해요. 시간이 없는 기록도 날짜를 누르면 함께 볼 수 있어요.",
                            ),
                          ),
                        ),
                        if (records.isEmpty)
                          Center(child: Text(tr("이 달에는 아직 남긴 감정이 없어요."))),
                      ],
                    )
                  : records.isEmpty
                  ? Center(
                      child: Text(
                        query.isNotEmpty || favoritesOnly
                            ? tr("조건에 맞는 카드가 없어요. 검색·간직하기 필터를 바꿔 보세요.")
                            : tr("아직 보관된 감정 카드가 없어요."),
                      ),
                    )
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
                                    '${favorites.contains(r.id) ? '♥ ' : ''}${r.label}',
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
