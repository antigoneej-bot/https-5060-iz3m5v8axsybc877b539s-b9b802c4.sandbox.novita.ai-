import '../../../theme.dart' show appFontFallback;
import 'dart:math' as math;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../models/emotion.dart';
import '../../services/sound_manager.dart';

/// 화면 왼쪽 고정 위치에서 두 발로 걷는 몽이.
/// 조작은 오직 하나 -> jump() 호출 (탭/스페이스바). 그 외 동작(펀치/먹기/축하)은 전부 자동.
class CatPlayer extends SpriteAnimationComponent with CollisionCallbacks {
  final double groundY;

  /// "마음 상자" 가챠로 획득해 장착한 코스튬 액세서리 이미지 경로.
  /// null이면 아무 것도 씌우지 않은 기본 모습.
  final String? costumeAsset;
  final double costumeOffsetXRatio;
  final double costumeOffsetYRatio;
  final double costumeScaleRatio;
  Sprite? _costumeSprite;

  double velocityY = 0;
  bool isGrounded = true;

  /// 러너 게임이 자동으로 진행되는 동안 true. [RunnerGame.onLoad]에서 한 번
  /// true로 켜진 뒤 스테이지가 끝날 때까지 계속 걷기 애니메이션을 유지한다.
  bool isWalking = false;

  late SpriteAnimation walkAnimation;
  late SpriteAnimation idleAnimation;
  late SpriteAnimation jumpAnimation;
  late SpriteAnimation punchAnimation;
  late SpriteAnimation eatAnimation;
  late SpriteAnimation happyAnimation;
  late SpriteAnimation cryAnimation;

  /// 펀치/먹기처럼 짧게 재생되고 다시 걷기로 돌아가는 동작이 진행 중인 시간(초).
  /// 0보다 크면 "일시 동작 중" 상태이며, 0이 되면 (땅에 있을 때) 걷기 애니메이션으로 복귀한다.
  double _transientTimer = 0;

  /// 걷는 동안 발소리 효과음을 4프레임 걷기 사이클에 맞춰 재생하기 위한 타이머.
  double _stepTimer = 0;
  static const double _stepInterval = 0.24; // 걷기 사이클(0.48s)당 두 번 발소리

  // --- 긍정적인 감정을 "가슴으로 받는" 빛 아우라 ---------------------------
  // [receiveLight]가 호출될 때마다 갱신된다. _auraBaseAlpha/_auraRadius는
  // 이번 판에서 긍정 감정을 받을 때마다 점점 커지도록 설계되어(RunnerGame이
  // 계산해 넘겨주는 glowLevel 기반) "받을수록 점점 밝아지는" 누적 연출을
  // 만든다. _auraPulseAlpha는 매번 받는 순간 반짝 튀었다가 금방 가라앉는
  // 임시 하이라이트로, 지속 밝기 위에 겹쳐 그려진다.
  double _auraBaseAlpha = 0;
  double _auraPulseAlpha = 0;
  double _auraRadius = 0;
  Color _auraColor = const Color(0xFFFFE39A);

  // --- 파워빛볼(무적 모드) 시각 효과 ---------------------------------------
  /// [RunnerGame.isPoweredUp]이 true인 동안 몸 주위로 계속 반짝이는 황금빛
  /// 링. 긍정 감정 아우라([_auraColor] 등)와는 별개의 레이어로, 무적 모드가
  /// 끝나면 즉시 사라진다(지속 누적 없음 - 순수 상태 표시용).
  bool _powered = false;
  double _powerPulsePhase = 0;

  /// 무적 모드가 몇 초 동안 지속되는지, 그리고 지금까지 얼마나 지났는지 -
  /// 머리 위 카운트다운 숫자를 계산하는 데 쓰인다. [RunnerGame]이 실제
  /// 남은 시간을 관리하지만(_powerRemaining), 그 값을 매 프레임 넘겨받는
  /// 대신 [setPowered]가 시작될 때 총 지속시간만 한 번 받아서 몽이 스스로
  /// 카운트다운을 세어나간다(더 단순하고, 표시 오차도 사실상 없다).
  double _powerDuration = 0;
  double _powerElapsed = 0;
  int get _powerSecondsLeft =>
      (_powerDuration - _powerElapsed).ceil().clamp(0, 99);

