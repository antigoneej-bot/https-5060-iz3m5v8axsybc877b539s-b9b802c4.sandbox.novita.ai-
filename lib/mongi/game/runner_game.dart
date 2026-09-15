import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/emotion_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/gen/app_localizations_ko.dart';
import '../models/emotion.dart';
import '../models/scene_biome.dart';
import '../models/time_of_day_ambience.dart';
import '../services/emotion_insight_service.dart';
import '../services/game_narrative_service.dart';
import 'components/cat_player.dart';
import 'components/emotion_cutin.dart';
import 'components/emotion_label_reveal.dart';
import 'components/emotion_monster_component.dart';
import 'components/floating_label.dart';
import 'components/hit_flash_overlay.dart';
import 'components/light_burst.dart';
import 'components/bonus_item.dart';
import 'components/breath_orb.dart';
import 'components/power_orb.dart';
import 'components/obstacle_creature.dart';
import 'components/obstacle_rock.dart';
import 'components/scenery_layer.dart';
import 'components/stage_clear_banner.dart';
import 'components/streak_burst.dart';
import '../services/sound_manager.dart';

// ---------------------------------------------------------------------------
// Spawn wave system: instead of picking a random single entity every time,
// entities arrive in small curated "waves" so a run feels rhythmic - calm
// combo-building bursts, a punchier rock rhythm, jump-only floaters, close
// rock pairs, and short breathers to look around and relax. Higher stages
// lean toward rockier/mixed waves and take fewer breathers.
// ---------------------------------------------------------------------------

enum _SpawnKind {
  rock,
  bigRock,
  monster,
  floatMonster,
  rockPair,
  leafBall,
  sparrow,
  frog,
}

class _SpawnStep {
  final double delay;
  final _SpawnKind kind;
  const _SpawnStep(this.delay, this.kind);
}

const List<_SpawnStep> _waveCalm = [
  _SpawnStep(0.0, _SpawnKind.monster),
  _SpawnStep(0.85, _SpawnKind.monster),
  _SpawnStep(0.85, _SpawnKind.monster),
  _SpawnStep(1.05, _SpawnKind.monster),
];

const List<_SpawnStep> _waveRocky = [
  _SpawnStep(0.0, _SpawnKind.rock),
  _SpawnStep(1.05, _SpawnKind.bigRock),
  _SpawnStep(0.95, _SpawnKind.rock),
  _SpawnStep(1.15, _SpawnKind.monster),
];

const List<_SpawnStep> _waveMixed = [
  _SpawnStep(0.0, _SpawnKind.monster),
  _SpawnStep(0.8, _SpawnKind.rock),
  _SpawnStep(0.95, _SpawnKind.monster),
  _SpawnStep(0.9, _SpawnKind.bigRock),
  _SpawnStep(1.05, _SpawnKind.monster),
];

const List<_SpawnStep> _waveFloaters = [
  _SpawnStep(0.0, _SpawnKind.floatMonster),
  _SpawnStep(0.95, _SpawnKind.monster),
  _SpawnStep(1.05, _SpawnKind.floatMonster),
  _SpawnStep(0.95, _SpawnKind.rock),
];

const List<_SpawnStep> _wavePairs = [
  _SpawnStep(0.0, _SpawnKind.rockPair),
  _SpawnStep(1.25, _SpawnKind.monster),
  _SpawnStep(0.95, _SpawnKind.monster),
];

const List<_SpawnStep> _waveBreather = [_SpawnStep(1.5, _SpawnKind.monster)];

// 몬스터 공급이 목표 진행 속도보다 뒤처졌을 때 빠르게 따라잡기 위한 전용
// 웨이브 - 장애물 없이 몬스터(공중 포함)만 촘촘하게 등장한다. 제한시간
// 자체는 건드리지 않되, 장애물 위주 웨이브가 연달아 뽑혀 "실수 하나 없이도
// 시간 안에 목표를 채울 몬스터 자체가 부족한" 상황을 막기 위한 안전장치다.
const List<_SpawnStep> _waveCatchUp = [
  _SpawnStep(0.0, _SpawnKind.monster),
  _SpawnStep(0.6, _SpawnKind.monster),
  _SpawnStep(0.6, _SpawnKind.monster),
  _SpawnStep(0.7, _SpawnKind.floatMonster),
];

// 새로운 애니메이션 장애물이 섞인 웨이브들 - 바위/돌만 반복되지 않도록
// 낙엽뭉치(주먹으로 부술 수 있음)/참새(반드시 점프)/개구리(반드시 점프)를
// 골고루 섞어 시각적으로도, 조작감으로도 다채로운 리듬을 만든다.
const List<_SpawnStep> _waveLeaves = [
  _SpawnStep(0.0, _SpawnKind.leafBall),
  _SpawnStep(0.95, _SpawnKind.monster),
  _SpawnStep(0.85, _SpawnKind.leafBall),
  _SpawnStep(1.05, _SpawnKind.rock),
];

const List<_SpawnStep> _waveSkyDance = [
  _SpawnStep(0.0, _SpawnKind.sparrow),
  _SpawnStep(0.9, _SpawnKind.monster),
  _SpawnStep(1.0, _SpawnKind.sparrow),
  _SpawnStep(0.9, _SpawnKind.floatMonster),
];

const List<_SpawnStep> _waveHop = [
  _SpawnStep(0.0, _SpawnKind.frog),
  _SpawnStep(1.0, _SpawnKind.monster),
  _SpawnStep(0.95, _SpawnKind.frog),
  _SpawnStep(1.05, _SpawnKind.leafBall),
];

// 스테이지 5+ : 여러 종류의 애니메이션 장애물이 한 웨이브 안에 섞여 등장하는
// 좀 더 북적북적한 패턴 - 그래도 각 개체 사이 간격은 충분히 둬서 반응할
// 시간을 준다.
const List<_SpawnStep> _waveMenagerie = [
  _SpawnStep(0.0, _SpawnKind.frog),
  _SpawnStep(0.85, _SpawnKind.sparrow),
  _SpawnStep(0.8, _SpawnKind.leafBall),
  _SpawnStep(0.95, _SpawnKind.monster),
  _SpawnStep(0.8, _SpawnKind.sparrow),
];

// Stage 5+: a denser, more layered combo (rock pair + floaters mixed with
// rocks) so mid-late stages feel meaningfully busier, not just faster.
const List<_SpawnStep> _waveAdvanced = [
  _SpawnStep(0.0, _SpawnKind.rockPair),
  _SpawnStep(0.85, _SpawnKind.floatMonster),
  _SpawnStep(0.75, _SpawnKind.bigRock),
  _SpawnStep(0.9, _SpawnKind.monster),
  _SpawnStep(0.8, _SpawnKind.floatMonster),
];

// Stage 8+: the busiest pattern - short gaps, big rocks, a pair and a
// floater all close together. Still soft-fail (no real game over), just a
// noticeably livelier late-game rhythm.
// 2024: "18단계가 너무 빨라서 반응속도가 오히려 느려진다"는 피드백을 받아
// 간격을 소폭 늘렸다(0.55/0.6 -> 0.62/0.68). 여전히 가장 촘촘한 패턴이지만,
// speedMultiplier가 쌓인 후반 스테이지에서도 한 박자 더 반응할 여유를 준다.
// (등장 시점 자체도 [_loadNextWave]에서 8단계 -> 12단계로 늦춰졌다.)
const List<_SpawnStep> _waveChaos = [
  _SpawnStep(0.0, _SpawnKind.rock),
  _SpawnStep(0.62, _SpawnKind.floatMonster),
  _SpawnStep(0.68, _SpawnKind.bigRock),
  _SpawnStep(0.62, _SpawnKind.rockPair),
  _SpawnStep(0.9, _SpawnKind.monster),
  _SpawnStep(0.68, _SpawnKind.bigRock),
];

// ---------------------------------------------------------------------------
// 5번: 바이옴별 전용 웨이브 - 지금까지는 배경(SceneBiome)이 정원->도시->
// 바닷가->산속으로 완전히 바뀌어도, 등장하는 장애물 "리듬"은 오직 스테이지
// 숫자에만 반응해서 뽑혔다(풍경은 바뀌는데 패턴은 그대로). 여기 4개 웨이브는
// 각 배경의 분위기에 맞춰 장애물 조합 자체를 다르게 짜서, 배경이 바뀌는
// 순간 "여기는 확실히 다른 곳이구나"가 리듬으로도 느껴지게 한다. 기존 풀에
// 완전히 대체가 아니라 "가산"되는 방식이라(_loadNextWave 참고) 기존 밸런스는
// 유지하면서 다양성만 더한다.
// ---------------------------------------------------------------------------

/// 🌿 정원: 낙엽뭉치/개구리 같은 작은 생명체들이 여유롭게 뒤섞여 등장하는,
/// 산책하듯 편안한 리듬.
const List<_SpawnStep> _waveGardenStroll = [
  _SpawnStep(0.0, _SpawnKind.leafBall),
  _SpawnStep(0.9, _SpawnKind.monster),
  _SpawnStep(0.85, _SpawnKind.frog),
  _SpawnStep(0.9, _SpawnKind.monster),
  _SpawnStep(0.85, _SpawnKind.leafBall),
];

/// 🏙️ 도시: 공사장 돌무더기가 연달아 놓인 듯, 바위 위주로 촘촘하게 이어지는
/// 리듬 - "도시는 좀 더 딱딱하고 빡빡하다"는 인상을 준다.
const List<_SpawnStep> _waveCityRush = [
  _SpawnStep(0.0, _SpawnKind.rockPair),
  _SpawnStep(0.9, _SpawnKind.monster),
  _SpawnStep(0.75, _SpawnKind.bigRock),
  _SpawnStep(0.85, _SpawnKind.monster),
  _SpawnStep(0.8, _SpawnKind.rock),
];

/// 🌊 바닷가: 참새(갈매기)가 파도 위를 낮게 스치듯 날아드는 공중 웨이브 -
/// 붕붕 뜬 몬스터와 함께 시원하게 하늘 쪽 리듬을 강조한다.
const List<_SpawnStep> _waveOceanBreeze = [
  _SpawnStep(0.0, _SpawnKind.sparrow),
  _SpawnStep(0.85, _SpawnKind.floatMonster),
  _SpawnStep(0.9, _SpawnKind.monster),
  _SpawnStep(0.85, _SpawnKind.sparrow),
  _SpawnStep(0.9, _SpawnKind.floatMonster),
];

