import '../../l10n/garden_copy.dart';
import '../../l10n/app_language.dart';
import '../../widgets/neighbor_news_bubble.dart';
import 'seasonal_garden_layer.dart';
import 'dart:typed_data';
import 'garden_basic_item_art.dart';
import 'garden_planting_hints.dart';
import 'storybook_garden.dart';
import '../../models/cat_visit.dart';
import '../../models/companion_coat.dart';
import '../../widgets/companion_coat_art.dart';
import '../../utils/companion_name.dart';
import '../../theme.dart';
import 'garden_grounded_art.dart';
import 'garden_cat_shadow.dart';
import 'garden_cat_pose.dart';
import 'garden_walking_cat.dart';
import 'garden_cat_response.dart';
import '../../widgets/companion_presence.dart';
import 'dart:math' as math;
import 'dart:async';
import '../models/garden_gifts.dart';
import 'garden_gift_art.dart';
import 'package:flutter/material.dart';
import '../models/garden_layout.dart';
import '../models/garden_life.dart';
import '../models/garden_decoration.dart';
import '../models/seed.dart';
import 'living_garden_scene.dart';
import 'garden_ambient.dart';

/// The camera moves; positions stay in world coordinates and survive resizing.
class GardenWorldView extends StatefulWidget {
  final String? requestedRestItem;
  final int restRequest;
  final Uint8List? personalArtwork;
  final String companionName;
  final VisitingCat? visitingHost, visitingGuest;
  final String visitActivity;
  final Map<CompanionCoat, int> family;
  final CompanionCoat? activeCoat;
  final VoidCallback? onCompanionCare, onOrchard;
  final double companionScale;
  final int companionBondStage;
  final bool companionAutomaticBehavior;
  final bool readOnly;

  /// Original open lawn is the saved, cultivatable garden. The illustrated
  /// landscape is used only by the separate, non-mutating resting space.
  final bool originalScenery;
  final bool? nightOverride;
  final DateTime Function()? clock;
  final int memoryDays, cheerFlowers;
  final int publicMemoryStage;
  final bool publicCheerBed;
  final List<String> flowerKinds;
  final List<GardenReaction> reactions;
  final VoidCallback? onMemoryTree, onCheerFlowers;
  final ValueChanged<bool>? onQuietChanged;
  final bool motionEnabled;
  final GardenLayout layout;
  final Map<String, int> seeds;

  /// Optional local fractional care; public snapshots keep their existing
  /// whole growth counts so published gardens need no server schema change.
  final Map<String, int> careRemainders;
  final List<String> decorations;
  final Future<void> Function(String id, Offset position) onMove;
  final ValueChanged<SeedType> onMemory;
  final VoidCallback onPlant, onDecorate;
  final Future<bool> Function(String id)? onWater;
  final bool preview;
  final String? previewDecorationId;
  final bool cameraGestures;

  /// Fill the available phone canvas; hide optional chrome until requested.
  final bool fillViewport;
  final double focusVerticalBias;
  final bool overviewRequested;
  final bool immersive;
  final String? focusPlantId;
  final int plantFocusRequest;
  final ValueChanged<SeedType>? onInspectPlant;
  final Map<String, String> wateredOn;
  final bool cultivationMode, wateringRequested;
  final SeedType? placementSeed;
  final int placementCount;
  final Offset? placementPoint;
  final ValueChanged<Offset>? onPlacementPoint;
  const GardenWorldView({
    super.key,
    this.personalArtwork,
    this.requestedRestItem,
    this.restRequest = 0,
    this.preview = false,
    this.previewDecorationId,
    this.cameraGestures = true,
    this.fillViewport = false,
    this.focusVerticalBias = -.12,
    this.overviewRequested = false,
    this.immersive = false,
    this.focusPlantId,
    this.plantFocusRequest = 0,
    this.onInspectPlant,
    this.wateredOn = const {},
    this.cultivationMode = false,
    this.wateringRequested = false,
    this.placementSeed,
    this.placementCount = 1,
    this.placementPoint,
    this.onPlacementPoint,
    this.onWater,
    this.companionName = '고양이',
    this.visitingHost,
    this.visitingGuest,
    this.visitActivity = 'greet',
    this.family = const {},
    this.activeCoat,
    this.onCompanionCare,
    this.onOrchard,
    this.companionScale = 1,
    this.companionBondStage = 0,
    this.companionAutomaticBehavior = true,
    this.readOnly = false,
    this.originalScenery = true,
    this.nightOverride,
    this.clock,
    this.publicMemoryStage = 0,
    this.publicCheerBed = false,
    this.flowerKinds = const [],
    this.reactions = const [],
    this.memoryDays = 0,
    this.cheerFlowers = 0,
    this.onMemoryTree,
    this.onCheerFlowers,
    this.onQuietChanged,
    this.motionEnabled = true,
    required this.layout,
    required this.seeds,
    this.careRemainders = const {},
    required this.decorations,
    required this.onMove,
    required this.onMemory,
    required this.onPlant,
    required this.onDecorate,
  });
  @override
  State<GardenWorldView> createState() => _GardenWorldViewState();
}

