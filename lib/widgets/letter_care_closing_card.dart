import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../models/care_journal_entry.dart';
import '../models/letter_entry.dart';
import '../models/special_letter_entry.dart';
import '../screens/care_journal_screen.dart';
import '../services/care_journal_store.dart';
import '../theme.dart';
import 'private_memory_links.dart';

/// A quiet ending after a successfully saved letter. Every extra choice is
/// optional, explicitly the writer's own, and independent of garden rewards.
class LetterCareClosingCard extends StatefulWidget {
  const LetterCareClosingCard({super.key, required LetterEntry letter})
    : letter = letter,
      heartLetter = null;
  const LetterCareClosingCard.heart({
    super.key,
    required SpecialLetterEntry letter,
  }) : letter = null,
       heartLetter = letter;
  final LetterEntry? letter;
  final SpecialLetterEntry? heartLetter;
  String get sourceId => letter?.id ?? 'heart:${heartLetter!.id}';
  String get originalText => letter?.letterText ?? heartLetter!.letterText;
  @override
  State<LetterCareClosingCard> createState() => _LetterCareClosingCardState();
}

class _LetterCareClosingCardState extends State<LetterCareClosingCard> {
  final _store = CareJournalStore.instance;
  bool _busy = false, _loading = true, _closed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _store.reload();
    } catch (_) {
      if (mounted)
        setState(() => _error = tr("돌봄 선택을 불러오지 못했어요. 편지는 이미 저장되어 있어요."));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(Future<void> Function() work) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await work();
    } catch (_) {
      if (mounted)
        setState(
          () => _error = tr(
            "이 선택을 저장하지 못했어요. 편지는 안전하게 남아 있어요. 다시 시도하거나 여기서 마쳐도 돼요.",
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseQuote() async {
    // Keep exact original characters. No model rewrites or inferred sentiment.
    final candidates = <String>{};
    for (final line in widget.originalText.split(
      RegExp(r'(?<=[.!?。！？])\s+|\r?\n'),
    )) {
      final value = line.trim();
      if (value.isNotEmpty && value.length <= 600) candidates.add(value);
    }
    final text = TextEditingController();
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, change) => AlertDialog(
          title: Text(tr("내 문장 하나 간직하기")),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(tr("내가 쓴 말 그대로 남겨요. 다른 사람에게 공개되지 않아요.")),
                  const SizedBox(height: 12),
                  for (final quote in candidates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: () => Navigator.pop(ctx, quote),
                        child: Text(quote),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: text,
                    maxLength: 600,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: tr("원문에서 다른 부분 고르기"),
                      hintText: tr("간직하고 싶은 부분을 그대로 옮겨 적어주세요."),
                    ),
                    onChanged: (_) => change(() {}),
                  ),
                  FilledButton(
                    onPressed:
                        text.text.trim().isNotEmpty &&
                            widget.originalText.contains(text.text)
                        ? () => Navigator.pop(ctx, text.text)
                        : null,
                    child: Text(tr("이 부분 간직하기")),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr("나중에")),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => text.dispose());
    if (selected == null || !mounted) return;
    await _save(
      () => _store.saveLetterQuote(
        sourceLetterId: widget.sourceId,
        originalText: widget.originalText,
        exactQuote: selected,
      ),
    );
  }

  Future<void> _chooseClosing() async {
    final text = TextEditingController();
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, change) => AlertDialog(
          title: Text(tr("내가 나에게 고르는 말")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr("고양이의 답장이 아닌, 내가 듣고 싶어 직접 고르는 말이에요.")),
                const SizedBox(height: 12),
                for (final words in [
                  tr("오늘은 여기까지 해도 괜찮아."),
                  tr("지금의 마음을 그대로 남겨두자."),
                  tr("천천히 내 속도로 가도 괜찮아."),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, words),
                      child: Text(words),
                    ),
                  ),
                TextField(
                  controller: text,
                  maxLength: 120,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: tr("직접 적어도 좋아요")),
                  onChanged: (_) => change(() {}),
                ),
                FilledButton(
                  onPressed: text.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(ctx, text.text.trim()),
                  child: Text(tr("이 말 남기기")),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr("건너뛰기")),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => text.dispose());
    if (selected != null && mounted)
      await _save(() => _store.saveClosingWords(widget.sourceId, selected));
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return AnimatedBuilder(
      animation: _store,
      builder: (context, _) {
        final entry = _store.entryForLetter(widget.sourceId);
        return Card(
          color: const Color(0xfff5f7ee),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  child: Icon(
                    _closed
                        ? Icons.mark_email_read_outlined
                        : Icons.mail_outline,
                    key: ValueKey(_closed),
                    size: 32,
                    color: AppColors.titlePastelGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _closed ? tr("오늘의 편지를 간직했어요.") : tr("오늘의 마음을 남겼어요."),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  tr("마음이 바로 달라지지 않아도 괜찮아요. 여기서 마쳐도 돼요."),
                  textAlign: TextAlign.center,
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: LinearProgressIndicator(),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _load,
                    child: Text(tr("다시 불러오기")),
                  ),
                ],
                if (!_closed && !_loading) ...[
                  const SizedBox(height: 18),
                  Text(tr("쓰고 난 지금은 어떤가요? · 선택")),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final feeling in AfterWritingFeeling.values)
                        ChoiceChip(
                          label: Text(feeling.label),
                          selected: entry?.afterWritingFeeling == feeling,
                          onSelected: _busy
                              ? null
                              : (_) => _save(
                                  () => _store.saveLetterFeeling(
                                    widget.sourceId,
                                    feeling,
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (entry?.ownQuote != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr("내가 간직한 문장"), style: TextStyle(fontSize: 12)),
                          SelectableText(entry!.ownQuote!),
                        ],
                      ),
                    ),
                  if (entry?.ownQuote != null)
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              final saved = await attachLetterQuoteToPlant(
                                context,
                                sourceLetterId: widget.sourceId,
                                quote: entry!.ownQuote!,
                              );
                              if (saved && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr("내 나무의 추억에 간직했어요. 나무를 눌러 다시 볼 수 있어요."),
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.park_outlined),
                      label: Text(tr("이 문장을 내 나무에 간직하기")),
                    ),
                  if (entry?.selfChosenClosing != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr("내가 나에게 고른 말"),
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(entry!.selfChosenClosing!),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (widget.originalText.trim().isNotEmpty)
                        TextButton.icon(
                          onPressed: _busy ? null : _chooseQuote,
                          icon: const Icon(Icons.bookmark_border),
                          label: Text(tr("내 문장 간직하기")),
                        ),
                      TextButton(
                        onPressed: _busy ? null : _chooseClosing,
                        child: Text(tr("듣고 싶은 말 고르기")),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CareJournalScreen(
                                sourceLetterId: widget.sourceId,
                              ),
                            ),
                          ),
                    child: Text(tr("나를 돌보는 방법 보기")),
                  ),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _closed = true),
                    child: Text(tr("오늘은 여기까지")),
                  ),
                ] else if (_closed)
                  TextButton(
                    onPressed: () => setState(() => _closed = false),
                    child: Text(tr("내 선택 다시 보기")),
                  ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}