/// ⛰️ 산속: 바위 사이를 개구리처럼 폴짝폴짝 뛰어넘는 느낌 - 큰 바위(암석)와
/// 개구리 점프가 번갈아 나와 오르막을 오르는 듯한 리듬을 만든다.
const List<_SpawnStep> _waveMountainClimb = [
  _SpawnStep(0.0, _SpawnKind.frog),
  _SpawnStep(0.85, _SpawnKind.bigRock),
  _SpawnStep(0.8, _SpawnKind.monster),
  _SpawnStep(0.85, _SpawnKind.frog),
  _SpawnStep(0.8, _SpawnKind.rockPair),
];

/// 감정을 먹어치우는 엔드리스 러너 게임 본체.
/// 왼쪽/Enter/아래 = 주먹, 오른쪽/Space/위 = 점프. 감정 수집은 접촉 시 자동.
///
/// 스테이지가 오를수록:
/// - 돌멩이가 조금씩 커진다 (작은 돌 / 큰 돌 모두)
/// - 첫 단계부터 작은 돌과 낙엽을 주먹 타이밍에 맞춰 부순다
///   (큰 돌멩이는 항상 점프로 피해야 한다)
class RunnerGame extends FlameGame with HasCollisionDetection {
  final List<Emotion> emotions;
  final String? targetName;
  final int targetEatenCount;
  final int stage;

  /// 1번(벤치마킹 제안: 감정 강도-게임 난이도 매칭) - 게임을 시작하기 전
  /// 감정 선택 화면에서 미리 물어본 "이 마음, 오늘은 얼마나 강했나요?"
  /// 강도(1~5, 기본값 3=보통). 격한 부정 감정을 강하게 느꼈다고 표시했다면
  /// 오히려 게임을 부드럽게(속도/장애물 완화), 피곤함/심심함처럼 낮은
  /// 에너지 감정을 약하게 느꼈다면 살짝 더 생동감 있게 진행한다
  /// ([_intensityDifficultyFactor], [_loadNextWave] 참고).
  final int emotionIntensity;

  /// 5번: 몬스터 감정 라벨링 - 이 판이 시작되기 전까지 감정 타입별로 정원에
  /// 몇 번 심어졌었는지(=GardenProvider.flowerCounts, key는 EmotionType.name).
  /// 이 값이 0(또는 없음)인 감정 타입을 이번 판에서 처음 먹거나 받는 순간,
  /// "처음 만난 마음이에요" 라벨링 컷인이 뜬다. 한 판 안에서 같은 타입이
  /// 여러 번 등장해도 [_labelRevealedTypes]로 딱 한 번만 보여준다.
  final Map<String, int> priorMetCounts;

  /// 10번: 지금까지 쌓인 감정 다이어리 전체(최신순) - 게임 플레이 중 컷인에서
  /// "냠! 사라졌어요" 같은 정형화된 문구 대신, 그 감정 타입으로 유저가 실제로
  /// 남긴 가장 최근 한 줄을 몽이가 다시 들려줄 수 있게 한다. 빈 리스트여도
  /// 안전하게 기존 healMessage로 대체되므로 필수는 아니다.
  final List<Map<String, dynamic>> diaryEntries;

  /// 영어지원: 몬스터 이름표/컷인/플로팅 라벨 등 게임 플레이 중 노출되는
  /// 텍스트를 언어별로 만들기 위한 [AppLocalizations] 인스턴스. Flame 게임
  /// 레이어는 BuildContext에 접근할 수 없으므로, 화면(BuildContext가 있는
  /// [RunnerGameScreen])이 이미 얻은 인스턴스를 생성자로 그대로 넘겨준다.
  /// 넘기지 않으면(테스트 등 기존 호출부) 한국어 기본값으로 안전하게
  /// 동작한다.
  final AppLocalizations l10n;

  /// 엔드리스 모드("무한의 계단"식 도전 모드) 여부. true이면 목표 개수 없이
  /// 무한히 진행되며, 시간이 지날수록([_difficultyStage]) 점점 빨라지고 어려워진다.
  /// 목숨을 다 쓰면 그 판이 끝나고 "오늘 내 최고 기록"과 비교된다.
  final bool isEndless;
  final bool isPractice;

  /// 지금 몽이에게 장착된 코스튬 이미지 경로 ("마음 상자" 가챠로 획득한 액세서리).
  /// null이면 기본 모습 그대로 플레이한다.
  final String? equippedCostumeAsset;
  final double costumeOffsetXRatio;
  final double costumeOffsetYRatio;
  final double costumeScaleRatio;

  /// 스테이지가 끝났을 때 호출된다. [earlyStop]이 true이면 목표 개수를 다 채우지
  /// 못하고 목숨을 다 써서 부드럽게 마무리된 경우다(실패가 아니라 '오늘은 여기까지').
  /// 엔드리스 모드에서는 항상 목숨을 다 써서 끝나므로 늘 [earlyStop]=true로 불린다.
  final void Function(int eatenCount, {bool earlyStop}) onStageComplete;
  final VoidCallback onRockHit;
  final VoidCallback onRockPunched;
  final void Function(int eatenCount) onProgressChanged;
  final void Function(int lives) onLivesChanged;
  final void Function(int combo) onComboChanged;

  /// 6번(호흡 미니게임): "숨결 구슬"에 닿아 호흡 순간이 시작될 때 화면
  /// 쪽(RunnerGameScreen)에 알린다. 화면은 이 콜백을 받으면
  /// [BreathingMomentSheet]를 띄우고, 사용자가 얼마나 잘 따라했는지에 따라
  /// 결과(성공 여부)를 [resolveBreathingMoment]로 되돌려준다. 게임 자체는
  /// 이 콜백이 없어도(null 허용 대신 기본값 _noopBreathing) 안전하게
  /// 동작한다 - 콜백이 없으면 그냥 아이템을 스폰하지 않는다.
  final void Function() onBreathingMomentStart;

  /// 목숨을 다 썼을 때 "이어하기"를 제안할 콜백. null이면(콜백 미제공) 부활
  /// 제안 없이 바로 스테이지가 끝난다. 반환값이 true면 부활(목숨 가득 회복
  /// 후 이어서 진행), false면 여기서 마친다.
  /// [reviveCountThisRun]은 이번 판에서 이미 몇 번 부활했는지 - 다이얼로그
  /// 문구 조정용. [requiresAd]가 true면 이번 제안은 반드시 광고를 끝까지
  /// 봐야만 이어할 수 있다는 뜻이다(아래 [freeRevivesPerRun] 참고).
  final Future<bool> Function(
    int reviveCountThisRun, {
    required bool requiresAd,
  })?
  onLivesExhausted;

  /// 한 판에서 광고 없이 "그냥 다시 도전"할 수 있는 무료 이어하기 횟수.
  /// 처음 [freeRevivesPerRun]번(0, 1, 2번째 죽음)까지는 광고 없이 바로
  /// 이어갈 수 있고, 그 이후부터는 계속 광고를 봐야만 이어갈 수 있다 -
  /// 힐링 게임 톤은 지키면서도 반복 재시청을 자연스럽게 유도한다. 이후
  /// 횟수 자체에는 별도 상한을 두지 않는다(광고 시청 자체가 자연스러운
  /// 빈도 제한이 된다).
  static const int freeRevivesPerRun = 3;

  /// 이번 판에서 지금까지 부활(이어하기)을 사용한 횟수.
  int revivesUsedThisRun = 0;
  bool _reviveOfferPending = false;

  RunnerGame({
    required this.emotions,
    required this.targetName,
    required this.onStageComplete,
    required this.onRockHit,
    required this.onProgressChanged,
    this.onRockPunched = _noop,
    this.onLivesChanged = _noopLives,
    this.onComboChanged = _noopLives,
    this.onLivesExhausted,
    this.onBreathingMomentStart = _noop,
    this.targetEatenCount = 10,
    this.stage = 1,
    this.maxLives = 3,
    this.emotionIntensity = 3,
    this.isEndless = false,
    this.isPractice = false,
    this.equippedCostumeAsset,
    this.costumeOffsetXRatio = 0.5,
    this.costumeOffsetYRatio = 0.16,
    this.costumeScaleRatio = 0.62,
    this.priorMetCounts = const {},
    this.diaryEntries = const [],
    AppLocalizations? l10n,
  }) : l10n = l10n ?? AppLocalizationsKo() {
    // biome/timeOfDay는 원래 onLoad()(비동기) 안에서 계산했었는데, 화면의
    // HUD 위젯들(_buildHud, _buildTimeOfDayBadge)이 게임 로드가 끝나기도
    // 전에 이미 이 late final 필드들을 읽으려 하면서 LateInitializationError가
    // 나 화면 전체가 회색으로 깨지는 문제가 있었다. 생성자 시점에 곧바로(동기적으로)
    // 계산해두면 위젯이 언제 읽어도 항상 값이 준비되어 있다.
    timeOfDay = TimeOfDayAmbience.current();
    biome = isEndless
        ? SceneBiome.values[_rand.nextInt(SceneBiome.values.length)]
        : SceneBiome.forStage(stage);
  }

  /// 이번 판에서 이미 "처음 만난 마음이에요" 라벨링을 보여준 감정 타입들 -
  /// 같은 타입 몬스터가 여러 번 등장해도 한 판에서 중복으로 뜨지 않게 막는다.
  final Set<EmotionType> _labelRevealedTypes = {};

  /// 10번: 이번 판에서 이미 "다이어리 기록과 연결된" 컷인을 보여준 감정
  /// 타입들. 같은 노트를 스트릭마다 반복해서 보여주면 오히려 뻔해지므로,
  /// 한 판에 타입별로 딱 한 번만 이 특별한 버전을 보여주고, 그 다음부터는
  /// (여전히 같은 스트릭을 이어가더라도) 원래의 healMessage로 되돌아간다.
  final Set<EmotionType> _diaryCutInShownTypes = {};

  /// 10번: 같은 감정을 연속으로 먹었을 때(스트릭 컷인) 보여줄 문구를 고른다.
  /// 이 감정 타입으로 유저가 실제로 남긴 다이어리 노트가 있고, 아직 이번
  /// 판에서 그 특별한 버전을 보여준 적이 없다면 그 노트와 연결된 문구를,
  /// 그렇지 않으면(노트가 없거나 이미 한 번 보여줬다면) 기존 healMessage
  /// 기반 문구를 반환한다.
  String _streakCutInMessageFor(Emotion emotion) {
    if (!_diaryCutInShownTypes.contains(emotion.type)) {
      final diaryMessage = EmotionInsightService.diaryLinkedCutInMessage(
        emotion: emotion,
        diaryEntries: diaryEntries,
      );
      if (diaryMessage != null) {
        _diaryCutInShownTypes.add(emotion.type);
        return diaryMessage;
      }
    }
    return emotionHealMessage(l10n, emotion.type);
  }

