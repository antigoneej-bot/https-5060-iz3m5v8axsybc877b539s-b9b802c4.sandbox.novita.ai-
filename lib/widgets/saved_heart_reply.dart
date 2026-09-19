import '../services/access_policy.dart';
import '../widgets/subscription_gate.dart';
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
  void initState() {
    super.initState();
    // 답장 생성 파이프라인(구독 확인·조합 연산)이 멈추더라도 이 화면이
    // 무한정 로딩 상태로 남지 않도록, 개인편지 답장에도 고양이 답장과
    // 동일하게 30초 타임아웃을 둡니다.
    _reply = SpecialLetterService.ensureReply(
      widget.entry,
    ).timeout(const Duration(seconds: 30));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _reply,
    builder: (context, snapshot) {
      if (snapshot.error is SubscriptionRequired)
        return SubscriptionNotice(
          message: snapshot.error.toString(),
          onReturn: () => setState(
            () => _reply = SpecialLetterService.ensureReply(
              widget.entry,
            ).timeout(const Duration(seconds: 30)),
          ),
        );
      if (snapshot.hasError)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('편지는 저장되어 있어요. 답장 준비를 다시 시도해 주세요.'),
            TextButton(
              onPressed: () => setState(
                () => _reply = SpecialLetterService.ensureReply(
                  widget.entry,
                ).timeout(const Duration(seconds: 30)),
              ),
              child: const Text('답장 다시 준비'),
            ),
          ],
        );
      if (!snapshot.hasData) return const Text('저장된 편지의 답장을 준비하고 있어요.');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.data!,
            style: const TextStyle(fontSize: 12.5, height: 1.6),
          ),
          ReplyFeedback(replyId: 'heart:${widget.entry.id}'),
        ],
      );
    },
  );
}
