import 'package:flutter/material.dart';
import '../models/seed.dart';
import 'plant_memory_store.dart';
import 'mongi_garden_store.dart';

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

  @override
  void initState() {
    super.initState();
    final memory = PlantMemoryStore.instance.value[widget.plant.id];
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
    final route = DialogRoute<PlantMemoryEntry>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('추억 다듬기'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () async {
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
                  maxLength: 300,
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(labelText: '그날의 한 장면'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(
                      dialogContext,
                      PlantMemoryEntry(
                        id: entry.id,
                        on: day,
                        note: controller.text.trim(),
                      ),
                    ),
              child: const Text('변경'),
            ),
          ],
        ),
      ),
    );
    final updated = await Navigator.of(context).push(route);
    // The route owns the controller until its exit animation completes.
    if (updated != null && mounted) {
      setState(() {
        final index = _entries.indexWhere((item) => item.id == entry.id);
        if (index >= 0) _entries[index] = updated;
      });
    }
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
                ? '이름, 기념일, 날짜별 추억이 지워져요. 식물과 성장 기록은 유지돼요.'
                : '저장을 누르면 이 추억이 지워져요. 식물과 다른 추억은 유지돼요.',
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

  Future<void> _water() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await MongiGardenStore.instance.waterPlant(widget.plant.id);
    } catch (_) {
      if (mounted) setState(() => _error = '물주기를 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = MongiGardenStore.instance.value;
    final id = widget.plant.id, count = data.seeds[id] ?? 0;
    final next = widget.plant.careUntilNextTier(count);
    final history = [..._entries]..sort((a, b) => b.on.compareTo(a.on));
    return PopScope(
      canPop: !_busy || _done,
      child: AlertDialog(
        title: Text('${widget.plant.label}에 남기는 추억'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  [
                    if (data.plantedOn[id] != null)
                      '심은 날 · ${data.plantedOn[id]}',
                    widget.plant.growthLabel(count),
                    if (next > 0) '다음 성장까지 물주기 $next번',
                  ].join('\n'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _busy || data.wateredToday(id, DateTime.now())
                      ? null
                      : _water,
                  icon: const Icon(Icons.water_drop_outlined),
                  label: Text(
                    data.wateredToday(id, DateTime.now())
                        ? '오늘 물주기 완료'
                        : '물 주기',
                  ),
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
                Text('새로운 추억 · ${_entries.length}/${PlantMemory.maxEntries}개'),
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
                  const Text('이 나무에 쌓인 추억'),
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
                            SelectableText(entry.note),
                            Wrap(
                              children: [
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _editEntry(entry),
                                  child: const Text('수정'),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          if (await _confirmDelete() &&
                                              mounted) {
                                            setState(
                                              () => _entries.removeWhere(
                                                (item) => item.id == entry.id,
                                              ),
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
                  '이름·기념일·추억은 저장을 누르면 반영돼요. 이 기록은 나만 볼 수 있고, 엽서에는 직접 고른 내용만 들어가요.',
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
            child: const Text('모든 추억 지우기'),
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
