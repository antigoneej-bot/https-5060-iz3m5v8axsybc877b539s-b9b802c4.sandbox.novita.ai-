import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/letter_entry.dart';
import '../mongi/integration/garden_layout_store.dart';
import '../mongi/integration/mongi_garden_store.dart';
import '../mongi/integration/plant_memory_store.dart';
import '../mongi/models/seed.dart';
import '../mongi/widgets/garden_world_view.dart';
import '../services/access_policy.dart';
import '../services/analytics_service.dart';
import '../services/care_journal_store.dart';
import '../services/garden_memory_book_store.dart';
import '../services/storage_service.dart';
import '../services/private_letter_memory_source.dart';
import '../widgets/private_memory_links.dart';
import 'care_journal_screen.dart';
import '../widgets/subscription_gate.dart';

Future<void> _logBookEvent(String name) async {
  try {
    await AnalyticsService().logEvent(name);
  } catch (_) {
    // Optional usage statistics must never block a private record operation.
  }
}

class GardenMemoryBookScreen extends StatefulWidget {
  final DateTime? initialMonth;
  const GardenMemoryBookScreen({super.key, this.initialMonth});
  @override
  State<GardenMemoryBookScreen> createState() => _GardenMemoryBookScreenState();
}

class _GardenMemoryBookScreenState extends State<GardenMemoryBookScreen> {
  bool _loading = true;
  String? _error;
  final _store = GardenMemoryBookStore.instance;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _store.reload();
    } catch (_) {
      _error = tr("기록집을 불러오지 못했어요. 다시 시도해 주세요.");
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.initialMonth ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: tr("기록집으로 남길 달을 골라 주세요"),
      confirmText: tr("이 달 선택"),
    );
    if (picked == null || !mounted) return;
    await _createForMonth(picked);
  }

  Future<void> _createForMonth(DateTime picked) async {
    final month = gardenBookMonth(picked);
    final existing = _store.value
        .where((book) => book.month == month)
        .firstOrNull;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BookEditor(month: month, existing: existing),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _open(GardenMemoryBook book) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _BookDetail(id: book.id)));
    if (mounted) await _load();
  }

  Future<void> _compare() async {
    if (!await requestSubscription(
      context,
      message: tr("여러 달의 기록집을 나란히 돌아보는 기능이에요. 기존 기록집은 무료로 계속 볼 수 있어요."),
    )) {
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(tr("정원에 쌓인 시간"))),
          body: ValueListenableBuilder<List<GardenMemoryBook>>(
            valueListenable: _store,
            builder: (context, books, _) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(tr("직접 골라 담은 기록을 달마다 돌아봐요. 기록의 개수는 마음의 점수가 아니에요.")),
                const SizedBox(height: 16),
                for (final book in books)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr("{0} · {1}개의 문장, {2}개의 돌봄", [
                              book.month,
                              book.quotes.length,
                              book.care.length,
                            ]),
                          ),
                          const SizedBox(height: 8),
                          if (book.care.isEmpty) Text(tr("선택해 담은 돌봄이 없어요.")),
                          for (final care in book.care)
                            Text('• ${care.actionLabel}'),
                          TextButton(
                            onPressed: () => _open(book),
                            child: Text(tr("이 달 펼쳐보기")),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr("월간 정원 기록집"))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                  TextButton(onPressed: _load, child: Text(tr("다시 불러오기"))),
                ],
              ),
            )
          : ValueListenableBuilder<List<GardenMemoryBook>>(
              valueListenable: _store,
              builder: (context, books, _) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    tr("내가 고른 문장과 도움이 된 경험을 한 달의 정원에 담아요."),
                    style: TextStyle(fontSize: 18, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      "첫 기본 기록집은 무료예요. 새 달의 기록집과 계절 표지는 구독으로 만들 수 있어요. 이미 만든 기록집은 해지 후에도 열람·수정·공유할 수 있어요.",
                    ),
                  ),
                  if (widget.initialMonth != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.bookmark_border),
                        title: Text(
                          tr("{0}의 마음 다시 보기", [
                            gardenBookMonth(widget.initialMonth!),
                          ]),
                        ),
                        subtitle: Text(tr("선택한 달의 기록집을 열거나 새로 만들 수 있어요.")),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final target = books
                              .where(
                                (book) =>
                                    book.month ==
                                    gardenBookMonth(widget.initialMonth!),
                              )
                              .firstOrNull;
                          if (target == null) {
                            _createForMonth(widget.initialMonth!);
                          } else {
                            _open(target);
                          }
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.auto_stories_outlined),
                    label: Text(tr("담을 달 고르기")),
                  ),
                  if (books.length > 1)
                    TextButton.icon(
                      onPressed: _compare,
                      icon: const Icon(Icons.calendar_view_month_outlined),
                      label: Text(tr("여러 달 함께 돌아보기 · 구독")),
                    ),
                  const SizedBox(height: 20),
                  if (books.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(tr("아직 기록집이 없어요. 남기고 싶은 달부터 천천히 만들어 보세요.")),
                    ),
                  for (final book in books)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.menu_book_rounded),
                        title: Text(tr("{0}의 정원", [book.month])),
                        subtitle: Text(
                          tr("내 문장 {0} · 돌봄 {1}\n{2}에 저장", [
                            book.quotes.length,
                            book.care.length,
                            DateFormat('yyyy.MM.dd').format(book.updatedAt),
                          ]),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(book),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _BookEditor extends StatefulWidget {
  final String month;
  final GardenMemoryBook? existing;
  const _BookEditor({required this.month, this.existing});
  @override
  State<_BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends State<_BookEditor> {
  bool _loading = true, _busy = false;
  String? _error;
  List<LetterEntry> _letters = [];
  List<GardenBookPlant> _plants = [];
  List<GardenBookCare> _care = [];
  final _quotes = <String, GardenBookQuote>{};
  final _selectedPlants = <String, GardenBookPlant>{};
  final _selectedCare = <String, GardenBookCare>{};
  GardenBookSnapshot? _snapshot;
  String _style = 'basic';
  GardenMemoryBook? _preview;
  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _quotes.addEntries(existing.quotes.map((q) => MapEntry(q.letterId, q)));
      _selectedPlants.addEntries(
        existing.plants.map((p) => MapEntry(p.plantId, p)),
      );
      _selectedCare.addEntries(
        existing.care.map((c) => MapEntry(c.entryId, c)),
      );
      _style = existing.style;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      await Future.wait([
        MongiGardenStore.instance.reload(),
        GardenLayoutStore.instance.reload(),
        PlantMemoryStore.instance.reload(),
        CareJournalStore.instance.reload(),
      ]);
      final letters = (await PrivateLetterMemorySource.bookLetters())
          .where(
            (l) =>
                gardenBookMonth(l.date) == widget.month ||
                (widget.existing?.quotes.any(
                      (saved) => saved.letterId == l.id,
                    ) ??
                    false),
          )
          .toList();
      final data = MongiGardenStore.instance.value;
      final companion = await StorageService.getCompanionName();
      _snapshot =
          widget.existing?.snapshot ??
          GardenBookSnapshot(
            capturedAt: DateTime.now(),
            seeds: data.seeds,
            decorations: data.placed.toList(),
            layout: GardenLayoutStore.instance.value,
            memoryDays: data.recordDays.length,
            companionName: companion?.trim().isNotEmpty == true
                ? companion!
                : tr("고양이"),
          );
      _letters = letters;
      _plants = [
        for (final seed in SeedType.all)
          if ((data.seeds[seed.id] ?? 0) > 0)
            GardenBookPlant(
              plantId: seed.id,
              name:
                  PlantMemoryStore.instance.value[seed.id]?.name
                          .trim()
                          .isNotEmpty ==
                      true
                  ? PlantMemoryStore.instance.value[seed.id]!.name
                  : seed.label,
              anniversaryOn:
                  PlantMemoryStore.instance.value[seed.id]?.anniversaryOn,
            ),
      ];
      _care = [
        for (final entry in CareJournalStore.instance.entries)
          if (entry.wasHelpful &&
              entry.actionLabel != null &&
              (gardenBookMonth(entry.completedAt!.toLocal()) == widget.month ||
                  (widget.existing?.care.any(
                        (saved) => saved.entryId == entry.id,
                      ) ??
                      false)))
            GardenBookCare(
              entryId: entry.id,
              actionLabel: entry.actionLabel!,
              completedAt: entry.completedAt!.toLocal(),
              calendarDay: widget.existing?.care
                  .where((saved) => saved.entryId == entry.id)
                  .firstOrNull
                  ?.calendarDay,
              sourceLetterId: entry.sourceLetterId,
            ),
      ];
      // A deleted source must not survive merely because an editor was reopened.
      _quotes.removeWhere(
        (id, q) =>
            !_letters.any((l) => l.id == id && l.letterText.contains(q.text)),
      );
      _selectedCare.removeWhere((id, _) => !_care.any((c) => c.entryId == id));
      _selectedPlants.removeWhere(
        (id, selected) => !_plants.any(
          (p) =>
              p.plantId == id &&
              p.name == selected.name &&
              p.anniversaryOn == selected.anniversaryOn,
        ),
      );
      _error = null;
    } catch (_) {
      _error = tr("기록을 불러오지 못했어요. 기존 기록은 그대로 보관돼요.");
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _chooseQuote(LetterEntry letter) async {
    if (_quotes.containsKey(letter.id)) {
      setState(() {
        _quotes.remove(letter.id);
        _preview = null;
      });
      return;
    }
    if (_quotes.length >= 3) {
      _message(tr("문장은 세 개까지 고를 수 있어요."));
      return;
    }
    final controller = TextEditingController();
    final route = DialogRoute<String>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text(tr("내 문장 그대로 담기")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(letter.letterText),
                const SizedBox(height: 20),
                Text(tr("위 편지에서 남길 부분을 복사하거나 그대로 적어 주세요.")),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (_) => update(() {}),
                  decoration: InputDecoration(labelText: tr("기록집에 담을 문장")),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(tr("취소")),
            ),
            FilledButton(
              onPressed:
                  controller.text.trim().isNotEmpty &&
                      letter.letterText.contains(controller.text.trim())
                  ? () => Navigator.pop(dialog, controller.text.trim())
                  : null,
              child: Text(tr("이 문장 담기")),
            ),
          ],
        ),
      ),
    );
    final text = await Navigator.of(context).push(route);
    if (text != null && mounted) {
      setState(() {
        _quotes[letter.id] = GardenBookQuote(
          letterId: letter.id,
          text: text,
          writtenAt: letter.date,
          calendarDay: widget.existing?.quotes
              .where((saved) => saved.letterId == letter.id)
              .firstOrNull
              ?.calendarDay,
        );
        _preview = null;
      });
    }
    await route.completed;
    controller.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  GardenMemoryBook _buildBook() {
    final now = DateTime.now();
    return GardenMemoryBook(
      month: widget.month,
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
      snapshot: _snapshot!,
      style: _style,
      quotes: _quotes.values.toList(),
      plants: _selectedPlants.values.toList(),
      care: _selectedCare.values.toList(),
      reflections: widget.existing?.reflections ?? const [],
    );
  }

  Future<void> _save() async {
    final book = _preview;
    if (book == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await GardenMemoryBookStore.instance.save(book);
      if (widget.existing == null) {
        _logBookEvent(AnalyticsEvents.gardenBookCreated);
      }
      if (mounted) Navigator.pop(context);
    } on SubscriptionRequired catch (e) {
      if (mounted && await requestSubscription(context, message: e.message)) {
        try {
          await GardenMemoryBookStore.instance.save(book);
          if (widget.existing == null) {
            _logBookEvent(AnalyticsEvents.gardenBookCreated);
          }
          if (mounted) Navigator.pop(context);
        } catch (_) {
          if (mounted) {
            setState(() => _error = tr("저장하지 못했어요. 선택한 내용은 이 화면에 남아 있어요."));
          }
        }
      }
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = tr("저장하지 못했어요. 연결과 기록을 확인한 뒤 다시 시도해 주세요."));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr("{0}의 정원 담기", [widget.month]))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _snapshot == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? tr("기록을 확인해 주세요.")),
                  TextButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    child: Text(tr("다시 불러오기")),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  tr(
                    "담을 내용은 직접 골라요. 아무것도 고르지 않으면 정원 구성만 남아요. 모든 내용은 기본 비공개예요.",
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr("정원 구성 저장일: {0}\n선택한 달의 과거 사진이 아니라, 이 날짜에 저장한 정원 배치예요.", [
                    DateFormat(
                      'yyyy.MM.dd HH:mm',
                    ).format(_snapshot!.capturedAt),
                  ]),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),
                Text(
                  tr("남기고 싶은 내 문장 · 최대 3개"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_letters.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(tr("이 달에 쓴 편지가 없어요.")),
                  ),
                for (final letter in _letters)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _quotes.containsKey(letter.id),
                    onChanged: _busy ? null : (_) => _chooseQuote(letter),
                    title: Text(DateFormat(tr("M월 d일")).format(letter.date)),
                    subtitle: Text(
                      _quotes[letter.id]?.text ?? letter.letterText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  tr("기억하고 싶은 식물과 기념일"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_plants.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(tr("아직 심은 식물이 없어요.")),
                  ),
                for (final plant in _plants)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selectedPlants.containsKey(plant.plantId),
                    onChanged: _busy
                        ? null
                        : (checked) => setState(() {
                            checked == true
                                ? _selectedPlants[plant.plantId] = plant
                                : _selectedPlants.remove(plant.plantId);
                            _preview = null;
                          }),
                    title: Text(plant.name),
                    subtitle: plant.anniversaryOn == null
                        ? null
                        : Text(tr("기념일 {0}", [plant.anniversaryOn])),
                  ),
                const SizedBox(height: 16),
                Text(
                  tr("도움이 됐다고 남긴 돌봄 · 최대 12개"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_care.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(tr("이 달에 도움이 됐다고 표시한 돌봄이 아직 없어요.")),
                  ),
                for (final care in _care)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selectedCare.containsKey(care.entryId),
                    onChanged: _busy
                        ? null
                        : (checked) {
                            if (checked == true && _selectedCare.length >= 12) {
                              _message(tr("돌봄은 열두 개까지 담을 수 있어요."));
                              return;
                            }
                            setState(() {
                              checked == true
                                  ? _selectedCare[care.entryId] = care
                                  : _selectedCare.remove(care.entryId);
                              _preview = null;
                            });
                          },
                    title: Text(care.actionLabel),
                    subtitle: Text(
                      tr("{0} · 내가 도움이 됐다고 표시했어요", [
                        DateFormat(tr("M월 d일")).format(care.calendarDate),
                      ]),
                    ),
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _style,
                  decoration: InputDecoration(labelText: tr("표지")),
                  items: [
                    DropdownMenuItem(value: 'basic', child: Text(tr("기본 표지"))),
                    DropdownMenuItem(
                      value: 'seasonal',
                      child: Text(tr("계절 표지 · 구독")),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _style = value!;
                          _preview = null;
                        }),
                ),
                const SizedBox(height: 12),
                Text(
                  tr(
                    "첫 기본 기록집은 무료예요. 이후 새 달의 기록집과 계절 표지는 구독이 필요해요. 기존 기록집의 내용은 해지 후에도 다듬을 수 있어요.",
                  ),
                  style: TextStyle(fontSize: 13),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _preview = _buildBook()),
                  child: Text(tr("미리보기")),
                ),
                if (_preview != null) ...[
                  const SizedBox(height: 16),
                  _BookContents(book: _preview!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Text(_busy ? tr("저장하고 있어요") : tr("이대로 비공개 저장")),
                  ),
                ],
                const SizedBox(height: 28),
              ],
            ),
    );
  }
}

