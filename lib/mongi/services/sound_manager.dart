import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/emotion.dart';

/// 게임 전반의 배경음악(BGM)과 효과음(SFX) 재생을 담당하는 매니저.
///
/// 오디오 재생은 게임 플레이에 있어 "있으면 좋은" 부가 요소이므로,
/// 오디오 재생 실패(테스트 환경, 플랫폼 미지원, 자산 로드 실패 등)가
/// 절대로 게임 로직/애니메이션을 막거나 예외를 던지지 않도록 설계되었다.
///
/// - 모든 재생 호출은 내부적으로 예외를 삼킨다.
/// - AudioPlayer 인스턴스는 실제로 재생이 필요한 시점에만 지연 생성한다
///   (테스트 환경에서 [setEnabled]로 완전히 비활성화하면 플러그인 채널을
///   전혀 건드리지 않아 MissingPluginException 자체가 발생하지 않는다).
class SoundManager {
  SoundManager._internal();
  static final SoundManager instance = SoundManager._internal();

  bool musicEnabled = true;
  bool effectsEnabled = true;
  bool _enabled = true;
  bool _muted = false;
  bool _bgmStarted = false;
  bool _ambientStarted = false;

  /// 발소리를 지금 재생해서는 안 되는 구간(스테이지 종료 순간부터 다음
  /// 스테이지가 시작되기 전까지, 또는 사용자가 종료 버튼으로 완전히
  /// 나갈 때)인지. [stopFootstep]이 true로 켜고, [resumeFootstep]이
  /// (다음 스테이지가 시작될 때) 다시 false로 되돌린다.
  ///
  /// 이 플래그가 필요한 이유(경쟁 상태 버그 수정): [playFootstep]은 내부적으로
  /// 여러 단계의 await(오디오 컨텍스트 설정 -> releaseMode 설정 -> stop ->
  /// setVolume -> play)를 거치는 비동기 호출이다. 걷기 사이클상 발소리가
  /// 막 호출된 바로 그 프레임에 스테이지가 끝나 [stopFootstep]이 호출되면,
  /// 이미 진행 중이던 [playFootstep]의 await 체인이 그 뒤에도 계속 이어져
  /// "정지시킨 다음에" 오히려 재생을 완료해버릴 수 있다 - 이게 바로
  /// "숨쉬기 인터스티셜 중에도 발자욱 소리가 들린다"는 버그의 원인이었다.
  /// [playFootstep]이 매 await 지점마다 이 플래그를 다시 확인해 즉시
  /// 중단하도록 해서 이 경쟁 상태를 근본적으로 막는다.
  bool _footstepSuppressed = false;

  AudioPlayer? _bgmPlayer;
  AudioPlayer? _ambientBirdsPlayer;
  AudioPlayer? _ambientWaterPlayer;
  AudioPlayer? _footstepPlayer;
  AudioPlayer? _jumpPlayer;
  AudioPlayer? _rockPlayer;
  AudioPlayer? _eatPlayer;
  AudioPlayer? _cryPlayer;
  AudioPlayer? _purrPlayer;
  AudioPlayer? _meowPlayer;

  // --- 감정별로 구분된 "먹기"/"받기" 효과음 -----------------------------
  // 부정 감정 10종을 3그룹(sharp/heavy/soft), 긍정 감정(+추가분) 8종을
  // 3그룹(sparkle/warm/triumphant)으로 나눠, 20개를 전부 따로 만들지 않고도
  // 감정 성격에 맞는 뚜렷한 소리 차이를 낸다(아래 [playEatForEmotion],
  // [playReceiveForEmotion] 매핑 참고).
  AudioPlayer? _eatSharpPlayer;
  AudioPlayer? _eatHeavyPlayer;
  AudioPlayer? _eatSoftPlayer;
  AudioPlayer? _receiveSparklePlayer;
  AudioPlayer? _receiveWarmPlayer;
  AudioPlayer? _receiveTriumphantPlayer;

