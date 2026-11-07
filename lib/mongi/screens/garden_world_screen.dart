import '../../l10n/app_language.dart';
import '../widgets/garden_essence_chip.dart';
import 'garden_daily_care_screen.dart';
import '../../widgets/garden_style_sheet.dart';
import '../../services/garden_style_store.dart';
import '../../widgets/garden_personal_canvas.dart';
import '../../widgets/sound_panel.dart';
import '../widgets/resting_garden_view.dart';
import '../../services/garden_personal_gallery_store.dart';
import '../../services/cat_care_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../widgets/garden_cultivation_tools.dart';
import '../../utils/recent_garden_plants.dart';
import '../integration/session_transaction.dart';
import 'mind_planting_screen.dart';
import '../integration/planting_mind.dart';
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
  final bool? initialNight;
  final bool cultivation, embedded;

  /// A read-only navigation request, resolved against saved plants after load.
  final String? initialFocusPlantId;
  final VoidCallback? onOpenCollection;
  const GardenWorldScreen({
    super.key,
    this.onOpenCollection,
    this.showRecordNote = false,
    this.initialLandscape = false,
    this.initialResting = false,
    this.initialNight,
    this.cultivation = true,
    this.embedded = false,
    this.initialFocusPlantId,
  });
  const GardenWorldScreen.owned({
    Key? key,
    VoidCallback? onOpenCollection,
    bool showRecordNote = false,
    bool initialLandscape = false,
    bool embedded = false,
    String? initialFocusPlantId,
  }) : this(
         key: key,
         onOpenCollection: onOpenCollection,
         showRecordNote: showRecordNote,
         initialLandscape: initialLandscape,
         cultivation: true,
         embedded: embedded,
         initialFocusPlantId: initialFocusPlantId,
       );

  const GardenWorldScreen.tools({Key? key})
    : this(key: key, cultivation: false);

  @override
  State<GardenWorldScreen> createState() => _GardenWorldScreenState();
}

