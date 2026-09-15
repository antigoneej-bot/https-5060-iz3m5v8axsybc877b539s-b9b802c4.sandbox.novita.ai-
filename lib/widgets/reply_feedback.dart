import '../theme.dart';
import 'package:flutter/material.dart';
import '../services/personal_reply_service.dart';

class ReplyFeedback extends StatefulWidget {
  final String replyId;
  const ReplyFeedback({super.key, required this.replyId});
  @override
  State<ReplyFeedback> createState() => _ReplyFeedbackState();
}

class _ReplyFeedbackState extends State<ReplyFeedback> {
  String? _value;
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReplyFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.replyId != widget.replyId) {
      _value = null;
      _busy = true;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.replyId;
    try {
      final value = await PersonalReplyService.feedback(id);
      if (mounted && widget.replyId == id) setState(() => _value = value);
    } catch (_) {
      /* Feedback failure never hides the letter. */
    } finally {
      if (mounted && widget.replyId == id) setState(() => _busy = false);
    }
  }

  Future<void> _save(String value) async {
    final id = widget.replyId;
    setState(() => _busy = true);
    try {
      final next = _value == value ? null : value;
      await PersonalReplyService.setFeedback(id, next);
      if (mounted && widget.replyId == id) setState(() => _value = next);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('평가를 저장하지 못했어요. 다시 시도해 주세요.')),
        );
    } finally {
      if (mounted && widget.replyId == id) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.catDustyRoseBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.blobRose),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이번 답장은 어땠나요? (선택)', style: bodyFont(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in const {
              'matched': '내 마음과 맞아요',
              'off_topic': '조금 달라요',
              'repeated': '반복적으로 느껴져요',
            }.entries)
              FilterChip(
                label: Text(item.value),
                selected: _value == item.key,
                onSelected: _busy ? null : (_) => _save(item.key),
              ),
          ],
        ),
        const Text(
          '다음 답장에서 잘 맞았던 표현을 참고하고, 엇나간 해석과 반복 문장은 줄여요. 평가는 이 기기에 저장되며, 이미 받은 편지는 바뀌지 않아요.',
          style: TextStyle(fontSize: 12, height: 1.6, color: AppColors.inkSoft),
        ),
      ],
    ),
  );
}