  /// 골골송이 짧은 시간 안에 여러 번 겹쳐서 "난무"하는 느낌을 주지 않도록,
  /// 마지막으로 재생된 시각을 기억해 최소 간격을 두고서만 실제로 소리를 낸다.
  /// (예: 긍정 감정을 연달아 여러 번 받으면 [playPurr]가 짧은 시간에 계속
  /// 호출될 수 있는데, 이 쿨다운이 그중 일부만 걸러서 재생해 적당한 빈도를
  /// 유지시켜준다. 스테이지 클리어/조기종료처럼 한 번만 부르는 경우는
  /// 쿨다운에 거의 영향받지 않는다.)
  DateTime? _lastPurrAt;
  static const Duration _purrCooldown = Duration(milliseconds: 2600);

  bool get isMuted => _muted;

  /// Android에서 오디오 포커스를 "독점(gain)"하지 않고 다른 사운드와 함께
  /// 섞여서(mix) 재생되도록 하는 설정.
  ///
  /// audioplayers의 기본 오디오 포커스 모드는 gain(독점)이라서, 새 소리가
  /// 재생될 때마다 이미 재생 중이던 다른 플레이어(배경음악 등)의 포커스를
  /// 빼앗아 그 소리를 멈춰버린다. 이 앱은 배경음악 위에 걷기/점프/먹기 같은
  /// 효과음이 짧게 겹쳐서 계속 재생되는 구조라, mixWithOthers를 설정하지
  /// 않으면 "걸을 때마다 발소리가 배경음악을 끊어버리는" 문제가 생긴다.
  /// (실제 증상: 스테이지를 진행하면 배경음악이 안 들린다고 느껴짐.)
  static final AudioContext _mixContext = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  /// 이미 mix 컨텍스트를 적용한 플레이어들 - 매번 재생할 때마다 플러그인
  /// 채널을 다시 호출하지 않도록, 플레이어를 새로 만들 때 딱 한 번만 적용한다.
  final Set<AudioPlayer> _contextApplied = {};

  Future<void> _ensureMixContext(AudioPlayer player) async {
    if (_contextApplied.contains(player)) return;
    _contextApplied.add(player);
    try {
      await player.setAudioContext(_mixContext);
    } catch (_) {
      // 무시: 컨텍스트 설정 실패는 치명적이지 않다 (기본 컨텍스트로 재생됨).
    }
  }

  /// 짧게 반복 재생되는 효과음(발소리 등)이 매번 웹 오디오 그래프를 통째로
  /// 파괴/재생성하지 않도록, releaseMode를 [ReleaseMode.stop]으로 한 번만
  /// 바꿔둔다.
  ///
  /// audioplayers의 기본 releaseMode는 [ReleaseMode.release]인데, 웹
  /// 플랫폼에서는 재생이 끝나거나 [AudioPlayer.stop]이 호출될 때마다
  /// AudioElement + AudioContext 노드(GainNode/StereoPannerNode/
  /// MediaElementSourceNode)를 전부 disconnect/삭제하고, 다음 재생 시
  /// 이걸 처음부터 새로 만든다. 발소리처럼 0.24초마다(초당 4번) 재생되는
  /// 소리에 이 비용이 반복되면 프레임마다 렌더링과 경쟁하는 무거운 작업이
  /// 되어 "게임이 버벅거린다"는 증상으로 이어진다. releaseMode를 [stop]으로
  /// 두면 재생이 끝나도 노드를 살려둔 채 재생 위치만 0으로 되돌리므로,
  /// 반복 재생 시 오디오 그래프 재구성 비용이 사실상 사라진다(이미 캐싱해둔
  /// AudioPlayer 인스턴스를 계속 재사용하는 이 앱 구조와도 잘 맞는다).
  final Set<AudioPlayer> _stopReleaseModeApplied = {};

