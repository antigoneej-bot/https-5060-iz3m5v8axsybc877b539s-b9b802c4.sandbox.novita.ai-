import '../services/meditation_audio_service.dart';
import 'package:flutter/material.dart';
import '../services/meditation_course_store.dart';
import '../services/media_coordinator.dart';
import '../data/solutions_data.dart';
import '../theme.dart';
import 'guide_steps.dart';

class MeditationCoursesCard extends StatefulWidget {
  const MeditationCoursesCard({super.key});
  @override
  State<MeditationCoursesCard> createState() => _MeditationCoursesCardState();
}

class _MeditationCoursesCardState extends State<MeditationCoursesCard> {
  final store = MeditationCourseStore.instance;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await store.load();
      await store.retry();
    } catch (_) {
      if (mounted) setState(() => _error = '과정 기록을 불러오지 못했어요.');
    }
  }

  Future<void> _open(MeditationCourse c) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await MediaCoordinator.instance.stopAll();
      await MeditationAudioService.instance.stopForNewSession();
      await store.activate(c.id);
      final index = store.step(c);
      if (!mounted || index >= c.guides.length) return;
      final key = c.guides[index];
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('${c.title} · ${index + 1}번째')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text('끝까지 재생하면 오늘의 한 걸음이 남아요. 하루 빠져도 이어서 할 수 있어요.'),
                  GuideSteps(guide: breathingGuide[key]!, guideKey: key),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('과정을 열지 못했어요. 진행 기록은 유지돼요.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blobLavender,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          '내 속도로 이어가는 명상',
          style: bodyFont(
            fontSize: 16,
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '두 가지 과정 · 하루에 한 걸음',
          style: bodyFont(fontSize: 13, color: AppColors.lavenderInk),
        ),
        children: [
          if (_error != null) Text(_error!),
          for (final c in meditationCourses) _course(c),
        ],
      ),
    ),
  );
  Widget _course(MeditationCourse c) {
    final progress = store.step(c);
    final complete = progress >= c.guides.length;
    final today = store.doneToday(c);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.catLavenderBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  c.id == 'first7'
                      ? Icons.spa_outlined
                      : Icons.bedtime_outlined,
                  color: AppColors.lavenderInk,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: bodyFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.description,
                      style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Semantics(
            label: '${c.title} $progress / ${c.guides.length}회 완료',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / c.guides.length,
                minHeight: 6,
                color: AppColors.lavenderInk,
                backgroundColor: AppColors.blobLavender,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$progress / ${c.guides.length}회 완료',
            style: bodyFont(fontSize: 12, color: AppColors.lavenderInk),
          ),
          const SizedBox(height: 8),
          if (complete || today)
            Text(
              complete ? '모두 마쳤어요 · 나를 돌본 시간이에요' : '오늘은 마쳤어요 · 내일 이어가요',
              style: bodyFont(fontSize: 13, color: AppColors.titlePastelGreen),
            )
          else
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _open(c),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(progress == 0 ? '시작' : '이어하기'),
            ),
        ],
      ),
    );
  }
}
