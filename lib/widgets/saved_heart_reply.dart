import 'package:flutter/material.dart';
import '../models/special_letter_entry.dart';
import '../services/special_letter_service.dart';
import 'reply_support_actions.dart';
import '../services/reply_safety.dart';

/// Read-only archive. Merely opening a history card cannot generate an answer.
class SavedHeartReply extends StatefulWidget {
  final SpecialLetterEntry entry;
  const SavedHeartReply({super.key, required this.entry});
  @override
  State<SavedHeartReply> createState() => _SavedHeartReplyState();
}

class _SavedHeartReplyState extends State<SavedHeartReply> {
  late Future<String?> _archive;
  @override
  void initState() {
    super.initState();
    _archive = _readArchive();
  }

  @override
  void didUpdateWidget(covariant SavedHeartReply oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id ||
        oldWidget.entry.letterText != widget.entry.letterText) {
      _archive = _readArchive();
    }
  }

  Future<String?> _readArchive() =>
      ReplySafety.assess(widget.entry.letterText) != ReplySupportNeed.none
      ? Future<String?>.value(null)
      : SpecialLetterService.savedReply(widget.entry);

  @override
  Widget build(BuildContext context) {
    if (ReplySafety.assess(widget.entry.letterText) != ReplySupportNeed.none) {
      return ReplySupportActions(letterText: widget.entry.letterText);
    }
    return FutureBuilder<String?>(
      future: _archive,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton(
            onPressed: () => setState(() {
              _archive = _readArchive();
            }),
            child: const Text('이전에 받은 답장 다시 읽기'),
          );
        }
        final text = snapshot.data;
        if (text == null) return const SizedBox.shrink();
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('이전에 받은 답장'),
          subtitle: const Text('과거에 저장된 내용이에요'),
          children: [
            SelectableText(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.6),
            ),
          ],
        );
      },
    );
  }
}
