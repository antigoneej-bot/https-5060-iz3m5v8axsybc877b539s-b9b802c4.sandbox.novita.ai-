import '../../../theme.dart' show appFontFallback;
import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../l10n/emotion_l10n.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/gen/app_localizations_ko.dart';
import '../../models/emotion.dart';
import '../runner_game.dart';
import 'cat_player.dart';

/// 감정 몬스터: 몽이가 닿으면 자동으로 "냠"하고 먹어치운다 (별도 탭 불필요).
/// 이름을 입력했다면 몬스터 위에 "OO의 화르르" 같은 이름표를 띄운다.
///
/// 5번: 몬스터 감정 라벨링 - "화"라는 뭉뚱그린 감정 범주 대신, 정원에 이미
/// 심어진 횟수([metCount], [EmotionEvolutionService]의 진화 이름)에 맞는
/// 구체적인 애칭("화르르"→"잔불이"→"온기")으로 이름표를 붙인다. 감정에
/// 이름을 붙여 부르는 것 자체가 감정을 다루는 첫걸음이라는 생각에서다.
///
/// [floating]이 true이면 공중에 살짝 떠서 위아래로 둥실둥실 움직이는
/// "점프해서 먹는" 버전이 된다 - 걷기만으로는 닿지 않고, 점프해서 맞춰야
/// 먹을 수 있다 (놓쳐도 페널티는 없음 - 콤보 기회 하나를 놓치는 정도).
///
/// 움직임 개성(Move archetype) - 예전에는 모든 몬스터가 감정 종류와 무관하게
/// 똑같은 sin파 하나로만 움직여서("떠 있으면 위아래로 둥실", 그 외엔 정지)
/// 20가지 감정이 다 똑같아 보인다는 아쉬움이 있었다. 이제 각 감정의 성격에
/// 맞는 고유한 리듬을 부여한다 - 예를 들어 불안/두려움은 자잘하게 떨고,
/// 슬픔/외로움은 느리고 무겁게 가라앉았다 떠오르며, 기쁨/설렘은 통통 튄다.
/// 충돌 판정에 쓰이는 위치([position])는 바닥 몬스터에서는 절대 건드리지
/// 않고(길 아래로 파묻혀 보이는 버그 방지), 대신 안전한 [scale] 변형으로
/// "숨 쉬는 듯한" 개성을 표현한다.
enum _MoveArchetype { steady, shiver, droop, pulse, glide, bouncy, swirl }

const Map<EmotionType, _MoveArchetype> _emotionMoveArchetypes = {
  // 부정 감정 10가지
  EmotionType.hate: _MoveArchetype.droop,
  EmotionType.anger: _MoveArchetype.pulse,
  EmotionType.worry: _MoveArchetype.shiver,
  EmotionType.sadness: _MoveArchetype.droop,
  EmotionType.loneliness: _MoveArchetype.droop,
  EmotionType.anxiety: _MoveArchetype.shiver,
  EmotionType.shame: _MoveArchetype.shiver,
  EmotionType.irritation: _MoveArchetype.pulse,
  EmotionType.grievance: _MoveArchetype.droop,
  EmotionType.fear: _MoveArchetype.shiver,
  // 긍정 감정 5가지
  EmotionType.joy: _MoveArchetype.bouncy,
  EmotionType.gratitude: _MoveArchetype.glide,
  EmotionType.excitement: _MoveArchetype.bouncy,
  EmotionType.calm: _MoveArchetype.glide,
  EmotionType.confidence: _MoveArchetype.bouncy,
  // 추가 감정 5가지
  EmotionType.tired: _MoveArchetype.droop,
  EmotionType.boredom: _MoveArchetype.swirl,
  EmotionType.courage: _MoveArchetype.pulse,
  EmotionType.thrill: _MoveArchetype.bouncy,
  EmotionType.happiness: _MoveArchetype.glide,
};

class EmotionMonsterComponent extends SpriteComponent with CollisionCallbacks {
  final RunnerGame game;
  final Emotion emotion;
  final String? name;
  final double speed;
  final bool floating;

  /// 이 판이 시작되기 전까지 정원에 이 감정 타입이 심어진 횟수 - 몬스터
  /// 이름표에 어떤 진화 애칭을 보여줄지 결정한다(0이면 기본형 이름).
  final int metCount;

  /// 영어지원: 몬스터 이름표(진화 애칭)를 언어별로 보여주기 위한
  /// [AppLocalizations]. 넘기지 않으면(테스트 등) 한국어 기본값으로 동작한다.
  final AppLocalizations l10n;

  EmotionMonsterComponent({
    required this.game,
    required this.emotion,
    this.name,
    this.speed = 230,
    this.floating = false,
    this.metCount = 0,
    AppLocalizations? l10n,
  }) : l10n = l10n ?? AppLocalizationsKo(),
       super(anchor: Anchor.bottomCenter);

  bool _handled = false;
  double _bobPhase = 0;
  double _baseY = 0;
  late final _MoveArchetype _archetype;
  late final double _phaseOffset;