class _BookContents extends StatelessWidget {
  final GardenMemoryBook book;
  const _BookContents({required this.book});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final season = parseGardenBookMonth(book.month).month;
    final color = book.style == 'basic'
        ? const Color(0xFFF8F4E8)
        : season >= 9 && season <= 11
        ? const Color(0xFFFFF0E2)
        : season == 12 || season <= 2
        ? const Color(0xFFEFF5FA)
        : const Color(0xFFEDF6EB);
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr("{0}의 정원", [book.month]),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            IgnorePointer(
              child: GardenWorldView(
                key: ValueKey(
                  'book-scene-${book.id}-${book.snapshot.capturedAt}',
                ),
                preview: true,
                readOnly: true,
                motionEnabled: false,
                companionName: book.snapshot.companionName,
                layout: book.snapshot.layout,
                seeds: book.snapshot.seeds,
                decorations: book.snapshot.decorations,
                memoryDays: book.snapshot.memoryDays,
                publicMemoryStage: book.snapshot.memoryDays >= 10
                    ? 3
                    : book.snapshot.memoryDays >= 3
                    ? 2
                    : book.snapshot.memoryDays > 0
                    ? 1
                    : 0,
                onMove: (_, _) async {},
                onMemory: (_) {},
                onPlant: () {},
                onDecorate: () {},
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr("{0}에 저장한 정원 구성\n현재 정원 그림으로 다시 표현했어요.", [
                DateFormat('yyyy.MM.dd').format(book.snapshot.capturedAt),
              ]),
              style: const TextStyle(fontSize: 12),
            ),
            for (final quote in book.quotes)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr("{0} · 내가 쓴 문장", [
                        DateFormat(tr("M월 d일")).format(quote.calendarDate),
                      ]),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      quote.text,
                      style: const TextStyle(fontSize: 17, height: 1.6),
                    ),
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: () =>
                              openPrivateLetterMemory(context, quote.letterId),
                          child: Text(tr("그날의 편지 보기")),
                        ),
                        TextButton.icon(
                          onPressed: () => attachLetterQuoteToPlant(
                            context,
                            sourceLetterId: quote.letterId,
                            quote: quote.text,
                          ),
                          icon: const Icon(Icons.park_outlined, size: 18),
                          label: Text(tr("내 나무에 간직하기")),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (book.plants.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  tr("함께 남긴 식물"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            for (final plant in book.plants)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '🌿 ${plant.name}${plant.anniversaryOn == null ? '' : tr(" · 기념일 {0}", [plant.anniversaryOn])}',
                ),
              ),
            if (book.care.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  tr("내가 도움이 됐다고 남긴 경험"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            for (final care in book.care)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${DateFormat(tr("M월 d일")).format(care.calendarDate)} · ${care.actionLabel}',
                ),
              ),
            if (book.care.isNotEmpty)
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CareJournalScreen()),
                ),
                icon: const Icon(Icons.spa_outlined),
                label: Text(tr("도움이 된 돌봄 다시 꺼내기")),
              ),
            if (book.reflections.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  tr("나중에 다시 돌아본 말"),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            for (final reflection in book.reflections)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy.MM.dd').format(reflection.at),
                      style: const TextStyle(fontSize: 12),
                    ),
                    SelectableText(reflection.text),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BookDetail extends StatefulWidget {
  final String id;
  const _BookDetail({required this.id});
  @override
  State<_BookDetail> createState() => _BookDetailState();
}

