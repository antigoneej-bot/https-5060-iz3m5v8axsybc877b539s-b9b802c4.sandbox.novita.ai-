import '../../theme.dart';
import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../screens/premium_screen.dart';
import 'garden_story_catalog.dart';
import 'mongi_garden_store.dart';

class GardenStoriesScreen extends StatefulWidget {
  const GardenStoriesScreen({super.key});
  @override
  State<GardenStoriesScreen> createState() => _GardenStoriesScreenState();
}

class _GardenStoriesScreenState extends State<GardenStoriesScreen> {
  bool _loading = true, _premium = false, _busy = false;
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
      _premium = await SubscriptionService().isPremium();
    } catch (_) {
      _error = '이야기를 불러오지 못했어요.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _open(GardenStoryPack pack, int chapter) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await MongiGardenStore.instance.openStoryChapter(pack, chapter);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(pack.title)),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pack.chapters[chapter].title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  SelectableText(
                    pack.chapters[chapter].body,
                    style: bodyFont(
                      fontSize: 17,
                      height: 1.9,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이야기를 열지 못했어요. 구독과 기록 일수를 확인해 주세요.')),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('몽이의 정원 이야기')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: TextButton(onPressed: _load, child: Text('$_error 다시 시도')),
          )
        : ValueListenableBuilder<MongiGardenData>(
            valueListenable: MongiGardenStore.instance,
            builder: (context, data, _) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '정원에서 이어지는 짧은 고양이 이야기.\n첫 장은 누구나 읽을 수 있어요. 구독자는 공개 이후 기록한 날이 3일·5일 쌓이면 다음 장을 만나요. 연속 기록일 필요는 없어요.',
                ),
                if (!_premium)
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PremiumScreen(),
                        ),
                      );
                      if (mounted) _load();
                    },
                    child: const Text('구독 혜택 보기'),
                  ),
                if (_busy) const LinearProgressIndicator(),
                ...gardenStories.map((pack) {
                  final released = pack.released(DateTime.now());
                  return Card(
                    color: AppColors.catSageBg,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${pack.month} · ${pack.title}',
                            style: titleFont(
                              fontSize: 24,
                              color: AppColors.titlePastelGreen,
                            ),
                          ),
                          if (!released)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('공개 예정'),
                            ),
                          if (released)
                            ...List.generate(pack.chapters.length, (index) {
                              final canOpen = pack.canOpen(
                                data,
                                index,
                                _premium,
                                DateTime.now(),
                              );
                              final alreadyRead =
                                  (data.storyProgress[pack.month] ?? 0) > index;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${index + 1}장 · ${pack.chapters[index].title}',
                                ),
                                subtitle: Text(
                                  alreadyRead
                                      ? '다시 읽기'
                                      : index == 0
                                      ? '무료로 읽기'
                                      : '구독 · 기록 ${pack.requiredDays(index)}일 · 앞 장 읽기',
                                ),
                                trailing: Icon(
                                  canOpen
                                      ? Icons.menu_book
                                      : Icons.lock_outline,
                                ),
                                enabled: canOpen && !_busy,
                                onTap: canOpen && !_busy
                                    ? () => _open(pack, index)
                                    : null,
                              );
                            }),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text('열어 본 장은 구독이 끝나도 다시 읽을 수 있어요.'),
              ],
            ),
          ),
  );
}
