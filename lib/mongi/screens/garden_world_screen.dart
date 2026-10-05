import '../widgets/companion_name_editor.dart';
import '../../providers/cat_care_provider.dart';
import '../integration/garden_bloom_sync.dart';
import 'package:flutter/material.dart';
import '../services/sound_manager.dart';
import '../../services/sound_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/storage_service.dart';
import '../../utils/garden_record_progress.dart';
import '../integration/cheer_flower_store.dart';
import '../widgets/garden_keepsake_sheets.dart';
import 'package:provider/provider.dart';
import '../providers/garden_provider.dart';
import '../models/garden_layout.dart';
import '../models/seed.dart';
import '../models/garden_decoration.dart';
import '../integration/garden_layout_store.dart';
import '../integration/mongi_garden_store.dart';
import '../integration/plant_memory_store.dart';
import '../integration/plant_memory_editor.dart';
import '../widgets/garden_world_view.dart';
import '../widgets/living_garden_scene.dart';
import '../widgets/garden_decoration_sheet.dart';

class GardenWorldScreen extends StatefulWidget {
  final bool showRecordNote;
  final VoidCallback? onOpenCollection;
  const GardenWorldScreen({
    super.key,
    this.onOpenCollection,
    this.showRecordNote = false,
  });
  @override
  State<GardenWorldScreen> createState() => _GardenWorldScreenState();
}

