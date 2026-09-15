import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/scene_biome.dart';
import '../../models/time_of_day_ambience.dart';
import '../runner_game.dart';

/// Stage-based time-of-day palette so the scenery visibly changes as the
/// player progresses, instead of always looking exactly the same two flat
/// rectangles. Still fully procedural (no heavy background art assets).
class ScenePalette {
  final Color sky;
  final Color ground;
  final Color boundary;
  final Color cloud;
  final Color hill;
  final Color tuft;
  final Color sunMoon;
  final bool isNight;

  const ScenePalette({
    required this.sky,
    required this.ground,
    required this.boundary,
    required this.cloud,
    required this.hill,
    required this.tuft,
    required this.sunMoon,
    required this.isNight,
  });

  static ScenePalette forStage(int stage) {
    if (stage >= 7) {
      // Dusk / night - calm, quiet, a little sleepy.
      return const ScenePalette(
        sky: Color(0xFF6E6FA0),
        ground: Color(0xFF52684F),
        boundary: Color(0xFF44573F),
        cloud: Color(0xFFB9BAD9),
        hill: Color(0xFF445A46),
        tuft: Color(0xFF3E5240),
        sunMoon: Color(0xFFF3EFC7),
        isNight: true,
      );
    } else if (stage >= 5) {
      // Golden late-afternoon.
      return const ScenePalette(
        sky: Color(0xFFFFC9A8),
        ground: Color(0xFFC9AE7C),
        boundary: Color(0xFFB89A66),
        cloud: Color(0xFFFFE3CF),
        hill: Color(0xFFE0A467),
        tuft: Color(0xFFAE8C55),
        sunMoon: Color(0xFFFFA65C),
        isNight: false,
      );
    } else if (stage >= 3) {
      // Warm midday.
      return const ScenePalette(
        sky: Color(0xFFFFF3D6),
        ground: Color(0xFFD8E4A0),
        boundary: Color(0xFFC5D488),
        cloud: Color(0xFFFFFBEF),
        hill: Color(0xFFBFD285),
        tuft: Color(0xFFA9C468),
        sunMoon: Color(0xFFFFDD66),
        isNight: false,
      );
    }
    // Stage 1-2: the original soft morning look.
    return const ScenePalette(
      sky: Color(0xFFEAF6FF),
      ground: Color(0xFFCFE8C4),
      boundary: Color(0xFFAED69C),
      cloud: Color(0xFFFFFFFF),
      hill: Color(0xFFBFE0B0),
      tuft: Color(0xFF9FCB8C),
      sunMoon: Color(0xFFFFE38C),
      isNight: false,
    );
  }
}

/// Fixed sun/moon (+ a few stars at night) drawn once in the corner of the
/// sky. Purely decorative, no movement.
class SkyOrb extends PositionComponent {
  final Color color;
  final bool isNight;
  final double areaWidth;
  final double skyHeight;
  late final List<Offset> _stars;

  SkyOrb({
    required this.color,
    required this.isNight,
    required this.areaWidth,
    required this.skyHeight,
  }) : super(position: Vector2.zero(), size: Vector2.zero()) {
    size = Vector2(areaWidth, skyHeight);
    final rand = math.Random(7);
    _stars = isNight
        ? List.generate(
            10,
            (_) => Offset(
              rand.nextDouble() * areaWidth,
              rand.nextDouble() * skyHeight * 0.6,
            ),
          )
        : const [];
  }

  @override
  void render(Canvas canvas) {
    if (isNight) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      for (final s in _stars) {
        canvas.drawCircle(s, 2.0, starPaint);
      }
    }
    final cx = areaWidth * 0.82;
    const cy = 56.0;
    final glowPaint = Paint()..color = color.withValues(alpha: 0.25);
    canvas.drawCircle(Offset(cx, cy), 46, glowPaint);
    final corePaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), 26, corePaint);
  }
}

/// Slow-drifting cloud puff for a gentle parallax feel in the far sky.
/// Loops back to the right edge once it drifts off-screen.
class CloudPuff extends PositionComponent {
  final RunnerGame game;
  final double speed;
  final Color color;
  final math.Random _rand;