class _GardenWorldViewState extends State<GardenWorldView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  void _showGardenGoals() {
    final count = widget.seeds.values.fold<int>(0, (a, b) => a + b);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('조금씩 넓어지는 내 정원'), style: titleFont(fontSize: 24)),
              const SizedBox(height: 8),
              Text(tr('씨앗을 심고 돌보며 성장 기록을 쌓아요. 한 번 열린 땅은 계속 남아요.')),
              const SizedBox(height: 12),
              for (final zone in [1, 0, 2]) ...[
                ListTile(
                  leading: Icon(
                    widget.layout.isOpen(zone)
                        ? Icons.check_circle_outline
                        : Icons.lock_outline,
                  ),
                  title: Text(GardenLayout.nameForZone(zone)),
                  subtitle: Text(
                    widget.layout.isOpen(zone)
                        ? tr('열린 공간 · 심고 가꿀 수 있어요')
                        : gardenCopy('garden90.0', [
                            GardenLayout.goalForZone(zone),
                            count.clamp(0, GardenLayout.goalForZone(zone)),
                          ]),
                  ),
                  trailing: widget.layout.isOpen(zone)
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: widget.layout.isOpen(zone)
                      ? () {
                          Navigator.pop(sheetContext);
                          setState(() {
                            _zone = zone;
                            _overview = false;
                            _viewport = Size.zero;
                          });
                          _jump((zone + .5) / 3);
                        }
                      : null,
                ),
                if (!widget.layout.isOpen(zone))
                  LinearProgressIndicator(
                    value: (count / GardenLayout.goalForZone(zone)).clamp(
                      0.0,
                      1.0,
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                widget.layout.nextZone == null
                    ? tr('모든 구역이 열렸어요. 나만의 정원을 계속 가꿔요.')
                    : gardenCopy('garden90.1', [
                        widget.layout.remainingGrowth(count),
                      ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _overview = false, _fullTools = false;
  double _focusX = .5;
  void _closeFullTools() {
    _fullTools = false;
    _toolsOpen = false;
    _editing = false;
    _wateringMode = false;
    _selected = null;
  }

  bool get _showChrome =>
      !widget.immersive && (!widget.fillViewport || _fullTools);
  void _showCat() {
    _focusX = (_displayedMoment?.feet.dx ?? 1200) / 2400;
    setState(() => _overview = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _jump(_focusX, scale: _minScale);
    });
  }

  double _catSeconds = 0, _lastCatAir = 0;
  Offset? _catAnchor;
  String _restItem = 'decor:cat_cushion';
  String get _restName => _restItem.startsWith('seed:')
      ? tr('나무 그늘')
      : _restItem == 'decor:cat_basket'
      ? tr('바구니')
      : tr('방석');
  bool _onCushion = false;
  int? _appliedRestRequest;
  void _applyRequestedRest() {
    final target = widget.requestedRestItem;
    if (!mounted ||
        target == null ||
        widget.readOnly ||
        widget.placementSeed != null ||
        _appliedRestRequest == widget.restRequest ||
        !_items.contains(target))
      return;
    if (target.startsWith('seed:') &&
        (!SeedType.byId(target.substring(5)).isTree ||
            SeedType.byId(
                  target.substring(5),
                ).tierForCount(widget.seeds[target.substring(5)] ?? 0) <
                3))
      return;
    _appliedRestRequest = widget.restRequest;
    if (!_onCushion || _restItem != target) _toggleCushion(target: target);
    _jump(widget.layout.position(target).dx);
  }

  Offset _cushionFrom = const Offset(1200, 600);
  late final _cushion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  void _toggleCushion({String? target}) {
    final selected = target ?? _restItem;
    if (!_items.contains(selected) || widget.readOnly) return;
    setState(() {
      _onCushion = !_onCushion || _restItem != selected;
      _restItem = selected;
      _catWanders = false;
      _responseKind = null;
      _response.stop();
      if (_onCushion) {
        _cushionFrom = _displayedMoment?.feet ?? const Offset(1200, 600);
        final p = widget.layout.position(_restItem);
        final distance =
            (_cushionFrom - Offset(p.dx * 2400, p.dy * 800 - 12)).distance;
        _cushion.duration = Duration(
          milliseconds: (distance / 65 * 1000)
              .round()
              .clamp(800, 20000)
              .toInt(),
        );
        if (_air.isAnimating) {
          _cushion.forward(from: 0);
        } else {
          _cushion.value = 1;
        }
      } else {
        _cushion.stop();
        final feet = _displayedMoment?.feet ?? _cushionFrom;
        _catAnchor = Offset(
          feet.dx + (feet.dx > 2200 ? -120 : 120),
          (feet.dy + 30).clamp(40.0, 760.0).toDouble(),
        );
        _displayedMoment = GardenCatMoment(
          _catAnchor!,
          false,
          0,
          GardenCatMoment.depthSize(_catAnchor!.dy) * 1.25,
          tr('방석 옆에서 쉬는 고양이'),
        );
      }
    });
    _message(
      _onCushion
          ? gardenCopy('garden90.2', [_restName])
          : gardenCopy('garden90.3', [_restName]),
    );
  }

  Timer? _expiryTimer;
  final _seenReactions = <String>{};
  String? _responseKind;
  DateTime? _responseDeadline;
  bool get _hasResponse =>
      _responseKind != null &&
      !_onCushion &&
      !_quiet &&
      (_responseDeadline?.isAfter(DateTime.now()) ?? false);
  GardenCatMoment? _responseAnchor, _displayedMoment;
  late final _response = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final _air = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  late final _daylight = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );
  late final _water = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _wateringMode = false, _quiet = false;
  String? _waterTarget;
  bool _paused = false, _foreground = true;
  void _setQuiet(bool value) {
    setState(() {
      _quiet = value;
      if (value) {
        if (_onCushion && _cushion.value < 1) {
          _onCushion = false;
          _cushion.stop();
        }
        _response.stop();
        _responseKind = null;
      }
      _editing = false;
      _wateringMode = false;
      _selected = null;
    });
    widget.onQuietChanged?.call(value);
    _jump((_displayedMoment?.feet.dx ?? 1200) / 2400);
  }

  bool _waterSaving = false;
  Future<void> _waterPlant(String id) async {
    if (widget.readOnly || _waterSaving || !id.startsWith('seed:')) return;
    if (widget.onWater == null) {
      _message(tr('정원 연결을 확인한 뒤 다시 시도해 주세요.'));
      return;
    }
    setState(() => _waterSaving = true);
    try {
      final cared = await widget.onWater!(id.substring(5));
      if (!mounted) return;
      if (!cared) {
        _message(gardenCopy('garden90.4', [_label(id)]));
        return;
      }
      setState(() => _waterTarget = id);
      if (_air.isAnimating) _water.forward(from: 0);
      _message(gardenCopy('garden90.5', [_label(id)]));
    } catch (_) {
      if (mounted) _message(tr('물주기를 저장하지 못했어요. 다시 시도해 주세요.'));
    } finally {
      if (mounted) setState(() => _waterSaving = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _night = widget.nightOverride ?? _night;
    _overview = widget.overviewRequested;
    if (widget.preview && widget.previewDecorationId != null) {
      _focusX = widget.layout
          .position('decor:' + widget.previewDecorationId!)
          .dx;
      _selected = 'decor:' + widget.previewDecorationId!;
    }
    _wateringMode = widget.wateringRequested;
    if (widget.cultivationMode) {
      final requested = 'seed:' + (widget.focusPlantId ?? '');
      _focusX = _items.contains(requested) ? widget.layout.position(requested).dx : .5;
    }
    WidgetsBinding.instance.addObserver(this);
    _lightingTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshLighting(),
    );
    _response.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted)
        setState(() => _responseKind = null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _considerReactions();
        _applyRequestedRest();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) _refreshLighting();
    if (_foreground && mounted) setState(() {});
    _syncMotion();
  }

  bool get _nightForNow {
    final hour = (widget.clock ?? DateTime.now)().hour;
    return hour < 6 || hour >= 18;
  }

  Timer? _lightingTimer;
  void _refreshLighting() {
    if (!mounted || widget.nightOverride != null) return;
    final hour = (widget.clock ?? DateTime.now)().hour;
    final night = hour < 6 || hour >= 18;
    if (_night != night) setState(() => _night = night);
  }

  void _syncMotion() {
    final enabled =
        widget.motionEnabled &&
        !_paused &&
        _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (!enabled) {
      _cushion.stop();
      if (_onCushion &&
          (!widget.motionEnabled || MediaQuery.disableAnimationsOf(context)))
        _cushion.value = 1;
      _response.stop();
    } else if (_responseKind != null &&
        !_response.isAnimating &&
        _response.value < 1) {
      _response.forward();
    }
    if (enabled) {
      if (_onCushion && _cushion.value < 1 && !_cushion.isAnimating)
        _cushion.forward();
      if (!_air.isAnimating) _air.repeat();
      if (!_daylight.isAnimating) _daylight.repeat();
    } else {
      _air.stop();
      _daylight.stop();
      _water.stop();
      _water.value = 0;
    }
  }

  final _camera = TransformationController();
  Size _viewport = Size.zero;
  double _minScale = .5;
  Matrix4? _cameraBeforeMap;
  Size? _viewportBeforeMap;
  bool _restoreMapCamera = false;
  final Map<int, Offset> _pointerOrigins = {};
  bool _cameraGesture = false;

  int _zone = 1;
  String? _highlightPlant;
  String? get _inspectedPlant =>
      widget.cultivationMode &&
          !widget.readOnly &&
          !_overview &&
          widget.placementSeed == null &&
          widget.focusPlantId != null &&
          _items.contains('seed:${widget.focusPlantId}')
      ? 'seed:${widget.focusPlantId}'
      : null;
  Timer? _highlightTimer;
  bool _toolsOpen = false;
  bool _catWanders = false;
  bool _loafRest = false;
  bool _editing = false, _saving = false;
  late bool _night = _nightForNow;
  String? _selected;
  MapEntry<String, Offset>? _undo;
  List<String> get _items => [
    ...SeedType.all
        .where((s) => (widget.seeds[s.id] ?? 0) > 0)
        .map((s) => 'seed:${s.id}'),
    ...GardenDecoration.all
        .where((d) => widget.decorations.contains(d.id))
        .map((d) => 'decor:${d.id}'),
  ];
  String _label(String id) => id.startsWith('seed:')
      ? SeedType.byId(id.substring(5)).label
      : GardenDecoration.byId(id.substring(6)).label;
  @override
  void didUpdateWidget(covariant GardenWorldView oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _considerReactions();
    });
    super.didUpdateWidget(oldWidget);
    if (widget.preview &&
        widget.previewDecorationId != null &&
        widget.previewDecorationId != oldWidget.previewDecorationId) {
      _focusX = widget.layout
          .position('decor:' + widget.previewDecorationId!)
          .dx;
      _selected = 'decor:' + widget.previewDecorationId!;
      _viewport = Size.zero;
    }
    if (widget.restRequest != oldWidget.restRequest &&
        widget.requestedRestItem != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyRequestedRest();
      });
    }
    if (_onCushion &&
        (widget.readOnly ||
            !_items.contains(_restItem) ||
            (_restItem.startsWith('seed:') &&
                SeedType.byId(
                      _restItem.substring(5),
                    ).tierForCount(widget.seeds[_restItem.substring(5)] ?? 0) <
                    3) ||
            widget.layout.position(_restItem) !=
                oldWidget.layout.position(_restItem))) {
      _onCushion = false;
      _cushion.stop();
      _catAnchor = null;
      _displayedMoment = null;
    }
    if (widget.nightOverride != oldWidget.nightOverride) {
      _night = widget.nightOverride ?? (_nightForNow);
    }
    if (widget.cultivationMode &&
        widget.placementSeed != null &&
        oldWidget.placementSeed?.id != widget.placementSeed!.id) {
      // Begin choosing on the original central lawn; preserve all saved positions.
      _focusX = .5;
      _overview = false;
      _viewport = Size.zero;
      _wateringMode = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _jump(.5, scale: _minScale);
      });
    }
    if (!widget.readOnly &&
        widget.plantFocusRequest != oldWidget.plantFocusRequest) {
      final id = 'seed:${widget.focusPlantId}';
      if (_items.contains(id)) {
        final point = widget.layout.position(id);
        _focusX = point.dx;
        _overview = false;
        _viewport = Size.zero;
        _highlightPlant = id;

        _highlightTimer?.cancel();
        _highlightTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _highlightPlant = null);
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted)
            _jump(
              point.dx,
              y: point.dy + widget.focusVerticalBias,
              scale: widget.cultivationMode ? _plantFocusScale(point) : null,
            );
        });
      }
    }
    if (widget.visitingGuest != null &&
        oldWidget.visitActivity != widget.visitActivity) {
      _catWanders = widget.visitActivity == 'walk';
    }
    if ((widget.fillViewport && !oldWidget.fillViewport) ||
        (widget.immersive && !oldWidget.immersive)) {
      _closeFullTools();
    }
    if (widget.overviewRequested != oldWidget.overviewRequested) {
      if (widget.overviewRequested) {
        _cameraBeforeMap = Matrix4.copy(_camera.value);
        _viewportBeforeMap = _viewport;
      } else {
        _restoreMapCamera =
            _cameraBeforeMap != null &&
            widget.plantFocusRequest == oldWidget.plantFocusRequest &&
            widget.placementSeed == oldWidget.placementSeed;
      }
      _overview = widget.overviewRequested;
      _viewport = Size.zero;
    }
    if (widget.wateringRequested != oldWidget.wateringRequested) {
      _wateringMode = widget.wateringRequested;
    }
    _syncMotion();
    if (!_items.contains(_selected)) _selected = null;
    if (_undo != null && !_items.contains(_undo!.key)) _undo = null;
  }

  void _restoreCamera(Matrix4 saved, Size from, Size to) {
    if (from == to) {
      _camera.value = saved.clone();
      return;
    }
    // Preserve the world point under the old viewport centre and zoom relative
    // to cover, rather than interpreting old screen pixels in the new aspect.
    final inverse = Matrix4.inverted(saved);
    final center = MatrixUtils.transformPoint(
      inverse,
      from.center(Offset.zero),
    );
    final oldCover = math.max(from.width / 2400, from.height / 800);
    final newCover = math.max(to.width / 2400, to.height / 800);
    _jump(
      center.dx / 2400,
      y: center.dy / 800,
      scale: newCover * saved.getMaxScaleOnAxis() / oldCover,
    );
  }

  ButtonStyle _chipStyle(Color bg, Color fg, {bool active = false}) =>
      TextButton.styleFrom(
        backgroundColor: active ? fg : bg,
        foregroundColor: active ? Colors.white : fg,
        textStyle: pathLabelFont(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: const StadiumBorder(),
        minimumSize: const Size(0, 44),
      );

  double _plantFocusScale(Offset point) {
    // A portrait overlay covers the lower lawn. Near its bottom edge, a
    // closer camera keeps the saved root visible without moving the plant.
    final zoom = widget.focusVerticalBias > 0
        ? math.max(1.5, .48 / (1 - point.dy).clamp(.09, 1)).clamp(1.5, 4)
        : 1.25;
    return _minScale * zoom;
  }

  void _jump(double x, {double? scale, double y = .5}) {
    final s = (scale ?? _camera.value.getMaxScaleOnAxis())
        .clamp(
          _minScale,
          math.max(
            _minScale,
            math.max(_viewport.width / 2400, _viewport.height / 800) * 4,
          ),
        )
        .toDouble();
    final dx = 2400 * s < _viewport.width
        ? (_viewport.width - 2400 * s) / 2
        : (_viewport.width / 2 - x * 2400 * s).clamp(
            math.min(0.0, _viewport.width - 2400 * s),
            0.0,
          );
    final dy = 800 * s < _viewport.height
        ? (_viewport.height - 800 * s) / 2
        : (_viewport.height / 2 - y * 800 * s).clamp(
            math.min(0.0, _viewport.height - 800 * s),
            0.0,
          );
    _camera.value = Matrix4.diagonal3Values(s, s, s)
      ..setTranslationRaw(dx.toDouble(), dy.toDouble(), 0);
  }

  void _zoom(double factor) {
    final center = _camera.toScene(
      Offset(_viewport.width / 2, _viewport.height / 2),
    );
    _jump(
      center.dx / 2400,
      y: center.dy / 800,
      scale: _camera.value.getMaxScaleOnAxis() * factor,
    );
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
  Future<void> _place(Offset point) async {
    final id = _selected;
    if (widget.readOnly || !_editing || id == null || _saving) return;
    final normalized = Offset(point.dx / 2400, point.dy / 800);
    final error = widget.layout.placementError(id, normalized, _items);
    if (error != null) {
      _message(error);
      return;
    }
    final before = widget.layout.position(id);
    setState(() => _saving = true);
    try {
      await widget.onMove(id, normalized);
      if (!mounted) return;
      setState(() {
        _undo = MapEntry(id, before);
        _selected = null;
      });
    } catch (_) {
      if (mounted) _message(tr('위치를 저장하지 못했어요. 다시 시도해 주세요.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _undoMove() async {
    final last = _undo;
    if (widget.readOnly || last == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onMove(last.key, last.value);
      if (mounted) setState(() => _undo = null);
    } catch (_) {
      if (mounted) _message(tr('되돌리지 못했어요. 자리가 비어 있는지 확인해 주세요.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _lightingTimer?.cancel();
    _highlightTimer?.cancel();
    _expiryTimer?.cancel();
    _cushion.dispose();
    _response.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _air.dispose();
    _daylight.dispose();
    _water.dispose();
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return widget.cultivationMode
        ? _canvas(context)
        : widget.immersive
        ? Stack(
            fit: StackFit.expand,
            children: [
              _canvas(context),
              Positioned(
                top: 8,
                right: 8,
                width: 300,
                child: SafeArea(bottom: false, child: _viewControls()),
              ),
              if (!widget.preview && !widget.readOnly && _toolsOpen)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 68,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * .45,
                      ),
                      child: SingleChildScrollView(child: _gardenControls()),
                    ),
                  ),
                ),
              if (!widget.preview)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: SafeArea(top: false, child: _storybookToolbar()),
                ),
            ],
          )
        : Column(
            children: [
              if (!_quiet && !widget.preview && _showChrome) _viewControls(),
              if (!_quiet && !widget.preview && _showChrome)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Tooltip(
                        message: _catWanders
                            ? tr('고양이 앉아서 쉬기')
                            : tr('고양이 산책하기'),
                        child: FilterChip(
                          selected: _catWanders,
                          avatar: Icon(
                            _catWanders ? Icons.directions_walk : Icons.weekend,
                            size: 18,
                          ),
                          label: Text(_catWanders ? tr('산책 켜짐') : tr('산책 꺼짐')),
                          onSelected: (v) => setState(() {
                            _catWanders = v;
                            if (v) {
                              _onCushion = false;
                              _cushion.stop();
                            }
                          }),
                        ),
                      ),
                      Tooltip(
                        message: _paused ? tr('정원 움직임 재생') : tr('정원 움직임 멈추기'),
                        child: ActionChip(
                          avatar: Icon(
                            _air.isAnimating ? Icons.pause : Icons.play_arrow,
                            size: 18,
                          ),
                          label: Text(
                            _air.isAnimating ? tr('움직임 켜짐') : tr('움직임 꺼짐'),
                          ),
                          onPressed: () {
                            if (!widget.motionEnabled ||
                                MediaQuery.disableAnimationsOf(context)) {
                              _message(
                                tr('앱 또는 기기의 움직임 설정이 꺼져 있어요. 설정에서 켜 주세요.'),
                              );
                              return;
                            }
                            setState(() => _paused = !_paused);
                            _syncMotion();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: Center(child: _canvas(context))),
              if (widget.fillViewport && !_quiet)
                SafeArea(
                  top: false,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton.icon(
                        key: const Key('garden-show-cat'),
                        onPressed: _showCat,
                        icon: const Icon(Icons.pets_outlined),
                        label: Text(tr('고양이 보기')),
                      ),
                      TextButton.icon(
                        key: const Key('garden-show-all'),
                        onPressed: () => setState(() {
                          _overview = true;
                          _viewport = Size.zero;
                        }),
                        icon: const Icon(Icons.panorama_outlined),
                        label: Text(tr('정원 전체')),
                      ),
                      TextButton.icon(
                        key: const Key('garden-toggle-tools'),
                        onPressed: () => setState(() {
                          if (_fullTools) {
                            _closeFullTools();
                          } else {
                            _fullTools = true;
                          }
                        }),
                        icon: Icon(_fullTools ? Icons.expand_less : Icons.tune),
                        label: Text(_fullTools ? tr('도구 접기') : tr('도구')),
                      ),
                    ],
                  ),
                ),
              if (_quiet && !widget.preview)
                SafeArea(
                  top: false,
                  child: TextButton.icon(
                    onPressed: () => _setQuiet(false),
                    icon: const Icon(Icons.close),
                    label: Text(tr('쉬기 마치기')),
                  ),
                ),
              if (!_quiet && !widget.preview && _showChrome) _gardenControls(),
            ],
          );
  }

  Widget _storybookToolbar() {
    Widget button(
      String key,
      String label,
      IconData icon,
      Color color,
      VoidCallback? action,
    ) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(25),
        elevation: 2,
        shadowColor: const Color(0x22746345),
        child: InkWell(
          key: ValueKey(key),
          onTap: action,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            constraints: BoxConstraints(
              minWidth: widget.immersive ? 60 : 80,
              minHeight: widget.immersive ? 48 : 72,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.immersive ? 8 : 12,
              vertical: widget.immersive ? 4 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: const Color(0xFFFDF7E7), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: widget.immersive ? 18 : 28,
                  color: const Color(0xFF8B806C),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: titleFont(
                    fontSize: widget.immersive ? 12 : 16,
                    color: const Color(0xFF786B59),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              'storybook-loaf',
              _loafRest ? tr('식빵 끝내기') : tr('식빵 쉬기'),
              Icons.pets_outlined,
              const Color(0xFFF4E5D8),
              () => setState(() {
                _loafRest = !_loafRest;
                if (_loafRest) _catWanders = false;
              }),
            ),
            if (!widget.readOnly) ...[
              button(
                'garden-growth-goals',
                tr('정원 넓히기'),
                Icons.map_outlined,
                const Color(0xFFE8EDD7),
                _showGardenGoals,
              ),
              button(
                'storybook-water',
                _wateringMode ? tr('물주기 마치기') : tr('물주기'),
                Icons.water_drop_outlined,
                const Color(0xFFF9EBCB),
                _saving
                    ? null
                    : () => setState(() {
                        _wateringMode = !_wateringMode;
                        _editing = false;
                        _selected = null;
                      }),
              ),
              button(
                'storybook-plant',
                tr('씨앗 심기'),
                Icons.spa_outlined,
                const Color(0xFFF6EAD1),
                _saving ? null : widget.onPlant,
              ),
              button(
                'storybook-decorate',
                _toolsOpen ? tr('도구 접기') : tr('꾸미기'),
                Icons.local_florist_outlined,
                const Color(0xFFF6DEDB),
                () => setState(() => _toolsOpen = !_toolsOpen),
              ),
              if (widget.onOrchard != null)
                button(
                  'storybook-storage',
                  tr('창고'),
                  Icons.inventory_2_outlined,
                  const Color(0xFFF4DFCC),
                  widget.onOrchard,
                ),
            ],
            button(
              'storybook-overview',
              tr('전체보기'),
              Icons.panorama_outlined,
              const Color(0xFFE8EDD7),
              () {
                setState(() {
                  _overview = !_overview;
                  _viewport = Size.zero;
                });
                _jump(.5, scale: _minScale);
              },
            ),
            if (widget.readOnly)
              button(
                'storybook-cat',
                tr('고양이 보기'),
                Icons.pets_outlined,
                const Color(0xFFE8EDD7),
                _showCat,
              ),
          ],
        ),
      ),
    );
  }

  Widget _viewControls() => Container(
    decoration: BoxDecoration(
      color: AppColors.bg0,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFF3EBDD)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.catSageBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.sageLine),
              ),
              child: DropdownButton<int>(
                value: _zone,
                isDense: widget.immersive,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: AppColors.bg1,
                iconEnabledColor: AppColors.catSage,
                style: bodyFont(
                  fontSize: widget.immersive ? 12 : 14,
                  color: AppColors.ink,
                ),
                items: [
                  for (var zone = 0; zone < 3; zone++)
                    DropdownMenuItem(
                      value: zone,
                      child: Text(
                        '${widget.layout.isOpen(zone) ? '' : '🔒 '}' +
                            [
                              tr('꽃밭'),
                              gardenCopy('garden90.6', [
                                companionDisplayName(widget.companionName),
                              ]),
                              tr('나무 뜰'),
                            ][zone],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (zone) {
                  if (zone == null) return;
                  setState(() => _zone = zone);
                  _jump((zone + .5) / 3);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: _night ? tr('햇살 정원') : tr('별빛 정원'),
            onPressed: () => setState(() => _night = !_night),
            icon: Icon(
              _night ? Icons.nightlight_round : Icons.wb_sunny_outlined,
              size: 20,
            ),
            constraints: const BoxConstraints.tightFor(width: 36, height: 40),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            tooltip: tr('정원 축소'),
            onPressed: () => _zoom(.8),
            icon: const Icon(Icons.remove, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.blobMint,
              foregroundColor: AppColors.blobMintAccent,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 3),
          IconButton(
            tooltip: tr('정원 확대'),
            onPressed: () => _zoom(1.25),
            icon: const Icon(Icons.add, size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.blobMint,
              foregroundColor: AppColors.blobMintAccent,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 3),
          PopupMenuButton<String>(
            tooltip: tr('보기 설정'),
            color: AppColors.bg1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: AppColors.blobLavender,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune,
                size: 18,
                color: AppColors.blobLavenderAccent,
              ),
            ),
            onSelected: (value) {
              if (value == 'reset') {
                setState(() => _zone = 1);
                _jump(.5, scale: _minScale);
              } else if (value == 'light') {
                setState(() => _night = !_night);
              } else if (value == 'cat') {
                setState(() {
                  _catWanders = !_catWanders;
                  if (_catWanders) {
                    _onCushion = false;
                    _cushion.stop();
                  }
                });
              } else if (value == 'motion') {
                setState(() => _paused = !_paused);
                _syncMotion();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'reset',
                child: Text(
                  tr('기본 크기로 보기'),
                  style: bodyFont(color: AppColors.ink),
                ),
              ),
              PopupMenuItem(
                value: 'cat',
                child: Text(
                  _catWanders ? tr('고양이 앉아서 쉬기') : tr('고양이 산책하기'),
                  style: bodyFont(
                    fontSize: widget.immersive ? 12 : 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'light',
                child: Text(
                  _night ? tr('햇살 정원') : tr('별빛 정원'),
                  style: bodyFont(
                    fontSize: widget.immersive ? 12 : 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'motion',
                child: Text(
                  _paused ? tr('정원 움직임 재생') : tr('정원 움직임 멈추기'),
                  style: bodyFont(
                    fontSize: widget.immersive ? 12 : 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _gardenControls() => Container(
    decoration: BoxDecoration(
      color: AppColors.bg0,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .05),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.readOnly)
              TextButton.icon(
                onPressed: _showGardenGoals,
                icon: const Icon(Icons.map_outlined),
                label: Text(tr('정원 넓히기 · 목표 보기')),
              ),
            Text(
              _saving
                  ? tr('위치를 저장하고 있어요…')
                  : _wateringMode
                  ? tr('꽃이나 나무를 눌러 주세요. 하루 한 번 돌보면 자라요.')
                  : _editing
                  ? (_selected == null
                        ? tr('아이템을 고른 뒤, 원하는 잔디를 눌러 주세요.')
                        : gardenCopy('garden90.7', [_label(_selected!)]))
                  : tr('좌우로 산책하고, 두 손가락으로 가까이 살펴보세요.'),
              textAlign: TextAlign.center,
              style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
            ),
            if (_editing && _items.isNotEmpty)
              SizedBox(
                height: 58,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (context, i) => Center(
                    child: ChoiceChip(
                      label: Text(_label(_items[i])),
                      selected: _selected == _items[i],
                      onSelected: _saving
                          ? null
                          : (_) {
                              setState(() => _selected = _items[i]);
                              _jump(widget.layout.position(_items[i]).dx);
                            },
                    ),
                  ),
                ),
              ),
            if (_editing && _items.isEmpty)
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(tr('씨앗을 심거나 장식을 놓으면 여기서 옮길 수 있어요.')),
              ),
            if (!widget.readOnly)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TextButton.icon(
                  onPressed: () => setState(() => _toolsOpen = !_toolsOpen),
                  style: _chipStyle(
                    AppColors.catSageBg,
                    AppColors.catSage,
                    active: _toolsOpen,
                  ),
                  icon: Icon(_toolsOpen ? Icons.expand_less : Icons.tune),
                  label: Text(_toolsOpen ? tr('도구 접기') : tr('돌보기 · 꾸미기 · 추억')),
                ),
              ),
            if (!widget.readOnly && _toolsOpen)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .28,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                  _wateringMode = !_wateringMode;
                                  _editing = false;
                                  _selected = null;
                                }),
                          style: _chipStyle(
                            AppColors.blobMint,
                            AppColors.blobMintAccent,
                            active: _wateringMode,
                          ),
                          icon: Icon(
                            _wateringMode
                                ? Icons.check
                                : Icons.water_drop_outlined,
                          ),
                          label: Text(
                            _waterSaving
                                ? tr('돌봄 저장 중…')
                                : _wateringMode
                                ? tr('물주기 마치기')
                                : tr("물 주기"),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                  _editing = !_editing;
                                  _wateringMode = false;
                                  _selected = null;
                                }),
                          style: _chipStyle(
                            AppColors.blobPeriwinkle,
                            AppColors.blobPeriwinkleAccent,
                            active: _editing,
                          ),
                          icon: Icon(_editing ? Icons.check : Icons.open_with),
                          label: Text(_editing ? tr('배치 완료') : tr('배치 모드')),
                        ),
                        if (widget.onOrchard != null)
                          TextButton.icon(
                            onPressed: widget.onOrchard,
                            icon: const Icon(Icons.shopping_basket_outlined),
                            label: Text(tr('열매 정원 · 창고')),
                          ),
                        if (widget.onMemoryTree != null)
                          TextButton.icon(
                            onPressed: widget.onMemoryTree,
                            style: _chipStyle(
                              AppColors.blobButter,
                              AppColors.blobButterAccent,
                            ),
                            icon: const Icon(Icons.park_outlined),
                            label: Text(tr("기억의 나무")),
                          ),
                        if (widget.onCheerFlowers != null)
                          TextButton.icon(
                            onPressed: widget.onCheerFlowers,
                            style: _chipStyle(
                              AppColors.blobRose,
                              AppColors.blobRoseAccent,
                            ),
                            icon: const Icon(Icons.local_florist_outlined),
                            label: Text(tr('응원 꽃')),
                          ),
                        TextButton.icon(
                          onPressed: () => _setQuiet(true),
                          style: _chipStyle(
                            AppColors.blobLavender,
                            AppColors.blobLavenderAccent,
                          ),
                          icon: const Icon(Icons.weekend_outlined),
                          label: Text(tr('잠깐 쉬기')),
                        ),
                        TextButton.icon(
                          onPressed: _saving ? null : widget.onPlant,
                          style: _chipStyle(
                            AppColors.blobPeach,
                            AppColors.blobPeachAccent,
                          ),
                          icon: const Icon(Icons.grass),
                          label: Text(tr('씨앗 심기')),
                        ),
                        TextButton.icon(
                          onPressed: _saving ? null : widget.onDecorate,
                          style: _chipStyle(
                            AppColors.blobButter,
                            AppColors.blobButterAccent,
                          ),
                          icon: const Icon(Icons.chair_outlined),
                          label: Text(tr('장식')),
                        ),
                        if (_undo != null)
                          TextButton.icon(
                            onPressed: _saving ? null : _undoMove,
                            style: _chipStyle(AppColors.bg2, AppColors.inkSoft),
                            icon: const Icon(Icons.undo),
                            label: Text(tr("되돌리기")),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _canvas(BuildContext context) => _GardenViewportFrame(
    fill: widget.immersive || widget.fillViewport,
    aspectRatio: widget.preview ? 2.35 : (_overview ? 3 : 1.25),
    child: LayoutBuilder(
      key: const Key('garden-canvas'),
      builder: (context, box) {
        final size = box.biggest;
        if (size != _viewport) {
          final previousSize = _viewport;
          final previousCamera = _camera.value.clone();
          _viewport = size;
          _minScale = _overview
              ? math.min(size.width / 2400, size.height / 800)
              : math.max(size.width / 2400, size.height / 800);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (_restoreMapCamera &&
                  _cameraBeforeMap != null &&
                  _viewportBeforeMap != null &&
                  !_viewportBeforeMap!.isEmpty) {
                _restoreMapCamera = false;
                _restoreCamera(_cameraBeforeMap!, _viewportBeforeMap!, size);
                return;
              }
              _restoreMapCamera = false;
              if (!_overview && !previousSize.isEmpty) {
                _restoreCamera(previousCamera, previousSize, size);
                return;
              }
              _jump(
                _quiet && widget.decorations.contains('bench')
                    ? widget.layout.position('decor:bench').dx
                    : (_overview ? .5 : _focusX),
                scale: _overview || _inspectedPlant == null
                    ? _minScale
                    : _plantFocusScale(
                        widget.layout.position(_inspectedPlant!),
                      ),
                y: _overview || _inspectedPlant == null
                    ? .5
                    : widget.layout.position(_inspectedPlant!).dy +
                          widget.focusVerticalBias,
              );
            }
          });
        }
        final sorted = [..._items]
          ..sort(
            (a, b) => widget.layout
                .position(a)
                .dy
                .compareTo(widget.layout.position(b).dy),
          );
        return Listener(
          onPointerDown: (e) {
            if (_pointerOrigins.isEmpty) _cameraGesture = false;
            _pointerOrigins[e.pointer] = e.position;
            if (_pointerOrigins.length > 1) _cameraGesture = true;
          },
          onPointerMove: (e) {
            final origin = _pointerOrigins[e.pointer];
            if (origin != null && (e.position - origin).distance > 8)
              _cameraGesture = true;
          },
          onPointerUp: (e) => _pointerOrigins.remove(e.pointer),
          onPointerCancel: (e) {
            _pointerOrigins.remove(e.pointer);
            _cameraGesture = true;
          },
          child: ClipRect(
            child: InteractiveViewer(
              key: const Key('garden-world-camera'),
              panEnabled: widget.cameraGestures,
              scaleEnabled: widget.cameraGestures,
              transformationController: _camera,
              constrained: false,
              alignment: Alignment.topLeft,
              minScale: _minScale,
              maxScale: math.max(size.width / 2400, size.height / 800) * 4,
              child: GestureDetector(
                onTapUp: (e) {
                  if (_cameraGesture) return;
                  if (widget.placementSeed != null && !widget.readOnly) {
                    widget.onPlacementPoint?.call(
                      Offset(
                        e.localPosition.dx / 2400,
                        e.localPosition.dy / 800,
                      ),
                    );
                  } else {
                    _place(e.localPosition);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  key: const Key('garden-world-ground'),
                  width: 2400,
                  height: 800,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: widget.originalScenery
                            ? Image.asset(
                                'assets/living_garden/cultivation_${_night ? 'night' : 'day'}.png',
                                key: const Key('original-garden-backdrop'),
                                fit: BoxFit.fill,
                                excludeFromSemantics: true,
                              )
                            : StorybookBackdrop(night: _night),
                      ),
                      if (_inspectedPlant != null)
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(
                              key: Key('plant-focus-backdrop'),
                              color: Color(0x24000000),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: widget.originalScenery
                                  ? GardenAtmosphere.animated(
                                      _air,
                                      _night,
                                      daylight: _daylight,
                                      openLawn: true,
                                    )
                                  : StorybookAtmosphere(_air, _night),
                            ),
                          ),
                        ),
                      ),
                      if (_editing)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(painter: _GroundGrid()),
                          ),
                        ),
                      if (widget.placementSeed != null && !widget.readOnly)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              key: const Key('planting-available-hints'),
                              painter: GardenPlantingHints(
                                points: widget.layout.plantingHints(
                                  'seed:${widget.placementSeed!.id}',
                                  _items,
                                ),
                                selected: widget.placementPoint,
                                validSelection:
                                    widget.placementPoint != null &&
                                    widget.layout.placementError(
                                          'seed:${widget.placementSeed!.id}',
                                          widget.placementPoint!,
                                          _items,
                                        ) ==
                                        null,
                                night: _night,
                              ),
                            ),
                          ),
                        ),
                      if (!widget.readOnly)
                        for (final id in sorted.where(
                          (id) => id.startsWith('seed:'),
                        ))
                          Positioned(
                            left: widget.layout.position(id).dx * 2400 - 38,
                            top: widget.layout.position(id).dy * 800 - 9,
                            width: 76,
                            height: 20,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                key: ValueKey('plant-soil-$id'),
                                decoration: BoxDecoration(
                                  color: const Color(0xBBA88B65),
                                  border: Border.all(
                                    color: const Color(0xCCDCC8A1),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                            ),
                          ),
                      if (!widget.readOnly &&
                          (_inspectedPlant ?? _highlightPlant) != null &&
                          _items.contains(_inspectedPlant ?? _highlightPlant))
                        Positioned(
                          key: const Key('located-plant-highlight'),
                          left:
                              widget.layout
                                      .position(
                                        (_inspectedPlant ?? _highlightPlant)!,
                                      )
                                      .dx *
                                  2400 -
                              78,
                          top:
                              widget.layout
                                      .position(
                                        (_inspectedPlant ?? _highlightPlant)!,
                                      )
                                      .dy *
                                  800 -
                              28,
                          width: 156,
                          height: 56,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFE7A1),
                                  width: 4,
                                ),
                                color: const Color(0x33FFF0AB),
                              ),
                            ),
                          ),
                        ),
                      if (!widget.readOnly || !widget.originalScenery)
                        const Positioned.fill(child: SeasonalGardenLayer()),
                      _sceneLayer(sorted),
                      if (widget.placementSeed != null &&
                          widget.placementPoint != null &&
                          !widget.readOnly &&
                          widget.layout.placementError(
                                'seed:${widget.placementSeed!.id}',
                                widget.placementPoint!,
                                _items,
                              ) ==
                              null)
                        _placementPreview(),
                      if (!widget.originalScenery)
                        Positioned.fill(
                          child: StorybookForeground(
                            clock: _air,
                            camera: _camera,
                            night: _night,
                          ),
                        ),
                      ..._reactionSprites(),
                      if (_waterTarget != null && _items.contains(_waterTarget))
                        Positioned(
                          left:
                              widget.layout.position(_waterTarget!).dx * 2400 -
                              70,
                          top:
                              widget.layout.position(_waterTarget!).dy * 800 -
                              160,
                          width: 140,
                          height: 170,
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: GardenWaterDrops(_water),
                            ),
                          ),
                        ),
                      for (final zone in [0, 2])
                        if (!widget.layout.isOpen(zone))
                          Positioned(
                            left: zone * 800.0,
                            top: 0,
                            width: 800,
                            height: 800,
                            child: widget.immersive
                                ? Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 30,
                                      ),
                                      child: Material(
                                        color: const Color(0xDDFBFAF4),
                                        borderRadius: BorderRadius.circular(24),
                                        child: TextButton.icon(
                                          onPressed: widget.readOnly
                                              ? null
                                              : _showGardenGoals,
                                          icon: const Icon(
                                            Icons.lock_outline,
                                            size: 18,
                                          ),
                                          label: Text(
                                            zone == 0
                                                ? tr('꽃밭 · 성장하면 열려요')
                                                : tr('나무 뜰 · 성장하면 열려요'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : ColoredBox(
                                    color: const Color(0x806D816C),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.bg1,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: AppColors.sageLine,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.spa_outlined,
                                              size: 38,
                                              color: AppColors.catSage,
                                            ),
                                            Text(
                                              zone == 0
                                                  ? tr('조금씩 열리는 꽃밭')
                                                  : tr('나무를 위한 넓은 뜰'),
                                              style: titleFont(
                                                fontSize: 22,
                                                color:
                                                    AppColors.titlePastelGreen,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              gardenCopy('garden90.8', [
                                                zone == 0 ? 3 : 8,
                                              ]),
                                              textAlign: TextAlign.center,
                                              style: bodyFont(
                                                fontSize: 15,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            Text(
                                              tr('한 번 열린 공간은 그대로 남아요'),
                                              style: bodyFont(
                                                fontSize: 13,
                                                color: AppColors.inkSoft,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                      if (widget.placementSeed != null && !widget.readOnly)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (e) {
                              if (!_cameraGesture)
                                widget.onPlacementPoint?.call(
                                  Offset(
                                    e.localPosition.dx / 2400,
                                    e.localPosition.dy / 800,
                                  ),
                                );
                            },
                            child: const ColoredBox(color: Colors.transparent),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  int get _visibleFlowerCount => widget.readOnly
      ? (widget.publicCheerBed
            ? (widget.flowerKinds.isEmpty ? 3 : widget.flowerKinds.length)
            : 0)
      : widget.cheerFlowers;

  void _considerReactions() {
    final active = widget.reactions
        .where((r) => r.activeAt(DateTime.now()))
        .toList();
    final fresh = active
        .where(
          (r) => !_seenReactions.contains(
            '${r.kind}:${r.expiresAt.toIso8601String()}',
          ),
        )
        .toList();
    _seenReactions.addAll(
      active.map((r) => '${r.kind}:${r.expiresAt.toIso8601String()}'),
    );
    if (fresh.isNotEmpty && !_quiet && _responseKind == null)
      _respondTo(fresh.last);
  }

  void _respondTo(GardenReaction reaction) {
    final kind = reaction.kind;
    if (!reaction.activeAt(DateTime.now())) return;
    if (_quiet || !_foreground || !gardenReactionNames.containsKey(kind))
      return;
    setState(() {
      _responseAnchor = _displayedMoment;
      _responseKind = kind;
      _responseDeadline = reaction.expiresAt;
    });
    _response.forward(from: 0);
  }

  List<Widget> _reactionSprites() {
    _expiryTimer?.cancel();
    final now = DateTime.now();
    final active = widget.reactions.where((r) => r.activeAt(now)).toList();
    if (active.isNotEmpty) {
      final first = active
          .map((r) => r.expiresAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      _expiryTimer = Timer(first.difference(now), () {
        if (mounted) setState(() {});
      });
    }
    return [
      for (var i = 0; i < math.min(active.length, 6); i++)
        Positioned(
          left: 1060 + i * 65.0,
          top: 430 - (i % 2) * 28.0,
          width: 52,
          height: 52,
          child: Semantics(
            label: gardenCopy('garden90.9', [
              tr(gardenReactionNames[active[i].kind] ?? ""),
            ]),
            child: GardenSway(
              animation: _air,
              child: TextButton(
                onPressed: () => _respondTo(active[i]),
                child: Text(
                  gardenReactionEmoji[active[i].kind]!,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        ),
    ];
  }

  /// Ground-coordinate obstacles (trees, bench, planted seeds) the walking
  /// path should bend around, so Mongi never clips through them.
  List<Offset> _catObstacles() => [
    if (_visibleFlowerCount > 0) const Offset(1060, 650),
    for (final id in _items)
      if (id != 'decor:bench')
        Offset(
          widget.layout.position(id).dx * 2400,
          widget.layout.position(id).dy * 800,
        ),
  ];

  /// Combines every seed/decoration plus the living cat into one Stack,
  /// ordered back-to-front by ground position, so a tree correctly hides
  /// Mongi while passing behind it and reveals it again out front.
  Widget _sceneLayer(List<String> sorted) => Positioned.fill(
    key: const Key('garden-item-layer'),
    child: AnimatedBuilder(
      animation: Listenable.merge([_air, _response, _cushion]),
      builder: (context, _) {
        final delta = (_air.value - _lastCatAir + 1) % 1;
        if (_air.isAnimating &&
            _catWanders &&
            !_quiet &&
            _responseKind == null) {
          _catSeconds += delta * 24;
        }
        _lastCatAir = _air.value;
        final plants = _items.where((id) => id.startsWith('seed:'));
        Offset world(String id) {
          final p = widget.layout.position(id);
          return Offset(p.dx * 2400, p.dy * 800);
        }

        var moment = GardenCatMoment.at(
          _catSeconds,
          plant: plants.isEmpty ? null : world(plants.first),
          bench: widget.decorations.contains('bench')
              ? world('decor:bench')
              : null,
          obstacles: _catObstacles(),
          zoneLeftOpen: widget.layout.isOpen(0),
          zoneRightOpen: widget.layout.isOpen(2),
          quiet: _quiet,
          animated: _air.isAnimating && _catWanders,
          anchor: _catAnchor,
          homePosition: const Offset(1200, 600),
        );
        moment = GardenCatMoment(
          moment.feet,
          moment.resting,
          moment.tilt,
          moment.size * 1.25,
          moment.label,
          onBench: moment.onBench,
          walking: moment.walking,
          faceLeft: moment.faceLeft,
          frame: moment.frame,
          facing: moment.facing,
          groundDy: moment.groundDy,
        );
        if ((!_air.isAnimating || !_catWanders || _quiet) &&
            _displayedMoment != null) {
          final previous = _displayedMoment!;
          moment = (!_air.isAnimating && !_quiet)
              ? previous
              : GardenCatMoment(
                  previous.feet,
                  false,
                  0,
                  previous.size,
                  tr('곁에서 쉬는 몽이'),
                  onBench: previous.onBench,
                  groundDy: previous.contactDy,
                );
        }
        if (_onCushion && !widget.readOnly && _items.contains(_restItem)) {
          final p = widget.layout.position(_restItem);
          final seat = Offset(p.dx * 2400, p.dy * 800 - 12);
          final obstacles = _items
              .where((id) => id != _restItem)
              .map(world)
              .toList();
          final resting = GardenCatMoment.cushion(
            _cushionFrom,
            seat,
            _cushion.value,
            obstacles,
          );
          moment = GardenCatMoment(
            resting.feet,
            resting.resting,
            resting.tilt,
            resting.size * 1.25,
            resting.label,
            walking: resting.walking,
            faceLeft: resting.faceLeft,
            frame: resting.frame,
            facing: resting.facing,
            groundDy: resting.resting ? p.dy * 800 + 1 : resting.contactDy,
          );
        }
        if (_hasResponse && !_onCushion) {
          final anchor = _responseAnchor ?? moment;
          moment = GardenCatMoment(
            anchor.feet,
            false,
            0,
            anchor.size,
            gardenResponseLabels[_responseKind]!,
            groundDy: anchor.contactDy,
            onBench: anchor.onBench,
          );
        }
        // Remember exactly where Mongi is standing whenever motion is
        // actually progressing, so turning the walk off later settles it
        // right here instead of snapping back to a start position.
        if (_air.isAnimating && _catWanders && !_hasResponse) {
          _catAnchor = moment.feet;
        }
        _displayedMoment = moment;
        final catWidget = CompanionCoatScope(
          useLocalChoice: !widget.readOnly || widget.visitingHost != null,
          coat: widget.visitingHost?.coat,
          growthStage: widget.visitingHost?.stage,
          child: Semantics(
            key: const Key('garden-companion'),
            button: true,
            label: _onCushion && !widget.readOnly
                ? gardenCopy('garden90.10', [
                    companionDisplayName(widget.companionName),
                    _restName,
                  ])
                : !widget.readOnly && widget.onCompanionCare != null
                ? gardenCopy('garden90.11', [
                    companionDisplayName(widget.companionName),
                  ])
                : companionCopy(moment.label, widget.companionName),
            child: GestureDetector(
              onTap: _onCushion && !widget.readOnly
                  ? _toggleCushion
                  : !widget.readOnly && widget.onCompanionCare != null
                  ? widget.onCompanionCare
                  : () => _message(
                      companionCopy(moment.label, widget.companionName),
                    ),
              child: GardenBenchMoonlight(
                night: _night,
                seated: moment.onBench,
                animate: _air.isAnimating,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: GardenCatShadowPainter(
                            walking: moment.walking,
                            frame: moment.frame,
                            facingDepth: moment.facing != GardenCatFacing.side,
                            faceLeft: moment.faceLeft,
                            night: _night,
                            lift: moment.contactDy - moment.feet.dy,
                            onBench: moment.onBench,
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: moment.walking ? moment.tilt : 0,
                      alignment: Alignment.bottomCenter,
                      child: Transform.scale(
                        alignment: Alignment.bottomCenter,
                        scaleY: 1,
                        child: GardenCatPose(
                          walking: moment.walking,
                          frame: moment.frame,
                          reaction: _hasResponse ? _responseKind : null,
                          child: _hasResponse
                              ? GardenCatResponse(
                                  key: const Key('garden-cat-response'),
                                  kind: _responseKind!,
                                  progress: _response.value,
                                  animated: _air.isAnimating && _catWanders,
                                )
                              : moment.walking
                              ? GardenWalkingCat(
                                  frame: moment.frame,
                                  facing: moment.facing,
                                  faceLeft: moment.faceLeft,
                                )
                              : CompanionPresence(
                                  enabled:
                                      widget.companionAutomaticBehavior &&
                                      !_paused &&
                                      !_quiet,
                                  bondStage: widget.companionBondStage,
                                  night: _night,
                                  resting:
                                      _loafRest ||
                                      _quiet ||
                                      (widget.visitingGuest != null &&
                                          widget.visitActivity == 'rest'),
                                ),
                        ),
                      ),
                    ),
                    if (!widget.readOnly)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: NeighborNewsBubble(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        // Depth-sort every ground item together with the cat by their
        // ground (contact) y, so trees correctly occlude Mongi walking
        // behind them and reveal it again once it steps out in front.
        final entries = <(double dy, Widget child)>[
          if (_visibleFlowerCount > 0)
            (
              683.0,
              Positioned(
                left: 970,
                top: 575,
                width: 180,
                height: 115,
                child: Semantics(
                  button: true,
                  label: tr('받은 응원의 꽃밭'),
                  child: GestureDetector(
                    key: const Key('garden-cheer-flowers'),
                    onTap: _quiet || widget.readOnly
                        ? null
                        : widget.onCheerFlowers,
                    child: Stack(
                      children: [
                        for (
                          var i = 0;
                          i < math.min(_visibleFlowerCount, 9);
                          i++
                        )
                          Positioned(
                            left: (i % 3) * 48.0,
                            top: (i ~/ 3) * 20.0,
                            width: 76,
                            height: 76,
                            child: GardenFlowerArt(
                              night: _night,
                              kind: i < widget.flowerKinds.length
                                  ? widget.flowerKinds[i]
                                  : gardenFlowerNames.keys.elementAt(i % 5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!widget.readOnly && widget.personalArtwork != null)
            (
              520.0,
              Positioned(
                left: 1300,
                top: 370,
                width: 100,
                height: 150,
                child: Semantics(
                  label: tr('간직한 작품 액자'),
                  image: true,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F0DF),
                        border: Border.all(
                          color: const Color(0xFF8C664B),
                          width: 7,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 5),
                        ],
                      ),
                      child: Image.memory(
                        widget.personalArtwork!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          for (final id in sorted)
            (widget.layout.position(id).dy * 800, _item(id)),
          if (!widget.readOnly)
            for (final member in widget.family.entries)
              if (member.key != widget.activeCoat)
                (580.0, _familyResident(member.key, member.value)),
          if (widget.visitingGuest != null)
            (moment.contactDy + 1, _visitingGuest(moment)),
          (moment.contactDy, catWidget),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final e in entries)
              if (identical(e.$2, catWidget))
                Positioned(
                  left:
                      moment.feet.dx -
                      moment.size * widget.companionScale.clamp(.82, 1.0) / 2,
                  top:
                      moment.feet.dy -
                      moment.size * widget.companionScale.clamp(.82, 1.0),
                  width: moment.size * widget.companionScale.clamp(.82, 1.0),
                  height: moment.size * widget.companionScale.clamp(.82, 1.0),
                  child: e.$2,
                )
              else
                e.$2,
          ],
        );
      },
    ),
  );

  Widget _visitingGuest(GardenCatMoment moment) {
    final guest = widget.visitingGuest!;
    final walking = widget.visitActivity == 'walk' && _air.isAnimating;
    final size = moment.size * guest.scale;
    final dx = (moment.feet.dx + (widget.visitActivity == 'greet' ? 105 : 155))
        .clamp(size / 2, 2400 - size / 2);
    return Positioned(
      key: const Key('garden-visiting-guest'),
      left: dx - size / 2,
      top: moment.feet.dy - size + 4,
      width: size,
      height: size,
      child: CompanionCoatScope(
        useLocalChoice: true,
        coat: guest.coat,
        growthStage: guest.stage,
        child: Semantics(
          label: gardenCopy('garden90.12', [guest.name]),
          child: walking
              ? GardenWalkingCat(
                  frame: (_air.value * 24 * 8).floor(),
                  facing: GardenCatFacing.side,
                  faceLeft: moment.faceLeft,
                )
              : CompanionPresence(
                  enabled: _air.isAnimating,
                  bondStage: 3,
                  night: _night,
                  resting: widget.visitActivity == 'rest',
                ),
        ),
      ),
    );
  }

  Widget _familyResident(CompanionCoat coat, int days) {
    final phase = _air.value * math.pi * 2 + coat.index;
    final walking =
        _catWanders &&
        _air.isAnimating &&
        !_quiet &&
        widget.companionAutomaticBehavior;
    final size = days >= 90
        ? 220.0
        : days >= 30
        ? 207.0
        : days >= 7
        ? 194.0
        : 180.0;
    return Positioned(
      key: ValueKey('resident-${coat.name}'),
      left:
          1200 +
          (coat.index % 2 == 0 ? 1 : -1) * (150 + (coat.index ~/ 2) * 130) +
          (walking ? math.sin(phase) * 45 : 0),
      top: 580 - size,
      width: size,
      height: size,
      child: CompanionCoatScope(
        useLocalChoice: true,
        coat: coat,
        growthStage: days >= 90
            ? 3
            : days >= 30
            ? 2
            : days >= 7
            ? 1
            : 0,
        child: Semantics(
          label: gardenCopy('garden90.13', [coat.label]),
          child: walking
              ? GardenWalkingCat(
                  frame: (_air.value * 24 * 8).floor(),
                  facing: GardenCatFacing.side,
                  faceLeft: math.cos(phase) < 0,
                )
              : CompanionPresence(
                  enabled: widget.companionAutomaticBehavior && !_paused,
                  bondStage: days >= 90 ? 3 : 0,
                  night: _night,
                ),
        ),
      ),
    );
  }

  Widget _placementPreview() {
    final point = widget.placementPoint!;
    final seed = widget.placementSeed!;
    final width =
        seed.worldArtSize(widget.placementCount.toDouble()) *
        GardenLayout.depthAt(point.dy);
    return Positioned(
      key: const Key('plant-location-preview'),
      left: point.dx * 2400 - width / 2,
      top: point.dy * 800 - width * .90,
      width: width,
      height: width,
      child: IgnorePointer(
        child: Opacity(
          opacity: .6,
          child: GardenPlantArt(
            seed: seed,
            count: widget.placementCount,
            night: _night,
          ),
        ),
      ),
    );
  }

  Widget _item(String id) {
    final p = widget.layout.position(id);
    final seed = id.startsWith('seed:') ? SeedType.byId(id.substring(5)) : null;
    final decoration = seed == null
        ? GardenDecoration.byId(id.substring(6))
        : null;
    final bench = decoration?.id == 'bench';
    final depth = GardenLayout.depthAt(p.dy);
    final growth = seed == null
        ? 0.0
        : (widget.seeds[seed.id] ?? 0) +
              (widget.careRemainders[seed.id] ?? 0) / 3;
    final artWidth =
        (bench ? 220.0 : seed?.worldArtSize(growth) ?? 104.0) * depth;
    final artHeight = bench ? artWidth * .667 : artWidth;
    final child = Semantics(
      button: true,
      label: '${_label(id)} ${_editing ? tr('배치 선택') : tr('살펴보기')}',
      child: GestureDetector(
        key: ValueKey('world-item-$id'),
        onTap: _saving
            ? null
            : () {
                if (_quiet || _cameraGesture) {
                  return;
                } else if (widget.placementSeed != null && !widget.readOnly) {
                  _message(tr('기존 식물이 없는 빈 땅을 골라 주세요.'));
                } else if (widget.readOnly) {
                  _message(_label(id));
                } else if (_wateringMode) {
                  if (seed != null) {
                    _waterPlant(id);
                  } else {
                    _message(tr('물은 꽃이나 나무에 줄 수 있어요.'));
                  }
                } else if (_editing) {
                  setState(() => _selected = id);
                } else if (seed != null) {
                  if (widget.cultivationMode && widget.onInspectPlant != null) {
                    widget.onInspectPlant!(seed);
                  } else {
                    widget.onMemory(seed);
                  }
                } else if (id == 'decor:cat_cushion' ||
                    id == 'decor:cat_basket') {
                  _toggleCushion(target: id);
                } else if (id == 'decor:bench') {
                  _setQuiet(true);
                } else {
                  _message(_label(id));
                }
              },
        child: Container(
          // Paint selection above the unchanged content bounds. A decoration
          // border adds padding and would shrink/move the saved plant artwork.
          foregroundDecoration: BoxDecoration(
            border: _selected == id || _inspectedPlant == id
                ? Border.all(color: AppColors.gold, width: 3)
                : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Expanded(
                child: seed != null
                    ? GardenSway(
                        animation: _air,
                        pulse: _waterTarget == id ? _water : null,
                        phase: SeedType.all.indexOf(seed).toDouble(),
                        child: GardenPlantArt(
                          seed: seed,
                          count: widget.seeds[seed.id] ?? 0,
                          night: _night,
                          animateGrowth: _air.isAnimating && !_quiet,
                        ),
                      )
                    : Center(
                        child: decoration!.id == 'bench'
                            ? GardenGroundedArt(
                                night: _night,
                                bench: true,
                                child: Image.asset(
                                  'assets/living_garden/bench.webp',
                                  width: artWidth,
                                  height: artHeight,
                                  fit: BoxFit.fill,
                                  excludeFromSemantics: true,
                                ),
                              )
                            : GardenBasicItemArt.ids.contains(decoration.id)
                            ? GardenBasicItemArt(
                                id: decoration.id,
                                night: _night,
                              )
                            : Icon(
                                _decorationIcon(decoration.id),
                                size: 56,
                                color: const Color(0xFF90754F),
                              ),
                      ),
              ),
              SizedBox(
                height: 22,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Opacity(
                    opacity:
                        _editing ||
                            _selected == id ||
                            _inspectedPlant == id ||
                            (seed != null && !widget.readOnly && _wateringMode)
                        ? 1
                        : 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bg1.withValues(alpha: .88),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.sageLine),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (seed != null &&
                              !widget.readOnly &&
                              widget.wateredOn[seed.id] !=
                                  DateTime.now().toIso8601String().substring(
                                    0,
                                    10,
                                  ))
                            Icon(
                              Icons.water_drop,
                              key: ValueKey('needs-water-${seed.id}'),
                              size: 14,
                              color: const Color(0xFF368697),
                            ),
                          Text(
                            _label(id),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: bodyFont(fontSize: 12, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (seed == null) {
      return Positioned(
        key: ValueKey('world-position-$id'),
        left: p.dx * 2400 - artWidth / 2,
        top: p.dy * 800 - artHeight * .90,
        width: artWidth,
        height: artHeight + 22,
        child: child,
      );
    }
    // Interpolate all four bounds together: the root at 90% height remains
    // exactly on its saved ground coordinate throughout the growth animation.
    return AnimatedPositioned(
      key: ValueKey('world-position-$id'),
      duration: Duration(milliseconds: _air.isAnimating && !_quiet ? 700 : 0),
      curve: Curves.easeOutCubic,
      left: p.dx * 2400 - artWidth / 2,
      top: p.dy * 800 - artHeight * .90,
      width: artWidth,
      height: artHeight + 22,
      child: child,
    );
  }
}

class _GroundGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .3)
      ..strokeWidth = 1;
    for (var x = 80.0; x < 2400; x += 80) {
      canvas.drawLine(Offset(x, 416), Offset(x, 728), p);
    }
    for (var y = 416.0; y <= 728; y += 78) {
      canvas.drawLine(Offset(84, y), Offset(2316, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GroundGrid oldDelegate) => false;
}

IconData _decorationIcon(String id) => switch (id) {
  'path' => Icons.route_outlined,
  'fountain' => Icons.water_drop_outlined,
  'lantern' || 'hanok_lantern' => Icons.light_outlined,
  'rainbow_fence' => Icons.fence,
  'star_light' => Icons.auto_awesome,
  'daisy_pot' => Icons.local_florist,
  'tulip_pot' => Icons.local_florist_outlined,
  'sunflower_pot' => Icons.wb_sunny,
  'cat_cushion' => Icons.bed,
  'cat_basket' => Icons.shopping_basket_outlined,
  'moon_lamp' => Icons.nightlight_round,
  'bird_house' => Icons.cottage_outlined,
  'wind_chime' => Icons.notifications_none,
  'butterfly_garden' => Icons.flutter_dash,
  'gazebo' => Icons.holiday_village_outlined,
  'lotus_pond' => Icons.local_florist_outlined,
  'jangdokdae' => Icons.yard_outlined,
  'ginkgo_path' => Icons.park_outlined,
  _ => Icons.chair_outlined,
};

/// A bounded Expanded parent supplies the full canvas in phone mode.
class _GardenViewportFrame extends StatelessWidget {
  final bool fill;
  final double aspectRatio;
  final Widget child;
  const _GardenViewportFrame({
    required this.fill,
    required this.aspectRatio,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return fill
        ? SizedBox.expand(child: child)
        : AspectRatio(aspectRatio: aspectRatio, child: child);
  }
}
