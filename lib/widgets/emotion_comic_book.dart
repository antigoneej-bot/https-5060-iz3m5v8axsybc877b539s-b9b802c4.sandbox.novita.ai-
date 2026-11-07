import '../l10n/app_language.dart';
import '../mongi/integration/mongi_garden_store.dart';
import '../mongi/models/seed.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import '../data/shadow_cats_data.dart';
import '../models/companion_coat.dart';
import '../services/draft_service.dart';
import '../services/emotion_summary_service.dart';
import '../services/unified_emotion_summary_service.dart';
import '../theme.dart';
import 'companion_coat_art.dart';

/// All records are paginated, never sampled or turned into invented events.
List<List<UnifiedEmotionRecord>> comicPages(
  List<UnifiedEmotionRecord> records,
) {
  final sorted = [...records]
    ..sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date == 0 ? a.id.compareTo(b.id) : date;
    });
  final pages = <List<UnifiedEmotionRecord>>[];
  var batch = <UnifiedEmotionRecord>[];
  for (final record in sorted) {
    if (batch.isNotEmpty &&
        (batch.length == 4 ||
            EmotionSummaryService.weekStart(batch.first.date) !=
                EmotionSummaryService.weekStart(record.date))) {
      pages.add(List.unmodifiable(batch));
      batch = [];
    }
    batch.add(record);
  }
  if (batch.isNotEmpty) pages.add(List.unmodifiable(batch));
  return pages;
}

class EmotionComicBook extends StatefulWidget {
  final UnifiedEmotionPeriod summary;
  final DateTime start, end;
  final bool monthly, detailed;
  const EmotionComicBook({
    super.key,
    required this.summary,
    required this.start,
    required this.end,
    required this.monthly,
    required this.detailed,
  });
  @override
  State<EmotionComicBook> createState() => _EmotionComicBookState();
}

class _EmotionComicBookState extends State<EmotionComicBook> {
  int _page = 0;
  List<Map<String, dynamic>> _events = [];
  String? _eventError;
  bool _sharing = false;
  final _capture = GlobalKey();
  late final DraftTextController _title;
  static const ink = Color(0xFF594031);
  static const paper = Color(0xFFFFFAF0);
  @override
  void initState() {
    super.initState();
    _loadEvents();
    _title = DraftTextController(
      'comic_title_${widget.monthly ? 'month' : 'week'}_${widget.start.toIso8601String()}',
    );
  }

  Future<void> _loadEvents() async {
    try {
      await MongiGardenStore.instance.reload();
      final data = MongiGardenStore.instance.value;
      final events = [...data.lifeEvents];
      // A saved planting date is evidence; never infer growth dates from today's size.
      for (final e in data.plantedOn.entries) {
        if (!events.any(
          (v) =>
              v['kind'] == 'plant' && v['plant'] == e.key && v['at'] == e.value,
        )) {
          events.add({
            'kind': 'plant',
            'plant': e.key,
            'at': e.value,
            'level': 1,
          });
        }
      }
      events.sort((a, b) => (a['at'] as String).compareTo(b['at'] as String));
      if (mounted)
        setState(() {
          _events = events;
          _eventError = null;
        });
    } catch (_) {
      if (mounted) setState(() => _eventError = tr("정원 이야기를 불러오지 못했어요."));
    }
  }