  static void _noop() {}
  static void _noopLives(int lives) {}

  /// 스테이지별 감정 목표 개수: 1단계부터 기본 20개로 시작해, 2단계=30개,
  /// 3단계=40개, 4단계부터는 40 + (stage-3)*10개씩 늘어난다
  /// (예: 4단계=50, 5단계=60...).
  static int targetForStage(int stage) {
    if (stage <= 1) return 20;
    if (stage == 2) return 30;
    if (stage == 3) return 40;
    return 40 + (stage - 3) * 10;
  }

  /// 작은 돌과 낙엽은 첫 스테이지부터 주먹으로 처리한다.
  bool get canPunchSmallRocks => true;

  bool get acceptsGameplayInput =>
      isLoaded &&
      !paused &&
      !stageCompleted &&
      !_reviveOfferPending &&
      !_breathingMomentActive &&
      isHolding;

  /// 몸통 앞쪽으로 뻗은 주먹의 실제 타격 범위. 점프 높이도 그대로 반영한다.
  bool isInPunchReach(PositionComponent obstacle) {
    if (!acceptsGameplayInput || !punchReady) return false;
    final body = cat.children
        .whereType<RectangleHitbox>()
        .first
        .toAbsoluteRect();
    final target = obstacle.children
        .whereType<RectangleHitbox>()
        .first
        .toAbsoluteRect();
    final reach = Rect.fromLTRB(
      body.center.dx,
      body.top,
      body.right + 42,
      body.bottom,
    );
    return reach.overlaps(target);
  }

  /// 엔드리스 모드에서 시간이 지날수록 커지는 "체감 난이도" 단계.
  /// 45초마다 한 단계씩 올라가며(무한의 계단식 "갈수록 빨라짐" 긴장감),
  /// 최대 10단계까지 올라간다. 일반 스테이지 모드에서는 사용하지 않는다.
  int get _endlessDifficultyStage => 1 + (elapsedSeconds ~/ 45).clamp(0, 9);

  /// 스테이지가 오를수록(또는 엔드리스 모드에서는 시간이 지날수록) 장애물/몬스터
  /// 속도가 빨라진다.
  ///
  /// - 엔드리스 모드: 한 판 안에서 시간이 지날수록 팽팽하게 조여지는 "도전"
  ///   모드라, 스테이지당 선형으로 빨라진다.
  /// - 일반 스테이지 모드: "마음을 심을래요"를 선택할 때마다 영구적으로 쌓이는
  ///   [stage]는 사람마다 아주 오래(수십 판) 이어질 수 있어서, 선형으로 계속
  ///   빠르게 하면 결국 사람이 반응하기 힘든 속도까지 치닫는다. 대신 제곱근
  ///   곡선을 써서 "레벨이 오를 때마다 살짝씩만" 빨라지게 하고, 뒤로 갈수록
  ///   증가폭이 점점 줄어들어(체감 난이도가 완만해져) 사람이 계속 적응하며
  ///   따라갈 수 있는 선을 지킨다.
  ///
  /// "속도가 다시 줄어들었다"는 피드백을 받아, 계수/상한을 한 번 끌어올렸다
  /// (일반 모드 0.12 -> 0.20, 상한 1.75 -> 2.15 / 엔드리스 0.11 -> 0.16,
  /// 상한 2.5 -> 3.0). 그런데 그 뒤 "18단계쯔음 되니 너무 빨라서 반응속도가
  /// 오히려 느려진다"(=장애물이 사람이 반응할 수 있는 속도보다 앞서간다)는
  /// 반대 방향 피드백을 받아, 일반 모드 계수를 0.20 -> 0.17로 살짝 낮췄다
  /// (18단계 기준: sqrt(17)*0.20+1.0 ≈ 1.825 -> sqrt(17)*0.17+1.0 ≈ 1.70).
  /// 상한(2.15)과 엔드리스 쪽은 그대로 유지한다 - 이번 피드백은 특히
  /// 중반 스테이지(약 10~25단계) 구간에서 체감됐던 것이라, 초반 진입장벽과
  /// 최종 상한은 손대지 않고 그 사이 증가 곡선만 완만하게 조정했다.
  double get speedMultiplier {
    if (isPractice) return .65;
    final double base;
    if (isEndless) {
      base = (1.0 + (_endlessDifficultyStage - 1) * 0.16).clamp(1.0, 3.0);
    } else {
      final extraLevels = math.sqrt((stage - 1).clamp(0, 1 << 30).toDouble());
      base = (1.0 + extraLevels * 0.17).clamp(1.0, 2.15);
    }
    return (base * _intensityDifficultyFactor).clamp(0.6, 3.0);
  }

  /// 1번(벤치마킹 제안: 감정 강도-게임 난이도 매칭) - "무겁게 격해진" 부정
  /// 감정. [EmotionInsightService]의 heavySignalTypes(슬픔/외로움/두려움/
  /// 불안/미움/억울함)에, 몸을 긴장시키는 화/짜증/부끄러움/걱정을 더해
  /// 조금 더 넓게 잡았다 - 강도가 세다면 이 감정들 모두 "빠른 반응"보다는
  /// "다독임"이 먼저 필요하다고 판단한다.
  static const Set<EmotionType> _heavyNegativeTypes = {
    EmotionType.sadness,
    EmotionType.loneliness,
    EmotionType.fear,
    EmotionType.anxiety,
    EmotionType.hate,
    EmotionType.grievance,
    EmotionType.anger,
    EmotionType.irritation,
    EmotionType.shame,
    EmotionType.worry,
  };

  /// 낮은 에너지 상태를 나타내는 감정(피곤함/심심함) - 강도가 약할 때는
  /// 오히려 살짝 활기찬 템포로 깨워주는 쪽이 더 어울린다고 판단한다.
  static const Set<EmotionType> _lowEnergyTypes = {
    EmotionType.tired,
    EmotionType.boredom,
  };

  bool get _hasHeavyNegativeEmotion =>
      emotions.any((e) => _heavyNegativeTypes.contains(e.type));

  bool get _hasLowEnergyEmotion =>
      emotions.any((e) => _lowEnergyTypes.contains(e.type));

  /// "격한 부정 감정을 강하게 느꼈다"고 표시한 판인지 - 게임을 부드럽게
  /// 완화하는 기준으로 [speedMultiplier]와 [_loadNextWave] 양쪽에서 함께
  /// 쓴다. 강도 4(강하게)/5(아주 강하게)일 때만 적용해, "보통" 이하에서는
  /// 평소와 똑같이 플레이된다.
  bool get isSoftenedBySoothingIntent =>
      _hasHeavyNegativeEmotion && emotionIntensity >= 4;

  /// "지루함/피곤함을 약하게 느꼈다"고 표시한 판인지 - 조금 더 생동감 있는
  /// 조합이 뽑히도록 [_loadNextWave]에서 참고한다.
  bool get isLivenedByLowEnergyIntent =>
      _hasLowEnergyEmotion && emotionIntensity <= 2;

  /// 감정 강도(1~5)를 게임 속도에 반영하는 배율. 1.0이면 강도의 영향이
  /// 전혀 없다(=평소와 동일).
  /// - 무거운 부정 감정을 강하게(4) 또는 아주 강하게(5) 느꼈다면 속도를
  ///   각각 10%/18% 낮춰, 몰아치는 장애물 대신 마음을 다독이는 흐름을
  ///   우선한다.
  /// - 피곤함/심심함을 약하게(1) 또는 그럭저럭 약하게(2) 느꼈다면 오히려
  ///   속도를 10%/5% 살짝 올려 처지지 않는 리듬을 만든다.
  /// - 그 외(보통 강도, 또는 다른 조합)는 손대지 않는다.
  double get _intensityDifficultyFactor {
    if (_hasHeavyNegativeEmotion) {
      if (emotionIntensity >= 5) return 0.82;
      if (emotionIntensity == 4) return 0.90;
    } else if (_hasLowEnergyEmotion) {
      if (emotionIntensity <= 1) return 1.10;
      if (emotionIntensity == 2) return 1.05;
    }
    return 1.0;
  }

  /// 엔드리스 모드에서 지금까지 살아남은 시간(초). 일반 스테이지 모드에서는
  /// [timeLimitSeconds]와 함께 "남은 시간" 압박을 만드는 기준이 된다.
  /// 게임이 자동으로 계속 진행되므로 스테이지가 시작된 순간부터 실시간으로 흐른다.
  double elapsedTime = 0;
  int get elapsedSeconds => elapsedTime.toInt();

  /// 일반 스테이지 모드(엔드리스 아님)에서 이번 판에 주어진 시간 제한(초).
  ///
  /// "스테이지마다 1분 가량"이라는 원래 의도를 따라, 1단계(목표 20개)는
  /// 정확히 60초를 준다. 목표 개수가 커지는 뒤 스테이지는 그만큼 더
  /// 여유를 주도록 선형으로 늘린다(스테이지가 올라 몬스터/장애물이 더
  /// 필요해지는 만큼 시간도 함께 늘어난다). 엔드리스 모드는 시간이
  /// 지날수록 빨라지는 자체 압박이 이미 있으므로 이 제한을 적용하지 않는다.
  /// `targetEatenCount`가 20보다 훨씬 작은 값으로 주어지는 경우(예: 테스트
  /// 코드가 극단적으로 짧은 목표를 설정하는 경우) 계산식이 음수가 되어
  /// "시작하자마자 시간 초과"가 되는 것을 막기 위해 최소 20초를 보장한다.
  /// 실제 게임에서는 [targetForStage]가 항상 20 이상을 반환하므로 이 clamp는
  /// 정상 플레이에는 영향을 주지 않는다.
  int get timeLimitSeconds =>
      (60 + (targetEatenCount - 20) * 4).clamp(20, 1 << 30);

  /// 일반 스테이지 모드에서, 시간 제한까지 남은 시간(초). 엔드리스 모드에서는
  /// 항상 -1(표시하지 않음).
  int get secondsRemaining {
    if (isEndless || isPractice) return -1;
    return (timeLimitSeconds - elapsedTime).ceil().clamp(0, timeLimitSeconds);
  }

  late CatPlayer cat;
  int eatenCount = 0;

  /// 감정 타입별로 이번 판에서 먹은 개수 (여러 감정을 동시에 골랐을 때 각 감정 타입별로
  /// 나뉘어 누적된다) - 스테이지가 끝나면 이 맵이 그대로 GardenProvider.recordSession으로
  /// 전달되어, 감정 타입별로 정원에 심어질 꽃 개수를 정확히 반영한다.
  final Map<EmotionType, int> eatenByType = {};