  /// 카운트다운 숫자의 [TextPainter]를 매 프레임(60fps) 새로 만들지 않도록
  /// 숫자가 바뀔 때만(초 단위) 다시 만들어서 캐싱해둔다.
  ///
  /// 처음엔 [_renderPowerCountdown]에서 매 render() 호출마다 TextPainter를
  /// 새로 생성 + layout()을 실행했는데, 이게 무적 모드 10초 동안 매 프레임
  /// 반복되면서 렌더링 부하가 커져 "주먹이 안 나가고 버벅거린다"는 입력
  /// 지연 문제로 이어졌다. 초 단위로만 다시 계산하면 이 부하가 사실상
  /// 사라진다.
  TextPainter? _powerCountdownPainter;
  int _powerCountdownCachedSeconds = -1;

  // 예전 값(gravity 2400 / jumpVelocity -780) -> 한 번 상향(2000 / -920) ->
  // 체공 시간을 40% 늘렸었지만(0.92s -> 1.29s), 이후 "점프가 너무 길어서
  // 장애물에 걸려 죽는다"는 피드백을 받아 기본 점프는 다시 짧게(체공 시간
  // 약 0.86s) 되돌렸다. 대신 점프를 발동한 손가락을 화면에서 떼지 않고 계속
  // 누르고 있으면(길게 누르기) [_holdGravityFactor]/[_maxHoldExtension]에
  // 의해 상승 구간 중력이 잠깐 약해져서 점프가 더 오래, 더 높이 이어지는
  // "차지 점프"가 된다 - 평소엔 짧고 가볍게, 필요할 때만 눌러서 길게.
  // 장애물 이동 속도를 여러 차례 올린 뒤 "점프/주먹 반응이 장애물보다
  // 느리다"는 피드백을 받아, 중력/점프 속도도 더 반응이 빠르고 짧게
  // 끊어지는 느낌으로 상향했다(체공 시간이 짧아져 장애물을 더 빠르게
  // 다시 피하거나 때릴 수 있다).
  static const double gravity = 1700; // was 1400
  static const double jumpVelocity = -640; // was -600

  /// 점프를 일으킨 터치를 계속 누르고 있는 동안(상승 중일 때만) 중력에
  /// 곱해지는 배율 - 1보다 작을수록 더 천천히 떠올라 체공 시간과 높이가
  /// 늘어난다. [_maxHoldExtension]초가 지나면 이 효과는 끝나고 원래
  /// 중력으로 돌아온다(무한정 눌러도 끝없이 길어지지 않도록 상한을 둠).
  static const double _holdGravityFactor = 0.45;
  static const double _maxHoldExtension = 0.35;

  /// 점프를 발동시킨 터치가 아직 화면에 닿아 있는지. [setJumpHeld]로 화면
  /// 쪽(러너 게임 화면의 포인터 down/up)에서 갱신해준다.
  bool _jumpHeld = false;
  double _holdExtensionUsed = 0;

  /// 코스메틱한 앞으로 도약 사인 곡선 계산에 쓰는, 이번 점프의 "예상" 체공
  /// 시간 - 홀드 중이면 차지 점프 쪽 추정치를, 아니면 기본 점프 추정치를
  /// 쓴다(정확한 물리값이 아니어도 시각 효과일 뿐이라 문제 없음).
  static const double _baseFlightDurationEstimate = 0.62; // was 0.86
  static const double _heldFlightDurationEstimate = 0.86; // was 1.2
  double get _jumpFlightDuration =>
      _jumpHeld ? _heldFlightDurationEstimate : _baseFlightDurationEstimate;

  /// 점프 중 앞으로 살짝 뛰어나가는 도약감을 표현하기 위한 기준 x좌표.
  /// (몽이는 화면상 고정 위치에 있고 배경/장애물이 흘러가는 구조라, 점프할 때만
  /// 잠깐 앞으로 나갔다가 착지하면 원래 자리로 돌아온다.)
  double _baseX = 0;
  double _jumpElapsed = 0;
  static const double _jumpForwardDistance = 44;

