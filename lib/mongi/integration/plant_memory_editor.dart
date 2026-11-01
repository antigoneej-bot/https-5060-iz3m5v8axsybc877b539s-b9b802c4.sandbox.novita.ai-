import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/companion_journey.dart';
import '../../providers/cat_care_provider.dart';
import '../models/seed.dart';
import '../models/plant_care.dart';
import 'plant_care_panel.dart';
import 'mature_tree_memories.dart';
import 'plant_memory_store.dart';
import 'mongi_garden_store.dart';
import '../../widgets/private_memory_links.dart';
import '../../screens/garden_memory_book_screen.dart';

class PlantMemoryEditor extends StatefulWidget {
  final SeedType plant;
  const PlantMemoryEditor({super.key, required this.plant});
  @override
  State<PlantMemoryEditor> createState() => _PlantMemoryEditorState();
}

class _PlantMemoryEditorState extends State<PlantMemoryEditor> {
  late final TextEditingController _name;
  final _note = TextEditingController();
  late List<PlantMemoryEntry> _entries;
  String? _anniversaryOn;
  late String _noteOn;
  bool _busy = false, _done = false;
  String? _error;
  String? _careFeedback;
  String? _savedMessage;
  DateTime? _revision;
  final _historyKey = GlobalKey();
  final _newNoteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final memory = PlantMemoryStore.instance.value[widget.plant.id];
    _revision = memory?.updatedAt;
    _name = TextEditingController(text: memory?.name ?? '');
    _entries = [...?memory?.timeline];
    _anniversaryOn = memory?.anniversaryOn;
    _noteOn = plantMemoryDay(DateTime.now());
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<String?> _chooseDay(String? current) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: current == null
          ? DateTime.now()
          : parsePlantMemoryDay(current),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
      helpText: '기억하고 싶은 날짜를 골라 주세요',
      cancelText: '취소',
      confirmText: '선택',
    );
    return selected == null ? null : plantMemoryDay(selected);
  }

  Future<void> _editEntry(PlantMemoryEntry entry) async {
    final controller = TextEditingController(text: entry.note);
    var day = entry.on;
    var saving = false;
    final route = DialogRoute<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: const Text('글 수정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.sourceLetterId != null)
                    const Text(
                      '이 나무에 남긴 문장만 수정해요. 수정하면 원본 편지와의 연결이 해제되고 별도의 추억으로 남아요. 원본 편지는 바뀌지 않아요.',
                    ),
                  TextButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final selected = await _chooseDay(day);
                            if (selected != null && dialogContext.mounted) {
                              setDialogState(() => day = selected);
                            }
                          },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(day),
                  ),
                  TextField(
                    controller: controller,
                    enabled: !saving,
                    maxLength: 300,
                    minLines: 3,
                    maxLines: 6,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(labelText: '그날의 한 장면'),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  if (saving) const LinearProgressIndicator(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: saving || controller.text.trim().isEmpty
                    ? null
                    : () async {
                        if (saving) return;
                        setDialogState(() => saving = true);
                        final updated = PlantMemoryEntry(
                          id: entry.id,
                          on: day,
                          note: controller.text.trim(),
                          sourceLetterId:
                              controller.text.trim() == entry.note &&
                                  day == entry.on
                              ? entry.sourceLetterId
                              : null,
                          sourceWrittenAt:
                              controller.text.trim() == entry.note &&
                                  day == entry.on
                              ? entry.sourceWrittenAt
                              : null,
                        );
                        final next = [..._entries];
                        final index = next.indexWhere(
                          (item) => item.id == entry.id,
                        );
                        bool saved = false;
                        if (index >= 0) {
                          next[index] = updated;
                          saved = await _saveEntries(next, '글을 수정했어요.');
                        }
                        if (!dialogContext.mounted) return;
                        setDialogState(() => saving = false);
                        if (saved) Navigator.pop(dialogContext);
                      },
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
    await Navigator.of(context).push(route);
    // The route owns the controller until its exit animation completes.
    await route.completed;
    controller.dispose();
  }

  Future<bool> _confirmDelete({bool all = false}) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(all ? '이 식물의 추억을 모두 지울까요?' : '이 추억을 지울까요?'),
          content: Text(
            all
                ? '이름, 기념일, 날짜별 추억과 월간 기록집에 담은 이 식물의 이름·기념일이 지워져요. 식물과 성장 기록, 원본 편지는 유지돼요.'
                : '이 추억만 지워져요. 나무와 다른 추억, 원본 편지는 그대로 남아요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('지우기'),
            ),
          ],
        ),
      ) ??
      false;

  Future<bool> _saveEntries(
    List<PlantMemoryEntry> entries,
    String message,
  ) async {
    if (_busy) return false;
    setState(() {
      _busy = true;
      _error = null;
      _savedMessage = null;
    });
    try {
      final saved = PlantMemoryStore.instance.value[widget.plant.id];
      final memory = PlantMemory(
        plantId: widget.plant.id,
        name: saved?.name ?? '',
        note: entries.isEmpty ? '' : entries.last.note,
        updatedAt: DateTime.now(),
        anniversaryOn: saved?.anniversaryOn,
        entries: entries,
      );
      await PlantMemoryStore.instance.saveMemory(
        memory,
        checkRevision: true,
        expectedUpdatedAt: _revision,
      );
      if (mounted)
        setState(() {
          _entries = entries;
          _revision = memory.updatedAt;
          _savedMessage = message;
        });
      return true;
    } catch (error) {
      if (mounted)
        setState(
          () => _error = error is StateError
              ? error.message.toString()
              : '변경 내용을 저장하지 못했어요. 다시 시도해 주세요.',
        );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deletePlant() async {
    if (_busy) return;
    final noun = widget.plant.isTree ? '나무' : '식물';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('이 $noun를 삭제할까요?'),
        content: Text(
          '정원에서 이 $noun가 사라지고, 이름·기념일·추억·성장 단계와 돌봄 날짜가 함께 지워져요. '
          '월간 기록집에 담은 이 $noun의 이름과 기념일도 지워져요.\n\n'
          '원본 편지와 다른 식물은 그대로 남아요. 사용한 씨앗은 반환되지 않으며, 다시 심으면 처음부터 자라요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const ValueKey('confirm-delete-plant'),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(
              '$noun 삭제',
              style: TextStyle(color: Theme.of(dialog).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await PlantMemoryStore.instance.deletePlant(widget.plant.id);
      if (mounted) {
        setState(() => _done = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = '삭제하지 못했어요. 다시 시도해 주세요.';
        });
    }
  }

  Future<void> _save({bool remove = false}) async {
    if (_busy) return;
    if (remove && !await _confirmDelete(all: true)) return;
    if (!mounted) return;
    if (!remove &&
        _note.text.trim().isNotEmpty &&
        _entries.length >= PlantMemory.maxEntries) {
      setState(() => _error = '추억은 60개까지 보관할 수 있어요. 기존 추억을 다듬거나 지운 뒤 저장해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (remove) {
        await PlantMemoryStore.instance.remove(widget.plant.id);
      } else {
        final now = DateTime.now();
        final entries = [..._entries];
        if (_note.text.trim().isNotEmpty) {
          entries.add(
            PlantMemoryEntry(
              id: 'memory-${now.microsecondsSinceEpoch}',
              on: _noteOn,
              note: _note.text.trim(),
            ),
          );
        }
        await PlantMemoryStore.instance.saveMemory(
          PlantMemory(
            plantId: widget.plant.id,
            name: _name.text.trim(),
            note: entries.isEmpty ? '' : entries.last.note,
            updatedAt: now,
            anniversaryOn: _anniversaryOn,
            entries: entries,
          ),
          checkRevision: true,
          expectedUpdatedAt: _revision,
        );
      }
      if (mounted) {
        setState(() => _done = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '추억을 저장하지 못했어요. 다시 시도해 주세요.';
        });
      }
    }
  }

  Future<void> _care(PlantCare care) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _careFeedback = null;
    });
    try {
      final changed = await MongiGardenStore.instance.carePlant(
        widget.plant.id,
        care,
      );
      if (changed && mounted) {
        // Editors can also be embedded without a companion provider in previews.
        await context.read<CatCareProvider?>()?.rememberMoment(
          care == PlantCare.water
              ? CompanionMoment.water
              : CompanionMoment.garden,
        );
      }
      if (mounted) {
        setState(
          () => _careFeedback = changed
              ? (MongiGardenStore.instance.value.growthFor(widget.plant.id) >=
                        10
                    ? '다 자란 식물도 오늘의 돌봄을 받았어요.'
                    : '${care.label}를 마쳤어요. 조금 더 자랐어요.')
              : '오늘은 이미 돌봤어요. 다음에 또 함께해요.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _careFeedback = '돌봄을 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = MongiGardenStore.instance.value;
    final id = widget.plant.id;
    final history = [..._entries]..sort((a, b) => b.on.compareTo(a.on));
    return PopScope(
      canPop: !_busy || _done,
      child: AlertDialog(
        title: Text('${widget.plant.label} · 추억 관리'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.plant.isTree && data.growthProgress(id) >= 1)
                  MatureTreeMemories(
                    entries: _entries,
                    anniversaryOn: _anniversaryOn,
                    onWrite: _busy
                        ? null
                        : () {
                            final target = _newNoteKey.currentContext;
                            if (target != null)
                              Scrollable.ensureVisible(
                                target,
                                duration: const Duration(milliseconds: 250),
                              );
                          },
                    onHistory: _busy
                        ? null
                        : () {
                            final target = _historyKey.currentContext;
                            if (target != null)
                              Scrollable.ensureVisible(
                                target,
                                duration: const Duration(milliseconds: 250),
                              );
                          },
                    onMonth: _busy
                        ? null
                        : (month) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  GardenMemoryBookScreen(initialMonth: month),
                            ),
                          ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                              final target = _entries.isEmpty
                                  ? _newNoteKey.currentContext
                                  : _historyKey.currentContext;
                              if (target != null)
                                Scrollable.ensureVisible(
                                  target,
                                  duration: const Duration(milliseconds: 250),
                                );
                            },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(_entries.isEmpty ? '추억 쓰기' : '글 수정·삭제'),
                    ),
                    TextButton.icon(
                      key: const ValueKey('delete-plant'),
                      onPressed: _busy ? null : _deletePlant,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(widget.plant.isTree ? '나무 삭제' : '식물 삭제'),
                    ),
                  ],
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_savedMessage != null)
                  Semantics(liveRegion: true, child: Text(_savedMessage!)),
                PlantCarePanel(
                  plant: widget.plant,
                  data: data,
                  busy: _busy,
                  onCare: _care,
                  feedback: _careFeedback,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _name,
                  enabled: !_busy,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: '나만의 이름',
                    hintText: '우리의 첫 나무',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final selected = await _chooseDay(
                            _anniversaryOn ?? data.plantedOn[id],
                          );
                          if (selected != null && mounted) {
                            setState(() => _anniversaryOn = selected);
                          }
                        },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _anniversaryOn == null
                        ? '함께 기억할 시작일 정하기 (선택)'
                        : '기념 시작일 · $_anniversaryOn',
                  ),
                ),
                if (_anniversaryOn != null)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _anniversaryOn = null),
                    child: const Text('기념 시작일 지우기'),
                  ),
                const Text('선택한 날을 1일째로 세어요. 30일·100일을 지나면 기념 엽서를 만들 수 있어요.'),
                const SizedBox(height: 16),
                Text(
                  '새로운 추억 · ${_entries.length}/${PlantMemory.maxEntries}개',
                  key: _newNoteKey,
                ),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final selected = await _chooseDay(_noteOn);
                          if (selected != null && mounted) {
                            setState(() => _noteOn = selected);
                          }
                        },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('추억의 날짜 · $_noteOn'),
                ),
                TextField(
                  controller: _note,
                  enabled: !_busy,
                  maxLength: 300,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '남기고 싶은 한 장면',
                    hintText: '오늘의 마음이나 함께한 순간을 남겨 주세요.',
                  ),
                ),
                if (history.isNotEmpty) ...[
                  const Divider(),
                  Text('이 나무에 쌓인 추억', key: _historyKey),
                  for (final entry in history)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              entry.on,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 6),
                            if (entry.sourceLetterId != null)
                              const Text(
                                '편지에서 내가 고른 문장 · 나만 보기',
                                style: TextStyle(fontSize: 12),
                              ),
                            SelectableText(entry.note),
                            Wrap(
                              children: [
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _editEntry(entry),
                                  child: const Text('수정'),
                                ),
                                if (entry.sourceLetterId != null) ...[
                                  TextButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => openPrivateLetterMemory(
                                            context,
                                            entry.sourceLetterId!,
                                          ),
                                    icon: const Icon(
                                      Icons.mail_outline,
                                      size: 18,
                                    ),
                                    label: const Text('그날의 편지 보기'),
                                  ),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  GardenMemoryBookScreen(
                                                    initialMonth: entry
                                                        .sourceWrittenAt!
                                                        .toLocal(),
                                                  ),
                                            ),
                                          ),
                                    child: const Text('이 달 기록집'),
                                  ),
                                ],
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          if (await _confirmDelete() &&
                                              mounted) {
                                            await _saveEntries(
                                              _entries
                                                  .where(
                                                    (item) =>
                                                        item.id != entry.id,
                                                  )
                                                  .toList(),
                                              '추억을 삭제했어요.',
                                            );
                                          }
                                        },
                                  child: const Text('삭제'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                const Text(
                  '수정한 글과 삭제한 추억은 바로 저장돼요. 이름·기념일·새 추억은 아래 저장을 눌러 주세요. 기록은 나만 볼 수 있어요.',
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => _save(remove: true),
            child: const Text('추억만 모두 지우기'),
          ),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