class _BookDetailState extends State<_BookDetail> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_book != null) _logBookEvent(AnalyticsEvents.gardenBookOpened);
  }

  GardenMemoryBook? get _book => GardenMemoryBookStore.instance.value
      .where((b) => b.id == widget.id)
      .firstOrNull;
  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _reflect() async {
    final controller = TextEditingController();
    final route = DialogRoute<String>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text(tr("지금의 내가 한 줄 남기기")),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 500,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(hintText: tr("그때와 같아도, 달라졌어도 괜찮아요.")),
            onChanged: (_) => update(() {}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(tr("취소")),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialog, controller.text.trim()),
              child: Text(tr("오늘 날짜로 남기기")),
            ),
          ],
        ),
      ),
    );
    final text = await Navigator.of(context).push(route);
    if (text != null && mounted) {
      setState(() => _busy = true);
      try {
        await GardenMemoryBookStore.instance.appendReflection(widget.id, text);
      } catch (_) {
        if (mounted) _message(tr("한 줄을 저장하지 못했어요. 다시 시도해 주세요."));
      }
      if (mounted) setState(() => _busy = false);
    }
    await route.completed;
    controller.dispose();
  }

  Future<void> _share(BuildContext anchorContext) async {
    final book = _book;
    if (book == null) return;
    var quotes = false, plants = false, care = false, reflections = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: Text(tr("공유할 내용만 골라 주세요")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr("선택한 내용이 다른 앱으로 전달돼요. 편지와 돌봄은 자동으로 포함되지 않아요.")),
                CheckboxListTile(
                  value: quotes,
                  onChanged: (v) => update(() => quotes = v!),
                  title: Text(tr("내가 담은 편지 문장")),
                ),
                CheckboxListTile(
                  value: plants,
                  onChanged: (v) => update(() => plants = v!),
                  title: Text(tr("식물 이름과 기념일")),
                ),
                CheckboxListTile(
                  value: care,
                  onChanged: (v) => update(() => care = v!),
                  title: Text(tr("도움이 된 돌봄")),
                ),
                CheckboxListTile(
                  value: reflections,
                  onChanged: (v) => update(() => reflections = v!),
                  title: Text(tr("나중에 남긴 말")),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(tr("취소")),
            ),
            FilledButton(
              onPressed: quotes || plants || care || reflections
                  ? () => Navigator.pop(dialog, true)
                  : null,
              child: Text(tr("선택한 내용 공유")),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || !mounted || !anchorContext.mounted) return;
    // A source may have been removed while the share picker was open.
    final current = _book;
    if (current == null) return;
    _logBookEvent(AnalyticsEvents.gardenBookShareRequested);
    final text = current.shareText(
      includeQuotes: quotes,
      includePlants: plants,
      includeCare: care,
      includeReflections: reflections,
    );
    try {
      final anchor = anchorContext.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          sharePositionOrigin: anchor.localToGlobal(Offset.zero) & anchor.size,
        ),
      );
    } catch (_) {
      if (mounted) _message(tr("공유하지 못했어요. 다시 시도해 주세요."));
    }
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(tr("이 기록집을 지울까요?")),
        content: Text(
          tr(
            "기록집과 여기에 나중에 남긴 말이 지워져요. 원래 편지와 정원은 그대로예요. 첫 무료 기록집을 삭제해도 무료 생성 기회가 다시 생기지는 않아요.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(tr("취소")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(tr("기록집 삭제")),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await GardenMemoryBookStore.instance.remove(widget.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _message(tr("삭제하지 못했어요. 다시 시도해 주세요."));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr("나의 정원 기록집"))),
      body: ValueListenableBuilder<List<GardenMemoryBook>>(
        valueListenable: GardenMemoryBookStore.instance,
        builder: (context, _, _) {
          final book = _book;
          if (book == null) return Center(child: Text(tr("기록집이 삭제되었어요.")));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BookContents(book: book),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _reflect,
                icon: const Icon(Icons.edit_note),
                label: Text(tr("지금의 내가 한 줄 남기기")),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _BookEditor(month: book.month, existing: book),
                          ),
                        );
                      },
                child: Text(tr("담은 내용 다듬기")),
              ),
              Builder(
                builder: (anchor) => TextButton.icon(
                  onPressed: _busy ? null : () => _share(anchor),
                  icon: const Icon(Icons.ios_share_outlined),
                  label: Text(tr("선택해서 공유")),
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _delete,
                child: Text(tr("기록집 삭제")),
              ),
            ],
          );
        },
      ),
    );
  }
}