  CatPlayer({
    required this.groundY,
    this.costumeAsset,
    this.costumeOffsetXRatio = 0.5,
    this.costumeOffsetYRatio = 0.16,
    this.costumeScaleRatio = 0.62,
  }) : super(anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    size = Vector2(118, 128);

    if (costumeAsset != null) {
      // costumeAsset은 "assets/mongi/images/xxx.png" 형태의 전체 경로로 넘어오므로,
      // Flame의 Sprite.load는 images/ 폴더 기준 상대경로를 기대하기 때문에
      // 접두사를 제거해서 로드한다.
      final trimmed = costumeAsset!.replaceFirst('assets/mongi/images/', '');
      try {
        _costumeSprite = await Sprite.load(trimmed);
      } catch (_) {
        _costumeSprite = null;
      }
    }

    // 두 발로 걷는 4프레임 걷기 애니메이션 (다리가 실제로 움직임)
    final walkFrames = await Future.wait([
      Sprite.load('cat_walk_0.png'),
      Sprite.load('cat_walk_1.png'),
      Sprite.load('cat_walk_2.png'),
      Sprite.load('cat_walk_3.png'),
    ]);
    walkAnimation = SpriteAnimation.spriteList(
      walkFrames,
      stepTime: 0.12,
      loop: true,
    );
    // 손을 떼고 있을 때 서 있는 모습 - 새 아트 없이 걷기 사이클의 첫 프레임을
    // 그대로 정지 화면으로 재사용한다 (양발이 모여 있어 자연스러운 대기 포즈).
    idleAnimation = SpriteAnimation.spriteList(
      [walkFrames[0]],
      stepTime: 1,
      loop: false,
    );

    final jumpSprite = await Sprite.load('cat_jump.png');
    jumpAnimation = SpriteAnimation.spriteList(
      [jumpSprite],
      stepTime: 1,
      loop: false,
    );

    final punchSprite = await Sprite.load('cat_punch.png');
    punchAnimation = SpriteAnimation.spriteList(
      [punchSprite],
      stepTime: 1,
      loop: false,
    );

    final eatSprite = await Sprite.load('cat_eating.png');
    eatAnimation = SpriteAnimation.spriteList(
      [eatSprite],
      stepTime: 1,
      loop: false,
    );

    final happySprite = await Sprite.load('cat_happy.png');
    happyAnimation = SpriteAnimation.spriteList(
      [happySprite],
      stepTime: 1,
      loop: false,
    );

    final crySprite = await Sprite.load('cat_cry.png');
    cryAnimation = SpriteAnimation.spriteList(
      [crySprite],
      stepTime: 1,
      loop: false,
    );

    animation = idleAnimation;
    position.y = groundY;
    _baseX = position.x;

    add(
      RectangleHitbox(
        size: Vector2(size.x * 0.62, size.y * 0.58),
        position: Vector2(size.x * 0.18, size.y * 0.30),
      ),
    );
  }

  /// 화면 터치 여부에 따라 걷기/대기 상태를 전환한다. 펀치/먹기/점프 등
  /// 다른 동작이 진행 중일 때는 그 동작이 끝난 뒤에 반영된다.
  void setWalking(bool walking) {
    if (isWalking == walking) return;
    isWalking = walking;
    if (isGrounded && _transientTimer <= 0) {
      animation = isWalking ? walkAnimation : idleAnimation;
    }
  }

  void jump() {
    if (!isGrounded) return;
    _cancelPunchMotion();
    position.x = _baseX;
    _transientTimer = 0;
    _jumpElapsed = 0;
    _holdExtensionUsed = 0;
    velocityY = jumpVelocity;
    isGrounded = false;
    animation = jumpAnimation;
    SoundManager.instance.playJump();
  }