  Widget _gardenScenes(List<Map<String, dynamic>> events, {Key? key}) => Column(
    key: key,
    children: [
      heading(tr("내 정원이 자란 날")),
      for (final event in events)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  event['kind'] == 'plant'
                      ? Icons.spa_outlined
                      : Icons.park_outlined,
                  size: 64,
                  color: const Color(0xFF82A58A),
                ),
                Text(
                  '${event['at']} · ${SeedType.byId(event['plant'] as String).label}',
                ),
                Text(
                  event['kind'] == 'plant'
                      ? tr("이날 내 정원에 심었어요.")
                      : tr("{0}단계로 자랐어요.", [event['level']]),
                ),
              ],
            ),
          ),
        ),
      note(tr("실제로 저장된 심기·성장 기록이에요. 최근 1,000건의 사건을 보관해요.")),
    ],
  );

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String date(DateTime d) => '${d.month}/${d.day}';
  Text heading(String s, [double size = 27]) => Text(
    s,
    textAlign: TextAlign.center,
    style: titleFont(fontSize: size, color: ink),
  );
  Widget note(String s) => Text(
    s,
    textAlign: TextAlign.center,
    style: bodyFont(fontSize: 13, color: ink),
  );
  void _openRecords(String title, List<UnifiedEmotionRecord> records) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              heading(title),
              if (records.isEmpty)
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(tr("이날 남긴 기록은 없어요.")),
                ),
              for (final r in records)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${date(r.date)} · ${r.displayLabel}',
                          style: bodyFont(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          r.note.isEmpty ? tr("감정만 남긴 기록이에요.") : r.note,
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr("닫기")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr("이 장을 이미지로 내보낼까요?")),
        content: Text(
          tr("화면에 보이는 감정, 기록 문장과 직접 쓴 제목이 이미지에 담겨요. 공유 대상을 직접 선택할 수 있어요."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr("취소")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr("이미지 내보내기")),
          ),
        ],
      ),
    );
    if (consent != true || !mounted) return;
    setState(() => _sharing = true);
    try {
      FocusScope.of(context).unfocus();
      await _title.flush();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null || !mounted) return;
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes.buffer.asUint8List(),
              mimeType: 'image/png',
              name:
                  'mindnyang-comic-${widget.start.year}-${widget.start.month}-${_page + 1}.png',
            ),
          ],
          text: tr("마음냥 정원 · 나의 작은 이야기"),
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr("이미지 내보내기를 다시 시도해 주세요."))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final pages = comicPages(widget.summary.records);
    final events = _events.where((e) {
      final day = DateTime.parse(e['at'] as String);
      return !day.isBefore(DateUtils.dateOnly(widget.start)) &&
          !day.isAfter(DateUtils.dateOnly(widget.end));
    }).toList();
    final gardenPages = <List<Map<String, dynamic>>>[
      for (var i = 0; i < events.length; i += 4)
        events.sublist(i, (i + 4).clamp(0, events.length).toInt()),
    ];
    final totalScenes = pages.length + gardenPages.length;
    final page = _page.clamp(0, totalScenes);
    final last = page == totalScenes;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        if (_eventError != null)
          TextButton(
            onPressed: _loadEvents,
            child: Text(tr("{0} 다시 시도", [_eventError])),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: tr("이전 장"),
              onPressed: page > 0
                  ? () => setState(() => _page = page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: note(
                last
                    ? tr("마지막 장 · {0} / {1}", [page + 1, totalScenes + 1])
                    : tr("{0} / {1} · 나의 이야기", [page + 1, totalScenes + 1]),
              ),
            ),
            IconButton(
              tooltip: tr("다음 장"),
              onPressed: last ? null : () => setState(() => _page = page + 1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -180 && !last) setState(() => _page = page + 1);
            if (velocity > 180 && page > 0) setState(() => _page = page - 1);
          },
          child: RepaintBoundary(
            key: _capture,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE2C7AD), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x197D5B43),
                    offset: Offset(3, 5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  note(tr("마음냥 정원")),
                  heading(
                    last
                        ? (widget.monthly ? tr("이번 달의 마음냥") : tr("이번 주의 마음냥"))
                        : tr("마음냥 만화책"),
                  ),
                  note(
                    tr("{0}년 {1}–{2}", [
                      widget.start.year,
                      date(widget.start),
                      date(widget.end),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: reduced ? 0 : 220),
                    child: last
                        ? _summary(key: const ValueKey('summary'))
                        : page < pages.length
                        ? _scenes(pages[page], key: ValueKey(page))
                        : _gardenScenes(
                            gardenPages[page - pages.length],
                            key: ValueKey(page),
                          ),
                  ),
                  const SizedBox(height: 12),
                  note(tr("내가 남긴 기록으로 엮은 이야기")),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (!last)
          TextButton(
            onPressed: () => setState(() => _page = totalScenes),
            child: Text(tr("마지막 장 · 마음 모아 보기")),
          ),
        FilledButton.icon(
          onPressed: _sharing ? null : _share,
          icon: const Icon(Icons.ios_share),
          label: Text(_sharing ? tr("이미지를 준비하고 있어요") : tr("이 장 간직하기 · 공유")),
        ),
        const SizedBox(height: 8),
        note(tr("좌우로 넘겨 읽어요. 그림은 감정의 표현이며 실제 사건을 재현하지 않아요.")),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _scenes(List<UnifiedEmotionRecord> records, {Key? key}) =>
      LayoutBuilder(
        key: key,
        builder: (context, constraints) {
          final two =
              constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(14) < 20;
          final width = two
              ? (constraints.maxWidth - 10) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 10,
            runSpacing: 14,
            children: [
              for (final r in records)
                SizedBox(
                  width: width,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () =>
                        _openRecords(tr("{0}의 마음", [date(r.date)]), [r]),
                    child: Container(
                      decoration: BoxDecoration(
                        color: r.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD6BDA9)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '${date(r.date)} · ${r.label}',
                              textAlign: TextAlign.center,
                              style: bodyFont(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ink,
                              ),
                            ),
                          ),
                          AspectRatio(aspectRatio: 1.1, child: _recordArt(r)),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(9),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .94),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              r.note.isEmpty
                                  ? tr("{0}을 느낀 날", [r.label])
                                  : r.note,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: bodyFont(fontSize: 15, color: ink),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Text(
                              tr("{0} · 눌러서 전체 읽기", [r.sourceLabel]),
                              style: bodyFont(fontSize: 11, color: ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
  Widget _recordArt(UnifiedEmotionRecord r) {
    final matches = shadowCats.where((cat) => cat.id == r.emotionId);
    if (r.source == EmotionRecordSource.letter && matches.isNotEmpty) {
      return Image.asset(
        matches.first.imageAsset,
        fit: BoxFit.cover,
        cacheWidth: 500,
        errorBuilder: (_, __, ___) => _room([r]),
      );
    }
    return _room([r]);
  }

  Widget _room(List<UnifiedEmotionRecord> records) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/living_garden/comic_room.png',
        fit: BoxFit.cover,
        cacheWidth: 1000,
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: .78,
          child: Row(
            children: [
              for (var i = 0; i < records.length; i++)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        records[i].emoji,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 23),
                      ),
                      Expanded(
                        child: CompanionCoatArt(
                          coat: [
                            CompanionCoat.white,
                            CompanionCoat.tabby,
                            CompanionCoat.ginger,
                          ][i % 3],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
  Widget _summary({Key? key}) {
    final summary = widget.summary;
    final top = summary.ranked.take(widget.detailed ? 3 : 1).toList();
    return Column(
      key: key,
      children: [
        if (top.isEmpty) ...[
          const Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: Color(0xFFBC9177),
          ),
          heading(tr("첫 이야기를 기다려요"), 24),
          note(tr("편지나 정원 일기에 마음을 남기면 이 책에 모여요.")),
        ] else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: _room(top.map((e) => e.emotion).toList()),
            ),
          ),
          const SizedBox(height: 10),
          heading(tr("자주 만난 마음 친구들"), 23),
          for (final item in top)
            Card(
              color: item.emotion.background,
              elevation: 0,
              child: ListTile(
                leading: Text(
                  item.emotion.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
                title: Text(
                  item.emotion.displayLabel,
                  style: bodyFont(fontSize: 16, color: ink),
                ),
                subtitle: Text(tr("{0}번 만났어요", [item.count])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openRecords(
                  item.emotion.displayLabel,
                  summary.records
                      .where((r) => r.categoryKey == item.emotion.categoryKey)
                      .toList(),
                ),
              ),
            ),
          if (widget.detailed && summary.ranked.length > top.length)
            note(
              tr("그 밖의 마음 {0}번", [
                summary.records.length -
                    top.fold<int>(0, (n, e) => n + e.count),
              ]),
            ),
        ],
        const SizedBox(height: 20),
        heading(tr("차곡차곡 남긴 발자국"), 25),
        note(
          tr("{0}일 동안, {1}개의 마음을 남겼어요", [
            summary.recordedDays,
            summary.records.length,
          ]),
        ),
        const SizedBox(height: 12),
        _calendar(),
        const SizedBox(height: 20),
        heading(widget.monthly ? tr("나에게 이번 달은") : tr("나에게 이번 주는"), 24),
        TextField(
          controller: _title,
          maxLength: 60,
          maxLines: 2,
          style: const TextStyle(
            fontFamily: 'GamjaFlower',
            fontSize: 26,
            color: ink,
          ),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: tr("나의 이야기 제목을 적어 주세요"),
            filled: true,
            fillColor: Color(0xFFFFE7DF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: _title.saveStatus,
          builder: (_, value, __) =>
              note(value.replaceAll(tr("임시저장"), tr("저장"))),
        ),
        note(tr("제목은 이 기기에 저장되며 기록 백업에 포함돼요.")),
      ],
    );
  }

  Widget _calendar() {
    final start = widget.start;
    final offset = start.weekday - 1;
    final total = widget.monthly
        ? DateTime(start.year, start.month + 1, 0).day
        : 7;
    final cells = ((offset + total + 6) ~/ 7) * 7;
    final days = <DateTime, List<UnifiedEmotionRecord>>{};
    for (final r in widget.summary.records) {
      days.putIfAbsent(EmotionSummaryService.day(r.date), () => []).add(r);
    }
    return Column(
      children: [
        Row(
          children: [
            for (final s in [
              tr("월"),
              tr("화"),
              tr("수"),
              tr("목"),
              tr("금"),
              tr("토"),
              tr("일"),
            ])
              Expanded(child: note(s)),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 62,
          ),
          itemBuilder: (context, i) {
            final n = i - offset;
            if (n < 0 || n >= total) return const SizedBox.shrink();
            final d = DateTime(start.year, start.month, start.day + n);
            final records = days[d] ?? <UnifiedEmotionRecord>[];
            final future = d.isAfter(widget.end);
            return Semantics(
              label: tr("{0}, {1}개 기록", [date(d), records.length]),
              button: !future,
              child: InkWell(
                onTap: future
                    ? null
                    : () => _openRecords(tr("{0}의 마음", [date(d)]), records),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: records.isEmpty
                        ? const Color(0xFFFFF4E4)
                        : const Color(0xFFFCE0DC),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${d.day}',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 13,
                            color: future ? Colors.grey : ink,
                          ),
                        ),
                      ),
                      if (records.isNotEmpty)
                        const Icon(
                          Icons.pets,
                          color: Color(0xFFD88488),
                          size: 22,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