  /// 직전에 먹은 감정 타입과, 그 타입을 몇 번 연속으로 먹었는지(스트릭).
  /// 다른 감정을 먹거나 돌멩이에 맞으면 스트릭이 끊긴다 - 콤보 서사 문구와
  /// 게임 플레이 중 컷인([EmotionCutIn]) 트리거에 함께 쓰인다.
  EmotionType? _lastEatenType;
  int _eatenStreak = 0;

  /// 긍정적인 감정을 이번 판에서 몇 번 받았는지(연속 여부와 무관하게 누적).
  /// [CatPlayer.receiveLight]에 넘길 glowLevel(0.0~1.0)을 계산하는 기준이
  /// 되며, 값이 클수록 몽이 몸의 빛 아우라가 점점 더 커지고 밝아진다 -
  /// "긍정 감정을 받을수록 점점 밝아지고 행복해진다"는 요구를 위한 누적치.
  int _lightReceivedCount = 0;

  /// 직전에 받은 긍정 감정 타입과, 그 타입을 몇 번 연속으로 받았는지(스트릭).
  /// 부정 감정을 먹거나 다른 긍정 감정을 받으면 끊긴다.
  EmotionType? _lastReceivedType;
  int _receivedStreak = 0;

  /// 이 정도 받으면 아우라가 사실상 최대 밝기에 도달하도록 하는 기준치.
  /// 한 스테이지 내에서 몇 번만 받아도 확실히 달라지는 게 느껴지도록 낮게
  /// 잡았다(스테이지를 새로 시작하면 다시 0부터 차오른다).
  static const int _maxGlowStacks = 8;
  List<_SpawnStep> _queue = List.of(_waveCalm);
  int _queueIndex = 0;
  double _stepTimer = 0;
  int _wavesSinceBreather = 0;

  /// A rare, friendly surprise (treat or heart) arrives every so often -
  /// independent of the regular wave rhythm, so it feels unexpected.
  double _bonusTimer = 0;
  double _nextBonusAt = 9.0;
  bool stageCompleted = false;
  bool _earlyStop = false;

  /// 목숨 소진이 아니라 시간 제한 초과로 스테이지가 끝났는지 여부.
  /// [_endStage]에서 어떤 짧은 안내 문구를 띄울지 구분하는 데 쓰인다.
  bool _timeUp = false;

  /// 몽이가 실제로 걷고 있는지(=돌멩이/몬스터가 다가오고 스폰이 진행되는지) 여부.
  /// 러너 게임답게 자동으로 계속 전진하도록 [onLoad]에서 한 번 true로 켜진 뒤
  /// 스테이지가 끝날 때까지 계속 유지된다(부활 시에도 그대로 true).
  bool _isHolding = false;
  bool get isHolding => _isHolding;
  double _celebrationRemaining = -1;
  final math.Random _rand = math.Random();
  double groundY = 0;

  /// 화면을 한 번 톡 쳐서 "주먹 준비" 상태가 됐는지 여부. 이 창(window) 동안
  /// 작은 돌멩이와 부딫히면 자동으로 부순다. 창이 지나면 다시 꺼진다.
  bool punchReady = false;
  double _punchReadyTimer = 0;
  // 0.6 -> 0.85초로 늘려 "주먹이 좀 길게 나갔으면 좋겠다"는 요청대로 판정
  // 창을 더 넉넉하게 잡았다. 이제 속도가 빨라진 만큼(장애물 속도 상향) 반응
  // 여유가 줄어든 걸 이 판정창 확장으로 다시 보완해준다.
  static const double _punchReadyWindow = 0.85;

  /// 돌멩이에 부딪히면 줄어드는 목숨. 0이 되면 스테이지 실패 처리된다.
  final int maxLives;
  late int lives = maxLives;

  /// 미스 없이 연속으로 성공(주먹 타이밍 or 점프 회피)한 횟수. 미스하면 0으로 리셋.
  int combo = 0;
  int maxCombo = 0;

  /// 화면을 붉게 번쩍이게 하는 미스 피드백 오버레이.
  late final HitFlashOverlay hitFlash;

  /// 실제 기기 시각을 기준으로 계산된 "아침/밤 정원" 분위기. 스테이지
  /// 팔레트([ScenePalette])와는 별개로 게임이 시작될 때 한 번 계산되어
  /// 화면 상단 배지(밤 정원이에요 🌙 등)에서도 그대로 참조한다.
  late final TimeOfDayAmbience timeOfDay;

  /// 스테이지가 2단계씩 오를 때마다 완전히 바뀌는 배경 지역(정원->도시->
  /// 바닷가->산속). 일반 스테이지 모드는 [stage]로 결정되고, 엔드리스
  /// 모드는 스테이지 개념이 없으므로 판마다 무작위로 하나를 골라 매번 다른
  /// 풍경에서 도전하는 느낌을 준다.
  late final SceneBiome biome;

  // --- 파워빛볼(무적 모드) -------------------------------------------------
  /// 한 판에 가끔(한두 번) 등장하는 특별한 아이템 - 먹으면 [powerModeDuration]초
  /// 동안 무적이 되어, 큰 돌멩이/참새/개구리처럼 평소엔 반드시 점프로만
  /// 피해야 하는 장애물까지 몸으로 부수며 시원하게 질주할 수 있다.
  static const double powerModeDuration = 10.0;
  double _powerRemaining = 0;
  double _powerOrbTimer = 0;
  double _nextPowerOrbAt = 12;
  bool get isPoweredUp => _powerRemaining > 0;
  int get powerRemainingSeconds =>
      _powerRemaining.ceil().clamp(0, powerModeDuration.toInt());

  /// 무적 모드인 동안 장애물/몬스터/배경이 얼마나 더 빨리 흘러가는지를
  /// 결정하는 배율. 몽이 자체는 화면 고정 위치에 있고 세상이 흘러가는
  /// 구조라, "몽이가 엄청 빨라진 느낌"은 이 배율만큼 모든 스크롤 요소가
  /// 한꺼번에 확 빨라지는 것으로 표현한다 - 평소엔 그대로(1.0배), 무적
  /// 모드에서는 1.85배로 눈에 띄게 질주하는 속도감을 준다.
  double get powerSpeedBoost => isPoweredUp && !isPractice ? 1.85 : 1.0;

  // --- 6번: 숨결 구슬(호흡 미니게임) ---------------------------------------
  /// 한 판에 딱 한 번만 등장하는 "숨결 구슬" - 파워빛볼보다도 훨씬 드물게,
  /// 조용히 한 번만 찾아오는 쉼표라는 인상을 주기 위함이다. 이미 등장했거나
  /// 이미 사용되었으면 다시 스폰하지 않는다.
  bool _breathOrbSpawned = false;
  double _breathOrbTimer = 0;
  double _nextBreathOrbAt = 20;

  /// 지금 호흡 미니게임 다이얼로그가 화면에 떠 있는 동안(pauseEngine 상태)
  /// true. 이 동안에는 시간 제한/스폰/충돌 판정이 모두 멈춘다.
  bool _breathingMomentActive = false;
  bool get isBreathingMoment => _breathingMomentActive;

  @override
  Color backgroundColor() => const Color(0xFFEAF6FF);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // "그림이 늦게 뜬다" 문제의 원인: 예전에는 각 돌멩이/몬스터가 화면에 처음
    // 스폰될 때마다 그제서야 Sprite.load()로 이미지를 비동기 로드했기 때문에,
    // 첫 등장 순간에 잠깐 빈 채로 나타났다가 로딩이 끝나야 그림이 보이는
    // "팝인" 현상이 있었다. 스테이지 시작 전에 사용할 모든 이미지를 한 번에
    // 미리 로드해두면, 실제 플레이 중에는 이미 캐시된 이미지를 즉시 그리기만
    // 하므로 이 지연이 사라진다.
    await images.loadAll([
      'cat_walk_0.png',
      'cat_walk_1.png',
      'cat_walk_2.png',
      'cat_walk_3.png',
      'cat_jump.png',
      'cat_punch.png',
      'cat_eating.png',
      'cat_happy.png',
      'cat_cry.png',
      'rock.png',
      'rock_big.png',
      'obstacle_leafball_0.png',
      'obstacle_leafball_1.png',
      'obstacle_leafball_2.png',
      'obstacle_sparrow_0.png',
      'obstacle_sparrow_1.png',
      'obstacle_sparrow_2.png',
      'obstacle_frog_0.png',
      'obstacle_frog_1.png',
      'obstacle_frog_2.png',
      ...emotions.map(
        (e) => e.monsterAsset.replaceFirst('assets/mongi/images/', ''),
      ),
    ]);

    groundY = size.y * 0.76;
    // Stage 1-2 morning, 3-4 midday, 5-6 golden afternoon, 7+ dusk/night -
    // the scenery visibly shifts as the player progresses through stages.
    final palette = ScenePalette.forStage(stage);
    // timeOfDay/biome은 생성자에서 이미 동기적으로 계산되어 있다(위 필드
    // 선언부 주석 참고) - 여기서는 그대로 사용만 한다.
    // 파워빛볼은 첫 등장까지 살짝 여유를 둬서, 스테이지가 막 시작되자마자
    // 바로 나오지 않게 한다(초반엔 기본 조작에 집중할 수 있도록).
    _nextPowerOrbAt = 10 + _rand.nextDouble() * 6;
    // 6번: 숨결 구슬은 파워빛볼보다도 늦게, 판이 어느 정도 흘러간 뒤에야
    // 한 번 등장한다 - "달리다 보니 문득 찾아오는 쉼표"라는 인상을 위함.
    _nextBreathOrbAt = 20 + _rand.nextDouble() * 12;

    // Sky.
    add(
      RectangleComponent(
        position: Vector2.zero(),
        size: Vector2(size.x, groundY),
        paint: Paint()..color = palette.sky,
      ),
    );

    // Fixed sun/moon (+ stars at night) in the corner of the sky.
    add(
      SkyOrb(
        color: palette.sunMoon,
        isNight: palette.isNight,
        areaWidth: size.x,
        skyHeight: groundY,
      ),
    );

    // Slow-drifting clouds for a gentle parallax feel in the far sky.
    final cloudRand = math.Random();
    for (int i = 0; i < 4; i++) {
      add(
        CloudPuff(
          game: this,
          speed: 14 + cloudRand.nextDouble() * 10,
          color: palette.cloud,
          startPosition: Vector2(
            cloudRand.nextDouble() * size.x,
            12 + cloudRand.nextDouble() * (groundY * 0.42),
          ),
          rand: cloudRand,
        ),
      );
    }