  /// 점프를 일으킨 손가락(또는 스페이스바)이 아직 눌린 상태인지 화면 쪽에서
  /// 알려준다. true인 동안에는(그리고 [_maxHoldExtension] 한도 내에서는)
  /// 상승 구간 중력이 약해져 점프가 더 길게/높게 이어진다 - "손으로 쭉
  /// 당기면(누르고 있으면) 점프가 길어지는" 요청 사항을 구현한 것.
  void setJumpHeld(bool held) {
    _jumpHeld = held;
  }

  SequenceEffect? _punchMove;
  SequenceEffect? _punchScale;

  void _cancelPunchMotion() {
    _punchMove?.removeFromParent();
    _punchScale?.removeFromParent();
    _punchMove = null;
    _punchScale = null;
    scale = Vector2.all(1);
  }

  /// 연속 입력이 이동 효과를 쌓거나 점프의 세로 위치를 덮어쓰지 않게 한다.
  void punchSwing() {
    _cancelPunchMotion();
    _transientTimer = 0.16;
    animation = punchAnimation;
    if (isGrounded) {
      _punchMove = SequenceEffect([
        MoveEffect.to(
          Vector2(_baseX + 30, groundY),
          EffectController(duration: 0.06, curve: Curves.easeOut),
        ),
        MoveEffect.to(
          Vector2(_baseX, groundY),
          EffectController(duration: 0.10),
        ),
      ]);
      add(_punchMove!);
    }
    _punchScale = SequenceEffect([
      ScaleEffect.to(Vector2(1.12, 0.92), EffectController(duration: 0.06)),
      ScaleEffect.to(Vector2.all(1), EffectController(duration: 0.10)),
    ]);
    add(_punchScale!);
  }

  void punch() {
    // 타격 성공은 준비 모션을 다시 이동시키지 않고 소리로도 알려준다.
    animation = punchAnimation;
    _transientTimer = 0.16;
    SoundManager.instance.playRockBreak();
  }

  void eat(EmotionType emotionType) {
    SoundManager.instance.playEatForEmotion(emotionType);
    if (!isGrounded) return;
    animation = eatAnimation;
    _transientTimer = 0.26;
  }

