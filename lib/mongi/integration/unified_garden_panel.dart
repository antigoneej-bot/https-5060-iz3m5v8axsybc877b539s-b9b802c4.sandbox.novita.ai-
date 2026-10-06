import 'garden_care_tree.dart';
import '../widgets/garden_tool_sheet.dart';
import 'garden_moments_card.dart';
import '../providers/garden_provider.dart';
import '../widgets/living_garden_entry.dart';
import '../widgets/garden_scene_view.dart';
import 'garden_postcard_screen.dart';
import 'garden_stories_screen.dart';
import 'plant_memory_store.dart';
import 'plant_memory_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/shadow_cats_data.dart';
import '../../providers/app_state_provider.dart';
import '../models/garden_decoration.dart';
import '../models/seed.dart';
import 'mongi_garden_store.dart';

/// The existing cat collection and runner rewards share this garden screen.
class UnifiedGardenPanel extends StatefulWidget {
  final String? section;
  const UnifiedGardenPanel({super.key, this.section});
  @override
  State<UnifiedGardenPanel> createState() => _UnifiedGardenPanelState();
}

class _UnifiedGardenPanelState extends State<UnifiedGardenPanel> {
  bool _loading = true, _busy = false;
  String? _error;
  final store = MongiGardenStore.instance;
  @override
  void initState() {
    super.initState();
    PlantMemoryStore.instance.addListener(_memoryChanged);
    _load();
  }

  void _memoryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PlantMemoryStore.instance.removeListener(_memoryChanged);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<GardenProvider>().ensureInitialized();
      await store.reload();
      await store.claimTodayRecord();
      await PlantMemoryStore.instance.reload();
    } catch (_) {
      _error = '정원 기록을 불러오지 못했어요.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError ? e.message : '정원을 저장하지 못했어요. 다시 시도해 주세요.',
            ),
          ),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final met = context.watch<AppStateProvider>().metCatIds;
    final cats = shadowCats.where((c) => met.contains(c.id)).toList();
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Column(
        children: [
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('다시 불러오기')),
        ],
      );
    }
    return ValueListenableBuilder<MongiGardenData>(
      valueListenable: store,
      builder: (context, data, _) {
        final section = widget.section;
        if (section != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy) const LinearProgressIndicator(),
              if (section == 'care') ...[
                Text('심을 씨앗 ${data.seedTokens}개 · 빛의 정수 ${data.essence}개'),
                const SizedBox(height: 12),

                const Text('씨앗 심기 · 같은 식물에 다시 심으면 자라요.'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SeedType.all
                      .map(
                        (seed) => OutlinedButton(
                          onPressed: _busy || data.seedTokens == 0
                              ? null
                              : () => _act(() => store.plant(seed.id)),
                          child: Text(
                            '${seed.growthStages.last} ${seed.label}',
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 16),
                GardenCareNote(data: data),
                const ExpansionTile(
                  title: Text('돌봄 나무와 장식 배치 보기'),
                  children: [GardenSceneView(height: 300)],
                ),
              ],
              if (section == 'decorate') ...[
                const Text('정원 꾸미기'),
                ...GardenDecoration.all.map((item) {
                  final owned = data.owned.contains(item.id),
                      placed = data.placed.contains(item.id);
                  return Card(
                    child: ListTile(
                      leading: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(item.label),
                      subtitle: Text(
                        owned
                            ? (placed ? '정원에 놓여 있어요' : '보관 중이에요')
                            : item.isPremium
                            ? '구독자 정원 선물 · 한 번 받으면 계속 소유해요'
                            : '빛의 정수 60개',
                      ),
                      trailing: TextButton(
                        onPressed: _busy
                            ? null
                            : () => _act(
                                () => owned
                                    ? store.toggle(item.id)
                                    : store.obtain(item),
                              ),
                        child: Text(
                          owned
                              ? (placed ? '보관' : '배치')
                              : item.isPremium
                              ? '선물 받기'
                              : '꾸미기',
                        ),
                      ),
                    ),
                  );
                }),
              ],
              if (section == 'memories') ...[
                if (!data.seeds.values.any((count) => count > 0))
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('씨앗을 심으면 이곳에서 이름과 추억을 남길 수 있어요.'),
                  ),
                for (final plant in SeedType.all)
                  if ((data.seeds[plant.id] ?? 0) > 0)
                    ListTile(
                      leading: Text(plant.emojiForCount(data.seeds[plant.id]!)),
                      title: Text(
                        PlantMemoryStore
                                    .instance
                                    .value[plant.id]
                                    ?.name
                                    .isNotEmpty ==
                                true
                            ? PlantMemoryStore.instance.value[plant.id]!.name
                            : plant.label,
                      ),
                      subtitle: const Text('이 식물에 이름과 추억 남기기'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => PlantMemoryEditor(plant: plant),
                      ),
                    ),
              ],
              if (section == 'records') ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GardenStoriesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('몽이의 정원 이야기'),
                ),
                GardenCareNote(data: data),
                GardenMomentsCard(data: data, catCount: cats.length),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GardenPostcardScreen(data: data, cats: cats),
                    ),
                  ),
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('정원 엽서 만들기'),
                ),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LivingGardenEntry(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _tool('돌보기', Icons.spa_outlined, 'care')),
                const SizedBox(width: 8),
                Expanded(child: _tool('꾸미기', Icons.yard_outlined, 'decorate')),
                const SizedBox(width: 8),
                Expanded(child: _tool('추억', Icons.bookmark_border, 'memories')),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.careDays.contains(MongiGardenData.dayKey(DateTime.now()))
                  ? '오늘도 정원에 마음 한 조각을 남겼어요 🌱'
                  : '잠시 머물러도 괜찮아요.',
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _tool(String label, IconData icon, String section) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    ),
    onPressed: () => showGardenToolSheet(
      context,
      title: label,
      builder: (_) => UnifiedGardenPanel(section: section),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}