  Future<void> _ensureStopReleaseMode(AudioPlayer player) async {
    if (_stopReleaseModeApplied.contains(player)) return;
    _stopReleaseModeApplied.add(player);
    try {
      await player.setReleaseMode(ReleaseMode.stop);
    } catch (_) {
      // 무시: 설정 실패해도 기본 동작(release)으로 재생은 계속 가능하다.
    }
  }

  /// 오디오 시스템 자체를 켜고 끈다. 위젯/게임 테스트 환경에서는 실제 오디오
  /// 플러그인이 없으므로 테스트 시작 시 false로 설정해 완전히 무음 처리한다.
  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      _bgmStarted = false;
      _ambientStarted = false;
    }
  }

  void setMuted(bool muted) {
    _muted = muted;
    if (muted) {
      stopBgm();
      stopAmbientNature();
    }
  }

  Future<void> _safePlay(
    AudioPlayer Function() getPlayer,
    String assetPath, {
    double volume = 1.0,
  }) async {
    if (!_enabled || _muted) return;
    try {
      final player = getPlayer();
      await _ensureMixContext(player);
      await _ensureStopReleaseMode(player);
      await player.stop();
      await player.setVolume(volume);
      if (!effectsEnabled) return;
      await player.play(AssetSource(assetPath));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SoundManager: failed to play $assetPath -> $e');
      }
    }
  }

  /// 걸을 때마다 살짝 나는 귀여운 발소리.
  ///
  /// [_footstepSuppressed]가 켜져 있으면(스테이지가 막 끝났거나, 숨쉬기
  /// 인터스티셜 중이거나, 완전 종료 처리 중) 아예 재생을 시작하지 않고,
  /// 이미 시작된 뒤라도 각 await 단계 사이마다 다시 확인해 즉시 멈춘다 -
  /// [_safePlay]의 일반 경로와 달리 발소리는 이 중간 확인이 반드시 필요하다
  /// (걷기 사이클마다 계속 호출되는 소리라 "정지된 뒤에도 들린다"는 문제가
  /// 유독 이 소리에서만 눈에 띄게 발생했었다).
  Future<void> playFootstep() async {
    if (!_enabled || _muted || _footstepSuppressed) return;
    try {
      final player = _footstepPlayer ??= AudioPlayer(
        playerId: 'sfx_footstep_player',
      );
      await _ensureMixContext(player);
      if (_footstepSuppressed) return;
      await _ensureStopReleaseMode(player);
      if (_footstepSuppressed) return;
      await player.stop();
      if (_footstepSuppressed) return;
      await player.setVolume(0.5);
      if (_footstepSuppressed) return;
      if (!effectsEnabled) return;
      await player.play(AssetSource('mongi/audio/sfx_footstep.mp3'));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SoundManager: failed to play footstep -> $e');
      }
    }
  }

  /// 점프할 때 나는 경쾌한 효과음.
  Future<void> playJump() => _safePlay(
    () => _jumpPlayer ??= AudioPlayer(playerId: 'sfx_jump_player'),
    'mongi/audio/sfx_jump.mp3',
    volume: 0.8,
  );

  /// 작은 돌멩이를 부술 때 나는 효과음.
  Future<void> playRockBreak() => _safePlay(
    () => _rockPlayer ??= AudioPlayer(playerId: 'sfx_rock_player'),
    'mongi/audio/sfx_rock_break.mp3',
    volume: 0.85,
  );

  /// 감정 몬스터를 냠냠 먹을 때 나는 효과음.
  Future<void> playEat() => _safePlay(
    () => _eatPlayer ??= AudioPlayer(playerId: 'sfx_eat_player'),
    'mongi/audio/sfx_eat_nom.mp3',
    volume: 0.9,
  );

  /// 스테이지 실패 - 엎어져서 엉엉 우는 순간 나는 효과음.
  Future<void> playCry() => _safePlay(
    () => _cryPlayer ??= AudioPlayer(playerId: 'sfx_cry_player'),
    'mongi/audio/sfx_cry.mp3',
    volume: 0.85,
  );

  /// 스테이지 클리어(또는 긍정 감정을 받는 순간)처럼 배부르게 골골송을
  /// 부르는 상황에 재생하는 효과음.
  ///
  /// 한 판 안에서 긍정 감정을 연달아 여러 번 받으면 이 메서드가 짧은
  /// 간격으로 계속 불릴 수 있는데, 그때마다 매번 소리를 내면 "골골송이
  /// 난무한다"는 느낌을 준다. [_purrCooldown] 동안은 추가 호출을 조용히
  /// 무시해 적당한 빈도로만 들리게 한다.
  Future<void> playPurr() {
    final now = DateTime.now();
    if (_lastPurrAt != null && now.difference(_lastPurrAt!) < _purrCooldown) {
      return Future.value();
    }
    _lastPurrAt = now;
    return _safePlay(
      () => _purrPlayer ??= AudioPlayer(playerId: 'sfx_purr_player'),
      'mongi/audio/sfx_purr.mp3',
      volume: 0.85,
    );
  }

  /// 몽이가 반갑게 인사할 때 내는 귀여운 야옹 소리.
  Future<void> playMeow() => _safePlay(
    () => _meowPlayer ??= AudioPlayer(playerId: 'sfx_meow_player'),
    'mongi/audio/sfx_meow.mp3',
    volume: 0.85,
  );

  // --- 감정별 "먹기" 효과음 (부정 감정 10종 -> 3그룹) ---------------------

  /// 날카롭고 팽팽한 느낌 - 분노/두려움/불안/짜증처럼 신경이 곤두선 감정.
  Future<void> playEatSharp() => _safePlay(
    () => _eatSharpPlayer ??= AudioPlayer(playerId: 'sfx_eat_sharp_player'),
    'mongi/audio/sfx_eat_sharp.mp3',
    volume: 0.9,
  );

  /// 묵직하고 가라앉는 느낌 - 미움/서러움/외로움/수치심처럼 무겁게 짓누르는 감정.
  Future<void> playEatHeavy() => _safePlay(
    () => _eatHeavyPlayer ??= AudioPlayer(playerId: 'sfx_eat_heavy_player'),
    'mongi/audio/sfx_eat_heavy.mp3',
    volume: 0.9,
  );

  /// 부드럽고 힘없는 느낌 - 슬픔/피곤함/걱정/심심함처럼 축 처지는 감정.
  Future<void> playEatSoft() => _safePlay(
    () => _eatSoftPlayer ??= AudioPlayer(playerId: 'sfx_eat_soft_player'),
    'mongi/audio/sfx_eat_soft.mp3',
    volume: 0.9,
  );

  // --- 감정별 "받기" 효과음 (긍정 감정 8종 -> 3그룹) ----------------------

  /// 반짝이고 들뜬 느낌 - 기쁨/설렘/신남처럼 마음이 튀어 오르는 감정.
  Future<void> playReceiveSparkle() => _safePlay(
    () => _receiveSparklePlayer ??= AudioPlayer(
      playerId: 'sfx_receive_sparkle_player',
    ),
    'mongi/audio/sfx_receive_sparkle.mp3',
    volume: 0.9,
  );

  /// 따뜻하고 포근한 느낌 - 감사/행복/평온처럼 은은하게 스며드는 감정.
  Future<void> playReceiveWarm() => _safePlay(
    () =>
        _receiveWarmPlayer ??= AudioPlayer(playerId: 'sfx_receive_warm_player'),
    'mongi/audio/sfx_receive_warm.mp3',
    volume: 0.9,
  );

  /// 힘차고 당당한 느낌 - 자신감/용기처럼 가슴을 펴게 하는 감정.
  Future<void> playReceiveTriumphant() => _safePlay(
    () => _receiveTriumphantPlayer ??= AudioPlayer(
      playerId: 'sfx_receive_triumphant_player',
    ),
    'mongi/audio/sfx_receive_triumphant.mp3',
    volume: 0.9,
  );

  /// 부정 감정 [type]에 맞는 "먹기" 효과음을 재생한다. 목록에 없는 값(즉
  /// 긍정 감정)이 잘못 들어와도 예외 없이 무난한 기본음으로 대체한다.
  Future<void> playEatForEmotion(EmotionType type) {
    switch (type) {
      case EmotionType.anger:
      case EmotionType.fear:
      case EmotionType.anxiety:
      case EmotionType.irritation:
        return playEatSharp();
      case EmotionType.hate:
      case EmotionType.grievance:
      case EmotionType.loneliness:
      case EmotionType.shame:
        return playEatHeavy();
      case EmotionType.sadness:
      case EmotionType.tired:
      case EmotionType.worry:
      case EmotionType.boredom:
        return playEatSoft();
      default:
        // 혹시 긍정 감정 타입이 잘못 전달되더라도 게임이 멈추지 않도록
        // 무난한 기본 먹기 효과음으로 대체한다.
        return playEat();
    }
  }

  /// 긍정 감정 [type]에 맞는 "받기" 효과음을 재생한다.
  Future<void> playReceiveForEmotion(EmotionType type) {
    switch (type) {
      case EmotionType.joy:
      case EmotionType.excitement:
      case EmotionType.thrill:
        return playReceiveSparkle();
      case EmotionType.gratitude:
      case EmotionType.happiness:
      case EmotionType.calm:
        return playReceiveWarm();
      case EmotionType.confidence:
      case EmotionType.courage:
        return playReceiveTriumphant();
      default:
        // 혹시 부정 감정 타입이 잘못 전달되더라도 게임이 멈추지 않도록
        // 무난한 기본 골골송으로 대체한다.
        return playPurr();
    }
  }

  /// 귀여운 배경음악을 무한 반복 재생 시작 (이미 재생 중이면 아무 것도 하지 않음).
  Future<void> startBgm() async {
    if (!musicEnabled) return;
    if (_bgmStarted || !_enabled || _muted) return;
    _bgmStarted = true;
    try {
      final player = _bgmPlayer ??= AudioPlayer(playerId: 'bgm_player');
      await _ensureMixContext(player);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.55);
      await player.play(AssetSource('mongi/audio/bgm_cute_loop.mp3'));
    } catch (e) {
      _bgmStarted = false;
      if (kDebugMode) {
        debugPrint('SoundManager: failed to start bgm -> $e');
      }
    }
  }

  Future<void> stopBgm() async {
    _bgmStarted = false;
    if (_bgmPlayer == null) return;
    try {
      await _bgmPlayer!.stop();
    } catch (_) {
      // 무시: 정지 실패는 치명적이지 않음.
    }
  }

  Future<void> pauseBgm() async {
    if (_bgmPlayer == null) return;
    try {
      await _bgmPlayer!.pause();
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!_bgmStarted || _muted || _bgmPlayer == null) return;
    try {
      await _bgmPlayer!.resume();
    } catch (_) {}
  }

  /// 이미 재생 중일 수 있는 발소리 효과음을 즉시 멈추고, 새로 시작되는
  /// [playFootstep] 호출도 [resumeFootstep]이 불리기 전까지는 전부 무시하게
  /// 만든다.
  ///
  /// 발소리는 [playFootstep]이 호출될 때마다 아주 짧게 재생되는 효과음이라
  /// 보통은 알아서 곧 끝나지만, 스테이지가 끝나는 순간 마침 발소리가 막
  /// 재생되기 시작한 타이밍이면 그 꼬리가 몇백 ms 남아 있을 수 있다.
  /// 스테이지 종료 시점(또는 숨쉬기 인터스티셜, 완전 종료)에 "물소리/새소리만
  /// 들려야 한다"는 요구를 확실히 지키기 위해, 이 순간에 남아있는 발소리
  /// 재생을 강제로 끊는 것만으로는 부족했다 - 마침 그 프레임에 시작된
  /// [playFootstep]의 비동기 체인이 정지 이후에도 이어져 재생을 완료해버릴
  /// 수 있었기 때문에([_footstepSuppressed] 플래그로 이 경쟁 상태 자체를
  /// 막는다).
  Future<void> stopFootstep() async {
    _footstepSuppressed = true;
    if (_footstepPlayer == null) return;
    try {
      await _footstepPlayer!.stop();
    } catch (_) {}
  }

  /// 새 스테이지가 시작될 때 발소리 억제를 다시 풀어준다.
  void resumeFootstep() {
    _footstepSuppressed = false;
  }

  /// 재생 중인 모든 소리(배경음악/자연 앰비언트/발소리 및 각종 효과음)를
  /// 즉시 멈춘다. 사용자가 "종료" 버튼으로 게임을 완전히 끝낼 때 호출되며,
  /// "종료를 누르면 소리도 안 나게 만들어줘"라는 요구를 지키기 위해 화면에
  /// 남아있을 수 있는 모든 오디오 플레이어를 하나도 빠짐없이 정지시킨다.
  /// 발소리는 다음 스테이지가 시작될 때([resumeFootstep])까지 계속 억제
  /// 상태로 남는다.
  Future<void> stopEverything() async {
    await stopBgm();
    await stopAmbientNature();
    await stopFootstep();
    for (final p in [
      _jumpPlayer,
      _rockPlayer,
      _eatPlayer,
      _cryPlayer,
      _purrPlayer,
      _meowPlayer,
      _eatSharpPlayer,
      _eatHeavyPlayer,
      _eatSoftPlayer,
      _receiveSparklePlayer,
      _receiveWarmPlayer,
      _receiveTriumphantPlayer,
    ]) {
      if (p == null) continue;
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  // --- 자연 앰비언트(새소리 + 물소리) ------------------------------------
  //
  // 홈 화면에 들어온 순간부터 게임 플레이 중까지 배경에 은은하게 깔리는
  // 새소리/물소리. BGM과는 완전히 분리된 두 개의 무한 반복 플레이어로
  // 재생해서, "숨쉬기" 인터스티셜에서 BGM만 잠깐 끄고 이 앰비언트는 그대로
  // 이어지게 할 수 있다(마음이 가라앉는 순간에도 정원의 생명감은 남아있게).
  // 이미 재생 중이면 다시 부르는 호출(예: 화면을 재방문할 때마다)은 조용히
  // 무시해서 소리가 겹쳐 재생되지 않도록 한다.
  Future<void> startAmbientNature() async {
    if (!musicEnabled) return;
    if (_ambientStarted || !_enabled || _muted) return;
    _ambientStarted = true;
    try {
      // 볼륨을 아주 낮게 잡아서(0.14/0.12) 귀에 또렷이 들리는 소리가 아니라
      // "저 멀리서 은은하게 배경에 깔리는" 느낌만 나도록 한다. 너무 크게
      // 들리면 오히려 정신이 산만해져 힐링 앱의 취지와 맞지 않는다는
      // 피드백을 받아 낮췄다.
      final birds = _ambientBirdsPlayer ??= AudioPlayer(
        playerId: 'ambient_birds_player',
      );
      await _ensureMixContext(birds);
      await birds.setReleaseMode(ReleaseMode.loop);
      await birds.setVolume(0.14);
      await birds.play(AssetSource('mongi/audio/ambient_birds.mp3'));

      final water = _ambientWaterPlayer ??= AudioPlayer(
        playerId: 'ambient_water_player',
      );
      await _ensureMixContext(water);
      await water.setReleaseMode(ReleaseMode.loop);
      await water.setVolume(0.12);
      await water.play(AssetSource('mongi/audio/ambient_water.mp3'));
    } catch (e) {
      _ambientStarted = false;
      if (kDebugMode) {
        debugPrint('SoundManager: failed to start ambient nature -> $e');
      }
    }
  }

  Future<void> stopAmbientNature() async {
    _ambientStarted = false;
    for (final p in [_ambientBirdsPlayer, _ambientWaterPlayer]) {
      if (p == null) continue;
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  Future<void> pauseAmbientNature() async {
    for (final p in [_ambientBirdsPlayer, _ambientWaterPlayer]) {
      if (p == null) continue;
      try {
        await p.pause();
      } catch (_) {}
    }
  }

  /// [_ambientStarted]가 true였던 경우에만(=원래 재생 중이었던 경우에만)
  /// 되살린다 - 애초에 재생된 적 없는 상태에서 잘못 재생을 시작시키지 않는다.
  Future<void> resumeAmbientNatureIfNeeded() async {
    if (!_ambientStarted || _muted) return;
    for (final p in [_ambientBirdsPlayer, _ambientWaterPlayer]) {
      if (p == null) continue;
      try {
        await p.resume();
      } catch (_) {}
    }
  }

  /// 앱이 백그라운드로 밀려나거나(홈 버튼/최근 앱 전환/뒤로가기로 앱을
  /// 완전히 벗어남) 시스템에 의해 종료되기 직전일 때 호출한다.
  ///
  /// [audioplayers]가 사용하는 네이티브 오디오 플레이어는 Flutter 위젯
  /// 트리(화면)와 생명주기가 분리되어 있어서, 화면이 사라져도(예: 뒤로가기로
  /// 앱을 나가도) 재생 중이던 배경음악/자연 앰비언트/효과음이 네이티브
  /// 단에서는 계속 재생되는 문제가 있었다 ("앱을 종료해도 효과음이 계속
  /// 들린다"는 버그의 근본 원인). BGM/자연 앰비언트는 다시 돌아왔을 때
  /// 이어서 들을 수 있도록 pause(정지 위치 보존)하고, 짧게 한 번 울리고
  /// 마는 효과음들은 즉시 완전히 멈춘다(발소리 포함, 다음 스테이지 진입
  /// 전까지 억제).
  Future<void> pauseAllForBackground() async {
    await pauseBgm();
    await pauseAmbientNature();
    await stopFootstep();
    for (final p in [
      _jumpPlayer,
      _rockPlayer,
      _eatPlayer,
      _cryPlayer,
      _purrPlayer,
      _meowPlayer,
      _eatSharpPlayer,
      _eatHeavyPlayer,
      _eatSoftPlayer,
      _receiveSparklePlayer,
      _receiveWarmPlayer,
      _receiveTriumphantPlayer,
    ]) {
      if (p == null) continue;
      try {
        await p.stop();
      } catch (_) {}
    }
  }

  /// 앱이 다시 포그라운드로 돌아왔을 때([pauseAllForBackground]와 짝을
  /// 이룬다) 원래 재생 중이었던 배경음악/자연 앰비언트만 이어서 재생한다.
  Future<void> resumeAllFromBackground() async {
    resumeFootstep();
    await resumeBgm();
    await resumeAmbientNatureIfNeeded();
  }

  Future<void> dispose() async {
    for (final p in [
      _bgmPlayer,
      _ambientBirdsPlayer,
      _ambientWaterPlayer,
      _footstepPlayer,
      _jumpPlayer,
      _rockPlayer,
      _eatPlayer,
      _cryPlayer,
      _purrPlayer,
      _meowPlayer,
      _eatSharpPlayer,
      _eatHeavyPlayer,
      _eatSoftPlayer,
      _receiveSparklePlayer,
      _receiveWarmPlayer,
      _receiveTriumphantPlayer,
    ]) {
      if (p == null) continue;
      try {
        await p.dispose();
      } catch (_) {}
    }
    _contextApplied.clear();
  }
}