  CloudPuff({
    required this.game,
    required this.speed,
    required this.color,
    required Vector2 startPosition,
    math.Random? rand,
  }) : _rand = rand ?? math.Random(),
       super(position: startPosition, size: Vector2(76, 42));

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    canvas.drawOval(const Rect.fromLTWH(6, 16, 64, 18), paint);
    canvas.drawCircle(const Offset(20, 16), 16, paint);
    canvas.drawCircle(const Offset(40, 11), 14, paint);
    canvas.drawCircle(const Offset(56, 18), 12, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isHolding) return;
    position.x -= speed * game.powerSpeedBoost * dt;
    if (position.x < -90) {
      position.x = game.size.x + 40 + _rand.nextDouble() * 140;
      position.y = 12 + _rand.nextDouble() * (game.groundY * 0.42);
    }
  }
}

/// Distant rolling hill silhouette along the horizon - a slow parallax
/// layer that gives the scene a bit of depth beyond the flat ground.
class HillSilhouette extends PositionComponent {
  final RunnerGame game;
  final double speed;
  final Color color;
  final math.Random _rand;

  HillSilhouette({
    required this.game,
    required this.speed,
    required this.color,
    required Vector2 startPosition,
    double hillWidth = 220,
    double hillHeight = 60,
    math.Random? rand,
  }) : _rand = rand ?? math.Random(),
       super(
         position: startPosition,
         size: Vector2(hillWidth, hillHeight),
         anchor: Anchor.bottomLeft,
       );

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.y)
      ..quadraticBezierTo(size.x * 0.5, -size.y * 0.35, size.x, size.y)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isHolding) return;
    position.x -= speed * game.powerSpeedBoost * dt;
    if (position.x < -size.x - 40) {
      position.x = game.size.x + 60 + _rand.nextDouble() * 160;
    }
  }
}

/// Small grass/bush tuft near the path - a bit of forward-motion texture
/// so the ground doesn't look completely empty between obstacles.
class GroundTuft extends PositionComponent {
  final RunnerGame game;
  final double speed;
  final Color color;
  final math.Random _rand;

  GroundTuft({
    required this.game,
    required this.speed,
    required this.color,
    required Vector2 startPosition,
    math.Random? rand,
  }) : _rand = rand ?? math.Random(),
       super(
         position: startPosition,
         size: Vector2(30, 18),
         anchor: Anchor.bottomCenter,
       );

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawCircle(const Offset(8, 14), 9, paint);
    canvas.drawCircle(const Offset(18, 12), 10, paint);
    canvas.drawCircle(const Offset(26, 15), 7, paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isHolding) return;
    position.x -= speed * game.powerSpeedBoost * dt;
    if (position.x < -50) {
      position.x = game.size.x + 30 + _rand.nextDouble() * 220;
    }
  }
}

/// 실제 기기 시각이 밤/새벽일 때, 스테이지 팔레트 위에 아주 은은하게 덮이는
/// 색감 오버레이. 순수 사각형 렌더링만 하므로(RectangleComponent와 동일한
/// 방식) TextComponent에 OpacityEffect를 쓸 때 발생하는 크래시 문제와 무관하다.
class TimeOfDayOverlay extends RectangleComponent {
  TimeOfDayOverlay({
    required TimeOfDayAmbience ambience,
    required Vector2 size,
    int priority = 500,
  }) : super(
         position: Vector2.zero(),
         size: size,
         paint: Paint()
           ..color = ambience.overlayColor.withValues(
             alpha: ambience.overlayAlpha,
           ),
         priority: priority,
       );
}

/// 스테이지가 2단계씩 오를 때마다 완전히 바뀌는 "지역(바이옴)" 배경 실루엣.
/// [HillSilhouette]과 같은 자리(수평선 바로 위)를 대신 채우며, 바이옴에 따라
/// 완전히 다른, 한국적인 모양을 그린다:
/// - garden(벚꽃마을): 부드러운 언덕 + 벚꽃 캐노피 뭉치
/// - city(한옥마을): 기와지붕 실루엣(처마 곡선) + 처마 밑 홍등 불빛
/// - ocean(대나무숲): 대나무 줄기 + 잎 뭉치
/// - mountain(고요한 산사): 뾰족한 산봉우리 + 산 위 작은 사찰(전각) 실루엣
/// 이동/루프 로직은 [HillSilhouette]과 동일해서 그대로 자리를 바꿔 끼울 수 있다.
class BiomeSilhouette extends PositionComponent {
  final RunnerGame game;
  final double speed;
  final SceneBiome biome;
  final Color color;
  final Color accentColor;
  final math.Random _rand;
  final int _windowSeed;

