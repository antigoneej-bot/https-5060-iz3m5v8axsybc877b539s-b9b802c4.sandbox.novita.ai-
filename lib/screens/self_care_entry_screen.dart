import 'dart:math';
import 'package:flutter/material.dart';
import '../data/shadow_cats_data.dart';
import '../models/self_care_entry.dart';
import '../services/self_care_store.dart';
import '../theme.dart';
import 'care_connection_screen.dart';

class ComfortPicker extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;
  const ComfortPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '지금 마음은 얼마나 편안한가요?',
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text('1 매우 힘들어요 · 10 매우 편안해요\n진단 점수가 아니라 내가 느끼는 정도예요.'),
      const SizedBox(height: 12),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (var i = 1; i <= 10; i++)
            ChoiceChip(
              label: Text('$i'),
              selected: value == i,
              onSelected: (_) => onChanged(i),
            ),
        ],
      ),
      TextButton(
        onPressed: () => onChanged(null),
        child: Text(value == null ? '지금은 모르겠어요 · 선택 안 함' : '점수 선택 지우기'),
      ),
    ],
  );
}

/// A short, optional sequence. No default score and no automatic reward.
class SelfCareEntryScreen extends StatefulWidget {
  final String? initialCatId;
  final CareAction? initialAction;
  const SelfCareEntryScreen({super.key, this.initialCatId, this.initialAction});
  @override
  State<SelfCareEntryScreen> createState() => _SelfCareEntryScreenState();
}

