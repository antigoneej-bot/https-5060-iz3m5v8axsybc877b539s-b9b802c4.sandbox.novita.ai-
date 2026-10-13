import '../models/garden_anniversary.dart';
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
  late final TextEditingController _name, _note;
  bool _busy = false, _done = false, _allowPop = false, _closing = false;
  late final String _initialName, _initialNote;
  DateTime? _initialDate;
  String? _error;
  DateTime? _memoryDate;
  @override
  void initState() {
    super.initState();
    final memory = PlantMemoryStore.instance.value[widget.plant.id];
    _name = TextEditingController(text: memory?.name ?? '');
    _note = TextEditingController(text: memory?.note ?? '');
    _memoryDate = memory?.memoryDate;
    _initialName = _name.text;
    _initialNote = _note.text;
    _initialDate = _memoryDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_busy || _closing) return;
    _closing = true;
    try {
      final changed =
          _name.text != _initialName ||
          _note.text != _initialNote ||
          _memoryDate != _initialDate;
      if (changed) {
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('작성 중인 추억을 닫을까요?'),
            content: const Text('저장하지 않은 변경은 사라져요.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('계속 쓰기'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
        if (discard != true || !mounted) return;
      }
      if (!mounted) return;
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } finally {
      _closing = false;
    }
  }

  Future<void> _save({bool remove = false}) async {
    if (_busy) return;
    if (remove) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('이 식물의 추억을 지울까요?'),
          content: const Text('이름·메모·기억할 날짜를 지워요. 식물과 성장 기록은 그대로 남아요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('추억 지우기'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (remove) {
        await PlantMemoryStore.instance.remove(widget.plant.id);
      } else {
        await PlantMemoryStore.instance.save(
          widget.plant.id,
          _name.text,
          _note.text,
          memoryDate: _memoryDate,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _memoryDate ?? DateTime.now(),
      firstDate: DateTime(
        (_memoryDate?.year ?? 1900) < 1900 ? _memoryDate!.year : 1900,
      ),
      lastDate: DateTime(
        (_memoryDate?.year ?? 0) > DateTime.now().year + 10
            ? _memoryDate!.year
            : DateTime.now().year + 10,
        12,
        31,
      ),
      helpText: '기억할 날짜 · 심은 날과 달라도 괜찮아요',
    );
    if (picked != null && mounted) setState(() => _memoryDate = picked);
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
  Widget build(BuildContext context) => PopScope(
    canPop: _done || _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: AlertDialog(
      title: Text('${widget.plant.label}에 남기는 추억'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (_) {
                final data = MongiGardenStore.instance.value;
                final id = widget.plant.id, count = data.seeds[id] ?? 0;
                final next = widget.plant.careUntilNextTier(count);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    [
                      if (data.plantedOn[id] != null)
                        '심은 날 · ${data.plantedOn[id]}',
                      widget.plant.growthLabel(count),
                      if (next > 0) '다음 성장까지 물주기 $next번',
                      data.wateredToday(id, DateTime.now())
                          ? '오늘 물주기 완료'
                          : '오늘도 물을 주며 돌볼 수 있어요.',
                    ].join('\n'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
            FilledButton.tonalIcon(
              onPressed:
                  _busy ||
                      MongiGardenStore.instance.value.wateredToday(
                        widget.plant.id,
                        DateTime.now(),
                      )
                  ? null
                  : _water,
              icon: const Icon(Icons.water_drop_outlined),
              label: Text(
                MongiGardenStore.instance.value.wateredToday(
                      widget.plant.id,
                      DateTime.now(),
                    )
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
                hintText: '면접을 마친 날의 나무',
              ),
            ),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLength: 300,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: '남기고 싶은 한 장면',
                hintText: '오늘 기억하고 싶은 순간을 적어 주세요.',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('기억할 날짜 · 선택'),
              subtitle: Text(
                _memoryDate == null
                    ? '우정이 시작된 날, 기념하고 싶은 날'
                    : GardenAnniversary.key(_memoryDate!),
              ),
              trailing: const Icon(Icons.calendar_month_outlined),
              onTap: _busy ? null : _pickDate,
            ),
            if (_memoryDate != null) ...[
              Text(GardenAnniversary.label(_memoryDate!, DateTime.now())),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _memoryDate = null),
                child: const Text('기억할 날짜 지우기'),
              ),
            ],
            const Text('이름·마음·날짜는 나만 볼 수 있어요. 공개 정원과 엽서에 자동으로 들어가지 않아요.'),
            if (_error != null) Text(_error!),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => _save(remove: true),
          child: const Text('추억 지우기'),
        ),
        TextButton(onPressed: _busy ? null : _close, child: const Text('취소')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('저장')),
      ],
    ),
  );
}