class _GardenWorldScreenState extends State<GardenWorldScreen>
    with WidgetsBindingObserver {
  bool _ownsRestAudio = false, _foreground = true, _disposed = false;
  Future<void> _audioQueue = Future.value();
  void _restAudio(bool requested) {
    _audioQueue = _audioQueue
        .then((_) async {
          final sound = SoundManager.instance;
          final start =
              requested &&
              _quiet &&
              _foreground &&
              !_disposed &&
              !SoundService().narrationPlaying &&
              SoundService().bgmEnabled;
          if (start && !sound.ambientNaturePlaying) {
            await sound.startAmbientNature();
            _ownsRestAudio = sound.ambientNaturePlaying;
          } else if (!start && _ownsRestAudio) {
            await sound.stopAmbientNature();
            _ownsRestAudio = false;
          }
        })
        .catchError((Object _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _restAudio(_quiet);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _restAudio(false);
    super.dispose();
  }

  bool _loading = true, _quiet = false, _recordNoteShown = false;
  String? _error;
  final _layout = GardenLayoutStore.instance;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<GardenProvider>().ensureInitialized();
      await MongiGardenStore.instance.reload();
      await MongiGardenStore.instance.reconcileRecordedDays();
      await _layout.reload();
      await CheerFlowerStore.instance.reload();
      final owner = currentGardenOwner();
      if (owner != null) await GardenBloomSync.flush(owner);
      // A network failure must not prevent opening the local garden.
      try {
        if (mounted) await context.read<GardenProvider>().loadMyPublicCheers();
      } catch (_) {}
      StorageService.getAllLetters();
      await _grow();
    } catch (_) {
      _error = '정원 배치를 불러오지 못했어요. 기록은 그대로 보관하고 있어요.';
    }
    if (mounted) {
      setState(() => _loading = false);
      if (_error == null && widget.showRecordNote && !_recordNoteShown) {
        _recordNoteShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('기억의 나무에 함께한 시간이 남아 있어요. 편지는 나만 볼 수 있어요.'),
              duration: const Duration(seconds: 7),
              action: SnackBarAction(
                label: '기록 보기',
                onPressed: () => showMemoryTree(context),
              ),
            ),
          );
        });
      }
    }
  }

  Future<void> _grow() async {
    if (!mounted) return;
    final count = context.read<GardenProvider>().seedCounts.values.fold<int>(
      0,
      (a, b) => a + b,
    );
    if (GardenLayout.earnedSpaces(count) > _layout.value.spaces) {
      await _layout.update((layout) => layout.grow(count));
    }
  }

  Future<void> _memory(SeedType seed) async {
    try {
      await PlantMemoryStore.instance.reload();
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => PlantMemoryEditor(plant: seed),
        );
      }
    } catch (_) {
      if (mounted) _message('추억을 불러오지 못했어요. 다시 시도해 주세요.');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _plant() async {
    final store = MongiGardenStore.instance;
    bool busy = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '마음을 심고 가꾸기 · 씨앗 ${store.value.seedTokens}개',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('처음 심으면 식물이 생기고, 같은 씨앗을 다시 심으면 그 식물이 자라요.'),
                  if (store.value.seedTokens == 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('씨앗이 아직 없어요. 기존 돌봄·기록 보상이나 달리기에서 모을 수 있어요.'),
                    ),
                  for (final seed in SeedType.all)
                    ListTile(
                      leading: SizedBox(
                        width: 48,
                        height: 48,
                        child: GardenPlantArt(seed: seed, count: 1),
                      ),
                      title: Text(seed.label),
                      subtitle: Text(seed.description),
                      trailing: const Icon(Icons.add_circle_outline),
                      enabled: !busy && store.value.seedTokens > 0,
                      onTap: busy || store.value.seedTokens == 0
                          ? null
                          : () async {
                              update(() => busy = true);
                              try {
                                await store.plant(seed.id);
                                await _grow();
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } catch (_) {
                                if (sheetContext.mounted) {
                                  update(() => busy = false);
                                }
                                if (mounted) {
                                  _message(
                                    '심기를 완료하지 못했어요. 정원을 확인한 뒤 다시 시도해 주세요.',
                                  );
                                }
                              }
                            },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final companionName = context.watch<CatCareProvider>().displayName;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9ED),
      appBar: _quiet
          ? null
          : AppBar(
              title: const Text('나의 넓은 정원'),
              backgroundColor: const Color(0xFFFFF9ED),
              actions: [
                IconButton(
                  tooltip: '고양이 이름 변경',
                  onPressed: () => editCompanionName(context),
                  icon: const Icon(Icons.edit_outlined),
                ),
                if (widget.onOpenCollection != null)
                  IconButton(
                    tooltip: '고양이와 정원 기록',
                    onPressed: widget.onOpenCollection,
                    icon: const Icon(Icons.menu_book_outlined),
                  ),
              ],
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('다시 불러오기')),
                  ],
                ),
              ),
            )
          : AnimatedBuilder(
              animation: Listenable.merge([
                _layout,
                MongiGardenStore.instance,
                CheerFlowerStore.instance,
                StorageService.letterBox.listenable(),
              ]),
              builder: (context, _) => GardenWorldView(
                companionName: companionName,
                flowerKinds: CheerFlowerStore.instance
                    .forOwner(currentGardenOwner())
                    .where((f) => f.planted)
                    .map((f) => f.flowerKind)
                    .toList(),
                reactions: CheerFlowerStore.instance
                    .forOwner(currentGardenOwner())
                    .map((f) => f.reaction)
                    .nonNulls
                    .toList(),
                memoryDays: gardenRecordDays(
                  MongiGardenStore.instance.value.recordDays,
                  StorageService.getAllLetters().map((entry) => entry.date),
                  now: DateTime.now(),
                ).length,
                cheerFlowers: CheerFlowerStore.instance
                    .forOwner(currentGardenOwner())
                    .where((f) => f.planted)
                    .length,
                onMemoryTree: () => showMemoryTree(context),
                onCheerFlowers: () => showCheerFlowers(context),
                onQuietChanged: (quiet) {
                  setState(() => _quiet = quiet);
                  _restAudio(quiet);
                },
                motionEnabled: garden.gardenMotionEnabled,
                layout: _layout.value,
                seeds: garden.seedCounts,
                decorations: garden.equippedDecorationIds,
                onMemory: _memory,
                onPlant: _plant,
                onDecorate: () => showGardenDecorationSheet(context),
                onMove: (id, point) async {
                  final current = context.read<GardenProvider>();
                  final visible = [
                    ...SeedType.all
                        .where((s) => (current.seedCounts[s.id] ?? 0) > 0)
                        .map((s) => 'seed:${s.id}'),
                    ...GardenDecoration.all
                        .where(
                          (d) => current.equippedDecorationIds.contains(d.id),
                        )
                        .map((d) => 'decor:${d.id}'),
                  ];
                  await _layout.update(
                    (latest) => latest.move(id, point, visible),
                  );
                },
              ),
            ),
    );
  }
}
