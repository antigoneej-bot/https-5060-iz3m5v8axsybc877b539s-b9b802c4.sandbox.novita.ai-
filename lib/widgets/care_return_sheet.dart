import 'package:flutter/material.dart';
import '../models/care_journal_entry.dart';
import '../services/care_journal_store.dart';
import 'private_memory_links.dart';

enum SavedWordKind { all, ownQuote, closing, encouragement }

/// The drawer only displays words deliberately saved by the person. Opening it
/// never creates a care action, changes helpfulness, or shares private writing.
class CareReturnSheet extends StatefulWidget {
  const CareReturnSheet({
    super.key,
    required this.store,
    required this.words,
    this.onRemove,
  });
  final CareJournalStore store;
  final bool words;
  final Future<void> Function(CareJournalEntry)? onRemove;

  @override
  State<CareReturnSheet> createState() => _CareReturnSheetState();
}

class _CareReturnSheetState extends State<CareReturnSheet> {
  SavedWordKind _filter = SavedWordKind.all;
  bool _busy = false;

  String _date(DateTime date) {
    final local = date.toLocal();
    return '${local.year}.${local.month}.${local.day}';
  }

  bool _show(SavedWordKind kind) =>
      _filter == SavedWordKind.all || _filter == kind;

  bool _matches(CareJournalEntry entry) =>
      (_show(SavedWordKind.ownQuote) && entry.ownQuote != null) ||
      (_show(SavedWordKind.closing) && entry.selfChosenClosing != null) ||
      (_show(SavedWordKind.encouragement) && entry.encouragementText != null);

  Future<void> _attach(CareJournalEntry entry) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await attachLetterQuoteToPlant(
        context,
        sourceLetterId: entry.sourceLetterId!,
        quote: entry.ownQuote!,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _word(String label, String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        SelectableText(text, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );

  Widget _words(CareJournalEntry entry) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_date(entry.createdAt)}에 간직했어요',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_show(SavedWordKind.ownQuote) && entry.ownQuote != null)
            _word('내 편지에서 고른 문장', entry.ownQuote!),
          if (_show(SavedWordKind.closing) && entry.selfChosenClosing != null)
            _word('내가 나에게 남긴 말', entry.selfChosenClosing!),
          if (_show(SavedWordKind.encouragement) &&
              entry.encouragementText != null)
            _word(
              '${entry.encouragementAuthor ?? '이웃'}에게 받은 응원',
              entry.encouragementText!,
            ),
          if (entry.sourceLetterId != null)
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => openPrivateLetterMemory(
                          context,
                          entry.sourceLetterId!,
                        ),
                  child: const Text('그날 편지 보기'),
                ),
                if (_show(SavedWordKind.ownQuote) && entry.ownQuote != null)
                  TextButton.icon(
                    onPressed: _busy ? null : () => _attach(entry),
                    icon: const Icon(Icons.park_outlined, size: 18),
                    label: const Text('나무에 간직하기'),
                  ),
              ],
            ),
          if (widget.onRemove != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy ? null : () => widget.onRemove!(entry),
                child: const Text('돌봄 목록에서 지우기'),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _care(CareJournalEntry entry) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            entry.actionLabel!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('${_date(entry.completedAt!)} · 내가 도움이 됐다고 남겼어요'),
          if (entry.contextLabel != null) ...[
            const SizedBox(height: 4),
            Text('그때의 상황 · ${entry.contextLabel}'),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, entry),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('다시 해볼 계획 남기기'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: FractionallySizedBox(
      heightFactor: .88,
      child: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final entries = widget.words
              ? widget.store.entries.where(_matches).toList()
              : widget.store.helpfulActions;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.words ? '간직한 말 다시 보기' : '도움이 됐던 돌봄',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      widget.words
                          ? '내가 직접 간직한 말이에요. 나만 볼 수 있어요.'
                          : '최근에 도움이 됐다고 남긴 경험이에요. 오늘도 맞을지 천천히 골라보세요.',
                    ),
                    const SizedBox(height: 12),
                    if (widget.words) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final option in SavedWordKind.values)
                            ChoiceChip(
                              label: Text(switch (option) {
                                SavedWordKind.all => '모두',
                                SavedWordKind.ownQuote => '내 문장',
                                SavedWordKind.closing => '나에게 한 말',
                                SavedWordKind.encouragement => '받은 응원',
                              }),
                              selected: _filter == option,
                              onSelected: (_) =>
                                  setState(() => _filter = option),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          widget.words
                              ? '아직 간직한 말이 없어요. 편지에서 내 문장을 고르거나 받은 응원을 저장해 보세요.'
                              : '아직 도움이 됐다고 남긴 돌봄이 없어요. 직접 해본 뒤 원하는 만큼만 남겨보세요.',
                        ),
                      ),
                    for (final entry in entries)
                      widget.words ? _words(entry) : _care(entry),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
