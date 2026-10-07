import '../../utils/companion_name.dart';
import '../../theme.dart';
import 'garden_grounded_art.dart';
import 'garden_cat_response.dart';
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
  final String companionName;
  final bool readOnly;
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
  final List<String> decorations;
  final Future<void> Function(String id, Offset position) onMove;
  final ValueChanged<SeedType> onMemory;
  final VoidCallback onPlant, onDecorate;
  const GardenWorldView({
    super.key,
    this.companionName = '고양이',
    this.readOnly = false,
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
  double _catSeconds = 0, _lastCatAir = 0;
  Timer? _expiryTimer;
  final _seenReactions = <String>{};
  String? _responseKind;
  DateTime? _responseDeadline;
  bool get _hasResponse =>
      _responseKind != null &&
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
        _response.stop();
        _responseKind = null;
      }
      _editing = false;
      _wateringMode = false;
      _selected = null;
    });
    widget.onQuietChanged?.call(value);
    _jump(
      widget.decorations.contains('bench')
          ? widget.layout.position('decor:bench').dx
          : .5,
    );
  }

  void _waterPlant(String id) {
    if (widget.readOnly || !id.startsWith('seed:')) return;
    setState(() => _waterTarget = id);
    if (_air.isAnimating) _water.forward(from: 0);
    _message('${_label(id)}에 물을 주었어요. 잎사귀가 촉촉해졌어요.');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _response.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted)
        setState(() => _responseKind = null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _considerReactions();
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
    if (_foreground && mounted) setState(() {});
    _syncMotion();
  }

  void _syncMotion() {
    if (!_foreground) {
      _response.stop();
    } else if (_responseKind != null &&
        !_response.isAnimating &&
        _response.value < 1) {
      _response.forward();
    }
    final enabled =
        widget.motionEnabled &&
        !_paused &&
        _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context);
    if (enabled) {
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
  int _zone = 1;
  bool _toolsOpen = false;
  bool _catWanders = false;
  bool _editing = false, _saving = false;
  late bool _night = DateTime.now().hour < 6 || DateTime.now().hour >= 19;
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
    _syncMotion();
    if (!_items.contains(_selected)) _selected = null;
    if (_undo != null && !_items.contains(_undo!.key)) _undo = null;
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

  void _jump(double x, {double? scale}) {
    final s = (scale ?? _camera.value.getMaxScaleOnAxis()).clamp(
      _minScale,
      _minScale * 2.5,
    );
    final dx = (_viewport.width / 2 - x * 2400 * s).clamp(
      math.min(0.0, _viewport.width - 2400 * s),
      0.0,
    );
    final dy = ((_viewport.height - 800 * s) / 2).clamp(
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
    _jump(center.dx / 2400, scale: _camera.value.getMaxScaleOnAxis() * factor);
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
      if (mounted) _message('위치를 저장하지 못했어요. 다시 시도해 주세요.');
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
      if (mounted) _message('되돌리지 못했어요. 자리가 비어 있는지 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _response.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _air.dispose();
    _daylight.dispose();
    _water.dispose();
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (!_quiet)
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg0,
            border: const Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.catSageBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.sageLine),
                    ),
                    child: DropdownButton<int>(
                    value: _zone,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.bg1,
                    iconEnabledColor: AppColors.catSage,
                    style: bodyFont(color: AppColors.ink),
                    items: [
                      for (var zone = 0; zone < 3; zone++)
                        DropdownMenuItem(
                          value: zone,
                          child: Text(
                            '${widget.layout.isOpen(zone) ? '' : '🔒 '}' +
                                [
                                  '꽃밭',
                                  '${companionDisplayName(widget.companionName)}의 집',
                                  '나무 뜰',
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
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '정원 축소',
                  onPressed: () => _zoom(.8),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.blobMint,
                    foregroundColor: AppColors.blobMintAccent,
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: '정원 확대',
                  onPressed: () => _zoom(1.25),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.blobMint,
                    foregroundColor: AppColors.blobMintAccent,
                    shape: const CircleBorder(),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  tooltip: '보기 설정',
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
                      setState(() => _catWanders = !_catWanders);
                    } else if (value == 'motion') {
                      setState(() => _paused = !_paused);
                      _syncMotion();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'reset',
                      child: Text('기본 크기로 보기', style: bodyFont(color: AppColors.ink)),
                    ),
                    PopupMenuItem(
                      value: 'cat',
                      child: Text(
                        _catWanders ? '고양이 앉아서 쉬기' : '고양이 산책하기',
                        style: bodyFont(color: AppColors.ink),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'light',
                      child: Text(
                        _night ? '햇살 정원' : '별빛 정원',
                        style: bodyFont(color: AppColors.ink),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'motion',
                      child: Text(
                        _paused ? '정원 움직임 재생' : '정원 움직임 멈추기',
                        style: bodyFont(color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      Expanded(
        child: Center(
          child: AspectRatio(
            // A landscape viewport avoids portrait-height-driven magnification.
            aspectRatio: 1.25,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = box.biggest;
                if (size != _viewport) {
                  _viewport = size;
                  _minScale = math.max(size.width / 2400, size.height / 800);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _jump(
                        _quiet && widget.decorations.contains('bench')
                            ? widget.layout.position('decor:bench').dx
                            : .5,
                        scale: _minScale,
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
                return ClipRect(
                  child: InteractiveViewer(
                    key: const Key('garden-world-camera'),
                    transformationController: _camera,
                    constrained: false,
                    alignment: Alignment.topLeft,
                    minScale: _minScale,
                    maxScale: _minScale * 2.5,
                    child: GestureDetector(
                      onTapUp: (e) => _place(e.localPosition),
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        key: const Key('garden-world-ground'),
                        width: 2400,
                        height: 800,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Image.asset(
                                'assets/living_garden/world_${_night ? 'night' : 'day'}.webp',
                                fit: BoxFit.fill,
                                excludeFromSemantics: true,
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: GardenAtmosphere.animated(
                                      _air,
                                      _night,
                                      daylight: _daylight,
                                    ),
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
                            for (final id in sorted) _item(id),
                            if (_visibleMemoryCount > 0)
                              Positioned(
                                left: 1430,
                                top: 370,
                                width: 155,
                                height: 170,
                                child: Semantics(
                                  button: true,
                                  label: widget.readOnly
                                      ? '기억의 나무'
                                      : '기억의 나무, 기록한 날 ${widget.memoryDays}일',
                                  child: GestureDetector(
                                    key: const Key('garden-memory-tree'),
                                    onTap: _quiet || widget.readOnly
                                        ? null
                                        : widget.onMemoryTree,
                                    child: GardenPlantArt(
                                      seed: SeedType.byId('cherry'),
                                      count: _visibleMemoryCount,
                                      night: _night,
                                    ),
                                  ),
                                ),
                              ),
                            if (_visibleFlowerCount > 0)
                              Positioned(
                                left: 970,
                                top: 575,
                                width: 180,
                                height: 115,
                                child: Semantics(
                                  button: true,
                                  label: '받은 응원의 꽃밭',
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
                                              kind:
                                                  i < widget.flowerKinds.length
                                                  ? widget.flowerKinds[i]
                                                  : gardenFlowerNames.keys
                                                        .elementAt(i % 5),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            _livingCat(),
                            ..._reactionSprites(),
                            if (_waterTarget != null &&
                                _items.contains(_waterTarget))
                              Positioned(
                                left:
                                    widget.layout.position(_waterTarget!).dx *
                                        2400 -
                                    70,
                                top:
                                    widget.layout.position(_waterTarget!).dy *
                                        800 -
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
                                  child: ColoredBox(
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
                                                  ? '조금씩 열리는 꽃밭'
                                                  : '나무를 위한 넓은 뜰',
                                              style: titleFont(
                                                fontSize: 22,
                                                color:
                                                    AppColors.titlePastelGreen,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '씨앗을 심거나 가꾼 횟수 ${zone == 0 ? 3 : 8}회에 열려요',
                                              textAlign: TextAlign.center,
                                              style: bodyFont(
                                                fontSize: 15,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            Text(
                                              '한 번 열린 공간은 그대로 남아요',
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
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      if (_quiet)
        SafeArea(
          top: false,
          child: TextButton.icon(
            onPressed: () => _setQuiet(false),
            icon: const Icon(Icons.close),
            label: const Text('쉬기 마치기'),
          ),
        ),
      if (!_quiet)
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg0,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
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
                  Text(
                    _saving
                        ? '위치를 저장하고 있어요…'
                        : _wateringMode
                        ? '물을 줄 꽃이나 나무를 눌러 주세요.'
                        : _editing
                        ? (_selected == null
                              ? '아이템을 고른 뒤, 원하는 잔디를 눌러 주세요.'
                              : '${_label(_selected!)} · 옮길 잔디를 눌러 주세요.')
                        : '좌우로 산책하고, 두 손가락으로 가까이 살펴보세요.',
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
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('씨앗을 심거나 장식을 놓으면 여기서 옮길 수 있어요.'),
                    ),
                  if (!widget.readOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _toolsOpen = !_toolsOpen),
                        style: _chipStyle(
                          AppColors.catSageBg,
                          AppColors.catSage,
                          active: _toolsOpen,
                        ),
                        icon: Icon(
                          _toolsOpen ? Icons.expand_less : Icons.tune,
                        ),
                        label: Text(
                          _toolsOpen ? '도구 접기' : '돌보기 · 꾸미기 · 추억',
                        ),
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
                              label: Text(_wateringMode ? '물주기 완료' : '물 주기'),
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
                              icon: Icon(
                                _editing ? Icons.check : Icons.open_with,
                              ),
                              label: Text(_editing ? '배치 완료' : '배치 모드'),
                            ),
                            if (widget.onMemoryTree != null)
                              TextButton.icon(
                                onPressed: widget.onMemoryTree,
                                style: _chipStyle(
                                  AppColors.blobButter,
                                  AppColors.blobButterAccent,
                                ),
                                icon: const Icon(Icons.park_outlined),
                                label: const Text('기억의 나무'),
                              ),
                            if (widget.onCheerFlowers != null)
                              TextButton.icon(
                                onPressed: widget.onCheerFlowers,
                                style: _chipStyle(
                                  AppColors.blobRose,
                                  AppColors.blobRoseAccent,
                                ),
                                icon: const Icon(Icons.local_florist_outlined),
                                label: const Text('응원 꽃'),
                              ),
                            TextButton.icon(
                              onPressed: () => _setQuiet(true),
                              style: _chipStyle(
                                AppColors.blobLavender,
                                AppColors.blobLavenderAccent,
                              ),
                              icon: const Icon(Icons.weekend_outlined),
                              label: const Text('잠깐 쉬기'),
                            ),
                            TextButton.icon(
                              onPressed: _saving ? null : widget.onPlant,
                              style: _chipStyle(
                                AppColors.blobPeach,
                                AppColors.blobPeachAccent,
                              ),
                              icon: const Icon(Icons.grass),
                              label: const Text('씨앗 심기'),
                            ),
                            TextButton.icon(
                              onPressed: _saving ? null : widget.onDecorate,
                              style: _chipStyle(
                                AppColors.blobButter,
                                AppColors.blobButterAccent,
                              ),
                              icon: const Icon(Icons.chair_outlined),
                              label: const Text('장식'),
                            ),
                            if (_undo != null)
                              TextButton.icon(
                                onPressed: _saving ? null : _undoMove,
                                style: _chipStyle(
                                  AppColors.bg2,
                                  AppColors.inkSoft,
                                ),
                                icon: const Icon(Icons.undo),
                                label: const Text('되돌리기'),
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
        ),
    ],
  );

  int get _visibleMemoryCount => widget.readOnly
      ? [0, 1, 3, 6, 10][widget.publicMemoryStage.clamp(0, 4)]
      : widget.memoryDays;
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
            label: '24시간 응원 ${gardenReactionNames[active[i].kind]}',
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

  Widget _livingCat() => AnimatedBuilder(
    animation: Listenable.merge([_air, _response]),
    builder: (context, _) {
      final delta = (_air.value - _lastCatAir + 1) % 1;
      if (_air.isAnimating && _responseKind == null) _catSeconds += delta * 24;
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
        quiet: _quiet,
        animated: _air.isAnimating && _catWanders,
      );
      if (_hasResponse) {
        final anchor = _responseAnchor ?? moment;
        moment = GardenCatMoment(
          anchor.feet,
          false,
          0,
          anchor.size,
          gardenResponseLabels[_responseKind]!,
        );
      }
      _displayedMoment = moment;
      return Positioned(
        left: moment.feet.dx - moment.size / 2,
        top: moment.feet.dy - moment.size,
        width: moment.size,
        height: moment.size,
        child: Semantics(
          button: true,
          label: companionCopy(moment.label, widget.companionName),
          child: GestureDetector(
            onTap: () =>
                _message(companionCopy(moment.label, widget.companionName)),
            child: GardenBenchMoonlight(
              night: _night,
              seated: moment.resting && widget.decorations.contains('bench'),
              animate: _air.isAnimating,
              child: Transform.rotate(
                angle: moment.tilt,
                alignment: Alignment.bottomCenter,
                child: _hasResponse
                    ? GardenCatResponse(
                        key: const Key('garden-cat-response'),
                        kind: _responseKind!,
                        progress: _response.value,
                        animated: _air.isAnimating && _catWanders,
                      )
                    : moment.walking
                    ? Transform.flip(
                        flipX: moment.faceLeft,
                        child: GardenAtlasArt(
                          asset: 'assets/living_garden/cat_walk.webp',
                          column: moment.frame,
                          rows: 1,
                        ),
                      )
                    : GardenSway(
                        animation: _air,
                        cat: true,
                        child: GardenCatArt(
                          animation: _air,
                          blinking: _air.isAnimating,
                          resting: moment.resting,
                        ),
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _item(String id) {
    final p = widget.layout.position(id);
    final seed = id.startsWith('seed:') ? SeedType.byId(id.substring(5)) : null;
    final decoration = seed == null
        ? GardenDecoration.byId(id.substring(6))
        : null;
    final bench = decoration?.id == 'bench';
    final tree = seed != null && ['pine', 'cherry', 'maple'].contains(seed.id);
    final depth = (.88 + (p.dy - .52) * .55).clamp(.84, 1.10);
    final artWidth =
        (bench
            ? 220.0
            : tree
            ? 192.0
            : 104.0) *
        depth;
    final artHeight = bench ? artWidth * .667 : artWidth;
    return Positioned(
      left: p.dx * 2400 - artWidth / 2,
      top: p.dy * 800 - artHeight * .90,
      width: artWidth,
      height: artHeight + 22,
      child: Semantics(
        button: true,
        label: '${_label(id)} ${_editing ? '배치 선택' : '살펴보기'}',
        child: GestureDetector(
          key: ValueKey('world-item-$id'),
          onTap: _saving
              ? null
              : () {
                  if (_quiet) {
                    return;
                  } else if (widget.readOnly) {
                    _message(_label(id));
                  } else if (_wateringMode) {
                    if (seed != null) {
                      _waterPlant(id);
                    } else {
                      _message('물은 꽃이나 나무에 줄 수 있어요.');
                    }
                  } else if (_editing) {
                    setState(() => _selected = id);
                  } else if (seed != null) {
                    widget.onMemory(seed);
                  } else if (id == 'decor:bench') {
                    _setQuiet(true);
                  } else {
                    _message(_label(id));
                  }
                },
          child: Container(
            decoration: BoxDecoration(
              border: _selected == id
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
                              : Icon(
                                  _decorationIcon(decoration.id),
                                  size: 56,
                                  color: const Color(0xFF90754F),
                                ),
                        ),
                ),
                Opacity(
                  opacity: _editing || _selected == id ? 1 : 0,
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
                    child: Text(
                      _label(id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyFont(fontSize: 12, color: AppColors.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  'wind_chime' => Icons.notifications_none,
  'butterfly_garden' => Icons.flutter_dash,
  'gazebo' => Icons.holiday_village_outlined,
  'lotus_pond' => Icons.local_florist_outlined,
  'jangdokdae' => Icons.yard_outlined,
  'ginkgo_path' => Icons.park_outlined,
  _ => Icons.chair_outlined,
};