  BiomeSilhouette({
    required this.game,
    required this.speed,
    required this.biome,
    required this.color,
    required this.accentColor,
    required Vector2 startPosition,
    double width = 220,
    double height = 60,
    math.Random? rand,
  }) : _rand = rand ?? math.Random(),
       _windowSeed = (rand ?? math.Random()).nextInt(1 << 30),
       super(
         position: startPosition,
         size: Vector2(width, height),
         anchor: Anchor.bottomLeft,
       );

  @override
  void render(Canvas canvas) {
    switch (biome) {
      case SceneBiome.garden:
        _renderHill(canvas);
      case SceneBiome.city:
        _renderHanok(canvas);
      case SceneBiome.ocean:
        _renderBamboo(canvas);
      case SceneBiome.mountain:
        _renderMountain(canvas);
    }
  }

  /// 벚꽃마을: 부드러운 언덕 위에 벚꽃 캐노피(뭉게뭉게 뭉친 원)를 얹는다.
  void _renderHill(Canvas canvas) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.y)
      ..quadraticBezierTo(size.x * 0.5, -size.y * 0.35, size.x, size.y)
      ..close();
    canvas.drawPath(path, paint);
    // 능선 위로 몽글몽글한 벚꽃 캐노피.
    final blossomPaint = Paint()..color = accentColor.withValues(alpha: 0.9);
    final cx = size.x * 0.5;
    final cy = -size.y * 0.1;
    canvas.drawCircle(Offset(cx, cy), size.y * 0.34, blossomPaint);
    canvas.drawCircle(
      Offset(cx - size.x * 0.16, cy + size.y * 0.14),
      size.y * 0.22,
      blossomPaint,
    );
    canvas.drawCircle(
      Offset(cx + size.x * 0.18, cy + size.y * 0.1),
      size.y * 0.24,
      blossomPaint,
    );
  }

  /// 한옥마을: 완만한 곡선의 기와지붕 처마 + 처마 밑에 매달린 홍등.
  void _renderHanok(Canvas canvas) {
    final paint = Paint()..color = color;
    final bodyTop = size.y * 0.32;
    // 기와지붕 - 양쪽 끝이 살짝 들려 올라간 처마 곡선.
    final roof = Path()
      ..moveTo(-size.x * 0.04, bodyTop)
      ..quadraticBezierTo(size.x * 0.5, -size.y * 0.06, size.x * 1.04, bodyTop)
      ..quadraticBezierTo(size.x * 0.5, bodyTop * 0.5, -size.x * 0.04, bodyTop)
      ..close();
    canvas.drawPath(roof, paint);
    // 지붕 밑 몸체(기둥/벽).
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.08, bodyTop, size.x * 0.84, size.y - bodyTop),
      paint,
    );
    // 처마 밑 홍등(등불) - 시드 고정 랜덤으로 몇 개는 밝게 켜진 것처럼 보이게.
    final litPaint = Paint()..color = accentColor.withValues(alpha: 0.92);
    final dimPaint = Paint()..color = accentColor.withValues(alpha: 0.45);
    final lanternCount = 3;
    final lit = _windowLit ??= () {
      final rng = math.Random(_windowSeed);
      return List<bool>.generate(lanternCount, (_) => rng.nextDouble() < 0.7);
    }();
    for (int i = 0; i < lanternCount; i++) {
      final lx = size.x * (0.22 + i * 0.28);
      final ly = bodyTop + size.y * 0.1;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(lx, ly), width: 9, height: 12),
        lit[i] ? litPaint : dimPaint,
      );
    }
  }

  List<bool>? _windowLit;

  /// 대나무숲: 곧게 뻗은 대나무 줄기 몇 그루 + 마디 + 끝의 잎 뭉치.
  void _renderBamboo(Canvas canvas) {
    final stalkPaint = Paint()..color = color;
    final nodePaint = Paint()..color = color.withValues(alpha: 0.55);
    final leafPaint = Paint()..color = accentColor.withValues(alpha: 0.85);
    final stalkCount = 4;
    for (int i = 0; i < stalkCount; i++) {
      final cx = size.x * (0.12 + i * 0.22);
      final topY = size.y * (0.05 + (i.isEven ? 0.0 : 0.12));
      final stalkW = size.x * 0.045;
      canvas.drawRect(
        Rect.fromLTWH(cx - stalkW / 2, topY, stalkW, size.y - topY),
        stalkPaint,
      );
      // 마디 표시.
      final nodeCount = 3;
      for (int n = 1; n <= nodeCount; n++) {
        final ny = topY + (size.y - topY) * (n / (nodeCount + 1));
        canvas.drawRect(
          Rect.fromLTWH(cx - stalkW / 2, ny, stalkW, 2.4),
          nodePaint,
        );
      }
      // 잎 뭉치.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + stalkW, topY + size.y * 0.06),
          width: size.x * 0.16,
          height: size.y * 0.14,
        ),
        leafPaint,
      );
    }
  }

  /// 고요한 산사: 뾰족한 산봉우리 + 한 봉우리 위에 얹힌 작은 전각(사찰) 실루엣.
  void _renderMountain(Canvas canvas) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.y)
      ..lineTo(size.x * 0.32, size.y * 0.12)
      ..lineTo(size.x * 0.58, size.y * 0.42)
      ..lineTo(size.x * 0.8, size.y * 0.05)
      ..lineTo(size.x, size.y)
      ..close();
    canvas.drawPath(path, paint);
    // 산 위 안개(운무).
    final mistPaint = Paint()..color = accentColor.withValues(alpha: 0.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.32, size.y * 0.42),
        width: size.x * 0.36,
        height: size.y * 0.14,
      ),
      mistPaint,
    );
    // 봉우리 위 작은 전각(사찰) 실루엣 - 기와지붕 + 몸체.
    final templeBase = size.y * 0.05;
    final templeCx = size.x * 0.8;
    final templeRoof = Path()
      ..moveTo(templeCx - size.x * 0.09, templeBase + size.y * 0.1)
      ..lineTo(templeCx, templeBase - size.y * 0.02)
      ..lineTo(templeCx + size.x * 0.09, templeBase + size.y * 0.1)
      ..close();
    canvas.drawPath(templeRoof, paint);
    canvas.drawRect(
      Rect.fromLTWH(
        templeCx - size.x * 0.05,
        templeBase + size.y * 0.1,
        size.x * 0.1,
        size.y * 0.07,
      ),
      paint,
    );
    final flagPaint = Paint()..color = accentColor.withValues(alpha: 0.9);
    canvas.drawCircle(
      Offset(templeCx, templeBase - size.y * 0.03),
      3,
      flagPaint,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isHolding) return;
    position.x -= speed * game.powerSpeedBoost * dt;
    if (position.x < -size.x - 40) {
      position.x = game.size.x + 60 + _rand.nextDouble() * 160;
    }
  }
}