class _GardenWorldScreenState extends State<GardenWorldScreen>
    with WidgetsBindingObserver {
  String? _requestedRestItem;
  Uint8List? _galleryArtwork;
  int _restRequest = 0;
  Future<void> _chooseCatRest() async {
    final data = MongiGardenStore.instance.value;
    final choices = <String, String>{
      if (data.placed.contains('cat_cushion'))
        'decor:cat_cushion': tr('방석에서 쉬기'),
      if (data.placed.contains('cat_basket'))
        'decor:cat_basket': tr('바구니에서 쉬기'),
      for (final seed in SeedType.all)
        if (seed.isTree && seed.tierForCount(data.seeds[seed.id] ?? 0) >= 3)
          'seed:${seed.id}': tr("{0} 그늘에서 쉬기", [seed.label]),
    };
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (c) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(tr('고양이 쉼터')),
            subtitle: Text(tr('고양이를 누르면 다시 일어나요.')),
          ),
          if (choices.isEmpty)
            ListTile(title: Text(tr('방석·바구니를 놓거나 나무가 무성해질 때까지 키워 보세요.'))),
          for (final choice in choices.entries)
            ListTile(
              leading: const Icon(Icons.pets),
              title: Text(choice.value),
              onTap: () => Navigator.pop(c, choice.key),
            ),
        ],
      ),
    );
    if (selected != null && mounted && _canChangeGarden)
      setState(() {
        _requestedRestItem = selected;
        _restRequest++;
      });
  }

  bool _cultivationActivated = false;
  late bool _restGarden = widget.initialResting;
  late bool? _gardenNight = widget.initialNight;
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
              !SoundService().sleepStopped;
          if (start && !sound.ambientNaturePlaying) {
            await sound.startAmbientNature();
            // Own the request even when nature is disabled, so leaving rest cancels it.
            _ownsRestAudio = true;
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
    if (_landscapeRequested || _portraitRequested) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
      unawaited(
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      );
    }
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
        _cultOverview = false;
        _focusedPlantId = null;
      }
    });
    try {
      await SystemChrome.setEnabledSystemUIMode(
        enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
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
          SnackBar(content: Text(tr('휴대폰의 자동 회전을 켜고 가로로 돌려 주세요.'))),
        );
      }
    }
  }

  Widget _rotationButton() => IconButton(
    key: const Key('garden-landscape'),
    tooltip: _landscapeRequested ? tr('자동 회전으로 돌아가기') : tr('가로 전체보기'),
    onPressed: _openFullGarden,
    icon: Icon(
      _landscapeRequested
          ? Icons.screen_lock_landscape
          : Icons.screen_rotation_outlined,
    ),
  );
  bool _expandedGarden = true;
  bool _loading = true, _quiet = false, _recordNoteShown = false;
  bool _initialFocusHandled = false;
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

  bool _mindLoadError = false;
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
      if (!mounted) return;
      try {
        await PlantMemoryStore.instance.reload();
        _mindLoadError = false;
      } catch (_) {
        _mindLoadError = true;
      }
      if (!mounted) return;
      // Optional styling follows the account/core storage load. Opening this
      // route alone must not start an independent encrypted-storage request.
      try {
        await GardenStyleStore.instance.reload();
        if (!mounted) return;
      } catch (_) {}
      try {
        final owner = CatCareService.localOwner;
        final gallery = await GardenPersonalGalleryStore.read(owner);
        if (mounted && owner == CatCareService.localOwner) {
          _galleryArtwork = gallery['artwork'] == null
              ? null
              : base64Decode(gallery['artwork'] as String);
        }
      } catch (_) {}
      if (!mounted) return;
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
      _error = tr('정원 배치를 불러오지 못했어요. 기록은 그대로 보관하고 있어요.');
    }
    if (mounted) {
      setState(() => _loading = false);
      if (_error == null && !_initialFocusHandled && widget.cultivation) {
        _initialFocusHandled = true;
        final id = widget.initialFocusPlantId;
        final matches = SeedType.all.where((seed) => seed.id == id);
        if (matches.isNotEmpty &&
            (MongiGardenStore.instance.value.seeds[id] ?? 0) > 0) {
          _focusPlant(matches.single);
        }
      }
      // Open the saved personal garden before waiting for any network work.
      // A slow server must not turn an offline garden into a loading screen.
      if (_error == null) unawaited(_syncReceivedFlowers());
      if (_error == null && widget.showRecordNote && !_recordNoteShown) {
        _recordNoteShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('함께한 기록을 간직했어요. 기억의 나무에서는 나만의 씨앗을 심을 수 있어요.')),
              duration: const Duration(seconds: 7),
              action: SnackBarAction(
                label: tr('기억의 나무 보기'),
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
            content: Text(tr('내 정원은 사용할 수 있어요. 새로 받은 마음은 연결 후 다시 확인해 주세요.')),
            duration: const Duration(seconds: 7),
            action: SnackBarAction(
              label: tr('다시 확인'),
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
      if (mounted) setState(() => _mindLoadError = false);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => PlantMemoryEditor(plant: seed),
        );
        await _grow();
      }
    } catch (_) {
      if (mounted) _message(tr('추억을 불러오지 못했어요. 다시 시도해 주세요.'));
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  String? _focusedPlantId;
  bool _plantPickerOpen = false;
  String? _justPlantedId;
  bool _focusWaterSaving = false;
  SeedType? _pendingSeed;
  PlantingMind? _pendingMind;
  String? _pendingMindOwner;
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
      return tr('점선 자리나 주변의 빈 잔디를 눌러 심을 위치를 골라주세요.');
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
    ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
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
    Offset? previousPosition;
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
      await _layout.update((latest) {
        previousPosition = latest.position('seed:${seed.id}');
        return latest.move('seed:${seed.id}', point, visible);
      });
      if (!mounted) return;
      setState(() {
        _pendingSeed = null;
        _pendingMind = null;
        _pendingMindOwner = null;
        _plantPoint = null;
        _movingPlant = false;
      });
      _focusPlant(seed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('식물 위치를 옮겼어요.')),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: tr("되돌리기"),
            onPressed: () {
              if (previousPosition != null)
                _undoPlantMove(seed, point, previousPosition!);
            },
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        setState(() => _plantError = tr('위치를 저장하지 못했어요. 다시 시도해 주세요.'));
    } finally {
      if (mounted) setState(() => _plantSaving = false);
    }
  }

  Future<void> _undoPlantMove(
    SeedType seed,
    Offset moved,
    Offset previous,
  ) async {
    if (!mounted || !_canChangeGarden) return;
    setState(() => _plantSaving = true);
    try {
      await _layout.update((latest) {
        final data = MongiGardenStore.instance.value;
        final visible = [
          ...data.seeds.entries
              .where((e) => e.value > 0)
              .map((e) => 'seed:${e.key}'),
          ...data.placed.map((id) => 'decor:$id'),
        ];
        final id = 'seed:${seed.id}';
        if (latest.position(id) != moved)
          throw StateError('Position changed since move');
        return latest.move(id, previous, visible);
      });
      if (mounted) {
        _focusPlant(seed);
        _message(tr('이전 위치로 되돌렸어요.'));
      }
    } catch (_) {
      if (mounted)
        _message(tr('위치가 바뀌었거나 빈자리가 없어 되돌리지 못했어요. 내 식물에서 다시 옮겨 주세요.'));
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
            initialNight: _gardenNight,
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
      if (_pendingMind != null &&
          _pendingMindOwner != CatCareService.localOwner) {
        setState(() {
          _pendingSeed = null;
          _pendingMind = null;
          _pendingMindOwner = null;
          _plantPoint = null;
        });
        _message(tr('계정이 바뀌었어요. 마음 심기를 다시 열어 주세요.'));
        return;
      }
      await MongiGardenStore.instance.plantAt(
        seed.id,
        point,
        mind: _pendingMind,
      );
      await PlantMemoryStore.instance.reload();
      if (!mounted) return;
      setState(() {
        _pendingSeed = null;
        _pendingMind = null;
        _pendingMindOwner = null;
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
        await PlantMemoryStore.instance.reload();
        final mindSaved =
            _pendingMind == null ||
            (PlantMemoryStore.instance.value[seed.id]?.timeline.any(
                  (e) =>
                      e.id == _pendingMind!.id &&
                      e.emotionCatId == _pendingMind!.emotionCatId &&
                      e.note == _pendingMind!.note.trim(),
                ) ??
                false);
        if (mindSaved &&
            (MongiGardenStore.instance.value.seeds[seed.id] ?? 0) > 0) {
          if (mounted) {
            setState(() {
              _pendingSeed = null;
              _pendingMind = null;
              _pendingMindOwner = null;
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
            ? tr('저장 확인이 필요해요. 다시 확인하면 중복 차감 없이 마무리해요.')
            : tr('저장하지 못했어요. 씨앗을 쓰지 않았어요. 다시 시도해 주세요.');
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
      if (mounted) _message(tr('물주기는 저장했어요. 성장 목표는 정원을 다시 열면 확인돼요.'));
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
    if (action == 'care-guide') {
      _showCareGuide();
      return;
    }
    if (action == 'cat-rest') {
      await _chooseCatRest();
      return;
    }
    if (action == 'styles') {
      await showGardenStyles(context);
      return;
    }
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

  Widget _buildCultivation(BuildContext context) =>
      ValueListenableBuilder<MongiGardenData>(
        valueListenable: MongiGardenStore.instance,
        builder: (context, data, _) => _landscapeRequested
            ? _buildFullscreenGarden(context, data)
            : _buildPortraitGarden(context, data),
      );

  Future<void> _openDailyCare() async {
    if (!_canChangeGarden) return;
    final plant = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GardenDailyCareScreen()),
    );
    if (mounted && plant == true && _canChangeGarden) await _plant();
  }

  Widget _buildPortraitGarden(BuildContext context, MongiGardenData data) {
    return PopScope(
      canPop: !_plantSaving && !_commitNeedsRecovery,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F5EA),
        body: LayoutBuilder(
          builder: (context, bounds) {
            final large = MediaQuery.textScalerOf(context).scale(14) > 20;
            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: SizedBox.expand(
                    key: const ValueKey('cultivation-canvas'),
                    child: IndexedStack(
                      sizing: StackFit.expand,
                      index: _restGarden ? 1 : 0,
                      children: [
                        TickerMode(
                          enabled: !_restGarden,
                          child: _gardenContent(context),
                        ),
                        TickerMode(
                          enabled: _restGarden,
                          child: RestingGardenView(
                            key: const Key('resting-garden-space'),
                            canvasOnly: true,
                            cameraGestures: !widget.embedded,
                            nightOverride: _gardenNight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      color: const Color(0xECFFF9EC),
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              if (!widget.embedded)
                                BackButton(
                                  onPressed:
                                      _plantSaving || _commitNeedsRecovery
                                      ? null
                                      : () => Navigator.of(context).maybePop(),
                                ),
                              Expanded(
                                child: Text(
                                  _restGarden ? tr('쉬어가는 정원') : tr('내 정원'),
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (!large)
                                GardenEssenceChip(amount: data.essence),
                              PopupMenuButton<String>(
                                key: const Key('portrait-garden-menu'),
                                tooltip: tr('정원 보조 메뉴'),
                                enabled: _canChangeGarden,
                                onSelected: (value) {
                                  if (value == 'cultivate' || value == 'rest') {
                                    _changeGarden(value == 'rest');
                                  } else {
                                    _cultivationMenu(value);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'cultivate',
                                    child: Text(tr('가꾸는 정원')),
                                  ),
                                  PopupMenuItem(
                                    value: 'rest',
                                    child: Text(tr('쉬어가는 정원')),
                                  ),
                                  if (!_restGarden) ...[
                                    if (widget.onOpenCollection != null)
                                      PopupMenuItem(
                                        value: 'collection',
                                        child: Text(tr('기록·활동 보기')),
                                      ),
                                    PopupMenuItem(
                                      value: 'cat-rest',
                                      child: Text(tr('고양이 쉼터')),
                                    ),
                                    PopupMenuItem(
                                      value: 'styles',
                                      child: Text(tr('계절·배치 저장')),
                                    ),
                                    PopupMenuItem(
                                      value: 'care-guide',
                                      child: Text(tr('성장·보상 안내')),
                                    ),
                                    PopupMenuItem(
                                      value: 'day',
                                      child: Text(tr('햇살 정원 보기')),
                                    ),
                                    PopupMenuItem(
                                      value: 'night',
                                      child: Text(tr('반딧불이 정원 보기')),
                                    ),
                                    PopupMenuItem(
                                      value: 'auto-light',
                                      child: Text(tr('현재 시간에 맞추기')),
                                    ),
                                    PopupMenuItem(
                                      value: 'memory',
                                      child: Text(tr("기억의 나무")),
                                    ),
                                    PopupMenuItem(
                                      value: 'orchard',
                                      child: Text(tr("열매 정원")),
                                    ),
                                    PopupMenuItem(
                                      value: 'neighbors',
                                      child: Text(tr("이웃 정원")),
                                    ),
                                    PopupMenuItem(
                                      value: 'decorate',
                                      child: Text(tr('장식 고르기')),
                                    ),
                                    PopupMenuItem(
                                      value: 'layout',
                                      child: Text(tr('정원 도구 · 장식 이동 · 확장')),
                                    ),
                                    PopupMenuItem(
                                      value: 'fullscreen',
                                      child: Text(tr('정원 전체화면')),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (large)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GardenEssenceChip(amount: data.essence),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: MediaQuery.paddingOf(context).top + (large ? 120 : 64),
                  child: _floatingPanel(
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: bounds.maxWidth * .58,
                        maxHeight: bounds.maxHeight * .2,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_restGarden)
                              PopupMenuButton<bool?>(
                                tooltip: tr('쉬어가는 정원 낮·밤'),
                                onSelected: (value) =>
                                    setState(() => _gardenNight = value),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: false,
                                    child: Text(tr('햇살 풍경')),
                                  ),
                                  PopupMenuItem(
                                    value: true,
                                    child: Text(tr('별빛 풍경')),
                                  ),
                                ],
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(tr('낮과 밤')),
                                ),
                              ),
                            if (!_restGarden)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Text(
                                  tr('보유 씨앗 {0}개', [data.seedTokens]),
                                  key: const Key('garden-seed-balance'),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            if (!_restGarden && _pendingSeed == null)
                              TextButton.icon(
                                key: const Key('garden-daily-care-entry'),
                                onPressed: _canChangeGarden
                                    ? _openDailyCare
                                    : null,
                                icon: const Icon(
                                  Icons.favorite_border,
                                  size: 18,
                                ),
                                label: Text(tr('마음돌봄')),
                              ),
                            if (!_restGarden &&
                                _pendingSeed == null &&
                                _focusedPlantId == null &&
                                !_loading &&
                                _error == null &&
                                _recentPlants(data).isNotEmpty)
                              TextButton.icon(
                                key: const Key('recent-planted-location'),
                                onPressed: () => _openRecentPlants(data),
                                icon: const Icon(Icons.spa_outlined, size: 18),
                                label: Text(tr('최근 심은 식물 보기')),
                              ),
                            if (_cultWater && !_restGarden)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(tr('물줄 식물을 눌러주세요')),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: SafeArea(
                    top: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: bounds.maxHeight * (large ? .46 : .42),
                      ),
                      child: SingleChildScrollView(
                        key: const Key('garden-overlay-scroll'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_restGarden && _pendingSeed != null)
                              _floatingPanel(
                                _fullscreenPlacementControls(context),
                              ),
                            if (!_restGarden &&
                                _pendingSeed == null &&
                                _focusedPlantId != null &&
                                (data.seeds[_focusedPlantId] ?? 0) > 0)
                              _floatingPanel(_focusedPlantCard(data)),
                            if (!_restGarden && _pendingSeed != null)
                              GardenCoreTools(
                                compact: true,
                                disabled: true,
                                onPlant: _plant,
                                onWater: () {},
                                onPlants: _myPlants,
                                onOverview: _openFullGarden,
                              ),
                            if (_pendingSeed == null) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: _floatingPanel(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!_restGarden)
                                        TextButton.icon(
                                          key: const Key('garden-items-button'),
                                          onPressed: _canChangeGarden
                                              ? () => showGardenDecorationSheet(
                                                  context,
                                                )
                                              : null,
                                          icon: const Icon(
                                            Icons.chair_outlined,
                                            size: 19,
                                          ),
                                          label: Text(
                                            large ? tr('꾸미기') : tr('우리 정원 꾸미기'),
                                          ),
                                        ),
                                      IconButton(
                                        key: const Key('portrait-tools-toggle'),
                                        tooltip: _gardenToolsOpen
                                            ? tr('도구 접기')
                                            : tr('도구 펼치기'),
                                        onPressed: () => setState(
                                          () => _gardenToolsOpen =
                                              !_gardenToolsOpen,
                                        ),
                                        icon: Icon(
                                          _gardenToolsOpen
                                              ? Icons.expand_more
                                              : Icons.expand_less,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (!_restGarden && _gardenToolsOpen)
                                GardenCoreTools(
                                  compact: bounds.maxHeight < 420,
                                  watering: _cultWater,
                                  overview: _cultOverview,
                                  disabled: _loading || _error != null,
                                  onPlant: _plant,
                                  onWater: () => setState(() {
                                    _cultWater = !_cultWater;
                                    _cultOverview = false;
                                  }),
                                  onPlants: _myPlants,
                                  onOverview: _openFullGarden,
                                ),
                              if (_restGarden || !_gardenToolsOpen)
                                _floatingPanel(
                                  TextButton.icon(
                                    key: _restGarden
                                        ? const Key('rest-garden-overview')
                                        : null,
                                    onPressed: _openFullGarden,
                                    icon: const Icon(Icons.fullscreen),
                                    label: Text(tr('가로 전체화면')),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _exitFullscreenGarden() async {
    if (_plantSaving || _commitNeedsRecovery) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _pendingSeed = null;
        _pendingMind = null;
        _pendingMindOwner = null;
        _plantPoint = null;
        _movingPlant = false;
      });
      await _setLandscape(false);
    }
  }

  Widget _floatingPanel(Widget child) => Material(
    color: const Color(0xEBFFFDF5),
    elevation: 2,
    borderRadius: BorderRadius.circular(18),
    clipBehavior: Clip.antiAlias,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: child,
    ),
  );

  Widget _buildFullscreenGarden(BuildContext context, MongiGardenData data) {
    final size = MediaQuery.sizeOf(context);
    Widget action(
      String label,
      IconData icon,
      VoidCallback? callback,
      String id,
    ) => TextButton.icon(
      key: ValueKey(id),
      onPressed: callback,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      icon: Icon(icon, size: 21),
      label: Text(label),
    );
    return PopScope(
      canPop: !_plantSaving && !_commitNeedsRecovery,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: SizedBox.expand(
                key: const Key('fullscreen-garden-canvas'),
                child: IndexedStack(
                  sizing: StackFit.expand,
                  index: _restGarden ? 1 : 0,
                  children: [
                    TickerMode(
                      enabled: !_restGarden,
                      child: _gardenContent(context),
                    ),
                    TickerMode(
                      enabled: _restGarden,
                      child: RestingGardenView(
                        canvasOnly: true,
                        cameraGestures: true,
                        overviewRequested: _cultOverview,
                        nightOverride: _gardenNight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _floatingPanel(
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            action(
                              _gardenToolsOpen ? tr('도구 접기') : tr('도구 펼치기'),
                              Icons.tune,
                              () => setState(
                                () => _gardenToolsOpen = !_gardenToolsOpen,
                              ),
                              'fullscreen-tools-toggle',
                            ),
                            action(
                              _cultOverview ? tr('정원으로 돌아가기') : tr('정원 전체 지도'),
                              Icons.map_outlined,
                              () => setState(
                                () => _cultOverview = !_cultOverview,
                              ),
                              'fullscreen-map-toggle',
                            ),
                            action(
                              tr('전체화면 나가기'),
                              Icons.fullscreen_exit,
                              _plantSaving || _commitNeedsRecovery
                                  ? null
                                  : _exitFullscreenGarden,
                              'fullscreen-exit',
                            ),
                            const SoundToggleButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_gardenToolsOpen && _pendingSeed == null)
              Positioned(
                left: 6,
                bottom: 6,
                child: SafeArea(
                  top: false,
                  right: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: size.width * .46,
                      maxHeight: size.height * .58,
                    ),
                    child: _floatingPanel(
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _restGarden
                                    ? tr('쉬어가는 정원')
                                    : tr('보유 씨앗 {0}개', [data.seedTokens]),
                              ),
                              if (!_restGarden) ...[
                                action(
                                  tr('마음 심기'),
                                  Icons.spa_outlined,
                                  _canChangeGarden ? _plant : null,
                                  'fullscreen-plant',
                                ),
                                action(
                                  _cultWater ? tr('물주기 마치기') : tr('물주기'),
                                  Icons.water_drop_outlined,
                                  _canChangeGarden
                                      ? () => setState(() {
                                          _cultWater = !_cultWater;
                                          _cultOverview = false;
                                        })
                                      : null,
                                  'fullscreen-water',
                                ),
                                action(
                                  tr('내 식물'),
                                  Icons.local_florist_outlined,
                                  _canChangeGarden ? _myPlants : null,
                                  'fullscreen-plants',
                                ),
                                action(
                                  tr('꾸미기'),
                                  Icons.chair_outlined,
                                  _canChangeGarden
                                      ? () => _cultivationMenu('layout')
                                      : null,
                                  'fullscreen-decorate',
                                ),
                              ],
                              PopupMenuButton<String>(
                                tooltip: tr('정원 보기와 보조 메뉴'),
                                onSelected: (value) {
                                  if (value == 'cultivate' || value == 'rest') {
                                    _changeGarden(value == 'rest');
                                  } else if (value == 'care-guide') {
                                    _showCareGuide();
                                  } else {
                                    _cultivationMenu(value);
                                  }
                                },
                                enabled: _canChangeGarden,
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'cultivate',
                                    child: Text(tr('가꾸는 정원')),
                                  ),
                                  PopupMenuItem(
                                    value: 'rest',
                                    child: Text(tr('쉬어가는 정원')),
                                  ),
                                  if (!_restGarden) ...[
                                    PopupMenuItem(
                                      value: 'cat-rest',
                                      child: Text(tr('고양이 쉼터')),
                                    ),
                                    PopupMenuItem(
                                      value: 'styles',
                                      child: Text(tr('계절·배치 저장')),
                                    ),
                                    PopupMenuItem(
                                      value: 'care-guide',
                                      child: Text(tr('성장·보상 안내')),
                                    ),
                                  ],
                                  PopupMenuItem(
                                    value: 'day',
                                    child: Text(tr('햇살 정원 보기')),
                                  ),
                                  PopupMenuItem(
                                    value: 'night',
                                    child: Text(tr('반딧불이 정원 보기')),
                                  ),
                                  PopupMenuItem(
                                    value: 'auto-light',
                                    child: Text(tr('현재 시간에 맞추기')),
                                  ),
                                  if (!_restGarden) ...[
                                    PopupMenuItem(
                                      value: 'memory',
                                      child: Text(tr("기억의 나무")),
                                    ),
                                    PopupMenuItem(
                                      value: 'orchard',
                                      child: Text(tr("열매 정원")),
                                    ),
                                    PopupMenuItem(
                                      value: 'neighbors',
                                      child: Text(tr("이웃 정원")),
                                    ),
                                    PopupMenuItem(
                                      value: 'decorate',
                                      child: Text(tr('장식 고르기')),
                                    ),
                                  ],
                                ],
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(tr('정원 바꾸기 · 낮과 밤 ⋯')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!_restGarden &&
                (_pendingSeed != null || _focusedPlantId != null))
              Positioned(
                right: 6,
                bottom: 6,
                child: SafeArea(
                  top: false,
                  left: false,
                  child: SizedBox(
                    width: size.width * .51,
                    child: _floatingPanel(
                      _pendingSeed != null
                          ? _fullscreenPlacementControls(context)
                          : ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: size.height * .46,
                              ),
                              child: SingleChildScrollView(
                                child: _focusedPlantCard(data),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fullscreenPlacementControls(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: (MediaQuery.sizeOf(context).height * .24).clamp(70, 155),
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
                  onPressed: _plantSaving || _commitNeedsRecovery
                      ? null
                      : () => setState(() {
                          _pendingSeed = null;
                          _pendingMind = null;
                          _pendingMindOwner = null;
                          _plantPoint = null;
                          _plantError = null;
                          _movingPlant = false;
                        }),
                  child: Text(tr("취소")),
                ),
                FilledButton(
                  key: const Key('confirm-plant-location'),
                  style: FilledButton.styleFrom(foregroundColor: Colors.white),
                  onPressed:
                      _plantSaving ||
                          (!_commitNeedsRecovery && _placementError != null)
                      ? null
                      : _confirmPlant,
                  child: Text(
                    _plantSaving
                        ? tr('저장 중…')
                        : _commitNeedsRecovery
                        ? tr('저장 다시 확인')
                        : _movingPlant
                        ? tr('이 위치로 옮기기')
                        : tr('여기에 마음 심기 · 씨앗 1개'),
                  ),
                ),
              ],
            ),
            Text(
              _plantError ??
                  _placementError ??
                  (_movingPlant
                      ? tr("{0}를 이 자리로 옮길까요? 씨앗은 사용하지 않아요.", [
                          _pendingSeed!.label,
                        ])
                      : tr("{0}를 이 자리에 심을까요?", [_pendingSeed!.label])),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  void _showCareGuide() {
    final data = MongiGardenStore.instance.value;
    final received = data.careDays.contains(
      MongiGardenData.dayKey(DateTime.now()),
    );
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('성장·보상 안내'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                received
                    ? tr('오늘의 돌봄 선물은 이미 받았어요.')
                    : tr('오늘의 돌봄 선물을 아직 받지 않았어요.'),
              ),
              Text(
                tr(
                  '마음 기록·명상·조용히 쉬기의 일일 돌봄 선물은 함께 계산해요. 하루에 씨앗 1개와 빛의 정수 20을 한 번 받아요.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  '물주기는 식물마다 하루 한 번 성장에 반영돼요. 내 식물에서 물주기만 할 때 다음 성장까지 남은 횟수를 볼 수 있어요. 거름·햇볕 돌봄을 함께 하면 더 빨리 자랄 수 있어요.',
                ),
              ),
              Text(tr('며칠 쉬어도 식물의 성장 기록은 사라지지 않아요. 편할 때 다시 가꿔 주세요.')),
              const SizedBox(height: 12),
              Text(
                tr("현재 씨앗 {0}개 · 빛의 정수 {1}", [data.seedTokens, data.essence]),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(tr('같은 날 심은 식물이에요. 찾을 식물을 골라주세요.')),
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
        _message(saved ? tr('물을 주었어요. 함께 자라는 중이에요.') : tr('오늘은 이미 물을 주었어요.'));
    } catch (_) {
      if (mounted) _message(tr('물주기를 저장하지 못했어요. 다시 시도해 주세요.'));
    } finally {
      if (mounted) setState(() => _focusWaterSaving = false);
    }
  }

  Widget _focusedPlantCard(MongiGardenData data) {
    final seed = SeedType.byId(_focusedPlantId!);
    final watered = data.wateredToday(seed.id, DateTime.now());
    final name = Text(
      tr("내 {0} · {1}", [seed.label, seed.growthLabel(data.seeds[seed.id]!)]),
      key: const Key('focused-plant-name'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final close = IconButton(
      tooltip: tr('식물 선택 닫기'),
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
            ? tr('저장 중…')
            : watered
            ? tr('오늘 물주기 완료')
            : _justPlantedId == seed.id && !data.wateredOn.containsKey(seed.id)
            ? tr('첫 물 주기')
            : tr('물주기'),
      ),
    );
    final move = TextButton.icon(
      key: const Key('focused-plant-move'),
      onPressed: _focusWaterSaving ? null : () => _startMovingPlant(seed),
      icon: const Icon(Icons.open_with, size: 18),
      label: Text(tr('위치 옮기기')),
    );
    final memory = TextButton(
      onPressed: () => _memory(seed),
      key: const Key('focused-plant-memory'),
      child: Text(tr('마음 다시 읽기')),
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
                if (_mindLoadError) Text(tr('마음 기록을 불러오지 못했어요. 다시 열어 주세요.')),
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
    ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
    if (_plantPickerOpen || _pendingSeed != null) return;
    if (!_cultivationEnabled) setState(() => _cultivationActivated = true);
    _plantPickerOpen = true;
    final owner = CatCareService.localOwner;
    try {
      final choice = await Navigator.of(context).push<MindPlantingChoice>(
        MaterialPageRoute(builder: (_) => const MindPlantingScreen()),
      );
      if (!mounted || choice == null) return;
      if (owner != CatCareService.localOwner) {
        _message(tr('계정이 바뀌었어요. 마음 심기를 다시 열어 주세요.'));
        return;
      }
      if (choice.mind == null) {
        _focusPlant(choice.seed);
        if (choice.savedMind) _message(tr('이 식물에 마음을 남겼어요.'));
        if (choice.openMemory) await _memory(choice.seed);
        return;
      }
      setState(() {
        _movingPlant = false;
        _pendingSeed = choice.seed;
        _pendingMind = choice.mind;
        _pendingMindOwner = owner;
        _plantPoint = null;
        _plantError = null;
        _cultWater = false;
        _cultOverview = false;
      });
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
        ? Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: Text(tr("다시 불러오기"))),
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
            builder: (context, _) => GardenPersonalCanvas(
              prefetched: true,
              initialArtwork: _galleryArtwork,
              enabled: _canChangeGarden,
              topPadding: _landscapeRequested
                  ? 76
                  : (MediaQuery.textScalerOf(context).scale(14) > 20
                        ? 160
                        : 76),
              showControls: _cultivationEnabled,
              builder: (artwork) => GardenWorldView(
                personalArtwork: artwork,
                requestedRestItem: _requestedRestItem,
                restRequest: _restRequest,
                originalScenery: true,
                cameraGestures: !widget.embedded,
                nightOverride: _gardenNight,
                fillViewport:
                    _cultivationEnabled || immersive || _expandedGarden,
                immersive: !_cultivationEnabled && immersive,
                cultivationMode: _cultivationEnabled,
                focusVerticalBias: _cultivationEnabled && !_landscapeRequested
                    ? .04
                    : -.12,
                wateringRequested: _cultWater,
                placementSeed: _pendingSeed,
                placementCount: _movingPlant
                    ? (MongiGardenStore.instance.value.seeds[_pendingSeed
                              ?.id] ??
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
                  MaterialPageRoute<void>(
                    builder: (_) => const OrchardScreen(),
                  ),
                ),
                companionName: companionName,
                family: companion.journey.residents,
                activeCoat: companion.journey.coat ?? CompanionCoat.ginger,
                companionScale: companion.journey.visualScale,
                companionBondStage: companion.journey.stage,
                companionAutomaticBehavior:
                    companion.journeyReady &&
                    companion.journey.automaticBehavior,
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
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
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
                tr('고양이 정원'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleFont(fontSize: 19),
              ),
              backgroundColor: AppColors.bg0,
              actions: [
                IconButton(
                  key: const Key('open-plant-picker'),
                  tooltip: tr('씨앗과 나무 · 심은 식물 찾기'),
                  onPressed: _loading || _error != null ? null : _plant,
                  icon: const Icon(Icons.spa_outlined),
                ),
                _rotationButton(),
                IconButton(
                  tooltip: tr('열매 정원 · 창고'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OrchardScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.park_outlined),
                ),
                IconButton(
                  key: const Key('garden-exit-fullscreen'),
                  tooltip: tr('정원 메뉴 펼치기'),
                  onPressed: () => setState(() => _expandedGarden = false),
                  icon: const Icon(Icons.fullscreen_exit),
                ),
                IconButton(
                  tooltip: tr("고양이 선택 · 구독 기능"),
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
                    tr('나의 넓은 정원'),
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
                        tr("빛의 정수 {0}개", [data.essence]),
                        style: TextStyle(fontSize: 13),
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
                          label: Text(tr('돌보기')),
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
                          label: Text(tr("정원 소식")),
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
                          label: Text(tr('냥이 마을')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                _rotationButton(),
                IconButton(
                  tooltip: tr('열매 정원 · 창고'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OrchardScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.park_outlined),
                ),
                IconButton(
                  tooltip: tr("고양이 선택 · 구독 기능"),
                  onPressed: () => showCompanionCoats(context),
                  icon: const Icon(Icons.palette_outlined),
                ),
                IconButton(
                  key: const Key('garden-enter-fullscreen'),
                  tooltip: tr('정원 전체화면'),
                  onPressed: () => setState(() => _expandedGarden = true),
                  icon: const Icon(Icons.fullscreen),
                ),
                if (widget.onOpenCollection != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 8),
                    child: IconButton(
                      tooltip: tr('고양이와 정원 기록'),
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
                        tooltip: tr('정원 나가기'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      IconButton(
                        key: const Key('garden-portrait'),
                        iconSize: 18,
                        tooltip: tr('세로 정원으로 돌아가기'),
                        onPressed: _portraitGarden,
                        icon: const Icon(Icons.stay_current_portrait),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 700)
                        Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Text(
                            tr("마음냥 정원"),
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
