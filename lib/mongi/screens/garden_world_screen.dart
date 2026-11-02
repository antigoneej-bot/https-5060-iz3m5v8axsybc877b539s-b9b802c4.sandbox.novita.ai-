import '../widgets/resting_garden_view.dart';
import '../widgets/garden_cultivation_tools.dart';
import '../../utils/recent_garden_plants.dart';
import '../integration/session_transaction.dart';
import '../widgets/garden_plant_picker.dart';
import 'package:flutter/services.dart';
import '../../screens/orchard_screen.dart';
import '../../models/companion_coat.dart';
import '../../screens/companion_coat_screen.dart';
import 'dart:async';
import '../../widgets/companion_care_panel.dart';
import '../../models/companion_journey.dart';
import '../../services/garden_return_store.dart';
import '../widgets/garden_return_sheet.dart';

import 'garden_village_screen.dart';
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
import '../widgets/garden_decoration_sheet.dart';
import '../../theme.dart';

class GardenWorldScreen extends StatefulWidget {
  final bool showRecordNote;
  final bool initialLandscape;
  final bool initialResting;
  final bool cultivation, embedded;
  final VoidCallback? onOpenCollection;
  const GardenWorldScreen({
    super.key,
    this.onOpenCollection,
    this.showRecordNote = false,
    this.initialLandscape = false,
    this.initialResting = false,
    this.cultivation = true,
    this.embedded = false,
  });
  const GardenWorldScreen.owned({
    Key? key,
    VoidCallback? onOpenCollection,
    bool showRecordNote = false,
    bool initialLandscape = false,
    bool embedded = false,
  }) : this(
         key: key,
         onOpenCollection: onOpenCollection,
         showRecordNote: showRecordNote,
         initialLandscape: initialLandscape,
         cultivation: true,
         embedded: embedded,
       );

  const GardenWorldScreen.tools({Key? key})
    : this(key: key, cultivation: false);

  @override
  State<GardenWorldScreen> createState() => _GardenWorldScreenState();
}

