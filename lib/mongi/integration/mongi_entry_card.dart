import '../../theme.dart';
import 'mongi_experience.dart';
import 'package:flutter/material.dart';
import '../../screens/my_garden_screen.dart';
import '../../widgets/feature_scaffold.dart';
import '../models/emotion.dart';
import 'mongi_garden_store.dart';
import 'mongi_play_screen.dart';

class MongiEntryCard extends StatelessWidget {
  final VoidCallback onGoMeetCat;
  const MongiEntryCard({super.key, required this.onGoMeetCat});
  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.catSageBg,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MongiExperience())),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 64, height: 72,
            decoration: BoxDecoration(color: AppColors.cardFace, borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.all(8),
            child: Image.asset('assets/mongi/images/cat_happy.png', fit: BoxFit.contain)),
          const SizedBox(width: 14),
          Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('몽이랑 달리기', style: titleFont(fontSize: 25, color: AppColors.titlePastelGreen)),
            const SizedBox(height: 4),
            Text('마음을 만나고, 함께 정원을 가꿔요.', style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, color: AppColors.titlePastelGreen, size: 20),
        ]),
      ),
    ),
  );
}

class MongiLobbyScreen extends StatefulWidget {
  final VoidCallback onGoMeetCat;
  const MongiLobbyScreen({super.key, required this.onGoMeetCat});
  @override
  State<MongiLobbyScreen> createState() => _MongiLobbyScreenState();
}

class _MongiLobbyScreenState extends State<MongiLobbyScreen> {
  final _selected = <EmotionType>{};
  bool _loading = true;
  bool _starting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await MongiGardenStore.instance.reload();
      await MongiGardenStore.instance.claimTodayRecord();
    } catch (_) {
      _error = '정원 기록을 불러오지 못했어요. 다시 시도해 주세요.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _meetCat() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onGoMeetCat();
  }

  Future<void> _start() async {
    if (_starting || _selected.isEmpty) return;
    setState(() => _starting = true);
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MongiPlayScreen(
          emotions: Emotion.all
              .where((e) => _selected.contains(e.type))
              .toList(),
          stage: MongiGardenStore.instance.value.stage,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _starting = false);
    pushFullScreen(context, '나의 정원', MyGardenScreen(onGoMeetCat: _meetCat));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('몽이랑 달리기')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('다시 불러오기')),
              ],
            ),
          )
        : ValueListenableBuilder<MongiGardenData>(
            valueListenable: MongiGardenStore.instance,
            builder: (context, data, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '스테이지 ${data.stage}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  '무거운 마음은 몽이가 냠냠 먹으며 함께 소화하고, 따뜻한 마음은 가슴으로 받아요.\n지금 만날 감정을 1~3개 골라 주세요.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Emotion.all
                      .map(
                        (emotion) => FilterChip(
                          label: Text(emotion.label),
                          selected: _selected.contains(emotion.type),
                          onSelected: (selected) => setState(() {
                            if (!selected) {
                              _selected.remove(emotion.type);
                            } else if (_selected.length < 3) {
                              _selected.add(emotion.type);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  '어떤 감정이든 느껴도 괜찮아요. 몽이와 잠깐 산책해요.\n주먹과 점프로 장애물을 피하세요.\n클리어하면 씨앗 1개와 빛의 정수 30개를 받아요.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _selected.isEmpty || _starting ? null : _start,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('달리기 시작'),
                ),
                const SizedBox(height: 16),
                Text('심을 씨앗 ${data.seedTokens}개 · 빛의 정수 ${data.essence}개'),
                OutlinedButton.icon(
                  onPressed: () => pushFullScreen(
                    context,
                    '나의 정원',
                    MyGardenScreen(onGoMeetCat: _meetCat),
                  ),
                  icon: const Icon(Icons.local_florist),
                  label: const Text('우리 정원에 심고 꾸미기'),
                ),
              ],
            ),
          ),
  );
}