  @override
  Future<void> onLoad() async {
    size = Vector2(76, 76);
    _baseY = position.y;
    _archetype = _emotionMoveArchetypes[emotion.type] ?? _MoveArchetype.steady;
    // 몬스터마다 위상을 조금씩 다르게 시작시켜, 같은 감정이 여러 마리
    // 동시에 등장해도 완전히 같은 박자로 움직이지 않게 한다.
    _phaseOffset = math.Random().nextDouble() * math.pi * 2;
    final fileName = emotion.monsterAsset.replaceFirst(
      'assets/mongi/images/',
      '',
    );
    sprite = await Sprite.load(fileName);
    add(
      RectangleHitbox(
        size: Vector2(size.x * 0.65, size.y * 0.65),
        position: Vector2(size.x * 0.17, size.x * 0.17),
      ),
    );

    final nickname = evolutionNameForCount(l10n, emotion.type, metCount);
    final label = (name != null && name!.trim().isNotEmpty)
        ? '${name!.trim()}의 $nickname${floating ? ' 🦘' : ''}'
        : '$nickname${floating ? ' 🦘' : ''}';

    add(
      TextComponent(
        text: label,
        anchor: Anchor.bottomCenter,
        position: Vector2(size.x / 2, -6),
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: Color(0xFF4A3F35),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// 감정별 고유 움직임에서, 좌우로 살랑거리는 성분만 매 프레임 "델타"로
  /// 계산해 position.x에 더한다(전체 오프셋을 매번 그대로 더하면 계속
  /// 누적돼 몬스터가 화면 밖으로 튕겨 나가버리므로, 직전 프레임과의 차이만
  /// 반영해야 한다).
  double _lastHorizontalOffset = 0;

  @override
  void update(double dt) {
    super.update(dt);
    // 스테이지가 끝난 뒤(마무리 애니메이션 중)에는 남은 몬스터도 멈춘다.
    if (!game.isHolding || game.stageCompleted) return;
    position.x -= speed * game.powerSpeedBoost * dt;
    _bobPhase += dt;
    final t = _bobPhase + _phaseOffset;

    double verticalOffset = 0;
    double horizontalOffset = 0;
    double scaleX = 1.0;
    double scaleY = 1.0;

    if (floating) {
      // 기존 "공중에 떠 있다" 기본 둥실거림은 그대로 유지한다.
      verticalOffset += math.sin(t * 3.2) * 8;
    }

    // 감정 성격에 맞는 고유 리듬을 더한다 - 20가지 감정이 전부 똑같이
    // 움직이지 않고, 각자의 정서적 질감이 시각적으로도 느껴지게 한다.
    switch (_archetype) {
      case _MoveArchetype.steady:
        break;
      case _MoveArchetype.shiver:
        // 불안/두려움/부끄러움처럼 자잘하게 떠는 감정 - 빠르고 미세한 진동.
        horizontalOffset = math.sin(t * 26) * 2.4;
        final jitter = (math.sin(t * 32) + 1) / 2;
        scaleX = 1.0 + jitter * 0.035;
        scaleY = 1.0 - jitter * 0.035;
      case _MoveArchetype.droop:
        // 슬픔/외로움/피곤처럼 무겁게 가라앉았다 천천히 떠오르는 감정.
        final wave = math.sin(t * 1.3);
        verticalOffset += wave * (floating ? 3.0 : 2.5);
        scaleY = 1.0 - (0.5 + 0.5 * wave) * 0.045;
      case _MoveArchetype.pulse:
        // 화/짜증/용기처럼 안에서 뜨겁게 두근거리는 감정 - 리드미컬한 맥동.
        final p = (math.sin(t * 5.0) + 1) / 2;
        scaleX = 1.0 + p * 0.09;
        scaleY = 1.0 + p * 0.09;
      case _MoveArchetype.glide:
        // 감사/평온/행복처럼 잔잔하고 부드럽게 흘러가는 감정.
        verticalOffset += math.sin(t * 1.7) * 3;
        horizontalOffset = math.sin(t * 1.05) * 3;
      case _MoveArchetype.bouncy:
        // 기쁨/설렘/자신감/신남처럼 통통 튀어 오르는 밝은 감정.
        final b = math.sin(t * 6.0).abs();
        verticalOffset -= b * 6;
        scaleY = 1.0 - b * 0.05;
        scaleX = 1.0 + b * 0.03;
      case _MoveArchetype.swirl:
        // 심심함처럼 목적 없이 느슨하게 맴도는 감정 - 작은 원을 그린다.
        horizontalOffset = math.cos(t * 2.0) * 4;
        verticalOffset += math.sin(t * 2.0) * 4;
    }

    position.y = _baseY + verticalOffset;
    position.x += horizontalOffset - _lastHorizontalOffset;
    _lastHorizontalOffset = horizontalOffset;
    if (scaleX != 1.0 || scaleY != 1.0) {
      scale.setValues(scaleX, scaleY);
    }

    if (position.x < -140) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is CatPlayer && isMounted && !_handled) {
      if (!game.stageCompleted && !game.acceptsGameplayInput) return;
      _handled = true;
      // 스테이지가 이미 끝난 뒤에는 몬스터를 먹는 판정을 하지 않는다(마무리
      // 애니메이션 중에 진행도가 계속 올라가는 것처럼 보이는 것을 방지).
      if (game.stageCompleted) {
        removeFromParent();
        return;
      }
      if (emotion.isPositive) {
        // 긍정적인 감정은 먹어치우는 대신 가슴으로 받아 안는다 - 몽이가
        // 빛나고, 이 자리에서 반짝이는 빛무리가 은은하게 퍼져 사라진다.
        game.onLightReceived(position.clone(), emotion);
      } else {
        other.eat(emotion.type);
        game.onMonsterEaten(position.clone(), emotion);
      }
      removeFromParent();
    }
  }
}