class _GardenWorldScreenState extends State<GardenWorldScreen>
    with WidgetsBindingObserver {
  bool _cultivationActivated = false;
  late bool _restGarden = widget.initialResting;
  bool? _gardenNight;
  bool get _canChangeGarden =>
      !_plantSaving &&
      _pendingSeed == null &&
      !_focusWaterSaving &&
      !_commitNeedsRecovery;
  void _changeGarden(bool resting) {
    if (!_canChangeGarden) return;
    setState(() => _restGarden = resting);
    _restAudio(false);
  }

  bool get _cultivationEnabled => widget.cultivation || _cultivationActivated;
  bool _ownsRestAudio = false, _foreground = true, _disposed = false;
  bool _syncingFlowers = false;
  String? _syncOwner;
  int _syncRequest = 0;
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
    if (_foreground) {
      unawaited(_syncReceivedFlowers());
    } else {
      // A late response may update its owner's cache, but cannot start another
      // request or show a stale error after this foreground session ends.
      _syncRequest++;
      _syncingFlowers = false;
      _syncOwner = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    if (_landscapeRequested || _portraitRequested)
      unawaited(
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      );
    _syncRequest++;
    WidgetsBinding.instance.removeObserver(this);
    _restAudio(false);
    super.dispose();
  }

  bool _landscapeRequested = false;
  bool _portraitRequested = false;
  Future<void> _portraitGarden() async {
    setState(() {
      _landscapeRequested = false;
      _portraitRequested = true;
    });
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _setLandscape(bool enabled) async {
    setState(() {
      _landscapeRequested = enabled;
      _portraitRequested = false;
      if (enabled) _expandedGarden = true;
      if (!_restGarden) {
        _cultOverview = enabled;
        _focusedPlantId = null;
      }
    });
    try {
      await SystemChrome.setPreferredOrientations(
        enabled
            ? [
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]
            : [DeviceOrientation.portraitUp],
      );
    } catch (_) {
      if (mounted) {
        setState(() => _landscapeRequested = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('휴대폰의 자동 회전을 켜고 가로로 돌려 주세요.')),
        );
      }
    }
  }

  Widget _rotationButton() => IconButton(
    key: const Key('garden-landscape'),
    tooltip: _landscapeRequested ? '자동 회전으로 돌아가기' : '가로 전체보기',
    onPressed: _openFullGarden,
    icon: Icon(
      _landscapeRequested
          ? Icons.screen_lock_landscape
          : Icons.screen_rotation_outlined,
    ),
  );
  bool _expandedGarden = true;
  bool _loading = true, _quiet = false, _recordNoteShown = false;
  String? _error;
  GardenReturnSummary? _returnSummary;
  String? _returnOwner;
  final _layout = GardenLayoutStore.instance;
  @override
  void initState() {
    super.initState();
    if (widget.initialLandscape) unawaited(_setLandscape(true));
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
      if (!mounted) return;
      await context.read<CatCareProvider>().loadJourney();
      await MongiGardenStore.instance.reload();
      await MongiGardenStore.instance.reconcileRecordedDays();
      await _layout.reload();
      await CheerFlowerStore.instance.reload();
      StorageService.getAllLetters();
      await _grow();
      // Local visit markers never delay opening or become a garden error.
      try {
        if (!mounted) return;
        final owner =
            context.read<GardenProvider>().publicGardenAccount ?? 'guest';
        final data = MongiGardenStore.instance.value;
        final summary = await GardenReturnStore.instance.recordVisit(
          owner,
          seeds: data.seeds,
          recordDays: gardenRecordDays(
            data.recordDays,
            StorageService.getAllLetters().map((entry) => entry.date),
            now: DateTime.now(),
          ).length,
        );
        await GardenReturnStore.instance.reload(owner);
        if (mounted &&
            (context.read<GardenProvider>().publicGardenAccount ?? 'guest') ==
                owner) {
          _returnSummary = summary;
          _returnOwner = owner;
        }
      } catch (_) {}
    } catch (_) {
      _error = '정원 배치를 불러오지 못했어요. 기록은 그대로 보관하고 있어요.';
    }
    if (mounted) {
      setState(() => _loading = false);
      // Open the saved personal garden before waiting for any network work.
      // A slow server must not turn an offline garden into a loading screen.
      if (_error == null) unawaited(_syncReceivedFlowers());
      if (_error == null && widget.showRecordNote && !_recordNoteShown) {
        _recordNoteShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('함께한 기록을 간직했어요. 기억의 나무에서는 나만의 씨앗을 심을 수 있어요.'),
              duration: const Duration(seconds: 7),
              action: SnackBarAction(
                label: '씨앗 심기',
                onPressed: () => showMemoryTree(context),
              ),
            ),
          );
        });
      }
    }
  }

  Future<void> _syncReceivedFlowers() async {
    if (!mounted || !_foreground || _loading || _error != null) return;
    final garden = context.read<GardenProvider>();
    final owner = garden.publicGardenAccount;
    if (owner == null || (_syncingFlowers && _syncOwner == owner)) return;
    final request = ++_syncRequest;
    _syncingFlowers = true;
    _syncOwner = owner;
    bool current() =>
        mounted &&
        !_disposed &&
        _foreground &&
        request == _syncRequest &&
        garden.publicGardenAccount == owner;
    try {
      // Preserve legacy planting receipt ordering. Both these services also
      // bind network writes/results to the signed-in owner themselves.
      await GardenBloomSync.flush(owner);
      if (!current()) return;
      await garden.loadMyPublicCheers();
    } catch (_) {
      if (current()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('내 정원은 사용할 수 있어요. 새로 받은 마음은 연결 후 다시 확인해 주세요.'),
            duration: const Duration(seconds: 7),
            action: SnackBarAction(
              label: '다시 확인',
              onPressed: () {
                if (current()) unawaited(_syncReceivedFlowers());
              },
            ),
          ),
        );
      }
    } finally {
      if (request == _syncRequest) {
        _syncingFlowers = false;
        _syncOwner = null;
      }
    }
  }

  Future<void> _grow() async {
    if (!mounted) return;
    final count = MongiGardenStore.instance.value.seeds.values.fold<int>(
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
        await _grow();
      }
    } catch (_) {
      if (mounted) _message('추억을 불러오지 못했어요. 다시 시도해 주세요.');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  String? _focusedPlantId;
  bool _plantPickerOpen = false;
  String? _justPlantedId;
  bool _focusWaterSaving = false;
  SeedType? _pendingSeed;
  Offset? _plantPoint;
  String? _plantError;
  bool _plantSaving = false, _commitNeedsRecovery = false;
  bool _cultWater = false, _cultOverview = false;
  bool _movingPlant = false;
  bool _gardenToolsOpen = true;
  bool get _compactCultivationControls =>
      MediaQuery.sizeOf(context).height < 500 ||
      (MediaQuery.sizeOf(context).height < 700 &&
          MediaQuery.textScalerOf(context).scale(14) > 20);

  String? get _placementError {
    if (_pendingSeed == null || _plantPoint == null)
      return '점선 자리나 주변의 빈 잔디를 눌러 심을 위치를 골라주세요.';
    final data = MongiGardenStore.instance.value;
    return _layout.value
        .placementError('seed:${_pendingSeed!.id}', _plantPoint!, [
          ...data.seeds.entries
              .where((e) => e.value > 0)
              .map((e) => 'seed:${e.key}'),
          ...data.placed.map((id) => 'decor:$id'),
        ]);
  }

  Future<void> _rememberPlantMoment() async {
    if (!mounted) return;
    try {
      await context.read<CatCareProvider>().rememberMoment(
        CompanionMoment.plant,
      );
    } catch (_) {
      /* Planting is already durable; a companion refresh cannot undo it. */
    }
  }

  void _startMovingPlant(SeedType seed) {
    if (!_canChangeGarden) return;
    _focusPlant(seed);
    setState(() {
      _movingPlant = true;
      _pendingSeed = seed;
      _plantPoint = _layout.value.position('seed:${seed.id}');
      _plantError = null;
      _cultWater = false;
    });
  }

  Future<void> _confirmMove() async {
    if (_plantSaving ||
        _pendingSeed == null ||
        _plantPoint == null ||
        _placementError != null)
      return;
    final seed = _pendingSeed!, point = _plantPoint!;
    setState(() {
      _plantSaving = true;
      _plantError = null;
    });
    try {
      final data = MongiGardenStore.instance.value;
      final visible = [
        ...data.seeds.entries
            .where((e) => e.value > 0)
            .map((e) => 'seed:${e.key}'),
        ...data.placed.map((id) => 'decor:$id'),
      ];
      await _layout.update(
        (latest) => latest.move('seed:${seed.id}', point, visible),
      );
      if (!mounted) return;
      setState(() {
        _pendingSeed = null;
        _plantPoint = null;
        _movingPlant = false;
      });
      _focusPlant(seed);
      _message('식물 위치를 옮겼어요.');
    } catch (_) {
      if (mounted) setState(() => _plantError = '위치를 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _plantSaving = false);
    }
  }

  Future<void> _openFullGarden() async {
    if (!_canChangeGarden) return;
    if (widget.embedded) {
      // A previous watering/planting toast must not migrate onto the full-screen
      // route and cover its bottom tools while the route is opening.
      ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GardenWorldScreen(
            cultivation: true,
            initialLandscape: true,
            initialResting: _restGarden,
          ),
        ),
      );
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      await _setLandscape(!_landscapeRequested);
    }
  }

  Future<void> _confirmPlant() async {
    if (_movingPlant) return _confirmMove();
    if (_plantSaving || _pendingSeed == null || _plantPoint == null) return;
    if (!_commitNeedsRecovery && _placementError != null) return;
    final seed = _pendingSeed!, point = _plantPoint!;
    setState(() {
      _plantSaving = true;
      _plantError = null;
    });
    try {
      await MongiGardenStore.instance.plantAt(seed.id, point);
      if (!mounted) return;
      setState(() {
        _pendingSeed = null;
        _plantPoint = null;
        _commitNeedsRecovery = false;
      });
      _justPlantedId = seed.id;
      _focusPlant(seed);
      unawaited(_rememberPlantMoment());
    } catch (_) {
      // A completed journal may report an I/O error after its final write.
      // Read/replay it before deciding whether this operation saved anything.
      var verifiedNoPlant = false;
      try {
        await MongiGardenStore.instance.reload();
        await _layout.reload();
        if ((MongiGardenStore.instance.value.seeds[seed.id] ?? 0) > 0) {
          if (mounted) {
            setState(() {
              _pendingSeed = null;
              _plantPoint = null;
              _commitNeedsRecovery = false;
            });
            _justPlantedId = seed.id;
            _focusPlant(seed);
            if (_layout.value.positions['seed:${seed.id}'] == point)
              unawaited(_rememberPlantMoment());
          }
          return;
        }
        verifiedNoPlant = true;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _commitNeedsRecovery =
            SessionTransaction.hasPending || !verifiedNoPlant;
        _plantError = _commitNeedsRecovery
            ? '저장 확인이 필요해요. 다시 확인하면 중복 차감 없이 마무리해요.'
            : '저장하지 못했어요. 씨앗을 쓰지 않았어요. 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) setState(() => _plantSaving = false);
    }
  }

  Future<bool> _waterCultivation(String id) async {
    final saved = await MongiGardenStore.instance.waterPlant(id);
    try {
      if (saved && mounted)
        await context.read<CatCareProvider>().rememberMoment(
          CompanionMoment.water,
        );
      await _grow();
    } catch (_) {
      if (mounted) _message('물주기는 저장했어요. 성장 목표는 정원을 다시 열면 확인돼요.');
    }
    return saved;
  }

  Future<void> _myPlants() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
      ),
      child: ValueListenableBuilder<MongiGardenData>(
        valueListenable: MongiGardenStore.instance,
        builder: (_, data, __) => GardenPlantList(
          data: data,
          onLocate: (seed) {
            setState(() {
              _cultOverview = false;
              _cultWater = false;
            });
            _focusPlant(seed);
            Navigator.pop(sheetContext);
          },
          onMove: (seed) {
            Navigator.pop(sheetContext);
            _startMovingPlant(seed);
          },
          onWater: _waterCultivation,
          onMemory: (seed) {
            Navigator.pop(sheetContext);
            unawaited(_memory(seed));
          },
        ),
      ),
    ),
  );

  Future<void> _cultivationMenu(String action) async {
    if (action == 'day' || action == 'night' || action == 'auto-light') {
      setState(
        () => _gardenNight = action == 'auto-light' ? null : action == 'night',
      );
      return;
    }
    if (action == 'collection') widget.onOpenCollection?.call();
    if (action == 'memory') {
      await showMemoryTree(context);
    }
    if (action == 'orchard') {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const OrchardScreen()),
      );
    }
    if (action == 'neighbors') {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const GardenVillageScreen()),
      );
    }
    if (action == 'decorate') {
      showGardenDecorationSheet(context);
    }
    if (action == 'layout') {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const GardenWorldScreen.tools(),
        ),
      );
    }
    if (action == 'fullscreen') {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const GardenWorldScreen.owned(),
        ),
      );
    }
    if (mounted) {
      await _layout.reload();
      await MongiGardenStore.instance.reload();
    }
  }

  Widget _buildCultivation(
    BuildContext context,
  ) => ValueListenableBuilder<MongiGardenData>(
    valueListenable: MongiGardenStore.instance,
    builder: (context, data, _) => Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(14) > 20
            ? 64
            : 44,
        title: MediaQuery.sizeOf(context).height < 500
            ? PopupMenuButton<bool>(
                key: const Key('compact-garden-switch'),
                tooltip: '정원 바꾸기',
                enabled: _canChangeGarden,
                onSelected: _changeGarden,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: false, child: Text('내가 가꾸는 정원')),
                  PopupMenuItem(value: true, child: Text('쉬어가는 정원')),
                ],
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        _restGarden
                            ? '쉬어가는 정원'
                            : '내 정원 · 씨앗 ${data.seedTokens}개',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 20),
                  ],
                ),
              )
            : Text(_restGarden ? '쉬어가는 정원' : '내 정원'),
        actions: [
          IconButton(
            tooltip: '가로·세로 보기',
            onPressed: _plantSaving ? null : _openFullGarden,
            icon: const Icon(Icons.screen_rotation_outlined),
          ),
          if (!_restGarden)
            PopupMenuButton<String>(
              tooltip: '정원 보조 메뉴',
              onSelected: _plantSaving || _pendingSeed != null
                  ? null
                  : _cultivationMenu,
              itemBuilder: (_) => [
                if (widget.onOpenCollection != null)
                  const PopupMenuItem(
                    value: 'collection',
                    child: Text('기록·활동 보기'),
                  ),
                const PopupMenuItem(value: 'day', child: Text('햇살 정원 보기')),
                const PopupMenuItem(value: 'night', child: Text('반딧불이 정원 보기')),
                const PopupMenuItem(
                  value: 'auto-light',
                  child: Text('현재 시간에 맞추기'),
                ),
                PopupMenuItem(value: 'memory', child: Text('기억의 나무')),
                PopupMenuItem(value: 'orchard', child: Text('열매 정원')),
                PopupMenuItem(value: 'neighbors', child: Text('이웃 정원')),
                PopupMenuItem(value: 'decorate', child: Text('장식 고르기')),
                PopupMenuItem(
                  value: 'layout',
                  child: Text('정원 도구 · 장식 이동 · 확장'),
                ),
                PopupMenuItem(value: 'fullscreen', child: Text('정원 전체화면')),
              ],
            ),
        ],
        bottom: MediaQuery.sizeOf(context).height < 500
            ? null
            : PreferredSize(
                preferredSize: Size.fromHeight(
                  MediaQuery.textScalerOf(context).scale(13) + 36,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  child: Row(
                    children: [
                      for (final resting in [false, true])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: ValueKey(
                              resting
                                  ? 'rest-garden-tab'
                                  : 'cultivate-garden-tab',
                            ),
                            label: Text(
                              resting ? '쉬어가는 정원' : '내가 가꾸는 정원',
                              style: const TextStyle(fontSize: 13),
                            ),
                            selected: _restGarden == resting,
                            onSelected: _canChangeGarden
                                ? (_) => _changeGarden(resting)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
      body: IndexedStack(
        index: _restGarden ? 1 : 0,
        children: [
          TickerMode(
            enabled: !_restGarden,
            child: Column(
              children: [
                if (_pendingSeed == null &&
                    MediaQuery.sizeOf(context).height >= 500)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 3,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '보유 씨앗 ${data.seedTokens}개${_cultWater ? ' · 물줄 식물을 눌러주세요' : ''}',
                        key: const Key('garden-seed-balance'),
                      ),
                    ),
                  ),
                if (_pendingSeed == null &&
                    _focusedPlantId == null &&
                    !_loading &&
                    _error == null &&
                    _recentPlants(data).isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('recent-planted-location'),
                      onPressed: () => _openRecentPlants(data),
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('최근 심은 식물 보기'),
                    ),
                  ),
                Expanded(
                  key: const ValueKey('cultivation-canvas'),
                  child: _gardenContent(context),
                ),
                if (_pendingSeed != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: (MediaQuery.sizeOf(context).height * .24)
                          .clamp(70, 155),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  key: const Key('cancel-plant-location'),
                                  onPressed:
                                      _plantSaving || _commitNeedsRecovery
                                      ? null
                                      : () => setState(() {
                                          _pendingSeed = null;
                                          _plantPoint = null;
                                          _plantError = null;
                                          _movingPlant = false;
                                        }),
                                  child: const Text('취소'),
                                ),
                                FilledButton(
                                  key: const Key('confirm-plant-location'),
                                  style: FilledButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed:
                                      _plantSaving ||
                                          (!_commitNeedsRecovery &&
                                              _placementError != null)
                                      ? null
                                      : _confirmPlant,
                                  child: Text(
                                    _plantSaving
                                        ? '저장 중…'
                                        : _commitNeedsRecovery
                                        ? '저장 다시 확인'
                                        : _movingPlant
                                        ? '이 위치로 옮기기'
                                        : '여기에 심기 · 씨앗 1개',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _plantError ??
                                  _placementError ??
                                  (_movingPlant
                                      ? '${_pendingSeed!.label}를 이 자리로 옮길까요? 씨앗은 사용하지 않아요.'
                                      : '${_pendingSeed!.label}를 이 자리에 심을까요?'),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_pendingSeed == null &&
                    _focusedPlantId != null &&
                    (data.seeds[_focusedPlantId] ?? 0) > 0)
                  _focusedPlantCard(data),
                if (_pendingSeed == null &&
                    (!_landscapeRequested || _gardenToolsOpen))
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('garden-items-button'),
                      onPressed: _canChangeGarden
                          ? () => showGardenDecorationSheet(context)
                          : null,
                      icon: const Icon(Icons.chair_outlined),
                      label: const Text('정원 아이템 · 꾸미기'),
                    ),
                  ),
                if (_landscapeRequested)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          setState(() => _gardenToolsOpen = !_gardenToolsOpen),
                      icon: Icon(
                        _gardenToolsOpen
                            ? Icons.expand_more
                            : Icons.expand_less,
                      ),
                      label: Text(_gardenToolsOpen ? '도구 접기' : '도구 펼치기'),
                    ),
                  ),
                if (!_landscapeRequested || _gardenToolsOpen)
                  GardenCoreTools(
                    compact: _compactCultivationControls,
                    watering: _cultWater,
                    overview: _cultOverview,
                    disabled:
                        _loading || _error != null || _pendingSeed != null,
                    onPlant: _plant,
                    onWater: () => setState(() {
                      _cultWater = !_cultWater;
                      _cultOverview = false;
                    }),
                    onPlants: _myPlants,
                    onOverview: _openFullGarden,
                  ),
              ],
            ),
          ),
          TickerMode(
            enabled: _restGarden,
            child: RestingGardenView(
              cameraGestures: !widget.embedded,
              onFullscreen: _openFullGarden,
              fullscreen: _landscapeRequested,
            ),
          ),
        ],
      ),
    ),
  );
  int _plantFocusRequest = 0;
  void _focusPlant(SeedType seed) {
    if (!mounted) return;
    setState(() {
      _focusedPlantId = seed.id;
      _cultOverview = false;
      _cultWater = false;
      _plantFocusRequest++;
    });
  }

  List<SeedType> _recentPlants(MongiGardenData data) =>
      recentGardenPlants(
            seeds: data.seeds,
            plantedOn: data.plantedOn,
            sessionLast: _justPlantedId,
          )
          .where((id) => SeedType.all.any((seed) => seed.id == id))
          .map(SeedType.byId)
          .toList();

  Future<void> _openRecentPlants(MongiGardenData data) async {
    final candidates = _recentPlants(data);
    if (candidates.isEmpty) return;
    if (candidates.length == 1) {
      _focusPlant(candidates.single);
      return;
    }
    final selected = await showModalBottomSheet<SeedType>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('같은 날 심은 식물이에요. 찾을 식물을 골라주세요.'),
                ),
                for (final seed in candidates)
                  ListTile(
                    key: ValueKey('recent-candidate-${seed.id}'),
                    title: Text(seed.label),
                    trailing: const Icon(Icons.my_location),
                    onTap: () => Navigator.pop(context, seed),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && selected != null) _focusPlant(selected);
  }

  Future<void> _waterFocused(String id) async {
    if (_focusWaterSaving) return;
    setState(() => _focusWaterSaving = true);
    try {
      final saved = await _waterCultivation(id);
      if (mounted)
        _message(saved ? '물을 주었어요. 함께 자라는 중이에요.' : '오늘은 이미 물을 주었어요.');
    } catch (_) {
      if (mounted) _message('물주기를 저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _focusWaterSaving = false);
    }
  }

  Widget _focusedPlantCard(MongiGardenData data) {
    final seed = SeedType.byId(_focusedPlantId!);
    final watered = data.wateredToday(seed.id, DateTime.now());
    final name = Text(
      '내 ${seed.label} · ${seed.growthLabel(data.seeds[seed.id]!)}',
      key: const Key('focused-plant-name'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final close = IconButton(
      tooltip: '식물 선택 닫기',
      onPressed: () => setState(() => _focusedPlantId = null),
      icon: const Icon(Icons.close, size: 18),
    );
    final water = FilledButton.icon(
      key: const Key('focused-plant-water'),
      onPressed: watered || _focusWaterSaving
          ? null
          : () => _waterFocused(seed.id),
      icon: const Icon(Icons.water_drop_outlined, size: 18),
      label: Text(
        _focusWaterSaving
            ? '저장 중…'
            : watered
            ? '오늘 물주기 완료'
            : _justPlantedId == seed.id && !data.wateredOn.containsKey(seed.id)
            ? '첫 물 주기'
            : '물주기',
      ),
    );
    final move = TextButton.icon(
      key: const Key('focused-plant-move'),
      onPressed: _focusWaterSaving ? null : () => _startMovingPlant(seed),
      icon: const Icon(Icons.open_with, size: 18),
      label: const Text('위치 옮기기'),
    );
    final memory = TextButton(
      onPressed: () => _memory(seed),
      child: const Text('추억 기록'),
    );
    if (_compactCultivationControls) {
      return Material(
        color: const Color(0xFFF4F5E9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              Expanded(child: name),
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [water, move, memory]),
                ),
              ),
              close,
            ],
          ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .22,
      ),
      child: SingleChildScrollView(
        child: Material(
          color: const Color(0xFFF4F5E9),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: name),
                    close,
                  ],
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [water, move, memory],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _plant() async {
    if (_plantPickerOpen) return;
    if (!_cultivationEnabled) setState(() => _cultivationActivated = true);
    _plantPickerOpen = true;
    final store = MongiGardenStore.instance;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .9,
          ),
          child: ValueListenableBuilder(
            valueListenable: store,
            builder: (context, data, _) => GardenPlantPicker(
              tokens: data.seedTokens,
              chooseLocation: _cultivationEnabled,
              seeds: data.seeds,
              onLocate: (seed) {
                _focusPlant(seed);
                Navigator.pop(sheetContext);
              },
              onCare: (seed) {
                _focusPlant(seed);
                Navigator.pop(sheetContext);
                unawaited(_memory(seed));
              },
              onPlant: (seed) async {
                setState(() {
                  _movingPlant = false;
                  _pendingSeed = seed;
                  _plantPoint = null;
                  _plantError = null;
                  _cultWater = false;
                  _cultOverview = false;
                });
                Navigator.pop(sheetContext);
              },
            ),
          ),
        ),
      );
    } finally {
      _plantPickerOpen = false;
    }
  }

  Widget _gardenContent(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final companion = context.watch<CatCareProvider>();
    final companionName = companion.displayName;
    final immersive =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return _loading
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
              originalScenery: true,
              cameraGestures: !widget.embedded,
              nightOverride: _gardenNight,
              fillViewport: _cultivationEnabled || immersive || _expandedGarden,
              immersive: !_cultivationEnabled && immersive,
              cultivationMode: _cultivationEnabled,
              wateringRequested: _cultWater,
              placementSeed: _pendingSeed,
              placementCount: _movingPlant
                  ? (MongiGardenStore.instance.value.seeds[_pendingSeed?.id] ??
                        1)
                  : 1,
              placementPoint: _plantPoint,
              onPlacementPoint: (point) => setState(() {
                if (_plantSaving || _commitNeedsRecovery) return;
                _plantPoint = point;
                _plantError = null;
              }),
              overviewRequested: _cultOverview,
              onOrchard: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const OrchardScreen()),
              ),
              companionName: companionName,
              family: companion.journey.residents,
              activeCoat: companion.journey.coat ?? CompanionCoat.ginger,
              companionScale: companion.journey.visualScale,
              companionBondStage: companion.journey.stage,
              companionAutomaticBehavior:
                  companion.journeyReady && companion.journey.automaticBehavior,
              onCompanionCare: () => showCompanionCare(context),
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
              seeds: MongiGardenStore.instance.value.seeds,
              careRemainders: MongiGardenStore.instance.value.careRemainders,
              decorations: garden.equippedDecorationIds,
              onMemory: _memory,
              onWater: (id) async {
                if (_cultivationEnabled) return _waterCultivation(id);
                final cared = await MongiGardenStore.instance.waterPlant(id);
                if (cared && mounted) {
                  await companion.rememberMoment(CompanionMoment.water);
                }
                await _grow();
                return cared;
              },
              onPlant: _plant,
              focusPlantId: _focusedPlantId,
              plantFocusRequest: _plantFocusRequest,
              onInspectPlant: _cultivationEnabled ? _focusPlant : null,
              wateredOn: MongiGardenStore.instance.value.wateredOn,
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
          );
  }

  @override
  Widget build(BuildContext context) {
    if (_cultivationEnabled) return _buildCultivation(context);
    final garden = context.watch<GardenProvider>();
    final immersive =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      extendBodyBehindAppBar: immersive,
      appBar: (_quiet || immersive)
          ? null
          : _expandedGarden
          ? AppBar(
              toolbarHeight: 48,
              title: Text(
                '고양이 정원',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleFont(fontSize: 19),
              ),
              backgroundColor: AppColors.bg0,
              actions: [
                IconButton(
                  key: const Key('open-plant-picker'),
                  tooltip: '씨앗과 나무 · 심은 식물 찾기',
                  onPressed: _loading || _error != null ? null : _plant,
                  icon: const Icon(Icons.spa_outlined),
                ),
                _rotationButton(),
                IconButton(
                  tooltip: '열매 정원 · 창고',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OrchardScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.park_outlined),
                ),
                IconButton(
                  key: const Key('garden-exit-fullscreen'),
                  tooltip: '정원 메뉴 펼치기',
                  onPressed: () => setState(() => _expandedGarden = false),
                  icon: const Icon(Icons.fullscreen_exit),
                ),
                IconButton(
                  tooltip: '고양이 선택 · 구독 기능',
                  onPressed: () => showCompanionCoats(context),
                  icon: const Icon(Icons.palette_outlined),
                ),
              ],
            )
          : AppBar(
              toolbarHeight: 82,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '나의 넓은 정원',
                    style: titleFont(
                      fontSize: 20,
                      color: AppColors.titlePastelGreen,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: MongiGardenStore.instance,
                    builder: (context, data, _) => TextButton.icon(
                      key: const ValueKey('garden-essence-balance'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _loading
                          ? null
                          : () => showGardenDecorationSheet(context),
                      icon: const Icon(Icons.auto_awesome, size: 15),
                      label: Text(
                        '빛의 정수 ${data.essence}개',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.bg0,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(largeText ? 88 : 48),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          key: const Key('garden-companion-care'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          onPressed: () => showCompanionCare(context),
                          icon: const Icon(Icons.pets_outlined, size: 18),
                          label: const Text('돌보기'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          onPressed: () => showGardenReturnSheet(
                            context,
                            _returnOwner ==
                                    (garden.publicGardenAccount ?? 'guest')
                                ? _returnSummary
                                : null,
                          ),
                          icon: ReceivedHeartIcon(
                            owner: garden.publicGardenAccount,
                          ),
                          label: const Text('정원 소식'),
                        ),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GardenVillageScreen(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.holiday_village_outlined,
                            size: 18,
                          ),
                          label: const Text('냥이 마을'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                _rotationButton(),
                IconButton(
                  tooltip: '열매 정원 · 창고',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OrchardScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.park_outlined),
                ),
                IconButton(
                  tooltip: '고양이 선택 · 구독 기능',
                  onPressed: () => showCompanionCoats(context),
                  icon: const Icon(Icons.palette_outlined),
                ),
                IconButton(
                  key: const Key('garden-enter-fullscreen'),
                  tooltip: '정원 전체화면',
                  onPressed: () => setState(() => _expandedGarden = true),
                  icon: const Icon(Icons.fullscreen),
                ),
                if (widget.onOpenCollection != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 8),
                    child: IconButton(
                      tooltip: '고양이와 정원 기록',
                      onPressed: widget.onOpenCollection,
                      icon: const Icon(Icons.menu_book_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.blobButter,
                        foregroundColor: AppColors.blobButterAccent,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
              ],
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _gardenContent(context),
          if (immersive)
            Positioned(
              top: 8,
              left: 10,
              child: SafeArea(
                child: Material(
                  color: const Color(0xDDFBFAF4),
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('garden-immersive-back'),
                        iconSize: 18,
                        tooltip: '정원 나가기',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      IconButton(
                        key: const Key('garden-portrait'),
                        iconSize: 18,
                        tooltip: '세로 정원으로 돌아가기',
                        onPressed: _portraitGarden,
                        icon: const Icon(Icons.stay_current_portrait),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 700)
                        const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Text(
                            '마음냥 정원',
                            style: TextStyle(
                              fontFamily: 'GamjaFlower',
                              fontSize: 16,
                              color: Color(0xFF786B59),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
