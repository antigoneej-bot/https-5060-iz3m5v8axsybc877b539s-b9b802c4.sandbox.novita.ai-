import 'package:flutter/material.dart';
import '../models/meditation_check_in_record.dart';
import '../services/meditation_completion_service.dart';
import '../services/meditation_library_store.dart';
import '../theme.dart';
import '../screens/self_care_entry_screen.dart';

/// Also shown at the library entrance so recovery is discoverable after restart.
class MeditationCompletionNotice extends StatelessWidget {
  const MeditationCompletionNotice({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: MeditationCompletionService.instance.saveState,
    builder: (context, state, _) {
      if (state == MeditationSaveState.idle) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(switch (state) {
              MeditationSaveState.saving => '명상 완료와 정원 성장을 저장하고 있어요.',
              MeditationSaveState.unsaved =>
                '명상 완료를 아직 기기에 저장하지 못했어요. 앱을 닫기 전에 다시 시도해 주세요.',
              _ => '명상 완료 기록을 확인하거나 과정·정원에 반영하지 못했어요. 다시 시도하면 이어서 저장해요.',
            }),
            if (state != MeditationSaveState.saving)
              TextButton.icon(
                onPressed: () => MeditationCompletionService.instance.retry(),
                icon: const Icon(Icons.refresh),
                label: const Text('완료 기록 다시 저장'),
              ),
          ],
        ),
      );
    },
  );
}

class MeditationCheckIn extends StatelessWidget {
  final String guideKey;
  const MeditationCheckIn({super.key, required this.guideKey});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: MeditationCompletionService.instance.completed,
    builder: (context, event, _) {
      if (event == null || event.key != guideKey)
        return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MeditationCompletionNotice(),
          _SessionCheckIn(
            key: ValueKey(event.session),
            session: event.session,
            guideKey: event.key,
          ),
        ],
      );
    },
  );
}

class _SessionCheckIn extends StatefulWidget {
  final String session, guideKey;
  const _SessionCheckIn({
    super.key,
    required this.session,
    required this.guideKey,
  });
  @override
  State<_SessionCheckIn> createState() => _SessionCheckInState();
}

class _SessionCheckInState extends State<_SessionCheckIn> {
  final _store = MeditationLibraryStore.instance;
  MeditationCheckInRecord? _record;
  bool _loading = true, _busy = false;
  String? _error;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _store.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _store.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    try {
      final record = await _store.findCheckIn(widget.session);
      if (!mounted || generation != _generation) return;
      setState(() {
        _record = record;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = '이전에 남긴 후기를 확인하지 못했어요. 다시 불러와 주세요.';
      });
    }
  }

  Future<void> _save(String feeling) async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      // The persisted value wins if another view already saved this session.
      final saved = await _store.checkIn(
        widget.session,
        widget.guideKey,
        feeling,
      );
      if (mounted)
        setState(() {
          _record = saved;
          _error = null;
        });
    } catch (_) {
      if (mounted) setState(() => _error = '후기를 저장하지 못했어요. 다시 불러온 뒤 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('남긴 후기를 확인하고 있어요.'),
      );
    if (_error != null)
      return Column(
        children: [
          Text(_error!),
          TextButton(
            onPressed: _busy ? null : _reload,
            child: const Text('후기 다시 불러오기'),
          ),
        ],
      );
    final record = _record;
    if (record != null)
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 명상에 남긴 마음: ${const {'better': '조금 편안해졌어요', 'same': '비슷해요', 'worse': '더 불편해요'}[record.feeling]}',
            ),
            const SizedBox(height: 8),
            Text(
              record.feeling == 'worse'
                  ? '여기서 마쳐도 괜찮아요. 지금 필요한 돌봄을 직접 골라볼 수 있어요.'
                  : '원한다면 오늘의 작은 돌봄도 골라보세요.',
            ),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SelfCareEntryScreen()),
              ),
              icon: const Icon(Icons.spa_outlined),
              label: const Text('내 마음 돌아보고 돌봄 고르기'),
            ),
          ],
        ),
      );
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blobLavender,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '잠깐 쉬고 난 지금은 어떤가요?',
            style: bodyFont(
              fontSize: 14,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text('선택하지 않아도 괜찮아요. 느낀 상태는 완료 보상에 영향을 주지 않아요.'),
          Wrap(
            spacing: 6,
            children: [
              for (final entry in const {
                'better': '조금 편안해졌어요',
                'same': '비슷해요',
                'worse': '더 불편해요',
              }.entries)
                ActionChip(
                  label: Text(entry.value),
                  onPressed: _busy ? null : () => _save(entry.key),
                ),
            ],
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    if (MeditationCompletionService
                            .instance
                            .completed
                            .value
                            ?.session ==
                        widget.session)
                      MeditationCompletionService.instance.completed.value =
                          null;
                  },
            child: const Text('건너뛰기'),
          ),
        ],
      ),
    );
  }
}
