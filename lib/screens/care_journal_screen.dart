import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../models/care_journal_entry.dart';
import '../models/care_next_step.dart';
import '../widgets/care_next_step_card.dart';
import '../mongi/screens/garden_world_screen.dart';
import '../services/care_journal_store.dart';
import '../services/analytics_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../widgets/care_return_sheet.dart';
import 'meditation_library_screen.dart';
import 'premium_screen.dart';
import 'self_care_screen.dart';

class CareJournalScreen extends StatefulWidget {
  const CareJournalScreen({super.key, this.sourceLetterId});
  final String? sourceLetterId;
  @override
  State<CareJournalScreen> createState() => _CareJournalScreenState();
}

class _CareJournalScreenState extends State<CareJournalScreen> {
  final _store = CareJournalStore.instance;
  bool _loading = true, _busy = false, _premium = false;
  String? _error;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    _load();
    AnalyticsService()
        .logEvent(AnalyticsEvents.careCollectionViewed)
        .catchError((Object _) {});
  }

  Future<void> _load() async {
    final request = ++_loadRequest;
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      await _store.reload();
    } catch (_) {
      if (mounted && request == _loadRequest) {
        setState(
          () => _error = tr("돌봄 기록을 불러오지 못했어요. 기록을 지우지 않고 다시 시도할 수 있어요."),
        );
      }
    } finally {
      if (mounted && request == _loadRequest) setState(() => _loading = false);
    }
    // Display free private care immediately; a purchase check updates only the
    // optional expanded comparison and must not keep the whole page loading.
    SubscriptionService()
        .isPremium()
        .timeout(const Duration(seconds: 4))
        .then<void>(
          (premium) {
            if (mounted && request == _loadRequest)
              setState(() => _premium = premium);
          },
          onError: (Object _) {
            if (mounted && request == _loadRequest)
              setState(() => _premium = false);
          },
        );
  }

  Future<void> _mutate(Future<void> Function() work, String success) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("저장을 마치지 못했어요. 다시 시도해 주세요."))),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _plan({
    CareActionKind? initial,
    String? label,
    String? initialContext,
  }) async {
    var kind = initial ?? CareActionKind.rest;
    String? circumstance = initialContext;
    final text = TextEditingController(text: label ?? '');
    final value =
        await showDialog<
          ({CareActionKind kind, String? label, String? context})
        >(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (ctx, change) => AlertDialog(
              title: Text(tr("나에게 맞는 작은 돌봄")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr("계획만 남겨도 괜찮아요. 실제로 해본 뒤 따로 표시할 수 있어요.")),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final option in CareActionKind.values)
                          ChoiceChip(
                            label: Text(option.label),
                            selected: kind == option,
                            onSelected: (_) => change(() => kind = option),
                          ),
                      ],
                    ),
                    if (kind == CareActionKind.custom)
                      TextField(
                        controller: text,
                        maxLength: 120,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: tr("해보고 싶은 돌봄"),
                          hintText: tr("예: 창가에서 차 한 잔 마시기"),
                        ),
                        onChanged: (_) => change(() {}),
                      ),
                    const SizedBox(height: 16),
                    Text(tr("어떤 때를 위한 건가요? · 선택")),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final option in [
                          tr("관계"),
                          tr("일·공부"),
                          tr("몸이 피곤할 때"),
                          tr("이유를 모르겠을 때"),
                        ])
                          ChoiceChip(
                            label: Text(option),
                            selected: circumstance == option,
                            onSelected: (selected) => change(
                              () => circumstance = selected ? option : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(tr("나중에")),
                ),
                FilledButton(
                  onPressed:
                      kind == CareActionKind.custom && text.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(ctx, (
                          kind: kind,
                          label: kind == CareActionKind.custom
                              ? text.text.trim()
                              : null,
                          context: circumstance,
                        )),
                  child: Text(tr("계획 남기기")),
                ),
              ],
            ),
          ),
        );
    // Dialog exit animation may still build the TextField for one frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => text.dispose());
    if (value == null || !mounted) return;
    await _mutate(() async {
      await _store.planAction(
        kind: value.kind,
        customLabel: value.label,
        contextLabel: value.context,
        sourceLetterId: widget.sourceLetterId,
      );
    }, tr("해보고 싶은 돌봄을 남겼어요. 편한 때 해보세요."));
  }

  Future<void> _openSaved({required bool words}) async {
    final entry = await showModalBottomSheet<CareJournalEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          CareReturnSheet(store: _store, words: words, onRemove: _remove),
    );
    if (entry != null && mounted) {
      await _plan(
        initial: entry.actionKind,
        label: entry.actionLabel,
        initialContext: entry.contextLabel,
      );
    }
  }

  Future<void> _complete(CareJournalEntry entry) async {
    final answer = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          entry.completedAt == null ? tr("실제로 해보셨나요?") : tr("해본 뒤 어땠나요?"),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(entry.actionLabel!),
              const SizedBox(height: 12),
              Text(tr("내가 느낀 만큼만 남겨주세요. 도움 여부를 고르지 않아도 돼요.")),
              const SizedBox(height: 12),
              for (final option in CareHelpfulness.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, option.name),
                    child: Text(option.label),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr("닫기")),
          ),
          if (entry.completedAt == null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'completed'),
              child: Text(tr("해봤다는 것만 남기기")),
            ),
        ],
      ),
    );
    if (answer == null || !mounted) return;
    final feedback = answer == 'completed'
        ? null
        : CareHelpfulness.values.firstWhere((item) => item.name == answer);
    await _mutate(
      () => _store.completeAction(entry.id, helpfulness: feedback),
      tr("내가 남긴 경험을 저장했어요."),
    );
  }

  Future<void> _remove(CareJournalEntry entry) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr("이 돌봄 기록을 지울까요?")),
        content: Text(tr("돌봄 목록에서 지워져요. 원래 쓴 편지와 정원의 성장은 유지돼요.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr("취소")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr("지우기")),
          ),
        ],
      ),
    );
    if (remove == true && mounted)
      await _mutate(() => _store.remove(entry.id), tr("돌봄 기록을 지웠어요."));
  }

  Future<void> _openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SelfCareScreen()),
    );
    if (mounted) await _load();
  }

  Future<void> _openMeditation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(tr("잠깐 명상하기"))),
          body: const SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(18),
              child: MeditationLibraryScreen(),
            ),
          ),
        ),
      ),
    );
    // Visiting/listening is not silently recorded as a completed care action.
  }

  String _date(DateTime date) {
    final local = date.toLocal();
    return tr("{0}월 {1}일", [local.month, local.day]);
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Widget _action(CareJournalEntry entry) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              entry.completedAt == null
                  ? Icons.spa_outlined
                  : Icons.check_circle_outline,
              color: AppColors.titlePastelGreen,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: tr("돌봄 기록 지우기"),
              visualDensity: VisualDensity.compact,
              onPressed: _busy ? null : () => _remove(entry),
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
        Text(
          tr("{0} 계획{1}", [
            _date(entry.createdAt),
            entry.contextLabel == null ? '' : ' · ${entry.contextLabel}',
          ]),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (entry.completedAt != null)
          Text(
            tr("{0} 해봤어요 · {1}", [
              _date(entry.completedAt!),
              entry.helpfulness?.label ?? tr("도움 여부는 남기지 않았어요"),
            ]),
          ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: _busy ? null : () => _complete(entry),
              child: Text(
                entry.completedAt == null ? tr("해봤어요") : tr("다시 돌아보기"),
              ),
            ),
            if (entry.actionKind == CareActionKind.meditation &&
                entry.isPlanned)
              TextButton(onPressed: _openMeditation, child: Text(tr("명상 고르기"))),
          ],
        ),
        const Divider(height: 12),
      ],
    ),
  );

  Widget _comparison(List<CareJournalEntry> entries) {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final previous = DateTime(now.year, now.month - 1);
    final next = DateTime(now.year, now.month + 1);
    List<CareJournalEntry> during(DateTime start, DateTime end) => entries
        .where(
          (e) =>
              e.completedAt != null &&
              !e.completedAt!.toLocal().isBefore(start) &&
              e.completedAt!.toLocal().isBefore(end),
        )
        .toList();
    final before = during(previous, current), after = during(current, next);
    return _section(tr("두 달의 돌봄 돌아보기"), [
      if (!_premium) ...[
        Text(
          tr(
            "정원 플러스에서는 지난달과 이번 달에 직접 남긴 돌봄 경험을 나란히 볼 수 있어요. 기존 기록 열람과 기본 통계는 무료예요.",
          ),
        ),
        TextButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            );
            if (mounted) await _load();
          },
          child: Text(tr("정원 플러스 알아보기")),
        ),
      ] else ...[
        Text(
          tr("지난달 · 해본 돌봄 {0}회 / 도움이 됐다고 남긴 경험 {1}회", [
            before.length,
            before.where((e) => e.wasHelpful).length,
          ]),
        ),
        const SizedBox(height: 8),
        Text(
          tr("이번 달 · 해본 돌봄 {0}회 / 도움이 됐다고 남긴 경험 {1}회", [
            after.length,
            after.where((e) => e.wasHelpful).length,
          ]),
        ),
        const SizedBox(height: 8),
        Text(tr("기록한 횟수이며 효과나 마음의 개선 점수가 아니에요. 기록이 없는 날은 계산하지 않아요.")),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: Text(tr("나를 돌보는 방법"))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        TextButton(
                          onPressed: _load,
                          child: Text(tr("다시 불러오기")),
                        ),
                      ],
                    ),
                  )
                : AnimatedBuilder(
                    animation: _store,
                    builder: (context, _) {
                      final entries = _store.entries;
                      final next = CareNextStep.fromEntries(
                        entries,
                        now: DateTime.now(),
                      );
                      final actions = entries
                          .where((e) => e.actionKind != null)
                          .toList();
                      final pending = actions
                          .where((e) => e.isPlanned)
                          .toList();
                      final completed = actions
                          .where((e) => e.completedAt != null)
                          .toList();
                      final now = DateTime.now();
                      final weekStart = DateTime(
                        now.year,
                        now.month,
                        now.day - now.weekday + 1,
                      );
                      final weekEnd = weekStart.add(const Duration(days: 7));
                      bool thisWeek(DateTime date) =>
                          !date.toLocal().isBefore(weekStart) &&
                          date.toLocal().isBefore(weekEnd);
                      final week = actions
                          .where(
                            (e) =>
                                e.completedAt != null &&
                                thisWeek(e.completedAt!),
                          )
                          .toList();
                      final words = entries
                          .where(
                            (e) =>
                                e.ownQuote != null ||
                                e.selfChosenClosing != null ||
                                e.encouragementText != null,
                          )
                          .toList();
                      return RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: [
                            Text(
                              tr("나에게 도움이 됐던 것을\n필요한 날 다시 꺼내요."),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              tr(
                                "내가 직접 남긴 경험만 모아요. 쉬어간 날에는 벌점도, 해야 할 숙제도 없어요.",
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (_busy) const LinearProgressIndicator(),
                            if (next.suggested != null ||
                                next.awaitingFeedback != null)
                              CareNextStepCard(
                                summary: next,
                                busy: _busy,
                                onRepeat: () {
                                  final entry = next.suggested;
                                  if (entry != null) {
                                    _plan(
                                      initial: entry.actionKind,
                                      label: entry.actionLabel,
                                      initialContext: entry.contextLabel,
                                    );
                                  }
                                },
                                onFeedback: () {
                                  if (next.awaitingFeedback != null) {
                                    _complete(next.awaitingFeedback!);
                                  }
                                },
                                onChoose: () => _plan(),
                                onGarden: () =>
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const GardenWorldScreen.owned(),
                                      ),
                                    ),
                              ),
                            _section(tr("필요한 날 다시 꺼내요"), [
                              OutlinedButton.icon(
                                key: const ValueKey('open-saved-words'),
                                onPressed: _busy
                                    ? null
                                    : () => _openSaved(words: true),
                                icon: const Icon(Icons.bookmark_border),
                                label: Text(tr("간직한 말 다시 보기")),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                key: const ValueKey('open-helpful-care'),
                                onPressed: _busy
                                    ? null
                                    : () => _openSaved(words: false),
                                icon: const Icon(Icons.spa_outlined),
                                label: Text(tr("도움이 됐던 돌봄 꺼내기")),
                              ),
                            ]),
                            _section(tr("지금 나에게 해줄 작은 일"), [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final kind in CareActionKind.values)
                                    OutlinedButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _plan(initial: kind),
                                      child: Text(kind.label),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextButton.icon(
                                onPressed: _openStatistics,
                                icon: const Icon(Icons.insights_outlined),
                                label: Text(tr("마음의 온도 · 주간·월간 통계")),
                              ),
                            ]),
                            _section(tr("이번 주, 내가 남긴 경험"), [
                              Text(
                                tr("해본 돌봄 {0}회 · 도움 여부를 남긴 경험 {1}회", [
                                  week.length,
                                  week
                                      .where((e) => e.helpfulness != null)
                                      .length,
                                ]),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                week.isEmpty
                                    ? tr("아직 남긴 경험이 없어요. 계획만 골라도 괜찮아요.")
                                    : tr("그중 {0}회는 도움이 됐다고 남겼어요.", [
                                        week.where((e) => e.wasHelpful).length,
                                      ]),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tr(
                                  "느낌이 그대로여도 소중한 기록이에요. 다음에 해보고 싶은 작은 일을 골라보세요.",
                                ),
                              ),
                            ]),
                            _section(tr("나에게 도움이 됐던 돌봄"), [
                              if (_store.helpfulActions.isEmpty)
                                Text(tr("직접 해보고 도움이 됐다고 남기면 여기에 모여요.")),
                              for (final entry in _store.helpfulActions.take(3))
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(entry.actionLabel!),
                                  subtitle: Text(
                                    tr("{0} · 내가 도움이 됐다고 남긴 경험", [
                                      _date(entry.completedAt!),
                                    ]),
                                  ),
                                  trailing: IconButton(
                                    tooltip: tr("다시 해볼 계획 남기기"),
                                    onPressed: _busy
                                        ? null
                                        : () => _plan(
                                            initial: entry.actionKind,
                                            label: entry.actionLabel,
                                            initialContext: entry.contextLabel,
                                          ),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ),
                            ]),
                            if (pending.isNotEmpty)
                              _section(tr("편한 때 해보고 싶은 돌봄"), [
                                for (final entry in pending) _action(entry),
                              ]),
                            _section(tr("간직한 말"), [
                              Text(
                                words.isEmpty
                                    ? tr("편지에서 직접 고른 문장과 저장한 응원을 모아볼 수 있어요.")
                                    : tr("간직한 말이 담긴 기록 {0}개가 있어요.", [
                                        words.length,
                                      ]),
                              ),
                              TextButton.icon(
                                onPressed: () => _openSaved(words: true),
                                icon: const Icon(Icons.bookmark_border),
                                label: Text(tr("내 문장 · 나에게 한 말 · 받은 응원 보기")),
                              ),
                            ]),
                            _comparison(entries),
                            if (completed.isNotEmpty)
                              _section(tr("해본 돌봄 기록"), [
                                for (final entry in completed) _action(entry),
                              ]),
                            Text(
                              tr(
                                "이 기록은 나의 경험을 돌아보기 위한 것이며 진단이나 치료 효과를 나타내지 않아요.",
                              ),
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