/// 길 옆으로 스쳐 지나가는 바이옴별 작은 소품 - [GroundTuft](수풀)와 같은
/// 자리를 대신 채우며, 바이옴에 맞는 한국적인 모양으로 바뀐다:
/// - garden(벚꽃마을): 수풀 뭉치 위 벚꽃 잎
/// - city(한옥마을): 처마 밑 홍등(작은 등)
/// - ocean(대나무숲): 작은 대나무 잎 다발
/// - mountain(고요한 산사): 작은 돌탑(수르마니)
class BiomeDecor extends PositionComponent {
  final RunnerGame game;
  final double speed;
  final SceneBiome biome;
  final Color color;
  final Color accentColor;
  final math.Random _rand;

  BiomeDecor({
    required this.game,
    required this.speed,
    required this.biome,
    required this.color,
    required this.accentColor,
    required Vector2 startPosition,
    math.Random? rand,
  }) : _rand = rand ?? math.Random(),
       super(
         position: startPosition,
         size: Vector2(30, 18),
         anchor: Anchor.bottomCenter,
       );

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    switch (biome) {
      case SceneBiome.garden:
        // 수풀 뭉치 + 그 위에 살랑이는 벚꽃 잎 두 장.
        canvas.drawCircle(const Offset(8, 14), 9, paint);
        canvas.drawCircle(const Offset(18, 12), 10, paint);
        canvas.drawCircle(const Offset(26, 15), 7, paint);
        final petalPaint = Paint()..color = accentColor;
        canvas.drawCircle(const Offset(14, 3), 3, petalPaint);
        canvas.drawCircle(const Offset(22, 5), 2.4, petalPaint);
      case SceneBiome.city:
        // 처마 밑 작은 홍등 - 갓 + 몸통 + 아래로 늘어진 술.
        final capPaint = Paint()..color = color;
        canvas.drawRect(const Rect.fromLTWH(11, 0, 8, 2.4), capPaint);
        final lanternPaint = Paint()..color = accentColor;
        canvas.drawOval(const Rect.fromLTWH(8, 2, 14, 12), lanternPaint);
        final tasselPaint = Paint()..color = color.withValues(alpha: 0.8);
        canvas.drawRect(const Rect.fromLTWH(14, 14, 2, 5), tasselPaint);
      case SceneBiome.ocean:
        // 작은 대나무 잎 다발 - 가느다란 줄기 + 뾰족한 잎 몇 장.
        final stalkPaint = Paint()..color = color;
        canvas.drawRect(const Rect.fromLTWH(14, 2, 2.4, 16), stalkPaint);
        final leafPaint = Paint()..color = accentColor;
        final leaf1 = Path()
          ..moveTo(15, 4)
          ..lineTo(26, 2)
          ..lineTo(16, 9)
          ..close();
        final leaf2 = Path()
          ..moveTo(15, 9)
          ..lineTo(4, 7)
          ..lineTo(15, 13)
          ..close();
        canvas.drawPath(leaf1, leafPaint);
        canvas.drawPath(leaf2, leafPaint);
      case SceneBiome.mountain:
        // 작은 돌탑(소원을 빌며 쌓은 돌무더기) - 위로 갈수록 작아지는 3단 돌.
        final stonePaint = Paint()..color = color;
        canvas.drawOval(const Rect.fromLTWH(6, 11, 18, 7), stonePaint);
        canvas.drawOval(const Rect.fromLTWH(9, 5, 12, 6.5), stonePaint);
        final topPaint = Paint()..color = accentColor;
        canvas.drawOval(const Rect.fromLTWH(11.5, 0.5, 7, 5), topPaint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isHolding) return;
    position.x -= speed * game.powerSpeedBoost * dt;
    if (position.x < -50) {
      position.x = game.size.x + 30 + _rand.nextDouble() * 220;
    }
  }
}