    // Distant rolling backdrop along the horizon (slower parallax layer) -
    // its shape depends entirely on the current biome (hills/buildings/
    // waves/mountains), tinted a touch by the stage's lighting palette hue.
    final hillRand = math.Random();
    for (int i = 0; i < 3; i++) {
      add(
        BiomeSilhouette(
          game: this,
          speed: 16 + hillRand.nextDouble() * 6,
          biome: biome,
          color: Color.lerp(biome.backdropColor, palette.hill, 0.35)!,
          accentColor: biome.accentColor,
          startPosition: Vector2(
            size.x * (i * 0.42) + hillRand.nextDouble() * 60,
            groundY + 6,
          ),
          width: 200 + hillRand.nextDouble() * 90,
          height: 46 + hillRand.nextDouble() * 30,
          rand: hillRand,
        ),
      );
    }

    // 바닥(길)
    add(
      RectangleComponent(
        position: Vector2(0, groundY),
        size: Vector2(size.x, size.y - groundY),
        paint: Paint()..color = palette.ground,
      ),
    );
    // 바닥 경계선
    add(
      RectangleComponent(
        position: Vector2(0, groundY - 4),
        size: Vector2(size.x, 6),
        paint: Paint()..color = palette.boundary,
      ),
    );

    // Small decorative props near the path for a bit of forward-motion
    // texture - which prop shows up (grass tuft/planter/shell/pine) depends
    // on the current biome.
    final tuftRand = math.Random();
    for (int i = 0; i < 5; i++) {
      add(
        BiomeDecor(
          game: this,
          speed: 60 + tuftRand.nextDouble() * 30,
          biome: biome,
          color: Color.lerp(biome.decorColor, palette.tuft, 0.25)!,
          accentColor: biome.accentColor,
          startPosition: Vector2(
            tuftRand.nextDouble() * size.x,
            groundY + 20 + tuftRand.nextDouble() * 18,
          ),
          rand: tuftRand,
        ),
      );
    }

    // 밤 시간대라면 화면 위쪽에 은은한 반딧불이 몇 마리를 띄우고, 새벽/밤
    // 모두 스테이지 팔레트 위에 아주 옅은 색감 오버레이를 한 겹 덮는다. 오직
    // 실제 시각에만 반응하므로 스테이지 자체의 밤 테마(7단계 이상)와 겹쳐도
    // 자연스럽다.
    if (timeOfDay.fireflyCount > 0) {
      final fireflyRand = math.Random();
      for (int i = 0; i < timeOfDay.fireflyCount; i++) {
        add(
          Firefly(
            game: this,
            startPosition: Vector2(
              fireflyRand.nextDouble() * size.x,
              groundY * 0.25 + fireflyRand.nextDouble() * (groundY * 0.55),
            ),
            driftSpeed: 8 + fireflyRand.nextDouble() * 10,
            swayAmplitude: 8 + fireflyRand.nextDouble() * 10,
            swaySpeed: 1.2 + fireflyRand.nextDouble() * 1.4,
            blinkSpeed: 1.5 + fireflyRand.nextDouble() * 1.5,
            rand: fireflyRand,
          ),
        );
      }
    }
    if (timeOfDay.overlayAlpha > 0) {
      add(TimeOfDayOverlay(ambience: timeOfDay, size: Vector2(size.x, size.y)));
    }

    _nextBonusAt = 9 + _rand.nextDouble() * 5;

    // 이전 스테이지가 끝나며 걸어둔 발소리 억제(stopFootstep)를 새 스테이지가
    // 시작되는 이 시점에 반드시 풀어준다 - 안 그러면 "이어하기"나 다음
    // 스테이지에서 발소리가 영영 다시 들리지 않는다.
    SoundManager.instance.resumeFootstep();

    cat = CatPlayer(
      groundY: groundY,
      costumeAsset: equippedCostumeAsset,
      costumeOffsetXRatio: costumeOffsetXRatio,
      costumeOffsetYRatio: costumeOffsetYRatio,
      costumeScaleRatio: costumeScaleRatio,
    )..position = Vector2(size.x * 0.20, groundY);
    // add()는 자식의 onLoad()를 백그라운드로 시작만 시키고 완료를 기다리지
    // 않는다(FutureOr 반환). setHolding(true) -> cat.setWalking(true)는
    // cat.onLoad()에서 초기화되는 late 필드(walkAnimation 등)에 접근하므로,
    // await 없이 곧바로 호출하면 웹(dart2js)에서 아직 초기화 전인 late 필드에
    // 접근해 LateInitializationError가 발생하고, 이를 GameWidget이
    // errorBuilder 없이 그대로 다시 던져 화면이 회색으로 보이는 문제가
    // 있었다. cat.onLoad()가 실제로 끝날 때까지 반드시 기다린다.
    await add(cat);

    hitFlash = HitFlashOverlay();
    add(hitFlash);

    // 러너 게임답게 속도감을 주기 위해 화면을 누르고 있을 필요 없이 항상
    // 자동으로 전진한다 - 플레이어는 오직 점프/주먹 타이밍에만 집중하면 된다.
    setHolding(true);

