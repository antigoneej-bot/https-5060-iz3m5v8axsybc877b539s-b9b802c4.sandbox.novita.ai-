import 'package:flutter/material.dart';
import '../models/special_letter_entry.dart';
import '../services/special_letter_service.dart';
import 'reply_feedback.dart';

class SavedHeartReply extends StatefulWidget {
  final SpecialLetterEntry entry;
  const SavedHeartReply({super.key, required this.entry});
  @override
  State<SavedHeartReply> createState() => _SavedHeartReplyState();
}
class _SavedHeartReplyState extends State<SavedHeartReply> {
  late Future<String> _reply;
  @override
  void initState() { super.initState(); _reply = SpecialLetterService.ensureReply(widget.entry); }
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(future: _reply, builder: (context, snapshot) {
    if (snapshot.hasError) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('편지는 저장되어 있어요. 답장 준비를 다시 시도해 주세요.'),
      TextButton(onPressed: () => setState(() => _reply = SpecialLetterService.ensureReply(widget.entry)), child: const Text('답장 다시 준비')),
    ]);
    if (!snapshot.hasData) return const Text('저장된 편지의 답장을 준비하고 있어요.');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(snapshot.data!, style: const TextStyle(fontSize: 12.5, height: 1.6)),
      ReplyFeedback(replyId: 'heart:${widget.entry.id}'),
    ]);
  });
}
