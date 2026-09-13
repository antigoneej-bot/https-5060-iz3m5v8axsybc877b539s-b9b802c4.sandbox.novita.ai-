import 'package:flutter/material.dart';
import '../services/draft_service.dart';

/// A stable calendar-period key keeps earlier reflections accessible.
/// Stored encrypted in the same draft box already included in file/cloud backup.
class PeriodReflectionCard extends StatefulWidget {
  final String periodKey;
  final bool monthly;
  const PeriodReflectionCard({super.key, required this.periodKey, required this.monthly});
  @override
  State<PeriodReflectionCard> createState() => _PeriodReflectionCardState();
}
class _PeriodReflectionCardState extends State<PeriodReflectionCard> {
  late final List<DraftTextController> _notes;
  @override
  void initState() {
    super.initState();
    _notes = List.generate(3, (i) => DraftTextController('reflection_${widget.periodKey}_$i'));
  }
  @override
  void dispose() { for (final note in _notes) { note.dispose(); } super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final prompts = widget.monthly
      ? ['이번 달에 기억하고 싶은 장면', '나에게 도움이 되었던 일', '다음 달에도 이어가고 싶은 작은 실천']
      : ['이번 주에 기억하고 싶은 장면', '나에게 도움이 되었던 일', '다음 주에 해보고 싶은 작은 실천'];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.monthly ? '나의 월간 회고' : '나의 주간 회고', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const Text('한 줄만 남겨도 좋아요. 이전 주·달로 이동하면 그때 쓴 내용을 다시 볼 수 있어요.'),
        for (var i = 0; i < prompts.length; i++) ...[
          const SizedBox(height: 12),
          TextField(controller: _notes[i], maxLines: null, minLines: 2, maxLength: 2000,
            decoration: InputDecoration(labelText: prompts[i], alignLabelWithHint: true)),
          ValueListenableBuilder<String>(valueListenable: _notes[i].saveStatus,
            builder: (_, status, __) => Text(status.replaceAll('임시저장', '저장'), style: const TextStyle(fontSize: 11))),
        ],
        const Text('회고도 백업에 포함돼요. 앱 삭제에 대비해 별도 백업을 보관해 주세요.'),
      ],
    )));
  }
}