    // 귀여운 배경음악 시작 (실패해도 게임 진행에는 영향 없음).
    SoundManager.instance.startBgm();
    // 새소리/물소리 앰비언트도 계속 이어지도록 보장한다(이미 홈 화면에서
    // 시작되어 있다면 내부 가드에 의해 조용히 무시됨 - 소리가 겹치지 않음).
    SoundManager.instance.startAmbientNature();
  }

  @override
  void onRemove() {
    // 화면을 떠날 때 배경음악을 확실히 멈춘다 (안전망 - 화면의 dispose에서도 정지시킴).
    // 앰비언트(새소리/물소리)는 홈 화면부터 계속 이어지는 배경 요소라 여기서
    // 끄지 않는다 - 결과 화면/숨쉬기에서도 계속 들려야 한다.
    SoundManager.instance.stopBgm();
    super.onRemove();
  }

  /// 몽이가 걷는 상태를 켜고 끈다. 지금은 [onLoad]에서 한 번 true로 켠 뒤
  /// 계속 유지되는 자동 전진 방식이라 외부에서 다시 끌 일은 없지만, 내부
  /// 초기화 로직에서 재사용할 수 있도록 그대로 남겨둔다.
  void setHolding(bool holding) {
    if (_isHolding == holding) return;
    _isHolding = holding;
    cat.setWalking(holding);
  }

  // Touch pointers and keyboard keys hold independently, including mixed input.
  final Set<Object> _jumpSources = {};

  void pressJumpInput(Object source) {
    if (!acceptsGameplayInput || !_jumpSources.add(source)) return;
    setJumpHeld(true);
    jump();
  }

  void releaseJumpInput(Object source) {
    _jumpSources.remove(source);
    setJumpHeld(_jumpSources.isNotEmpty);
  }

  void clearGameplayInput() {
    _jumpSources.clear();
    setJumpHeld(false);
    consumePunchReady();
  }

  @override
  void pauseEngine() {
    clearGameplayInput();
    super.pauseEngine();
  }

  /// 더블탭(또는 스페이스바) - 점프. 큰 돌멩이는 반드시 이걸로 피해야 한다.
  void jump() {
    if (acceptsGameplayInput) cat.jump();
  }

  /// 점프를 일으킨 터치(또는 스페이스바)가 화면에서 떨어졌는지를 화면
  /// 쪽에서 알려준다. true인 동안 계속 누르고 있으면 몽이의 점프가 더
  /// 길게/높게 이어진다("손으로 쭉 당기면 점프가 길어진다" 요청 구현).
  void setJumpHeld(bool held) {
    if (isLoaded && (!held || acceptsGameplayInput)) cat.setJumpHeld(held);
  }

  /// 누르는 즉시 주먹을 준비하고, 이미 사거리 안에 있는 장애물도 처리한다.
  void punchAction() {
    if (!acceptsGameplayInput) return;
    cat.punchSwing();
    punchReady = true;
    _punchReadyTimer = _punchReadyWindow;
    final obstacles =
        children
            .whereType<PositionComponent>()
            .where((c) => c is ObstacleRock || c is AnimatedObstacle)
            .toList()
          ..sort((a, b) => a.position.x.compareTo(b.position.x));
    for (final obstacle in obstacles) {
      if (obstacle is ObstacleRock) obstacle.tryPunch();
      if (obstacle is AnimatedObstacle) obstacle.tryPunch();
      if (!punchReady) break;
    }
  }

  /// 작은 돌멩이가 성공적으로 부서졌을 때 준비 상태를 소모한다.
  void consumePunchReady() {
    punchReady = false;
    _punchReadyTimer = 0;
  }

  /// 주먹 준비 창(0.85초)이 얼마나 남았는지의 비율(0.0~1.0).
  /// 값이 높을수록 - 준비한 뒤 거의 바로 돌멩이가 왔다는 뜻 - 반응속도가 빠른
  /// "완벽한 타이밍"으로 판정한다. 낮으면(미리 눌러두고 기다린 경우) 정상 성공으로만 처리한다.
  double get punchReadyRemainingRatio =>
      punchReady ? (_punchReadyTimer / _punchReadyWindow).clamp(0.0, 1.0) : 0.0;

  /// 미스 없이 돌멩이를 성공적으로 처리했을 때(주먹 타이밍 성공 또는 점프로 회피)
  /// 호출한다. 콤보를 쌓고, 가벼운 햅틱으로 손맛을 더한다.
  void registerSuccess({bool perfect = false}) {
    if (stageCompleted) return;
    combo += 1;
    if (combo > maxCombo) maxCombo = combo;
    onComboChanged(combo);
    if (perfect) {
      _haptic(HapticFeedback.heavyImpact);
      add(
        FloatingLabel(
          position: cat.position + Vector2(0, -78),
          text: l10n.gamePerfectTimingLabel,
        ),
      );
    } else {
      _haptic(HapticFeedback.lightImpact);
    }
  }

  /// 위젯 테스트(VM) 환경에는 haptic 플러그인 구현체가 없어 실패할 수 있으므로,
  /// 실제 기기/브라우저에서만 조용히 동작하고 테스트에서는 에러를 무시한다.
  void _haptic(Future<void> Function() trigger) {
    trigger().catchError((_) {});
  }

  /// 돌멩이에 부딪혔을 때 - 표시용 카운터 콜백을 호출하고, 실제로 목숨을 하나 깎는다.
  /// 목숨이 0이 되어도 '게임오버'로 끝내지 않고, 그동안 먹은 만큼을 들고 부드럽게
  /// 스테이지를 마무리한다 (실패 페널티/재도전 강요 없음 - 힐링 목적에 맞게).
  void registerRockHit() {
    if (stageCompleted || _reviveOfferPending) return;
    onRockHit();
    if (isPractice) return;
    add(
      FloatingLabel(
        position: cat.position + Vector2(0, -78),
        text: l10n.gameRockHitLabel,
      ),
    );
    combo = 0;
    onComboChanged(0);
    _lastEatenType = null;
    _eatenStreak = 0;
    hitFlash.trigger();
    _haptic(HapticFeedback.mediumImpact);
    if (lives > 0) {
      lives -= 1;
      onLivesChanged(lives);
    }
    if (lives <= 0) {
      _handleLivesExhausted();
    }
  }

  /// 목숨을 다 썼을 때 - 부활 제안이 가능하면(콜백 제공) 게임을 잠시
  /// 멈추고 "이어하기"를 제안한다. 처음 [freeRevivesPerRun]번까지는 광고
  /// 없이 바로 이어갈 수 있고, 그 이후부터는 광고를 봐야만 이어갈 수 있다.
  /// 제안을 거절하거나 광고 시청에 실패하면 평소처럼 스테이지를 부드럽게
  /// 마무리한다. (콜백 자체가 없으면 - 즉 부활 제안을 지원하지 않는
  /// 화면이면 - 즉시 마무리한다.)
  void _handleLivesExhausted() {
    if (onLivesExhausted == null) {
      _endStage(earlyStop: true);
      return;
    }
    final requiresAd = revivesUsedThisRun >= freeRevivesPerRun;
    _reviveOfferPending = true;
    pauseEngine();
    onLivesExhausted!(revivesUsedThisRun, requiresAd: requiresAd).then((
      revived,
    ) {
      _reviveOfferPending = false;
      resumeEngine();
      if (revived) {
        revivesUsedThisRun += 1;
        lives = maxLives;
        onLivesChanged(lives);
        add(
          FloatingLabel(
            position: cat.position + Vector2(0, -96),
            text: l10n.gameReviveEncouragementLabel,
          ),
        );
      } else {
        _endStage(earlyStop: true);
      }
    });
  }

  /// 5번: 몬스터 감정 라벨링 - 정원에 한 번도 심어본 적 없는(=[priorMetCounts]에
  /// 없거나 0인) 감정 타입을 이번 판에서 처음 마주치는 순간, "처음 만난
  /// 마음이에요" + 그 감정의 진화 애칭(기본형) + 이미 있던 catQuestion 대사를
  /// 묶어 화면 위쪽에 크게 보여준다. 한 판 안에서는 타입별로 딱 한 번만 뜬다.
  ///
  /// "몬스터"라는 뭉뚱그린 존재가 아니라 "화르르", "걱정구름" 같은 구체적인
  /// 이름으로 처음 불러주는 순간 자체가, 심리학에서 말하는 감정 명명하기
  /// (affect labeling)를 게임 이펙트로 옮긴 것이다.
  void _maybeRevealFirstMeetLabel(Vector2 atPosition, Emotion emotion) {
    if (_labelRevealedTypes.contains(emotion.type)) return;
    final priorCount = priorMetCounts[emotion.type.name] ?? 0;
    if (priorCount > 0) return;
    _labelRevealedTypes.add(emotion.type);
    add(
      EmotionLabelReveal(
        nickname: evolutionNameForCount(l10n, emotion.type, 0),
        catLine: emotionCatQuestion(l10n, emotion.type),
        accentColor: emotion.color,
        areaWidth: size.x,
        caption: l10n.gameFirstMeetCaption,
        topCenter: Vector2(size.x / 2, 68),
      ),
    );
  }

  void onMonsterEaten(Vector2 atPosition, Emotion eaten) {
    if (stageCompleted) return;
    eatenCount++;
    eatenByType[eaten.type] = (eatenByType[eaten.type] ?? 0) + 1;
    _maybeRevealFirstMeetLabel(atPosition, eaten);

    // 같은 감정을 연속으로 먹은 횟수를 추적한다 - 순수 게임 콤보가 아니라
    // "이 감정을 몇 번 연속으로 마주했는가"라는 감정 서사의 재료가 된다.
    if (_lastEatenType == eaten.type) {
      _eatenStreak++;
    } else {
      _lastEatenType = eaten.type;
      _eatenStreak = 1;
    }

    add(
      FloatingLabel(
        position: atPosition + Vector2(0, -40),
        text: gameEatenLineText(l10n, eaten.type, streak: _eatenStreak),
      ),
    );

    // 4번: 게임 플레이 도중의 감정 컷인 - 같은 감정을 3번째 연속으로 먹는
    // 순간, 그 감정의 healMessage가 짧은 게임 이펙트처럼 화면 위쪽에 튀어
    // 나온다. 스테이지가 끝나야만 힐링 파트가 나오는 경계를 없애기 위함이다.
    // 이후로도 3의 배수마다(6, 9...) 다시 한번 짚어주되, 너무 잦은 컷인이
    // 플레이를 방해하지 않도록 최소 간격을 둔다.
    if (GameNarrativeService.shouldTriggerCutIn(_eatenStreak)) {
      add(
        EmotionCutIn(
          text: _streakCutInMessageFor(eaten),
          accentColor: eaten.color,
          areaWidth: size.x,
          topCenter: Vector2(size.x / 2, 68),
        ),
      );
      // 4번: 스트릭 미니 이벤트 - 설명 카드만으로는 "축하받는 손맛"이 잘
      // 느껴지지 않아서, 몬스터가 사라진 그 자리에서 곧바로 반짝이는 조각들이
      // 사방으로 튀는 축하 이펙트를 함께 터뜨린다. 스트릭이 오래 이어질수록
      // (티어가 높아질수록) 조각 수와 중앙 별이 조금씩 더 커진다.
      add(
        StreakBurst(
          position: atPosition,
          color: eaten.color,
          tier: (_eatenStreak / GameNarrativeService.cutInStreakInterval)
              .floor(),
        ),
      );
      _haptic(HapticFeedback.mediumImpact);
    }

    onProgressChanged(eatenCount);
    // 엔드리스 모드는 목표 개수가 없다 - 목숨을 다 쓸 때까지 계속 이어진다.
    if (!isEndless && eatenCount >= targetEatenCount) {
      _endStage(earlyStop: false);
    }
  }

  /// 긍정적인 감정(joy/gratitude/excitement/calm/confidence/courage/
  /// thrill/happiness)을 몽이가 가슴으로 받아 안았을 때 - 먹어서 사라지는
  /// [onMonsterEaten]과 달리, 받을수록 몽이 몸의 빛이 점점 더 밝아지고
  /// 커지도록 누적치를 관리한다.
  void onLightReceived(Vector2 atPosition, Emotion received) {
    if (stageCompleted) return;
    eatenCount++;
    eatenByType[received.type] = (eatenByType[received.type] ?? 0) + 1;
    _maybeRevealFirstMeetLabel(atPosition, received);

    if (_lastReceivedType == received.type) {
      _receivedStreak++;
    } else {
      _lastReceivedType = received.type;
      _receivedStreak = 1;
    }

    // 받을 때마다 누적치를 올려 몽이 몸의 빛이 계속 진해지게 한다
    // (한 판 안에서는 줄어들지 않고, 다음 스테이지에서 다시 0부터 차오른다).
    _lightReceivedCount++;
    final glowLevel = (_lightReceivedCount / _maxGlowStacks).clamp(0.0, 1.0);
    cat.receiveLight(received.color, glowLevel, received.type);

    // 몬스터가 있던 자리에서 은은하게 퍼지는 빛무리 - "먹어서 사라짐"이
    // 아니라 "빛이 되어 스며듦"이라는 인상을 준다.
    add(LightBurst(position: atPosition, color: received.color));

    add(
      FloatingLabel(
        position: atPosition + Vector2(0, -40),
        text: gameReceivedLineText(
          l10n,
          received.type,
          streak: _receivedStreak,
        ),
      ),
    );

    if (GameNarrativeService.shouldTriggerCutIn(_receivedStreak)) {
      add(
        EmotionCutIn(
          text: _streakCutInMessageFor(received),
          accentColor: received.color,
          areaWidth: size.x,
          topCenter: Vector2(size.x / 2, 68),
        ),
      );
      // 4번: 스트릭 미니 이벤트 - 긍정 감정을 연속으로 품어 안을 때도 동일하게
      // 반짝이는 축하 이펙트를 터뜨려, "먹기"와 "받기" 양쪽 모두에서 같은
      // 리듬감을 느낄 수 있게 한다.
      add(
        StreakBurst(
          position: atPosition,
          color: received.color,
          tier: (_receivedStreak / GameNarrativeService.cutInStreakInterval)
              .floor(),
        ),
      );
      _haptic(HapticFeedback.mediumImpact);
    }

    onProgressChanged(eatenCount);
    if (!isEndless && eatenCount >= targetEatenCount) {
      _endStage(earlyStop: false);
    }
  }

  /// 스테이지를 마무리한다. 목표를 다 채웠으면([earlyStop]=false) 배부르게 골골거리는
  /// 축하 모션을, 중간에 목숨을 다 썼으면([earlyStop]=true) 게임오버 없이 잔잔하게
  /// 위로하는 모션을 보여준 뒤 다음(선택) 화면으로 넘어간다.
  void _endStage({required bool earlyStop}) {
    if (stageCompleted) return;
    stageCompleted = true;
    _earlyStop = earlyStop;
    // 스테이지가 끝나는 바로 이 순간부터는 물소리/새소리(자연 앰비언트)만
    // 남기고 배경음악과 (혹시 막 재생되기 시작했을 수 있는) 발소리는 즉시
    // 정지한다. 원래는 이후 "숨쉬기" 인터스티셜(pauseBgm)이나 화면 dispose
    // (stopBgm) 시점에야 배경음악이 멈췄는데, 그 사이(최대 약 1.85초) 동안
    // 배경음악이 계속 들려서 "스테이지가 끝났는데도 배경소리/발소리가
    // 들린다"는 문제가 있었다. 여기서 곧바로 멈춰 그 공백을 없앤다.
    SoundManager.instance.stopBgm();
    SoundManager.instance.stopFootstep();
    if (earlyStop) {
      cat.comfort();
      // 2번: 실패(목숨 소진/시간 초과)를 처벌하지 않되, 다음 판을 당기는 게임
      // 후크로 전환하는 첫 단추 - 게임 화면(FloatingLabel)에는 짧은 한 줄만
      // 띄우고, "아직 남은 감정" 같은 자세한 후크는 이어지는 선택/결과
      // 화면에서 [GameNarrativeService.earlyStopHook]으로 보여준다.
      add(
        FloatingLabel(
          position: cat.position + Vector2(0, -96),
          text: _timeUp
              ? l10n.gameTimeUpLabel(eatenCount)
              : (isEndless
                    ? l10n.gameEarlyStopShortEndless(eatenCount)
                    : l10n.gameEarlyStopShortNormal(eatenCount)),
        ),
      );
    } else {
      cat.celebrate();
      add(
        FloatingLabel(
          position: cat.position + Vector2(0, -96),
          text: l10n.gameStageClearPurrLabel,
        ),
      );
      // 목숨이 다 돼서 끝난 것(earlyStop)과 뚜렷이 구분되도록, 화면 중앙에
      // 크게 "CLEAR!" 배너 + 색종이 효과를 띄운다. 작은 FloatingLabel 한
      // 줄만으로는 "먹었을 때 뜨는 냠!"과 구분이 잘 안 돼서, "죽은 건지
      // 스테이지를 완료한 건지 알 수가 없다"는 피드백이 있었다.
      add(StageClearBanner(areaSize: size));
    }
    // 성공 배너(StageClearBanner)는 약 2초간 보여지므로, 다음 화면으로
    // 넘어가기 전에 충분히 눈에 담을 시간을 준다. earlyStop(실패/시간초과)은
    // 기존과 동일하게 짧게 유지한다.
    _celebrationRemaining = earlyStop ? 1.5 : 2.1;
  }

  @override
  void update(double dt) {
    // 몽이의 점프 물리(중력/착지)는 isHolding과 무관하게 항상 실시간으로 계산한다.
    // 돌멩이/몬스터의 이동과 새 스폰은 각자 game.isHolding을 확인하지만, 이제는
    // onLoad에서 한 번 true로 켜진 뒤 계속 유지되므로 실질적으로 항상 진행된다.
    if (punchReady) {
      _punchReadyTimer -= dt;
      if (_punchReadyTimer <= 0) {
        punchReady = false;
        _punchReadyTimer = 0;
      }
    }

    super.update(dt);

    if (stageCompleted) {
      if (_celebrationRemaining > 0) {
        _celebrationRemaining -= dt;
        if (_celebrationRemaining <= 0) {
          _celebrationRemaining = -1;
          onStageComplete(eatenCount, earlyStop: _earlyStop);
        }
      }
      return;
    }

    if (!_isHolding) return; // 안전장치: 정상적으로는 스테이지 시작 후 항상 true.

    // 6번: 호흡 미니게임 다이얼로그가 떠 있는 동안(pauseEngine으로 실제
    // 렌더링/입력도 멈춰있지만, 혹시 그 사이 한 프레임이라도 update가 불려도
    // 시간/스폰/충돌 판정이 전혀 진행되지 않도록 이중으로 막아둔다.
    if (_breathingMomentActive) return;

    elapsedTime += dt;

    // 일반 스테이지 모드에서 시간 제한을 넘기면, 목숨을 다 썼을 때와 동일한
    // "부드러운 마무리"로 처리한다 - 실패로 취급하지 않고 그동안 만난 만큼을
    // 인정해준다. 부활 제안 등이 이미 진행 중이면 중복 트리거하지 않는다.
    if (!isEndless &&
        !isPractice &&
        !_reviveOfferPending &&
        elapsedTime >= timeLimitSeconds) {
      _timeUp = true;
      _endStage(earlyStop: true);
      return;
    }

    _stepTimer += dt;
    if (_queueIndex < _queue.length &&
        _stepTimer >= _queue[_queueIndex].delay) {
      _stepTimer = 0;
      _spawnKind(_queue[_queueIndex].kind);
      _queueIndex++;
    }
    if (_queueIndex >= _queue.length) {
      _loadNextWave();
    }

    _bonusTimer += dt;
    if (_bonusTimer >= _nextBonusAt) {
      _bonusTimer = 0;
      _nextBonusAt = 9 + _rand.nextDouble() * 5;
      _spawnBonus();
    }

    // 파워빛볼(무적 모드) 진행 시간 감소 - 다 되면 자동으로 평소 상태로 복귀.
    if (_powerRemaining > 0) {
      _powerRemaining -= dt;
      if (_powerRemaining <= 0) {
        _powerRemaining = 0;
        cat.setPowered(false);
      }
    }

    // 파워빛볼 스폰 - 이미 무적 상태인 동안에는 새로 띄우지 않는다("한 판에
    // 가끔 한두 번"이라는 취지를 지키기 위함이며, 중첩되어 쌓이지도 않는다).
    if (!isPoweredUp) {
      _powerOrbTimer += dt;
      if (_powerOrbTimer >= _nextPowerOrbAt) {
        _powerOrbTimer = 0;
        _nextPowerOrbAt = 18 + _rand.nextDouble() * 10;
        _spawnPowerOrb();
      }
    }

    // 6번: 숨결 구슬 스폰 - 한 판에 딱 한 번만.
    if (!_breathOrbSpawned) {
      _breathOrbTimer += dt;
      if (_breathOrbTimer >= _nextBreathOrbAt) {
        _breathOrbSpawned = true;
        _spawnBreathOrb();
      }
    }
  }

  void _spawnBonus() {
    final wantHeart = lives < maxLives && _rand.nextDouble() < 0.5;
    add(
      BonusItem(
        game: this,
        kind: wantHeart ? BonusKind.heart : BonusKind.treat,
        speed: 250 * speedMultiplier,
      )..position = Vector2(size.x + 60, groundY),
    );
  }

  void _spawnPowerOrb() {
    add(
      PowerOrb(game: this, speed: 250 * speedMultiplier)
        ..position = Vector2(size.x + 60, groundY),
    );
  }

  void _spawnBreathOrb() {
    if (isPractice) return;
    add(
      BreathOrb(game: this, speed: 220 * speedMultiplier)
        ..position = Vector2(size.x + 60, groundY),
    );
  }

  /// 6번: "숨결 구슬"에 닿는 순간 - 주먹/점프 같은 "빠르게 반응하기"와는
  /// 정반대로, 게임 전체를 잠깐 멈추고 화면 쪽에 호흡 미니게임을 띄워달라고
  /// 알린다. 실제 다이얼로그는 화면(RunnerGameScreen)의 책임이며, 결과는
  /// [resolveBreathingMoment]로 되돌아온다.
  void startBreathingMoment() {
    if (stageCompleted || _breathingMomentActive) return;
    _breathingMomentActive = true;
    cat.startBreathingPose();
    SoundManager.instance.pauseBgm();
    pauseEngine();
    onBreathingMomentStart();
  }

  /// 호흡 미니게임 다이얼로그가 닫힌 뒤(성공했든 건너뛰었든) 화면 쪽에서
  /// 호출한다. [succeeded]가 true면(호흡 리듬을 잘 따라간 경우) 부드러운
  /// 보상(생명 회복, 없으면 작은 진행도 보너스)을 주고, 아니어도 페널티
  /// 없이 그냥 원래 속도로 되돌아간다.
  void resolveBreathingMoment({required bool succeeded}) {
    if (!_breathingMomentActive) return;
    _breathingMomentActive = false;
    cat.endBreathingPose();
    resumeEngine();
    SoundManager.instance.resumeBgm();
    if (stageCompleted) return;
    if (succeeded) {
      _haptic(HapticFeedback.mediumImpact);
      if (lives < maxLives) {
        lives += 1;
        onLivesChanged(lives);
        add(
          FloatingLabel(
            position: cat.position + Vector2(0, -96),
            text: l10n.gameBreathingLifeRestoredLabel,
          ),
        );
      } else {
        final before = eatenCount;
        eatenCount = isEndless
            ? eatenCount + 1
            : (eatenCount + 1).clamp(0, targetEatenCount);
        if (eatenCount != before) {
          final bonusType = emotions[_rand.nextInt(emotions.length)].type;
          eatenByType[bonusType] = (eatenByType[bonusType] ?? 0) + 1;
          onProgressChanged(eatenCount);
        }
        add(
          FloatingLabel(
            position: cat.position + Vector2(0, -96),
            text: l10n.gameBreathingBonusLabel,
          ),
        );
        if (!isEndless && eatenCount >= targetEatenCount) {
          _endStage(earlyStop: false);
          return;
        }
      }
    } else {
      add(
        FloatingLabel(
          position: cat.position + Vector2(0, -96),
          text: l10n.gameBreathingSkippedLabel,
        ),
      );
    }
  }

  /// 파워빛볼을 먹는 순간 - [powerModeDuration]초 동안 무적 모드에 들어간다.
  /// 스폰 로직상 이미 무적인 동안에는 새로 뜨지 않지만, 혹시라도 겹치면
  /// 남은 시간을 다시 최대치로 채워준다(스택으로 계속 늘어나진 않음).
  void activatePowerMode() {
    if (stageCompleted) return;
    final wasActive = isPoweredUp;
    _powerRemaining = powerModeDuration;
    cat.setPowered(true, duration: powerModeDuration);
    if (!wasActive) {
      _haptic(HapticFeedback.heavyImpact);
      SoundManager.instance.playReceiveSparkle();
      add(
        FloatingLabel(
          position: cat.position + Vector2(0, -110),
          text: l10n.gamePowerModeActivatedLabel,
        ),
      );
    }
  }

  /// 무적 모드 중에 장애물을 몸으로 부수고 지나갈 때 - 패널티 없이 콤보만
  /// 쌓아준다. 일반 성공([registerSuccess])과는 문구/느낌을 다르게 주기 위해
  /// 별도 메서드로 분리했다.
  void registerPowerSmash(Vector2 atPosition) {
    if (stageCompleted) return;
    combo += 1;
    if (combo > maxCombo) maxCombo = combo;
    onComboChanged(combo);
    _haptic(HapticFeedback.mediumImpact);
    add(
      FloatingLabel(
        position: atPosition + Vector2(0, -40),
        text: l10n.gamePowerSmashLabel,
      ),
    );
  }

  /// A sparkly treat was collected - worth +2 progress and a small combo
  /// celebration (no penalty for missing it, it's purely a bonus).
  void collectTreat(Vector2 atPosition) {
    if (stageCompleted) return;
    final before = eatenCount;
    eatenCount = isEndless
        ? eatenCount + 2
        : (eatenCount + 2).clamp(0, targetEatenCount);
    final delta = eatenCount - before;
    if (delta > 0) {
      final bonusType = emotions[_rand.nextInt(emotions.length)].type;
      eatenByType[bonusType] = (eatenByType[bonusType] ?? 0) + delta;
    }
    onProgressChanged(eatenCount);
    combo += 1;
    if (combo > maxCombo) maxCombo = combo;
    onComboChanged(combo);
    _haptic(HapticFeedback.heavyImpact);
    add(
      FloatingLabel(
        position: atPosition + Vector2(0, -46),
        text: l10n.gameTreatBonusLabel,
      ),
    );
    if (!isEndless && eatenCount >= targetEatenCount) {
      _endStage(earlyStop: false);
    }
  }

  /// A heart was collected - restores one life. Only ever spawned while a
  /// life is missing, so this always has a visible effect.
  void collectHeart(Vector2 atPosition) {
    if (stageCompleted) return;
    if (lives < maxLives) {
      lives += 1;
      onLivesChanged(lives);
    }
    _haptic(HapticFeedback.mediumImpact);
    add(
      FloatingLabel(
        position: atPosition + Vector2(0, -46),
        text: l10n.gameHeartRestoredLabel,
      ),
    );
  }

  /// 목표 개수 대비 지금까지 먹은 비율이, 제한시간 대비 지금까지 흐른 시간
  /// 비율보다 눈에 띄게(20%p 이상) 뒤처졌는지 판단한다. 장애물 위주 웨이브가
  /// 연달아 나와 먹을 몬스터 자체가 부족했던 경우를 잡아내기 위함이다.
  /// 엔드리스 모드는 애초에 목표/제한시간 개념이 없으므로 항상 false.
  bool _isBehindSchedule() {
    if (isEndless || isPractice || targetEatenCount <= 0) return false;
    final timeRatio = (elapsedTime / timeLimitSeconds).clamp(0.0, 1.0);
    if (timeRatio < 0.25) return false; // 초반에는 아직 판단하기 이르다.
    final progressRatio = (eatenCount / targetEatenCount).clamp(0.0, 1.0);
    return progressRatio < timeRatio - 0.2;
  }

  /// 5번: 지금 화면에 보이는 [biome]에 맞춰 골라지는 전용 웨이브. 스테이지
  /// 숫자가 아니라 실제로 보여지는 배경 그 자체를 기준으로 삼기 때문에,
  /// 엔드리스 모드(배경이 판마다 무작위)에서도 "지금 여기" 풍경에 어울리는
  /// 리듬이 나온다.
  List<_SpawnStep> get _biomeWave {
    switch (biome) {
      case SceneBiome.garden:
        return _waveGardenStroll;
      case SceneBiome.city:
        return _waveCityRush;
      case SceneBiome.ocean:
        return _waveOceanBreeze;
      case SceneBiome.mountain:
        return _waveMountainClimb;
    }
  }

  /// Picks the next wave so a run feels rhythmic instead of flat random.
  /// Higher stages lean more toward rockier/mixed waves and take fewer
  /// breathers; a short breather is still inserted every couple of waves
  /// so the pace keeps breathing in and out.
  ///
  /// 제한시간([timeLimitSeconds]) 자체는 그대로 두되, 장애물 위주 웨이브가
  /// 연달아 뽑혀서 "먹을 몬스터 자체가 부족해 시간 안에 목표를 채울 방법이
  /// 없는" 불운한 상황을 막기 위해, 지금까지 흐른 시간 대비 먹은 개수가
  /// 눈에 띄게 뒤처졌다면 몬스터 위주 웨이브([_waveCatchUp])를 강제로
  /// 끼워 넣어 따라잡을 기회를 준다.
  void _loadNextWave() {
    final effectiveStage = isEndless ? _endlessDifficultyStage : stage;
    List<_SpawnStep> chosen;
    if (_isBehindSchedule()) {
      chosen = _waveCatchUp;
      _wavesSinceBreather++;
      _queue = chosen;
      _queueIndex = 0;
      _stepTimer = 0;
      return;
    }
    // 1번(벤치마킹 제안: 감정 강도-게임 난이도 매칭) - 격한 부정 감정을
    // 강하게 느꼈다고 표시한 판이면 숨 고르기 웨이브가 더 자주 뽑히도록
    // 확률을 높여, 몰아치는 리듬 대신 다독이는 흐름을 우선한다.
    final soften = isSoftenedBySoothingIntent;
    var breatherChance = effectiveStage <= 3
        ? 0.30
        : (effectiveStage <= 7 ? 0.18 : 0.10);
    if (soften) breatherChance = (breatherChance + 0.20).clamp(0.0, 0.6);
    if (_wavesSinceBreather >= 2 && _rand.nextDouble() < breatherChance) {
      chosen = _waveBreather;
      _wavesSinceBreather = 0;
    } else {
      // 1단계부터도 목표가 20개로 늘어나 한 판이 꽤 길어졌으므로, 초반부터
      // 같은 웨이브 몇 개만 계속 반복되지 않도록 기본 풀에 8가지 웨이브를
      // 모두 넣어 처음부터 장애물/등장 패턴이 다채롭게 섞이게 한다. 더 바쁘고
      // 난이도가 높은 후반 전용 패턴(_waveAdvanced/_waveChaos/_waveMenagerie
      // 등)은 기존과 동일하게 스테이지가 오른 뒤에만 섞인다.
      final liven = isLivenedByLowEnergyIntent;
      final pool = <List<_SpawnStep>>[
        _waveCalm,
        _waveMixed,
        _waveRocky,
        _waveLeaves,
        _waveSkyDance,
        _waveHop,
        _waveFloaters,
        _wavePairs,
        // 지루함/피곤함을 약하게 느꼈다고 표시했다면 잔잔한 _waveCalm 비중을
        // 조금 더 늘려서 오히려 "몬스터를 자주 만나는" 활기찬 리듬을 만든다
        // (장애물이 아니라 몬스터 위주 웨이브를 더 자주 뽑는 방식이라, 반응
        // 속도 부담 없이도 체감 속도만 살짝 올라간다).
        if (liven) _waveCalm,
        if (liven) _waveMixed,
        if (effectiveStage >= 3 && !soften) _waveRocky,
        if (effectiveStage >= 3 && !soften) _waveMixed,
        if (effectiveStage >= 3) _waveSkyDance,
        if (effectiveStage >= 3) _waveHop,
        // 다독임이 필요한 판(soften)에서는 후반 전용의 더 빡빡한 패턴
        // (_waveAdvanced/_waveMenagerie/_waveChaos)을 풀에서 완전히 배제해,
        // 스테이지가 높아도 그 판만큼은 확실히 부드럽게 흘러가게 한다.
        if (effectiveStage >= 5 && !soften) _waveAdvanced,
        if (effectiveStage >= 5 && !soften) _waveMenagerie,
        // "18단계가 너무 빨라 반응속도가 오히려 느려진다"는 피드백을 받아,
        // 가장 촘촘한 _waveChaos의 등장 시점을 8단계 -> 12단계로 늦추고
        // 풀 안에서의 비중도 2개 -> 1개로 줄였다. 대신 _waveAdvanced를
        // 8단계 구간에도 한 번 더 추가해 "점점 북적북적해지는" 체감 난이도
        // 곡선 자체는 유지하면서, 가장 빡빡한 패턴만 뒤로 미뤘다.
        if (effectiveStage >= 8 && !soften) _waveAdvanced,
        if (effectiveStage >= 8 && !soften) _waveMenagerie,
        if (effectiveStage >= 12 && !soften) _waveChaos,
        if (effectiveStage >= 12 && !soften) _waveMenagerie,
        // 5번: 지금 배경(바이옴)에 어울리는 전용 웨이브를 풀에 2번씩 더
        // 넣어(다른 웨이브 1개당 노출 비중의 약 2배) "이 구간은 확실히
        // 다르다"는 게 리듬으로도 느껴지도록 살짝 힘을 실어준다. 완전히
        // 고정하지 않고 풀에 "가산"만 하는 이유는, 그래도 매번 똑같은
        // 조합만 나오면 오히려 예측 가능해져 지루해지기 때문이다.
        _biomeWave,
        _biomeWave,
      ];
      chosen = pool[_rand.nextInt(pool.length)];
      _wavesSinceBreather++;
    }
    _queue = chosen;
    _queueIndex = 0;
    _stepTimer = 0;
  }

  void _spawnKind(_SpawnKind kind) {
    switch (kind) {
      case _SpawnKind.rock:
        _spawnRock(isBig: false);
      case _SpawnKind.bigRock:
        _spawnRock(isBig: true);
      case _SpawnKind.monster:
        _spawnMonster();
      case _SpawnKind.floatMonster:
        _spawnMonster(floating: true);
      case _SpawnKind.rockPair:
        _spawnRock(isBig: false, xOffset: 60);
        _spawnRock(isBig: false, xOffset: 150);
      case _SpawnKind.leafBall:
        _spawnCreature(ObstacleKind.leafBall);
      case _SpawnKind.sparrow:
        _spawnCreature(ObstacleKind.sparrow);
      case _SpawnKind.frog:
        _spawnCreature(ObstacleKind.frog);
    }
  }

  void _spawnRock({required bool isBig, double xOffset = 60}) {
    final effectiveStage = isEndless ? _endlessDifficultyStage : stage;
    final smallBase = (60 + (effectiveStage - 1) * 4.5)
        .clamp(60, 96)
        .toDouble();
    final bigBase = (96 + (effectiveStage - 1) * 9).clamp(96, 165).toDouble();
    add(
      ObstacleRock(
        game: this,
        isBig: isBig,
        baseSize: isBig ? bigBase : smallBase,
        speed: 300 * speedMultiplier,
      )..position = Vector2(size.x + xOffset, groundY),
    );
  }

  void _spawnMonster({bool floating = false}) {
    final chosen = emotions[_rand.nextInt(emotions.length)];
    add(
      EmotionMonsterComponent(
        game: this,
        emotion: chosen,
        l10n: l10n,
        name: targetName,
        speed: 275 * speedMultiplier,
        floating: floating,
        metCount: priorMetCounts[chosen.type.name] ?? 0,
      )..position = Vector2(size.x + 60, floating ? groundY - 130 : groundY),
    );
  }

  /// 낙엽뭉치/참새/개구리 - 정적 이미지가 아니라 애니메이션으로 살아
  /// 움직이는 새로운 장애물들. 참새는 머리 높이로 날아드는 "공중" 장애물이라
  /// 점프로만 피할 수 있고, 개구리는 바닥에서 뛰는 "지상" 장애물로 역시
  /// 항상 점프로 피해야 한다. 낙엽뭉치는 작은 돌멩이와 동일하게 주먹으로
  /// 부술 수 있다.
  void _spawnCreature(ObstacleKind kind) {
    final effectiveStage = isEndless ? _endlessDifficultyStage : stage;
    final base = (66 + (effectiveStage - 1) * 4.5).clamp(66, 100).toDouble();
    final isFloating = kind == ObstacleKind.sparrow;
    add(
      AnimatedObstacle(
        game: this,
        kind: kind,
        baseSize: base,
        speed: 275 * speedMultiplier,
      )..position = Vector2(size.x + 60, isFloating ? groundY - 130 : groundY),
    );
  }
}
