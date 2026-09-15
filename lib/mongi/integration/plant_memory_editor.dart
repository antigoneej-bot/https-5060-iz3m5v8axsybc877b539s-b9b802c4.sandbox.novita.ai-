import 'package:flutter/material.dart';
import '../models/seed.dart';
import 'plant_memory_store.dart';

class PlantMemoryEditor extends StatefulWidget {
  final SeedType plant;
  const PlantMemoryEditor({super.key, required this.plant});
  @override
  State<PlantMemoryEditor> createState() => _PlantMemoryEditorState();
}

class _PlantMemoryEditorState extends State<PlantMemoryEditor> {
  late final TextEditingController _name, _note;
  bool _busy = false, _done = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final memory = PlantMemoryStore.instance.value[widget.plant.id];
    _name = TextEditingController(text: memory?.name ?? '');
    _note = TextEditingController(text: memory?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save({bool remove = false}) async {
    if (_busy) return;
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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy || _done,
    child: AlertDialog(
      title: Text('${widget.plant.label}에 남기는 추억'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const Text('이 기록은 나만 볼 수 있어요. 엽서에는 자동으로 들어가지 않아요.'),
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
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('저장')),
      ],
    ),
  );
}