class _SelfCareEntryScreenState extends State<SelfCareEntryScreen> {
  final _reflection = TextEditingController();
  final _plan = TextEditingController();
  final _scroll = ScrollController();
  final _createdAt = DateTime.now();
  late final String _id;
  late String? _catId;
  late CareAction? _action;
  int? _comfort;
  int _step = 0;
  int _prompt = 0;
  bool _saving = false;
  bool _saved = false;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _id =
        '${_createdAt.microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}';
    _catId = widget.initialCatId;
    _action = widget.initialAction;
    if (_action != null) _step = 2;
  }

  @override
  void dispose() {
    _reflection.dispose();
    _plan.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _comfort != null ||
      _catId != null ||
      _reflection.text.trim().isNotEmpty ||
      _action != null ||
      _plan.text.trim().isNotEmpty;

  Future<void> _leave() async {
    if (_saving) return;
    if (_hasContent && !_saved) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('작성 중인 기록을 닫을까요?'),
          content: const Text('아직 저장하지 않은 내용은 사라져요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('계속 쓰기'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, _saved);
    });
  }

  void _move(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_hasContent) {
      await _leave();
      return;
    }
    setState(() => _saving = true);
    try {
      await SelfCareStore.instance.save(
        SelfCareEntry(
          id: _id,
          createdAt: _createdAt,
          comfort: _comfort,
          catId: _catId,
          promptIndex: _prompt,
          reflection: _reflection.text.trim(),
          action: _action,
          plan: _plan.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _action == null
                ? '내 마음을 저장했어요.'
                : '저장했어요. 해본 뒤 기록에서 도움 여부를 남겨 주세요.',
          ),
        ),
      );
      await _leave();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장하지 못했어요. 내용은 그대로 있으니 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('내 마음 돌보기'),
        leading: IconButton(
          onPressed: _saving ? null : _leave,
          icon: const Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${_step + 1} / 3 · ${['마음 알아차리기', '잠깐 돌아보기', '작은 돌봄 고르기'][_step]}',
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                if (_step == 0) ...[
                  ComfortPicker(
                    value: _comfort,
                    onChanged: (v) => setState(() => _comfort = v),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _catId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '이름 붙이고 싶은 감정 · 선택',
                    ),
                    items: [
                      for (final cat in shadowCats)
                        DropdownMenuItem(
                          value: cat.id,
                          child: Text('${cat.emoji} ${cat.keyword}'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _catId = v),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _catId = null),
                    child: const Text('감정 이름은 나중에 정할래요'),
                  ),
                ],
                if (_step == 1) ...[
                  const Text('답할 수 있는 질문 하나만 골라요.'),
                  const SizedBox(height: 12),
                  for (var i = 0; i < reflectionPrompts.length; i++)
                    RadioListTile<int>(
                      value: i,
                      groupValue: _prompt,
                      title: Text(reflectionPrompts[i]),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setState(() => _prompt = v!),
                    ),
                  TextField(
                    controller: _reflection,
                    minLines: 3,
                    maxLines: 7,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: '한 줄도 괜찮아요. 잘 모르겠다면 비워 두세요.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('아직 이유를 설명하거나 감정을 바꾸지 않아도 괜찮아요.'),
                ],
                if (_step == 2) ...[
                  const Text('지금 해보고 싶은 게 있나요?\n고르는 것만으로 완료 처리되지는 않아요.'),
                  const SizedBox(height: 12),
                  for (final action in CareAction.values)
                    RadioListTile<CareAction>(
                      value: action,
                      groupValue: _action,
                      title: Text(action.label),
                      subtitle: Text(action.guide),
                      contentPadding: EdgeInsets.zero,
                      onChanged: _saving
                          ? null
                          : (v) => setState(() => _action = v),
                    ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _action = null),
                    child: const Text('오늘은 기록만 남길래요'),
                  ),
                  TextField(
                    controller: _plan,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 4,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: '나에게 남길 한 줄 · 선택',
                      hintText: '예: 퇴근 뒤 5분 쉬어보기',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이 기록은 내 기기에 저장되고 기존 암호화 백업에 포함돼요.\n기관이나 이웃에게 자동으로 공유되지 않아요.',
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () => _step < 2 ? _move(_step + 1) : _save(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _saving
                          ? '저장 중…'
                          : _step < 2
                          ? '다음 · 비워 두어도 괜찮아요'
                          : '내 기록 저장',
                    ),
                  ),
                ),
                if (_step > 0)
                  TextButton(
                    onPressed: _saving ? null : () => _move(_step - 1),
                    child: const Text('이전'),
                  ),
                TextButton.icon(
                  onPressed: _saving
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CareConnectionScreen(),
                          ),
                        ),
                  icon: const Icon(Icons.support_agent),
                  label: const Text('누군가의 도움이 필요해요'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// No assumed improvement and no feedback sent to analytics/providers.
class CareFeedbackScreen extends StatefulWidget {
  final SelfCareEntry entry;
  const CareFeedbackScreen({super.key, required this.entry});
  @override
  State<CareFeedbackScreen> createState() => _CareFeedbackScreenState();
}

class _CareFeedbackScreenState extends State<CareFeedbackScreen> {
  late CareFeedback? _feedback;
  late int? _comfort;
  bool _busy = false, _allowPop = false, _confirming = false;
  bool get _changed =>
      _feedback != widget.entry.feedback ||
      _comfort != widget.entry.afterComfort;

  Future<void> _leave({bool saved = false}) async {
    if (_busy || _confirming || _allowPop) return;
    if (!saved && _changed) {
      _confirming = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('작성 중인 후기를 닫을까요?'),
          content: const Text('변경한 후기는 아직 저장되지 않았어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('계속 쓰기'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
      _confirming = false;
      if (discard != true) return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, saved);
    });
  }

  @override
  void initState() {
    super.initState();
    _feedback = widget.entry.feedback;
    _comfort = widget.entry.afterComfort;
  }

  Future<void> _save() async {
    if (_busy || _feedback == null) return;
    setState(() => _busy = true);
    try {
      await SelfCareStore.instance.review(
        widget.entry.id,
        _feedback!,
        _comfort,
      );
      if (mounted) {
        setState(() => _busy = false);
        await _leave(saved: true);
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('해본 뒤 돌아보기'),
        leading: BackButton(onPressed: _busy ? null : _leave),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.entry.action!.label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '직접 해보았다면 어땠는지 남겨 주세요.\n점수가 오르지 않아도 괜찮아요. 아직 안 했다면 나중에 돌아와도 돼요.',
                ),
                for (final feedback in CareFeedback.values)
                  RadioListTile<CareFeedback>(
                    value: feedback,
                    groupValue: _feedback,
                    title: Text(feedback.label),
                    contentPadding: EdgeInsets.zero,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _feedback = v),
                  ),
                if (_feedback == CareFeedback.uncomfortable)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('이 방법을 계속하지 않아도 괜찮아요. 다음에는 다른 돌봄을 선택할 수 있어요.'),
                  ),
                const SizedBox(height: 20),
                IgnorePointer(
                  ignoring: _busy,
                  child: ComfortPicker(
                    value: _comfort,
                    label: '지금의 편안함도 남길까요? · 선택',
                    onChanged: (v) => setState(() => _comfort = v),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy || _feedback == null ? null : _save,
                  child: Text(_busy ? '저장 중…' : '후기 저장'),
                ),
                TextButton(
                  onPressed: _busy ? null : _leave,
                  child: const Text('다음에 남길래요'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
