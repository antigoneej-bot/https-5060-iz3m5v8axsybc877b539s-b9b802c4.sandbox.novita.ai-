import '../services/access_policy.dart';
import '../widgets/subscription_gate.dart';
import 'package:flutter/material.dart';
import '../models/special_letter_entry.dart';
import '../services/special_letter_service.dart';
import '../services/personal_reply_service.dart';
import '../services/reply_failure.dart';
import 'reply_feedback.dart';
import 'reply_support_actions.dart';
import '../services/reply_safety.dart';

class SavedHeartReply extends StatefulWidget {
  final SpecialLetterEntry entry;
  const SavedHeartReply({super.key, required this.entry});
  @override
  State<SavedHeartReply> createState() => _SavedHeartReplyState();
}

class _SavedHeartReplyState extends State<SavedHeartReply>
    with WidgetsBindingObserver {
  String? _reply;
  Object? _error;
  bool _loading = false;
  bool _canRefresh = false;
  bool _refreshed = false;
  int _request = 0;
  bool _loaded = false;
  bool _generationRequested = false;
  bool _markedSeen = false;
  bool _foreground = true;
  final _answerKey = GlobalKey();
  ScrollPosition? _scroll;

  bool get _needsSupport =>
      ReplySafety.assess(widget.entry.letterText) != ReplySupportNeed.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(covariant SavedHeartReply oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _request++;
      _reply = null;
      _error = null;
      _loading = false;
      _canRefresh = false;
      _refreshed = false;
      _loaded = false;
      _generationRequested = false;
      _markedSeen = false;
      _load();
    }
  }

  bool _isCurrent(int request, String id) =>
      mounted && _request == request && widget.entry.id == id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (!identical(_scroll, scroll)) {
      _scroll?.removeListener(_markSeenIfVisible);
      _scroll = scroll;
      _scroll?.addListener(_markSeenIfVisible);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _markSeenIfVisible());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markSeenIfVisible());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll?.removeListener(_markSeenIfVisible);
    super.dispose();
  }

  // A history list can build cards below the viewport. Reading a cached answer
  // is harmless, but that alone must not mark an unseen, off-screen card read.
  void _markSeenIfVisible() {
    if (!mounted ||
        !_foreground ||
        _markedSeen ||
        (_reply == null && !(_needsSupport && widget.entry.isReplyReady)) ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    final answer = _answerKey.currentContext?.findRenderObject();
    if (answer is! RenderBox || !answer.hasSize) return;
    final bounds = answer.localToGlobal(Offset.zero) & answer.size;
    final viewport = Scrollable.maybeOf(context)?.context.findRenderObject();
    final visible = viewport is RenderBox && viewport.hasSize
        ? viewport.localToGlobal(Offset.zero) & viewport.size
        : Offset.zero & MediaQuery.sizeOf(context);
    final overlap = bounds.intersect(visible);
    if (overlap.isEmpty || overlap.height < bounds.height.clamp(0, 40)) return;
    final id = widget.entry.id;
    final request = _request;
    _markedSeen = true;
    SpecialLetterService.markReplySeen(id).catchError((Object _) {
      if (_isCurrent(request, id)) _markedSeen = false;
    });
  }

  void _load({bool refreshExisting = false, bool generate = false}) {
    if (_loading || _needsSupport) return;
    final entry = widget.entry;
    final request = ++_request;
    _loading = true;
    _error = null;
    _generationRequested = generate || refreshExisting;
    // Opening a history card only reads saved content. New answers require an
    // explicit action so an off-screen card cannot consume today's free answer.
    final Future<String?> pending = _generationRequested
        ? SpecialLetterService.ensureReply(
            entry,
            refreshExisting: refreshExisting,
          )
        : SpecialLetterService.savedReply(entry);
    pending
        .timeout(Duration(seconds: refreshExisting ? 50 : 30))
        .then(
          (value) async {
            if (!_isCurrent(request, entry.id)) return;
            setState(() {
              _reply = value;
              _loading = false;
              _loaded = true;
              if (refreshExisting) {
                _refreshed = true;
                _canRefresh = false;
              }
            });
            if (value == null) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_isCurrent(request, entry.id)) _markSeenIfVisible();
            });
            if (!refreshExisting) {
              try {
                final outdated = await PersonalReplyService.needsRefresh(
                  'heart:${entry.id}',
                );
                if (_isCurrent(request, entry.id)) {
                  setState(() => _canRefresh = outdated);
                }
              } catch (_) {
                /* Metadata failure never hides saved content. */
              }
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!_isCurrent(request, entry.id)) return;
            setState(() {
              _loading = false;
              _error = error;
            });
          },
        );
  }

  void _retry() => setState(
    () =>
        _load(refreshExisting: _reply != null, generate: _generationRequested),
  );

  @override
  Widget build(BuildContext context) {
    // Do not present an old, possibly cheerful answer to a current safety need.
    // The original answer stays saved; support never waits for quota or arrival.
    if (_needsSupport) {
      return ReplySupportActions(
        key: _answerKey,
        letterText: widget.entry.letterText,
      );
    }
    if (_reply == null && _error is SubscriptionRequired) {
      return SubscriptionNotice(message: _error.toString(), onReturn: _retry);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_reply != null)
          Text(
            _reply!,
            key: _answerKey,
            style: const TextStyle(fontSize: 12.5, height: 1.6),
          ),
        if (_loaded && _reply == null && !_loading && _error == null)
          TextButton.icon(
            onPressed: () => setState(() => _load(generate: true)),
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('답장 열기'),
          ),
        if (_loading) ...[
          const SizedBox(height: 8),
          Text(
            _reply == null
                ? '저장된 편지의 답장을 준비하고 있어요.'
                : '새 문안으로 답장을 준비하고 있어요. 기존 답장은 그대로 보관 중이에요.',
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _reply == null
                ? '편지는 저장되어 있어요. 답장 준비를 다시 시도해 주세요.'
                : '새 답장을 준비하지 못했어요. 기존 답장은 그대로예요.',
          ),
          SelectableText(
            ReplyFailure.description(_error),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          TextButton(
            onPressed: _loading ? null : _retry,
            child: Text(_reply == null ? '답장 다시 준비' : '새 답장 다시 시도'),
          ),
        ],
        if (_reply != null && _canRefresh && _error == null) ...[
          const SizedBox(height: 8),
          const Text(
            '예전에 저장한 답장이에요. 원할 때 새 문안으로 바꿀 수 있어요. 무료 답장 횟수는 추가로 차감되지 않아요.',
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
          TextButton.icon(
            onPressed: _loading
                ? null
                : () => setState(() => _load(refreshExisting: true)),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('새 문안으로 답장 다시 받기'),
          ),
        ],
        if (_refreshed)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '새 문안의 답장으로 바꿨어요. 원래 편지와 정원 기록은 그대로예요.',
              style: TextStyle(fontSize: 12, height: 1.6),
            ),
          ),
        if (_reply != null && !_loading)
          ReplyFeedback(
            key: ValueKey('heart:${widget.entry.id}:$_refreshed'),
            replyId: 'heart:${widget.entry.id}',
          ),
      ],
    );
  }
}