  /// 긍정적인 감정을 먹지 않고 가슴으로 받아 안을 때 - 눈을 감고 포근하게
  /// 품는 동작(기존 happyAnimation을 재사용)과 함께, 몸 주위로 그 감정
  /// 고유의 색으로 빛이 은은하게 퍼진다.
  ///
  /// [glowLevel]은 0.0~1.0 범위로, 이번 판에서 지금까지 받은 긍정 감정
  /// 누적치를 나타낸다(RunnerGame이 계산해서 전달) - 값이 클수록 빛이 더
  /// 크고 진하게 남아, "받을수록 점점 밝아지고 행복해지는" 효과를 만든다.
  /// [emotionType]에 따라 반짝이는(sparkle)/따뜻한(warm)/힘찬(triumphant)
  /// 세 가지 효과음 중 어울리는 것을 골라 재생한다.
  void receiveLight(Color color, double glowLevel, EmotionType emotionType) {
    // Airborne pickups still sound and glow; keep the jumping pose and physics.
    SoundManager.instance.playReceiveForEmotion(emotionType);

    final clamped = glowLevel.clamp(0.0, 1.0);
    _auraColor = color;
    // 지속적으로 남는 은은한 밝기 - 매번 받을 때마다 조금씩 더 밝아진다.
    _auraBaseAlpha = 0.14 + clamped * 0.36;
    _auraRadius = size.x * (0.58 + clamped * 0.55);
    // 받는 순간에만 반짝 튀어 오르는 하이라이트(금방 가라앉음).
    _auraPulseAlpha = 0.5;
    if (!isGrounded) return;
    animation = happyAnimation;
    _transientTimer = 0.5;

    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.16),
          EffectController(duration: 0.22, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.28, curve: Curves.easeInOut),
        ),
      ]),
    );
  }

  /// 스테이지를 클리어했을 때 - 배가 부풀어 올랐다가 가라앉으며 골골거리는 느낌.
  void celebrate() {
    animation = happyAnimation;
    _transientTimer = 999; // 다음 스테이지로 넘어갈 때까지 걷기로 돌아가지 않는다.
    SoundManager.instance.playPurr();
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.22),
          EffectController(duration: 0.35, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.35, curve: Curves.easeInOut),
        ),
        ScaleEffect.to(
          Vector2.all(1.22),
          EffectController(duration: 0.35, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.35, curve: Curves.easeInOut),
        ),
      ]),
    );
  }

  /// 돌멩이에 부딪혔을 때 - 게임오버 없이 살짝 움찔하는 정도의 부드러운 피드백만 준다.
  void stumble() {
    add(
      SequenceEffect([
        ScaleEffect.to(Vector2(0.88, 1.08), EffectController(duration: 0.07)),
        ScaleEffect.to(Vector2(1.0, 1.0), EffectController(duration: 0.10)),
      ]),
    );
  }

  /// 목숨을 다 썼을 때 - 게임오버 없이, "오늘은 여기까지 함께했다"는 잔잔한 위로 동작.
  /// 크게 우울해하지도, 과하게 축하하지도 않는 조용한 안도의 골골거림.
  void comfort() {
    animation = happyAnimation;
    _transientTimer = 999; // 다음(선택) 화면으로 넘어갈 때까지 걷기로 돌아가지 않는다.
    SoundManager.instance.playPurr();
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.08),
          EffectController(duration: 0.4, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.4, curve: Curves.easeInOut),
        ),
      ]),
    );
  }

  /// 파워빛볼을 먹어 무적 상태가 시작/종료될 때 [RunnerGame]이 호출한다.
  /// 켜지는 순간에는 몸이 살짝 커졌다가 돌아오는 임팩트 효과를 주고, 머리
  /// 위 카운트다운을 [duration]초부터 다시 세기 시작한다(이미 무적인 동안
  /// 새 파워빛볼을 먹어 갱신되는 경우에도 카운트다운이 처음부터 다시 시작).
  void setPowered(bool powered, {double duration = 0}) {
    if (powered) {
      _powerDuration = duration;
      _powerElapsed = 0;
    }
    if (_powered == powered) return;
    _powered = powered;
    if (powered) {
      _powerPulsePhase = 0;
      add(
        SequenceEffect([
          ScaleEffect.to(
            Vector2.all(1.28),
            EffectController(duration: 0.18, curve: Curves.easeOut),
          ),
          ScaleEffect.to(
            Vector2.all(1.0),
            EffectController(duration: 0.22, curve: Curves.easeInOut),
          ),
        ]),
      );
    }
  }

  /// 무적 상태에서 장애물을 그대로 몸으로 부수고 지나갈 때 - 아프지 않고
  /// 오히려 신나게, 살짝 앞으로 튕겨나가는 듯한 통쾌한 모션.
  void smashThrough() {
    add(
      SequenceEffect([
        ScaleEffect.to(Vector2(1.16, 0.9), EffectController(duration: 0.06)),
        ScaleEffect.to(Vector2(1.0, 1.0), EffectController(duration: 0.12)),
      ]),
    );
  }

  /// 6번(호흡 미니게임): "숨결 구슬"에 닿아 게임이 잠깐 멈추는 동안 - 눈을
  /// 감고 편안하게 서 있는 정지 포즈. happyAnimation을 재사용해(별도
  /// 스프라이트 없이도 충분히 편안한 표정) 러너 게임의 빠른 걷기/펀치/점프
  /// 모션과 뚜렷이 대비시킨다.
  ///
  /// [RunnerGame.startBreathingMoment]는 이 포즈를 설정한 직후 곧바로
  /// engine을 pauseEngine()으로 멈추므로(호흡 다이얼로그가 떠 있는 동안
  /// 배경/장애물도 함께 멈춰야 하기 때문), 이 몸은 실제로는 화면에 정지된
  /// 한 장의 스틸컷처럼 보인다 - 움직이는 효과 대신 정적인 "쉬어가는 포즈"
  /// 자체로 대비를 준다.
  void startBreathingPose() {
    animation = happyAnimation;
    _transientTimer = 999;
    scale = Vector2.all(1.0);
  }

  /// 호흡 미니게임이 끝나고 다시 달리기 시작할 때 - 원래 걷기 상태로 복귀한다.
  void endBreathingPose() {
    _transientTimer = 0;
    animation = isWalking ? walkAnimation : idleAnimation;
  }

  /// (더 이상 실패 처리에는 쓰이지 않지만, 향후 다른 상황을 위해 남겨둔 동작.)
  /// 엎어져서 엉엉 우는 모습.
  void cry() {
    animation = cryAnimation;
    _transientTimer = 999; // 실패 처리가 끝날 때까지 걷기로 돌아가지 않는다.
    SoundManager.instance.playCry();
    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2(1.06, 0.88),
          EffectController(duration: 0.14, curve: Curves.easeOut),
        ),
        ScaleEffect.to(
          Vector2(0.97, 0.97),
          EffectController(duration: 0.30, curve: Curves.easeInOut),
        ),
      ]),
    );
  }

  @override
  void render(Canvas canvas) {
    // 긍정 감정을 받아 몸에 남은 빛 아우라 - 스프라이트보다 먼저 그려서
    // 뒤에서 은은하게 퍼지는 느낌을 준다. 블러 처리로 딱딱한 원이 아니라
    // 부드러운 광채처럼 보이게 한다.
    final totalAlpha = (_auraBaseAlpha + _auraPulseAlpha).clamp(0.0, 0.85);
    if (totalAlpha > 0.01 && _auraRadius > 0) {
      final center = Offset(size.x / 2, size.y * 0.56);
      canvas.drawCircle(
        center,
        _auraRadius,
        Paint()
          ..color = _auraColor.withValues(alpha: totalAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
      );
    }
    // 파워빛볼 무적 모드 - 몸 주위로 계속 반짝이는 황금빛 링(sin 파형으로
    // 은은하게 깜빡인다). 스프라이트보다 먼저 그려서 뒤에서 감싸는 느낌을 준다.
    if (_powered) {
      final pulse = 0.55 + 0.35 * math.sin(_powerPulsePhase * 6.5);
      final center = Offset(size.x / 2, size.y * 0.56);
      canvas.drawCircle(
        center,
        size.x * 0.62,
        Paint()
          ..color = const Color(0xFFFFD84D).withValues(alpha: pulse * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      canvas.drawCircle(
        center,
        size.x * 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFFFF3C0).withValues(alpha: pulse),
      );
    }

    super.render(canvas);

    // 무적 모드 카운트다운 - 몽이 머리 위에 남은 시간을 숫자로 보여줘서
    // "지금 최강 상태이고, 몇 초 남았는지" 플레이어가 바로 알 수 있게 한다.
    if (_powered) {
      _renderPowerCountdown(canvas);
    }

    // 가챠로 얻어 장착한 코스튬을 몽이 위에 겹쳐 그린다. 원본 스프라이트의
    // 가로세로 비율을 유지한 채, costumeScaleRatio를 기준 너비로 삼아
    // costumeOffsetXRatio/YRatio 지점에 중심이 오도록 배치한다.
    final costume = _costumeSprite;
    if (costume != null) {
      final srcSize = costume.srcSize;
      final targetWidth = size.x * costumeScaleRatio;
      final aspect = srcSize.y == 0 ? 1.0 : srcSize.y / srcSize.x;
      final targetHeight = targetWidth * aspect;
      final centerX = size.x * costumeOffsetXRatio;
      final centerY = size.y * costumeOffsetYRatio;
      costume.render(
        canvas,
        position: Vector2(
          centerX - targetWidth / 2,
          centerY - targetHeight / 2,
        ),
        size: Vector2(targetWidth, targetHeight),
      );
    }
  }

  /// 무적 모드 카운트다운 숫자를 몽이 머리 위, 동그란 황금빛 배지 안에
  /// 그린다. TextComponent를 자식으로 추가하는 대신 매 프레임 직접
  /// Canvas.drawParagraph로 그리는 이유: 자식 컴포넌트를 쓰면 숫자가 바뀔
  /// 때마다(매초) add/remove 하거나 별도 상태 동기화가 필요해 번거롭고,
  /// 이 컴포넌트는 이미 자체 render()에서 자유롭게 그릴 수 있으니 여기서
  /// 함께 처리하는 편이 훨씬 간단하다.
  void _renderPowerCountdown(Canvas canvas) {
    final seconds = _powerSecondsLeft;
    final center = Offset(size.x / 2, -26);
    // 배지 배경(황금빛 원판) - 스프라이트 밖(머리 위)에 그려지므로 몽이의
    // 표정/애니메이션을 가리지 않는다.
    canvas.drawCircle(
      center,
      20,
      Paint()
        ..color = const Color(0xFFFFC93C)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      20,
      Paint()
        ..color = const Color(0xFFFFF3C0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    if (_powerCountdownPainter == null ||
        _powerCountdownCachedSeconds != seconds) {
      _powerCountdownCachedSeconds = seconds;
      _powerCountdownPainter = TextPainter(
        text: TextSpan(
          text: '$seconds',
          style: const TextStyle(
            fontFamily: 'GowunDodum',
            fontFamilyFallback: appFontFallback,
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    final painter = _powerCountdownPainter!;
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 받는 순간의 반짝임은 빠르게 가라앉혀 지속되는 은은한 밝기(_auraBaseAlpha)만
    // 남긴다.
    if (_auraPulseAlpha > 0) {
      _auraPulseAlpha = (_auraPulseAlpha - dt * 1.4).clamp(0.0, 1.0);
    }
    if (_powered) {
      _powerPulsePhase += dt;
      _powerElapsed += dt;
    }
    if (!isGrounded) {
      // 상승 중(velocityY < 0)이고, 점프를 일으킨 터치가 계속 눌려있고,
      // 아직 최대 연장 시간을 다 쓰지 않았다면 중력을 약화시켜 더 오래/높이
      // 뜨게 한다. 하강이 시작되면(velocityY >= 0) 항상 원래 중력으로
      // 돌아와 자연스럽게 떨어진다.
      var effectiveGravity = gravity;
      if (_jumpHeld &&
          velocityY < 0 &&
          _holdExtensionUsed < _maxHoldExtension) {
        effectiveGravity = gravity * _holdGravityFactor;
        _holdExtensionUsed += dt;
      }
      velocityY += effectiveGravity * dt;
      position.y += velocityY * dt;

      // 점프 중에는 사인 커브를 따라 앞으로 살짝 도약했다가(정점 부근에서 가장
      // 많이 나가고) 착지 시점에 원래 자리로 돌아온다 - "점프해도 앞으로 안
      // 나간다"는 느낌을 없애기 위한 순수 시각 효과(장애물 판정 위치는 groundY
      // 기준 히트박스로 처리되므로 실제 충돌 로직에는 영향 없다).
      _jumpElapsed += dt;
      final flightRatio = (_jumpElapsed / _jumpFlightDuration).clamp(0.0, 1.0);
      position.x =
          _baseX + math.sin(flightRatio * math.pi) * _jumpForwardDistance;

      if (position.y >= groundY) {
        position.y = groundY;
        position.x = _baseX;
        velocityY = 0;
        isGrounded = true;
        _transientTimer = 0;
        _stepTimer = 0;
        animation = isWalking ? walkAnimation : idleAnimation;
      }
      return;
    }

    if (_transientTimer > 0) {
      _transientTimer -= dt;
      if (_transientTimer <= 0) {
        _transientTimer = 0;
        animation = isWalking ? walkAnimation : idleAnimation;
      }
      return;
    }

    if (!isWalking) {
      // 터치를 떼고 서 있는 동안에는 발소리도 쌓이지 않게 한다.
      _stepTimer = 0;
      return;
    }

    // 걷고 있는 상태(펀치/먹기/축하 중이 아님) - 4프레임 걷기 사이클에 맞춰
    // 귀여운 발소리 효과음을 주기적으로 재생한다.
    _stepTimer += dt;
    if (_stepTimer >= _stepInterval) {
      _stepTimer -= _stepInterval;
      SoundManager.instance.playFootstep();
    }
  }
}
