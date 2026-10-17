import 'package:flutter/material.dart';
import '../data/solutions_data.dart';
import '../services/meditation_library_store.dart';
import '../services/meditation_recap_service.dart';
import '../theme.dart';
import 'guide_steps.dart';

/// Available even without a letter this week. Opening a guide never starts its
/// media automatically; the existing guide keeps its subscription and player
/// controls. Individual check-ins are not added to shareable reflection cards.
class MeditationRecapCard extends StatefulWidget {
  final MeditationLibraryStore? store;
  final DateTime? now;
  final ValueChanged<String>? onOpenGuide;
  const MeditationRecapCard({
    super.key,
    this.store,
    this.now,
    this.onOpenGuide,
  });

  @override
  State<MeditationRecapCard> createState() => _MeditationRecapCardState();
}

class _MeditationRecapCardState extends State<MeditationRecapCard> {
  late final MeditationLibraryStore _store =
      widget.store ?? MeditationLibraryStore.instance;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _store.load();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _openGuide(String key) {
    if (widget.onOpenGuide != null) {
      widget.onOpenGuide!(key);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(breathingGuide[key]!.title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('지금 마음이 내킬 때 재생해 보세요. 중간에 쉬어도 괜찮아요.'),
                  const SizedBox(height: 14),
                  GuideSteps(guide: breathingGuide[key]!, guideKey: key),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPause() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '지금은 잠깐 쉬어도 괜찮아요',
              style: titleFont(fontSize: 20, color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            const Text(
              '눈을 편하게 뜨고, 주변에 보이는 사물 세 가지를 천천히 살펴보세요.\n\n편한 자세로 바꾸거나 물 한 모금을 마셔도 좋아요. 호흡을 바꾸려고 애쓰지 않아도 돼요.\n\n불편함이 이어지면 오늘 명상은 여기서 멈춰도 괜찮아요.',
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('내 속도로 쉴게요'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) {
      final recap = MeditationRecap.fromCheckIns(
        _store.checkIns,
        now: widget.now,
      );
      final preferred = recap.preferredGuide;
      final guideKey = preferred ?? 'forestRest';
      final guideTitle = breathingGuide[guideKey]!.title;
      final period =
          '${recap.from.month}.${recap.from.day}–${recap.through.month}.${recap.through.day}';
      return Container(
          key: const ValueKey('meditation-weekly-recap'),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.blobMint.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.sageLine.withValues(alpha: .6),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.blobMintAccent.withValues(alpha: 0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '이번 주 나를 도운 것',
                style: titleFont(
                  fontSize: 18,
                  color: AppColors.moon,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '명상 후 돌아보기 · 최근 7일 ($period)',
                style: pathLabelFont(fontSize: 12, color: AppColors.moon),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Text('돌아보기 기록을 불러오고 있어요.')
              else if (_failed) ...[
                const Text('명상 후 기록을 불러오지 못했어요.'),
                TextButton(
                  onPressed: () {
                    setState(() => _loading = true);
                    _load();
                  },
                  child: const Text('다시 불러오기'),
                ),
              ] else ...[
                if (recap.total == 0)
                  const Text(
                    '이번 주에는 명상 후 남긴 응답이 없어요. 짧게 쉬어 보고, 그 후의 느낌을 남겨도 좋아요.',
                  )
                else ...[
                  Text('${recap.recordedDays}일 동안 남긴 ${recap.total}개의 응답'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _count('편안해짐', recap.better),
                      _count('비슷함', recap.same),
                      _count('불편함', recap.worse),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '직접 선택한 응답만 모았어요. 응답하지 않은 날의 상태는 추정하지 않아요.',
                    style: pathLabelFont(fontSize: 12, color: AppColors.moon),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  recap.suggestPause
                      ? '가장 최근에는 불편하다고 남겼어요. 오늘은 명상을 이어가기보다 잠시 쉬어도 좋아요.'
                      : preferred != null
                      ? '최근에 ‘$guideTitle’ 후 편안해졌다고 남겼어요. 오늘도 마음이 내키면 다시 살펴볼까요?'
                      : '오늘의 작은 돌봄: 2분 숲 명상을 살펴보거나, 잠깐 쉬어가도 좋아요.',
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: recap.suggestPause
                        ? _openPause
                        : () => _openGuide(guideKey),
                    icon: Icon(
                      recap.suggestPause
                          ? Icons.visibility_outlined
                          : Icons.spa_outlined,
                      size: 18,
                    ),
                    label: Text(
                      recap.suggestPause
                          ? '주변 잠깐 살펴보기'
                          : preferred != null
                          ? '그 명상 다시 열기'
                          : '2분 숲 명상 살펴보기',
                      style: pathLabelFont(
                        fontSize: 13,
                        color: AppColors.titlePastelGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
      );
    },
  );

  Widget _count(String label, int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$label $count회',
      style: bodyFont(fontSize: 13, color: AppColors.ink),
    ),
  );
}
