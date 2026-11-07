import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../data/shadow_cats_data.dart';
import '../models/self_care_entry.dart';
import '../services/self_care_store.dart';
import '../services/self_care_summary.dart';
import '../theme.dart';
import '../widgets/period_reflection_card.dart';
import 'self_care_entry_screen.dart';
import 'care_connection_screen.dart';

String _date(DateTime d) => '${d.year}.${d.month}.${d.day}';
String _time(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

class SelfCareScreen extends StatefulWidget {
  final bool initialMonthly;
  final DateTime? initialDate;
  final VoidCallback? onOpenRecords;
  const SelfCareScreen({
    super.key,
    this.initialMonthly = false,
    this.initialDate,
    this.onOpenRecords,
  });
  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen> {
  late bool _monthly;
  late DateTime _anchor;
  DateTime get _today => SelfCareSummary.day(DateTime.now());
  @override
  void initState() {
    super.initState();
    _monthly = widget.initialMonthly;
    _anchor = widget.initialDate ?? _today;
  }

  DateTime get _start => _monthly
      ? DateTime(_anchor.year, _anchor.month)
      : DateTime(
          _anchor.year,
          _anchor.month,
          _anchor.day - _anchor.weekday + 1,
        );
  DateTime get _end {
    final end = _monthly
        ? DateTime(_anchor.year, _anchor.month + 1, 0)
        : DateTime(_start.year, _start.month, _start.day + 6);
    return end.isAfter(_today) ? _today : end;
  }

  void _shift(int delta) => setState(() {
    _anchor = _monthly
        ? DateTime(_anchor.year, _anchor.month + delta)
        : DateTime(_start.year, _start.month, _start.day + 7 * delta);
  });

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final key = '${_monthly ? 'month' : 'week'}_${_start.toIso8601String()}';
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(tr("돌아보고 돌보기")),
        actions: [
          if (widget.onOpenRecords != null)
            IconButton(
              tooltip: tr("지난 편지 보기"),
              icon: const Icon(Icons.mail_outline),
              onPressed: () {
                Navigator.pop(context);
                widget.onOpenRecords!();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  tr("나에게 도움이 되는 돌봄을 찾아가요"),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(
                    "내 마음을 기록하고, 작은 돌봄을 해본 뒤 돌아봐요. 모든 감정을 편안한 쪽으로 바꿔야 하는 것은 아니에요.",
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelfCareEntryScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(tr("지금 마음 남기기")),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(tr("주간")),
                      selected: !_monthly,
                      onSelected: (_) => setState(() => _monthly = false),
                    ),
                    ChoiceChip(
                      label: Text(tr("월간")),
                      selected: _monthly,
                      onSelected: (_) => setState(() => _monthly = true),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: tr("이전 기간"),
                      onPressed: () => _shift(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        '${_date(_start)} – ${_date(_end)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      tooltip: tr("다음 기간"),
                      onPressed: _end.isBefore(_today) ? () => _shift(1) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                SelfCarePeriodCard(
                  start: _start,
                  end: _end,
                  expanded: true,
                  monthly: _monthly,
                ),
                PeriodReflectionCard(
                  key: ValueKey(key),
                  periodKey: key,
                  monthly: _monthly,
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CareConnectionScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.support_agent),
                  label: Text(tr("상담·명상·지역 도움 찾기")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reused in existing statistics. The core records and support stay free.
class SelfCarePeriodCard extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final bool expanded;
  final bool monthly;
  const SelfCarePeriodCard({
    super.key,
    required this.start,
    required this.end,
    this.expanded = false,
    this.monthly = false,
  });
  @override
  State<SelfCarePeriodCard> createState() => _SelfCarePeriodCardState();
}

class _SelfCarePeriodCardState extends State<SelfCarePeriodCard> {
  late Future<List<SelfCareEntry>> _future;
  @override
  void initState() {
    super.initState();
    _future = SelfCareStore.instance.load();
    SelfCareStore.instance.revision.addListener(_reload);
  }

  @override
  void dispose() {
    SelfCareStore.instance.revision.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) setState(() => _future = SelfCareStore.instance.load());
  }

  Future<void> _delete(SelfCareEntry entry) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr("이 돌봄 기록을 삭제할까요?")),
        content: Text(
          tr("점수·돌아보기·돌봄 후기를 함께 삭제해요. 정원의 성장은 유지돼요. 이전에 저장한 백업에는 남을 수 있어요."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr("취소")),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr("삭제")),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await SelfCareStore.instance.remove(entry.id);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr("삭제하지 못했어요. 다시 시도해 주세요."))));
    }
  }

  Widget _entry(SelfCareEntry entry) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 16),
    title: Text('${_date(entry.createdAt)} ${_time(entry.createdAt)}'),
    subtitle: Text(
      [
        entry.comfort == null
            ? tr("점수 선택 안 함")
            : tr("편안함 {0}/10", [entry.comfort]),
        if (entry.catId != null) shadowCatById(entry.catId!).displayKeyword,
        if (entry.action != null)
          entry.feedback == null ? tr("돌봄 후기 대기") : entry.feedback!.label,
      ].join(' · '),
    ),
    children: [
      if (entry.reflection.isNotEmpty) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(reflectionPrompts[entry.promptIndex]),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(entry.reflection),
        ),
      ],
      if (entry.action != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(entry.action!.label),
          subtitle: Text(entry.action!.guide),
        ),
      if (entry.plan.isNotEmpty)
        Align(
          alignment: Alignment.centerLeft,
          child: SelectableText(entry.plan),
        ),
      if (entry.feedback != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            tr("{0}\n후기: {1}{2}", [
              entry.feedback!.label,
              _date(entry.reviewedAt!),
              entry.afterComfort == null
                  ? ''
                  : tr(" · 실천 후 편안함 {0}/10", [entry.afterComfort]),
            ]),
          ),
        ),
      if (entry.action != null)
        OutlinedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CareFeedbackScreen(entry: entry)),
          ),
          child: Text(
            entry.feedback == null ? tr("해봤어요 · 도움 여부 남기기") : tr("돌봄 후기 수정"),
          ),
        ),
      TextButton(
        onPressed: () => _delete(entry),
        child: Text(tr("이 돌봄 기록 삭제")),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: AppColors.blobMint,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<List<SelfCareEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Column(
                children: [
                  Text(tr("돌봄 기록을 불러오지 못했어요. 기존 기록은 삭제하지 않았어요.")),
                  TextButton(onPressed: _reload, child: Text(tr("다시 불러오기"))),
                ],
              );
            if (!snapshot.hasData)
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            final summary = SelfCareSummary(
              snapshot.data!,
              widget.start,
              widget.end,
            );
            final daily = summary.dailyComfort;
            final pending = SelfCareSummary.pending(
              snapshot.data!,
              DateTime.now(),
            );
            final reusable = SelfCareSummary.reusable(snapshot.data!);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr("내가 느낀 마음 · 돌봄 후기"),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  summary.average == null
                      ? tr("아직 직접 남긴 점수가 없어요.")
                      : tr("편안함 평균 {0} / 10", [
                          summary.average!.toStringAsFixed(1),
                        ]),
                ),
                const SizedBox(height: 6),
                Text(
                  tr("점수를 남긴 날 {0} / {1}일 · 점수 기록 {2}회", [
                    daily.length,
                    summary.elapsedDays,
                    summary.scoredEntries,
                  ]),
                ),
                const SizedBox(height: 8),
                Text(
                  tr(
                    "1 매우 힘들어요 · 10 매우 편안해요\n하루에 여러 번 남긴 점수는 일평균으로 묶어요. 기록 없는 날은 계산에서 제외하며, 실천 후 점수는 별도로 보관해요.",
                  ),
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
                if (summary.entries.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(tr("비어 있는 날도 괜찮아요. 오늘 남기고 싶은 마음부터 시작해요.")),
                  ),
                if (!widget.expanded)
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SelfCareScreen(
                          initialMonthly: widget.monthly,
                          initialDate: widget.start,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.spa_outlined),
                    label: Text(tr("돌아보기 · 돌봄 이어가기")),
                  ),
                if (widget.expanded) ...[
                  const SizedBox(height: 16),
                  Text(
                    tr("작은 돌봄 이어가기"),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(tr("해보았다면 어땠는지 남겨요. 아직 하지 않았다면 서두르지 않아도 괜찮아요.")),
                  for (final entry in pending.take(3))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.action!.label),
                      subtitle: Text(
                        tr("{0}에 골랐어요 · 나만 보는 기록", [_date(entry.createdAt)]),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CareFeedbackScreen(entry: entry),
                        ),
                      ),
                    ),
                  if (pending.length > 3)
                    ExpansionTile(
                      title: Text(
                        tr("후기를 기다리는 돌봄 {0}개 더 보기", [pending.length - 3]),
                      ),
                      children: [
                        for (final entry in pending.skip(3))
                          ListTile(
                            title: Text(entry.action!.label),
                            subtitle: Text(_date(entry.createdAt)),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CareFeedbackScreen(entry: entry),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (reusable.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(tr("최근에 도움이 됐다고 남긴 돌봄")),
                    for (final action in reusable.take(2))
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SelfCareEntryScreen(initialAction: action),
                          ),
                        ),
                        child: Text(tr("{0} 다시 선택", [action.label])),
                      ),
                  ],
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SelfCareEntryScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.spa_outlined),
                    label: Text(tr("오늘의 작은 돌봄 새로 고르기")),
                  ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(tr("날짜별 편안함 살펴보기")),
                    children: [
                      for (
                        var date = widget.start;
                        !date.isAfter(widget.end);
                        date = DateTime(date.year, date.month, date.day + 1)
                      )
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 55,
                                child: Text('${date.month}/${date.day}'),
                              ),
                              Expanded(
                                child: daily[date] == null
                                    ? Text(tr("점수 기록 없음"))
                                    : Semantics(
                                        label: tr("{0}월 {1}일 편안함 {2}점, 10점 중", [
                                          date.month,
                                          date.day,
                                          daily[date]!.toStringAsFixed(1),
                                        ]),
                                        child: LinearProgressIndicator(
                                          value: daily[date]! / 10,
                                          minHeight: 8,
                                          color: AppColors.titlePastelGreen,
                                          backgroundColor: Colors.white70,
                                        ),
                                      ),
                              ),
                              if (daily[date] != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(daily[date]!.toStringAsFixed(1)),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr("내가 선택했던 돌봄"),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      "선택한 날짜가 이 기간에 속하는 기록의 후기를 모았어요. 내 경험의 기록이며, 효과를 판정하는 결과는 아니에요.",
                    ),
                    style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                  ),
                  if (summary.actions.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(tr("아직 선택한 돌봄이 없어요. 기록만 남겨도 괜찮아요.")),
                    ),
                  for (final action in summary.actions) ...[
                    const SizedBox(height: 16),
                    Text(
                      action.action.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      tr("선택 {0}회 · 후기 {1}회 · 후기 대기 {2}회", [
                        action.planned,
                        action.reviewed,
                        action.planned - action.reviewed,
                      ]),
                    ),
                    Text(
                      tr("조금 도움 {0} · 변화 없음 {1} · 불편 {2} · 모르겠음 {3}", [
                        action.helped,
                        action.responses[CareFeedback.unchanged],
                        action.responses[CareFeedback.uncomfortable],
                        action.responses[CareFeedback.unsure],
                      ]),
                    ),
                    if (action.helped > 0 && reusable.contains(action.action))
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelfCareEntryScreen(
                              initialAction: action.action,
                            ),
                          ),
                        ),
                        child: Text(tr("도움 됐던 이 돌봄 다시 선택")),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    tr("기록을 눌러 다시 보고, 해본 뒤 후기를 남겨요."),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  for (final entry in summary.entries) _entry(entry),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
