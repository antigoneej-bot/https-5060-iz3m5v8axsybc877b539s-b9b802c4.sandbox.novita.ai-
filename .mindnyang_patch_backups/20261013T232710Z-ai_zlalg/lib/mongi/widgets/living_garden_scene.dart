import '../../utils/companion_name.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'garden_gift_art.dart';
import 'garden_grounded_art.dart';
import '../models/seed.dart';
import 'garden_ambient.dart';

/// Rendered 3D layers, not a rotatable mesh. No economy or mood is mutated here.
class LivingGardenScene extends StatefulWidget {
  final String companionName;
  final Map<String, int> seeds;
  final bool motionEnabled;
  final bool compact;
  final VoidCallback? onWrite, onGarden, onNeighbors;
  final ValueChanged<SeedType>? onPlant;
  const LivingGardenScene({
    super.key,
    this.companionName = '고양이',
    this.seeds = const {},
    this.motionEnabled = true,
    this.compact = false,
    this.onWrite,
    this.onGarden,
    this.onNeighbors,
    this.onPlant,
  });
  @override
  State<LivingGardenScene> createState() => _LivingGardenSceneState();
}

class _LivingGardenSceneState extends State<LivingGardenScene>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _air = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  late final AnimationController _pet = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool _canBlink = false;
  Timer? _clock;
  int _light =
      0; // 0 device time, 1 day, 2 night; preview never changes records.
  // 정원 화면의 입체 고양이는 움직임이 부자연스럽다는 피드백에 따라
  // 기본값을 '정지'로 두고, 사용자가 직접 '정원 움직임 켜기'를 눌렀을 때만
  // 흔들림/배회 애니메이션을 재생합니다(쓰다듬기 탭 자체는 항상 가능).
  bool _paused = true, _foreground = true, _animate = false;
  Offset _look = Offset.zero;
  bool get _night =>
      _light == 2 ||
      (_light == 0 && (DateTime.now().hour < 6 || DateTime.now().hour >= 19));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _foreground && _light == 0) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant LivingGardenScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) {
      setState(() {});
      _syncMotion();
    }
  }

  void _syncMotion() {
    // Idle blinking is independent of the optional wind/body animation.
    _canBlink =
        widget.motionEnabled &&
        _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (_canBlink) {
      if (!_blink.isAnimating) _blink.repeat();
    } else {
      _blink.stop();
    }
    _animate =
        widget.motionEnabled &&
        !_paused &&
        _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context);
    if (_animate) {
      if (!_air.isAnimating) _air.repeat();
    } else {
      _air.stop();
      _pet.stop();
      _look = Offset.zero;
    }
  }

  void _touchCat() {
    if (_animate) {
      _pet.forward(from: 0);
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            companionCopy('몽이가 손에 살며시 기대어요.', widget.companionName),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _air.dispose();
    _blink.dispose();
    _pet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final night = _night;
    final planted = SeedType.all
        .where((s) => (widget.seeds[s.id] ?? 0) > 0)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AspectRatio(
            aspectRatio: widget.compact ? 4 / 5 : 2 / 3,
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth, h = box.maxHeight;
                return MouseRegion(
                  onHover: (e) {
                    if (_animate) {
                      setState(
                        () => _look = Offset(
                          (e.localPosition.dx / w - .5) * 2,
                          (e.localPosition.dy / h - .5) * 2,
                        ),
                      );
                    }
                  },
                  onExit: (_) {
                    if (mounted) setState(() => _look = Offset.zero);
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_air, _pet]),
                    builder: (context, _) {
                      final t = _animate ? _air.value * math.pi * 2 : 0.0;
                      final pet = _animate && _pet.isAnimating
                          ? math.sin(_pet.value * math.pi)
                          : 0.0;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Transform.translate(
                            offset: Offset(
                              _look.dx * -3 + math.sin(t) * 1.5,
                              _look.dy * -2,
                            ),
                            child: Transform.scale(
                              scale: 1.035,
                              child: AnimatedSwitcher(
                                duration: Duration(
                                  milliseconds: _animate ? 900 : 0,
                                ),
                                child: Image.asset(
                                  'assets/living_garden/${night ? 'night' : 'day'}.webp',
                                  key: ValueKey(night),
                                  width: w,
                                  height: h,
                                  fit: BoxFit.cover,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: w * .085,
                            top: h * .34,
                            width: w * .17,
                            height: w * .20,
                            child: CustomPaint(painter: _Waterwheel(t, night)),
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              painter: GardenAtmosphere(
                                t,
                                night,
                                panoramic: false,
                              ),
                            ),
                          ),
                          for (final seed in planted)
                            _plant(seed, w, h, t, night),
                          Positioned(
                            left: w * (widget.compact ? .39 : .31),
                            top: h * (widget.compact ? .766 : .795),
                            width: w * (widget.compact ? .24 : .39),
                            height: h * .032,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: night ? .4 : .23,
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            // 배경(정원 씬)에 비해 고양이가 지나치게 크고
                            // 움직임도 부담스럽다는 피드백에 따라, 비율을
                            // 약 35%로 줄이고 흔들림 폭도 함께 낮췄습니다.
                            left:
                                w * (widget.compact ? .37 : .34) + _look.dx * 3,
                            top:
                                h * (widget.compact ? .55 : .577) +
                                math.sin(t * 6) * .7 -
                                pet * 5,
                            width: w * (widget.compact ? .28 : .35),
                            height: w * (widget.compact ? .28 : .35),
                            child: Transform.rotate(
                              angle: pet * -.03,
                              child: Transform.scale(
                                scale: 1 + pet * .025,
                                alignment: Alignment.bottomCenter,
                                child: Semantics(
                                  label:
                                      '${companionDisplayName(widget.companionName)} 쓰다듬기',
                                  button: true,
                                  child: Tooltip(
                                    message: companionCopy(
                                      '몽이를 쓰다듬어 보세요',
                                      widget.companionName,
                                    ),
                                    child: InkWell(
                                      key: const Key('living-cat'),
                                      onTap: _touchCat,
                                      borderRadius: BorderRadius.circular(100),
                                      child: GardenNightLight(
                                        night: night,
                                        child: GardenCatArt(
                                          animation: _blink,
                                          blinking: _canBlink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (pet > 0)
                            Positioned(
                              top: h * .52 - pet * 20,
                              left: w * .48,
                              child: Opacity(
                                opacity: pet,
                                child: const Icon(
                                  Icons.favorite,
                                  color: Color(0xFFFFB9C4),
                                  size: 28,
                                ),
                              ),
                            ),
                          if (!widget.compact)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: h * .32,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: night
                                          ? [
                                              const Color(0xA6192945),
                                              Colors.transparent,
                                            ]
                                          : [
                                              const Color(0xDBFFFAE8),
                                              const Color(0x00FFFAE8),
                                            ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (!widget.compact)
                            Positioned(
                              top: 23,
                              left: 12,
                              right: 12,
                              child: IgnorePointer(
                                child: Column(
                                  children: [
                                    Text(
                                      '마음냥 정원',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'GamjaFlower',
                                        fontSize: widget.compact
                                            ? 28
                                            : (w < 320 ? 34 : 40),
                                        color: night
                                            ? const Color(0xFFFFF0D1)
                                            : const Color(0xFF456747),
                                        shadows: [
                                          Shadow(
                                            color: night
                                                ? Colors.black26
                                                : Colors.white70,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '내 마음이 자라는 곳',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'GowunDodum',
                                        fontSize: 13,
                                        color: night
                                            ? const Color(0xFFE3E8EC)
                                            : const Color(0xFF53674D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Positioned(
                            right: 10,
                            top: h * .20,
                            child: Column(
                              children: [
                                _control(
                                  Icons.wb_twilight,
                                  ['시간에 맞춰 보기', '햇살 정원', '별빛 정원'][_light],
                                  () =>
                                      setState(() => _light = (_light + 1) % 3),
                                ),
                                const SizedBox(height: 6),
                                _control(
                                  _paused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                  _paused
                                      ? '바람과 물레방아 움직임 켜기'
                                      : '바람과 물레방아 움직임 쉬기',
                                  () {
                                    setState(() => _paused = !_paused);
                                    _syncMotion();
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (!widget.compact)
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 18,
                              child: IgnorePointer(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: night
                                        ? const Color(0xD92A3A49)
                                        : const Color(0xE6FFF9E8),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white38),
                                  ),
                                  child: Text(
                                    planted.isEmpty
                                        ? '오늘의 마음을, 이곳에 심어 볼까요?'
                                        : '${planted.length}가지 마음이 정원에서 자라고 있어요',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'GowunDodum',
                                      fontSize: 12,
                                      color: night
                                          ? const Color(0xFFFFF2D8)
                                          : const Color(0xFF4A604A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.onWrite != null ||
            widget.onGarden != null ||
            widget.onNeighbors != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.onWrite != null)
                  _action(
                    Icons.edit_note_rounded,
                    '마음 남기기',
                    widget.onWrite!,
                    true,
                  ),
                if (widget.onGarden != null)
                  _action(
                    Icons.local_florist_outlined,
                    '정원 가꾸기',
                    widget.onGarden!,
                    false,
                  ),
                if (widget.onNeighbors != null)
                  _action(
                    Icons.favorite_border_rounded,
                    '이웃 정원',
                    widget.onNeighbors!,
                    false,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _control(IconData icon, String label, VoidCallback onTap) => Tooltip(
    message: label,
    child: Material(
      color: const Color(0xEFFFFBEC),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        tooltip: label,
        icon: Icon(icon, size: 21),
        color: const Color(0xFF526952),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      ),
    ),
  );

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool primary,
  ) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: primary ? const Color(0xFF52724E) : const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 25,
                  color: primary ? Colors.white : const Color(0xFF647356),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'GowunDodum',
                    fontSize: 12,
                    color: primary ? Colors.white : const Color(0xFF455B42),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _plant(SeedType seed, double w, double h, double t, bool night) {
    final index = SeedType.all.indexOf(seed);
    final tier = seed.tierForCount(widget.seeds[seed.id] ?? 0);
    final x = index.isEven ? .08 : .73;
    final y = .56 + (index ~/ 2) * .075;
    return Positioned(
      left: w * x,
      top: h * y,
      width: w * .19,
      height: w * .25,
      child: Semantics(
        label: '${seed.label}, 성장 $tier단계',
        button: widget.onPlant != null,
        child: Tooltip(
          message: '${seed.label} · 성장 $tier단계',
          child: InkWell(
            onTap: widget.onPlant == null ? null : () => widget.onPlant!(seed),
            child: Transform.rotate(
              angle: math.sin(t * 3 + index) * .025,
              alignment: Alignment.bottomCenter,
              child: GardenPlantArt(
                seed: seed,
                count: widget.seeds[seed.id] ?? 0,
                night: night,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Waterwheel extends CustomPainter {
  final double t;
  final bool night;
  _Waterwheel(this.t, this.night);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width * .44;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(.77, 1);
    canvas.drawCircle(
      const Offset(4, 3),
      r,
      Paint()
        ..color = const Color(0xFF3E3022)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.rotate(t);
    final wood = Paint()
      ..color = night ? const Color(0xFF806C56) : const Color(0xFFA87543)
      ..strokeWidth = 4;
    for (var i = 0; i < 10; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 5);
      canvas.drawLine(Offset.zero, Offset(r, 0), wood);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(r, 0), width: 9, height: 12),
          const Radius.circular(2),
        ),
        wood,
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      r * .82,
      Paint()
        ..color = const Color(0xFFDBAF72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(Offset.zero, 5, Paint()..color = const Color(0xFF4C4639));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Waterwheel old) =>
      t != old.t || night != old.night;
}

/// The atlas contains six species, each with three genuinely different stages.
/// Stage four keeps the mature plant and adds a soft halo.
class GardenPlantArt extends StatelessWidget {
  final SeedType seed;
  final int count;
  final bool night;
  const GardenPlantArt({
    super.key,
    required this.seed,
    required this.count,
    this.night = false,
  });
  @override
  Widget build(BuildContext context) {
    final tier = seed.tierForCount(count);
    if (tier == 0) return const SizedBox.shrink();
    final column = SeedType.all.indexWhere((s) => s.id == seed.id);
    final row = (tier - 1).clamp(0, 2);
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(box.maxWidth, box.maxHeight);
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: side,
            height: side,
            child: GardenGroundedArt(
              night: night,
              child: GardenAtlasArt(
                asset: 'assets/living_garden/plants.webp',
                column: column,
                row: row,
                columns: 6,
                rows: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}