/// 밤 시간대에만 화면 위쪽 하늘을 천천히 떠다니는 작은 반딧불이 점. 스테이지
/// 진행과 무관하게 실제 시각이 밤일 때만 몇 개 추가되어 "밤 정원"임을 은은하게
/// 알려준다. RectangleComponent와 마찬가지로 순수 렌더 컴포넌트라 OpacityEffect
/// 제약과 무관하며, 대신 자체 sin 파형으로 은은한 깜빡임을 흉내낸다.
class Firefly extends PositionComponent {
  final RunnerGame game;
  final double driftSpeed;
  final double swayAmplitude;
  final double swaySpeed;
  final double blinkSpeed;
  final math.Random _rand;
  double _time;
  final double _baseY;

  Firefly({
    required this.game,
    required Vector2 startPosition,
    required this.driftSpeed,
    required this.swayAmplitude,
    required this.swaySpeed,
    required this.blinkSpeed,
    math.Random? rand,
  }) : _rand = rand ?? math.Random(),
       _time = (rand ?? math.Random()).nextDouble() * 10,
       _baseY = startPosition.y,
       super(position: startPosition, size: Vector2.all(6));

  @override
  void render(Canvas canvas) {
    final blink = 0.45 + 0.45 * math.sin(_time * blinkSpeed);
    final glowPaint = Paint()
      ..color = const Color(0xFFEFFFA0).withValues(alpha: blink * 0.35);
    canvas.drawCircle(const Offset(3, 3), 7, glowPaint);
    final corePaint = Paint()
      ..color = const Color(0xFFF5FFB8).withValues(alpha: blink);
    canvas.drawCircle(const Offset(3, 3), 2.4, corePaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isHolding) return;
    _time += dt;
    position.x -= driftSpeed * game.powerSpeedBoost * dt;
    position.y = _baseY + math.sin(_time * swaySpeed) * swayAmplitude;
    if (position.x < -20) {
      position.x = game.size.x + 10 + _rand.nextDouble() * 120;
    }
  }
}
