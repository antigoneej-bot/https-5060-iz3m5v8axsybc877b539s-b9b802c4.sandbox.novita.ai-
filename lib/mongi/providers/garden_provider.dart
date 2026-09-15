import '../integration/session_transaction.dart';
import '../integration/mongi_garden_store.dart';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../l10n/notification_l10n.dart';
import '../models/daily_mission.dart';
import '../models/emotion.dart';
import '../models/garden_decoration.dart';
import '../models/light_essence_pack.dart';
import '../models/breathing_technique.dart';
import '../models/mind_challenge.dart';
import '../models/mongi_care_item.dart';
import '../models/mongi_cheer.dart';
import '../models/mongi_costume.dart';
import '../models/power_item.dart';
import '../models/season_pass.dart';
import '../models/tree_growth.dart';
import '../services/emotion_evolution_service.dart';
import '../services/emotion_insight_service.dart';
import '../services/gacha_service.dart';
import '../services/garden_storage.dart';
import '../services/mongi_mood_service.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';
import '../services/revive_service.dart';

/// 홈 화면 위젯(GardenWidgetProvider, Android)에 표시할 데이터 키.
/// android/app/src/main/kotlin/.../GardenWidgetProvider.kt 에서 동일한 키로 읽는다.
const String _kWidgetProgressPercent = 'garden_progress_percent';
const String _kWidgetStage = 'garden_stage';
const String _kWidgetStreak = 'garden_streak';

/// 앱 전체(여러 날에 걸친) 정원 회복 진행도를 관리하는 메타 상태.
/// 게임 자체의 실시간 로직(달리기/점프/충돌)은 RunnerGame(Flame)이 담당하고,
/// 이 Provider는 "한 판이 끝난 뒤의 결과"만 저장/반영한다.
class GardenProvider extends ChangeNotifier {
  Future<void>? _initializing;
  Future<void> ensureInitialized() => _initializing ??= init().catchError((Object error) {
    _initializing = null;
    throw error;
  });
  void _sharedChanged() {
    if (!_initialized) return;
    stage = _storage.stage;
    seedCounts = _storage.seedCounts;
    lightEssence = _storage.lightEssence;
    equippedDecorationIds = _storage.equippedDecorations;
    notifyListeners();
  }
  @override
  void dispose() {
    MongiGardenStore.instance.removeListener(_sharedChanged);
    super.dispose();
  }

  final GardenStorage _storage = GardenStorage();

  double progress = 0.0;
  int todayFedCount = 0;
  int streakDays = 0;
  int stage = 1;
  Map<String, int> flowerCounts = {};
  Map<String, int> seedCounts = {};
  List<Map<String, dynamic>> diaryEntries = [];
  int premiumFrameInterestCount = 0;
  bool hasSeenOnboarding = false;
  bool notificationsEnabled = false;
  int notificationHour = 20;
  int notificationMinute = 0;

  /// 사용자가 직접 고른 언어('ko'/'en'). null이면 시스템 언어를 따라간다.
  String? languageCode;
  bool premiumFramesUnlocked = false;
  bool hasBloomedOnce = false;
  List<String> equippedDecorationIds = [];
  bool decorationPackUnlocked = false;
  int score = 0;
  bool hasCheckedInToday = false;
  String? todayCheckInEmotionName;
  int checkInStreak = 0;
  int bestCheckInStreak = 0;
  int bestEndlessCount = 0;
  int bestEndlessSeconds = 0;
  bool hasSeenGrowthMilestone = false;
  bool hasShownWeeklyReportRecently = false;
  bool hasUnreadMongiLetter = false;
  Set<String> goldenFrameEmotions = {};
  int? todayEasterEggIndex;
  Map<String, String> safetyPlan = {};
  List<Map<String, dynamic>> gratitudeEntries = [];

  // ── 몽이의 숨결 도감 (Calm/Headspace 벤치마킹) ─────────────
  /// 오늘 이미 호흡 완료 보상을 받았는지 여부.
  bool hasBreathingRewardToday = false;

  /// 지금까지 끝까지 완료한 누적 호흡 횟수(통계용).
  int breathingLibraryTotalCompletions = 0;

  // ── 몽이의 마음 성찰 / 옵트인 AI 리플렉션 (벤치마킹 제안 #6) ─────────────
  /// "마음 성찰" 기능(여러 기록을 종합한 리플렉션) 사용 동의 여부.
  bool aiReflectionOptIn = false;

  // ── F2P 이중 화폐 시스템 ─────────────────────────
  int lightEssence = 0;
  int starShard = 0;

  // ── 파워 부적(소모품 인벤토리) ─────────────────────────
  /// 지금 보유한 "파워 부적" 개수. 게임 중 언제든 하나를 소비해서 즉시
  /// 10초 무적 모드([RunnerGame.activatePowerMode])를 발동할 수 있다.
  int powerCharmCount = 0;

  // ── 몽이 돌봄 세트(참치캔/사료/맑은물/담요/몽이의 집) ─────────────
  /// 돌봄 아이템 id -> 지금까지 준 누적 횟수. keepsake(담요/몽이의 집)는
  /// 1 이상이면 정원 씬에 영구 배치된다.
  Map<String, int> mongiCareCounts = {};

  /// 가장 최근 [recordSession]/[recordEndlessSession] 호출에서 얻은 빛의 정수
  /// (0이면 이번엔 얻지 못함). 결과 화면에서 "+N 빛의 정수" 팝업을 보여줄 때 참조한다.
  int lastEarnedLightEssence = 0;

  /// 가장 최근 세션에서 신기록으로 얻은 별조각(신기록이 아니면 0).
  int lastEarnedStarShard = 0;

  /// 가장 최근 세션에서 "성장나무 마일스톤"(새싹/나무/꽃/열매 단계 최초 도달)
  /// 보너스로 얻은 빛의 정수. [lastEarnedLightEssence]에도 합산되어 있지만,
  /// 결과 화면에서 "나무가 자라 특별히 더 받았어요"를 따로 강조하고 싶을 때
  /// 이 값을 참조한다(0이면 이번엔 새 단계에 도달하지 않음).
  int lastTreeMilestoneBonusLight = 0;

  // ── "마음 상자" 가챠 (몽이 코스튬) ─────────────────────────
  Set<String> ownedCostumes = {};
  String? equippedCostumeId;
  int gachaTotalPulls = 0;

  // ── 일일 미션 ─────────────────────────
  Map<String, int> dailyMissionProgress = {};
  Set<String> dailyMissionClaimed = {};
  bool dailyMissionAllClearClaimed = false;

  /// 이 미션의 오늘 진행도(target으로 클램프된 값). UI에서 진행 바에 그대로 쓴다.
  int dailyMissionProgressFor(DailyMissionDef mission) =>
      (dailyMissionProgress[mission.id] ?? 0).clamp(0, mission.target);

  /// 이 미션의 목표를 오늘 이미 달성했는지 여부(수령 여부와는 무관).
  bool isDailyMissionAchieved(DailyMissionDef mission) =>
      dailyMissionProgressFor(mission) >= mission.target;

  /// 이 미션이 이미 수령까지 완료됐는지 여부.
  bool isDailyMissionClaimed(DailyMissionDef mission) =>
      dailyMissionClaimed.contains(mission.id);

  /// 지금 수령 가능한(달성했지만 아직 수령 안 한) 미션이 하나라도 있는지 -
  /// 홈 화면 배지에 "받을 것 있어요"를 표시할 때 사용한다.
  bool get hasClaimableDailyMission {
    for (final mission in DailyMission.all) {
      if (isDailyMissionAchieved(mission) && !isDailyMissionClaimed(mission)) {
        return true;
      }
    }
    return _canClaimAllClearBonus;
  }

  /// 오늘 3개 미션을 모두 수령했고, 아직 올클리어 보너스를 받지 않았는지 여부.
  bool get _canClaimAllClearBonus =>
      !dailyMissionAllClearClaimed &&
      DailyMission.all.every((m) => isDailyMissionClaimed(m));

  /// 올클리어 보너스를 지금 수령할 수 있는지 여부(UI에서 버튼 활성화 판단용).
  bool get canClaimDailyMissionAllClearBonus => _canClaimAllClearBonus;

  // ── 마음 챌린지 (Finch "Goal Journeys" 벤치마킹) ─────────────────
  /// 지금 진행 중인 챌린지 id (null이면 없음).
  String? mindChallengeActiveId;

  /// 진행 중인 챌린지를 시작한 날짜(yyyy-MM-dd).
  String? mindChallengeStartDate;

  /// 진행 중인 챌린지에서 체크인을 완료한 날짜 목록.
  Set<String> mindChallengeCheckedDates = {};

  /// 지금까지 완주한 챌린지 id 목록.
  Set<String> mindChallengeCompletedIds = {};

  /// 지금 진행 중인 챌린지의 정의(없으면 null).
  MindChallengeDef? get activeMindChallenge => mindChallengeActiveId == null
      ? null
      : MindChallenge.byId(mindChallengeActiveId!);

  /// 진행 중인 챌린지에서 완료한 날짜 수(= 며칠째 진행했는지). 챌린지가
  /// 없으면 0.
  int get mindChallengeDaysDone => mindChallengeCheckedDates.length;

  /// 오늘 이미 진행 중인 챌린지의 체크인을 완료했는지 여부(홈 배너 표시용).
  bool get hasCheckedInMindChallengeToday {
    if (mindChallengeActiveId == null) return false;
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return mindChallengeCheckedDates.contains(today);
  }

  /// 진행 중인 챌린지의 모든 날짜를 채웠지만 아직 완주 처리(보너스 수령)를
  /// 하지 않은 상태인지 여부 - true면 화면에서 완주 축하 + 수령 버튼을 보여준다.
  bool get canCompleteMindChallenge {
    final def = activeMindChallenge;
    if (def == null) return false;
    return mindChallengeDaysDone >= def.durationDays;
  }

  /// [challengeId] 챌린지를 새로 시작한다. 이미 다른 챌린지가 진행 중이면
  /// 그 챌린지는 중도 포기 처리되고 새 챌린지로 교체된다.
  Future<void> startMindChallenge(String challengeId) async {
    await _storage.startMindChallenge(challengeId);
    mindChallengeActiveId = _storage.mindChallengeActiveId;
    mindChallengeStartDate = _storage.mindChallengeStartDate;
    mindChallengeCheckedDates = _storage.mindChallengeCheckedDates;
    notifyListeners();
  }

  /// 진행 중인 챌린지를 중도에 그만둔다.
  Future<void> abandonMindChallenge() async {
    await _storage.abandonMindChallenge();
    mindChallengeActiveId = null;
    mindChallengeStartDate = null;
    mindChallengeCheckedDates = {};
    notifyListeners();
  }

  /// [recordDailyCheckIn]에서 오늘의 감정 체크인이 처음 기록될 때 함께
  /// 호출되어, 진행 중인 챌린지가 있으면 오늘 날짜를 진행도에 더한다.
  /// 새로운 행동을 요구하지 않고 기존 "오늘의 감정 체크인" 지표를 그대로
  /// 재사용한다.
  Future<void> _markMindChallengeDayFromCheckIn() async {
    if (mindChallengeActiveId == null) return;
    await _storage.markMindChallengeDayDone();
    mindChallengeCheckedDates = _storage.mindChallengeCheckedDates;
    final def = activeMindChallenge;
    if (def != null && def.rewardLightEssencePerDay > 0) {
      await _storage.addLightEssence(def.rewardLightEssencePerDay);
      lightEssence = _storage.lightEssence;
    }
  }

  /// 진행 중인 챌린지의 모든 날짜를 채운 뒤, 완주 보너스를 수령하고 완주
  /// 목록에 추가한다. 아직 모든 날짜를 채우지 못했으면 false를 반환한다.
  Future<bool> claimMindChallengeCompletion() async {
    if (!canCompleteMindChallenge) return false;
    final def = activeMindChallenge;
    if (def == null) return false;
    await _storage.completeMindChallenge(def.id);
    mindChallengeCompletedIds = _storage.mindChallengeCompletedIds;
    mindChallengeActiveId = null;
    mindChallengeStartDate = null;
    mindChallengeCheckedDates = {};
    if (def.completionBonusLightEssence > 0) {
      await _storage.addLightEssence(def.completionBonusLightEssence);
      lightEssence = _storage.lightEssence;
    }
    if (def.completionBonusStarShard > 0) {
      await _storage.addStarShard(def.completionBonusStarShard);
      starShard = _storage.starShard;
    }
    notifyListeners();
    return true;
  }

  // ── 몽이의 응원 우편함 (Finch "Good Vibes" 벤치마킹) ─────────────
  /// 오늘 이미 응원을 "보냈는지" 여부.
  bool hasSentCheerToday = false;

  /// 오늘 이미 응원을 "받았는지" 여부.
  bool hasReceivedCheerToday = false;

  /// 오늘 받은 응원 문구 인덱스(오늘 아직 받지 않았으면 null). 실제 문구는
  /// 화면에서 [MongiCheer.receiveMessageCount] 범위의 인덱스를
  /// AppLocalizations로 변환해 사용한다.
  int? todayCheerReceivedIndex;

  /// 지금까지 응원을 보낸 총 횟수(통계용).
  int cheerSentTotalCount = 0;

  /// 오늘의 응원을 "보낸다"(실제 수신자 없이 몽이에게 마음을 맡기는 제스처).
  /// 이미 오늘 보냈으면 아무 것도 하지 않고 false를 반환한다. [optionIndex]는
  /// 유저가 고른 응원 문구의 인덱스로, 지금은 통계용으로만 쓰이며 저장하지는
  /// 않는다(어떤 문구를 골랐는지와 무관하게 "오늘 보냈다"만 기록한다).
  Future<bool> sendCheer(int optionIndex) async {
    if (hasSentCheerToday) return false;
    await _storage.markCheerSentToday();
    hasSentCheerToday = _storage.hasSentCheerToday;
    cheerSentTotalCount = _storage.cheerSentTotalCount;
    if (MongiCheer.sendRewardLightEssence > 0) {
      await _storage.addLightEssence(MongiCheer.sendRewardLightEssence);
      lightEssence = _storage.lightEssence;
    }
    notifyListeners();
    return true;
  }

  /// 오늘의 응원 문구를 "받는다". 이미 오늘 받았다면 저장된 인덱스를 그대로
  /// 돌려주고(중복 보상 없음), 아직이면 새로 랜덤 추첨해서 저장하고 보상을
  /// 지급한다.
  Future<int> ensureTodayCheerReceived() async {
    if (todayCheerReceivedIndex != null) return todayCheerReceivedIndex!;
    final stored = _storage.todayCheerReceivedIndex;
    if (stored != null) {
      todayCheerReceivedIndex = stored;
      hasReceivedCheerToday = true;
      notifyListeners();
      return stored;
    }
    final index = MongiCheer.randomReceiveIndex();
    await _storage.saveTodayCheerReceivedIndex(index);
    todayCheerReceivedIndex = index;
    hasReceivedCheerToday = true;
    if (MongiCheer.receiveRewardLightEssence > 0) {
      await _storage.addLightEssence(MongiCheer.receiveRewardLightEssence);
      lightEssence = _storage.lightEssence;
    }
    notifyListeners();
    return index;
  }

  // ── 시즌 패스("몽이의 마음여정") ─────────────────────────
  int seasonNumber = 1;
  int seasonSecondsRemaining = 0;
  int seasonXp = 0;
  bool seasonPremiumPurchased = false;
  Set<int> seasonClaimedFreeLevels = {};
  Set<int> seasonClaimedPremiumLevels = {};

  /// "1번 개선": 방금 [_addSeasonXp] 호출로 "마음 마일스톤"(5의 배수 레벨)에
  /// 새로 도달했다면 그 격려 문구가 담긴다(여러 레벨을 한 번에 건너뛰었다면
  /// 가장 높은 레벨의 문구). 도달하지 않았으면 null. 결과 화면/체크인 시트/
  /// 감사기록 화면에서 한 번 읽은 뒤 각자 소비하면 된다.
  ///
  /// 다국어 지원: 이 필드는 여전히 고정 한국어 문구를 담고 있어(아직 옮기지
  /// 않은 화면과의 호환용) 그대로 남겨두고, 대신 [lastSeasonMilestoneLevel]에
  /// "어떤 레벨에 도달했는지"만 함께 저장한다. 다국어 화면은 이 레벨 값을
  /// [seasonMilestoneText]([AppLocalizations]) 헬퍼에 넘겨 문구를 완성한다.
  String? lastSeasonMilestoneMessage;

  /// [lastSeasonMilestoneMessage]와 동일한 시점에 함께 채워지는 마일스톤
  /// 레벨(5/10/15/20). 도달하지 않았으면 null.
  int? lastSeasonMilestoneLevel;

  /// 지금 시즌 경험치로 도달한 레벨(0~[SeasonPass.maxLevel]).
  int get seasonLevel => SeasonPass.levelForXp(seasonXp);

  /// 지금 레벨 안에서 진행 중인 경험치(다음 레벨까지 필요한 것 대비).
  int get seasonXpIntoLevel => SeasonPass.xpIntoCurrentLevel(seasonXp);

  /// 다음 레벨업까지 필요한 경험치 칸 전체 크기(이미 최고 레벨이면 0).
  int get seasonXpSpanForLevel => SeasonPass.xpForNextLevelSpan(seasonXp);

  /// 지금 수령할 수 있는(레벨을 이미 넘었고 아직 수령 안 한) 무료/프리미엄
  /// 보상이 하나라도 있는지 여부 - 홈 화면 배지에 "받을 것 있어요" 표시용.
  bool get hasClaimableSeasonReward {
    for (var level = 1; level <= seasonLevel; level++) {
      if (!seasonClaimedFreeLevels.contains(level)) return true;
      if (seasonPremiumPurchased &&
          !seasonClaimedPremiumLevels.contains(level)) {
        return true;
      }
    }
    return false;
  }

  /// 방금 [recordSession]/[recordEndlessSession] 호출에서 새로 "황금 프레임"을
  /// 획득했다면 그 감정을 담는다 (결과 화면에서 축하 팝업을 보여주기 위함).
  Emotion? lastGoldenFrameUnlocked;

  /// 6번: 방금 세션으로 어떤 감정이 처음으로 "초월"(100번째 마주침, 히든
  /// 4단계) 상태가 됐다면 그 감정을 담는다. 황금 프레임과 달리 확률이 아니라
  /// 100% 확정으로 도달하는 마일스톤이지만, 도감 어디에도 카운트다운을
  /// 보여주지 않았기 때문에 유저 입장에서는 "어? 갑자기?" 하고 발견하게
  /// 되는 히든 이벤트다. 세션마다 결과 화면에서 한 번만 보여주면 되므로
  /// 배열이 아니라 단일 값(가장 먼저 발견된 하나)으로 충분하다.
  Emotion? lastTranscendedEmotion;

  /// 가장 최근 [recordSession] 호출에서 얻은 점수 (0이면 이번엔 점수를 얻지 못함).
  /// 결과 화면에서 "+N점" 팝업을 보여줄 때 참조한다.
  int lastEarnedScore = 0;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// 지금 점수로 자라난 "몽이의 성장나무" 단계 인덱스 (-1=아직 씨앗, 0=새싹...3=열매).
  int get treeStageIndex => TreeGrowth.stageIndexForScore(score);

  /// 다음 나무 성장 단계까지 남은 점수 (이미 열매 단계면 0).
  int get pointsToNextTreeStage => TreeGrowth.pointsToNextStage(score);

  /// 몽이의 성장나무가 지금 살짝 시들어 보이는 상태인지 여부.
  /// 정원을 이틀 이상 찾아오지 않았을 때만 true가 되고, 오늘 한 번만 다시
  /// 감정을 먹이면(recordSession 호출) 곧바로 원래대로 돌아온다 - 절대
  /// 처벌적으로 느껴지지 않는, 부드러운 "그리움" 표현을 위한 상태다.
  bool get isTreeWilted => _storage.isTreeWilted;

  /// 마지막으로 정원에 감정을 먹인 날로부터 오늘까지 며칠이 지났는지.
  /// "복귀 케어" 문구가 며칠 만에 돌아왔는지 자연스럽게 알려주는 데 쓰인다.
  int get daysSinceLastFeed => _storage.daysSinceLastFeed;

  /// 지금까지 정원에 심어진 꽃의 총 개수 (모든 감정 타입 합산).
  int get totalFlowersPlanted =>
      flowerCounts.values.fold(0, (sum, count) => sum + count);

  /// 몽이의 성장나무가 가장 마지막 단계(열매)까지 다 자랐는지 여부.
  /// "성장 마일스톤 회고" 엔딩 화면을 보여줄 수 있는 상태인지 판단하는 데 쓰인다.
  bool get isTreeFullyGrown => treeStageIndex >= TreeGrowth.maxStageIndex;

  /// 지금 스테이지에서 만날 수 있는(잠금 해제된) 감정 목록. 1스테이지당 1개씩 열린다.
  List<Emotion> get unlockedEmotions =>
      Emotion.all.take(stage.clamp(1, Emotion.all.length)).toList();

  /// 해당 감정이 이미 열렸는지 여부.
  bool isEmotionUnlocked(Emotion emotion) =>
      Emotion.all.indexOf(emotion) < stage;

  /// 해당 장식 아이템을 지금 사용할 수 있는(=꾸미기에서 고를 수 있는) 상태인지 여부.
  /// - 프리미엄 아이템: 정원 장식팩 구매 여부로 판단
  /// - 무료 아이템: 각자의 마일스톤 달성 여부로 판단
  bool isDecorationUnlocked(GardenDecoration decoration) {
    if (MongiGardenStore.instance.value.owned.contains(decoration.id)) return true;
    if (decoration.isPremium) return decorationPackUnlocked;
    switch (decoration.id) {
      case 'bench':
        return streakDays >= 3;
      case 'path':
        return hasBloomedOnce;
      case 'fountain':
        const requiredSeeds = ['forgiveness', 'love', 'peace'];
        return requiredSeeds.every((id) => (seedCounts[id] ?? 0) > 0);
      case 'wind_chime':
        return streakDays >= 7;
      case 'butterfly_garden':
        final masteredCount = Emotion.all.where((e) => isMastered(e)).length;
        return masteredCount >= 3;
      case 'jangdokdae':
        return totalFlowersPlanted >= 10;
      case 'ginkgo_path':
        return streakDays >= 14;
      default:
        return false;
    }
  }

  bool isDecorationEquipped(GardenDecoration decoration) =>
      equippedDecorationIds.contains(decoration.id);

  // ── "마음 상자" 가챠 (몽이 코스튬) ─────────────────────────

  /// 지금 몽이에게 씌워져 있는 코스튬 (없으면 null - 기본 모습).
  MongiCostume? get equippedCostume =>
      equippedCostumeId == null ? null : MongiCostume.byId(equippedCostumeId!);

  bool hasCostume(MongiCostume costume) => ownedCostumes.contains(costume.id);

  /// 가챠 풀에 있는 코스튬을 전부 모았는지 여부 - "이제 열어도 나올 새 선물이
  /// 없다"는 상태를 UI에서 안내할 때 사용한다.
  bool get hasCollectedAllCostumes =>
      MongiCostume.gachaPool.every((c) => ownedCostumes.contains(c.id));

  /// 아직 보유하지 않은 가챠 풀 코스튬 개수 - 도감 진행률 표시용.
  int get remainingGachaCostumeCount =>
      MongiCostume.gachaPool.where((c) => !ownedCostumes.contains(c.id)).length;

  // ── 감정 도감 레어도 시스템 ("황금 프레임") ─────────────────────────

  /// 이 감정이 몇 번째 진화 단계인지(0/1/2), [flowerCounts]의 누적 횟수를 그대로 사용한다.
  int evolutionStageOf(Emotion emotion) =>
      EmotionEvolutionService.stageIndexForCount(
        flowerCounts[emotion.type.name] ?? 0,
      );

  /// 이 감정이 "마스터"(50번 이상) 단계에 도달했는지 여부.
  bool isMastered(Emotion emotion) =>
      EmotionEvolutionService.isMastered(flowerCounts[emotion.type.name] ?? 0);

  /// 이 감정에 대해 이미 황금 프레임을 획득했는지 여부.
  bool hasGoldenFrame(Emotion emotion) =>
      goldenFrameEmotions.contains(emotion.type.name);

  /// 6번: 이 감정이 히든 4단계("초월", 100번 이상)에 도달했는지 여부.
  bool isTranscended(Emotion emotion) => EmotionEvolutionService.isTranscended(
    flowerCounts[emotion.type.name] ?? 0,
  );

  /// 감정을 하나 이상 마주한 뒤(정원에 꽃이 심어진 뒤), 마스터 등급인
  /// 감정들에 한해 극히 낮은 확률(5%)로 "황금 프레임"을 하나 추첨한다.
  /// 이미 그 감정의 황금 프레임을 가지고 있으면 대상에서 제외한다.
  /// 새로 획득한 감정이 있으면 [lastGoldenFrameUnlocked]에 기록하고 반환한다.
  Future<Emotion?> _maybeAwardGoldenFrame(
    Map<EmotionType, int> eatenByType,
  ) async {
    lastGoldenFrameUnlocked = null;
    const chance = 0.05;
    final rand = Random();
    for (final type in eatenByType.keys) {
      final emotion = Emotion.byTypeName(type.name);
      final count = flowerCounts[type.name] ?? 0;
      if (!EmotionEvolutionService.isMastered(count)) continue;
      if (goldenFrameEmotions.contains(type.name)) continue;
      if (rand.nextDouble() <= chance) {
        await _storage.unlockGoldenFrame(type.name);
        goldenFrameEmotions = _storage.goldenFrameEmotions;
        lastGoldenFrameUnlocked = emotion;
        return emotion;
      }
    }
    return null;
  }

  /// 6번: 이번 세션으로 실제 정원에 심어진(=이미 [flowerCounts]가 갱신된)
  /// 감정들 중, 100번째 마주침(히든 4단계 "초월")을 이번에 처음 넘긴 감정이
  /// 있는지 확인한다. 황금 프레임과 달리 확률이 아니라 100% 확정 마일스톤이므로
  /// - "우연히 걸렸는지"가 아니라 "이번 세션에 그 문턱을 실제로 넘었는지"만
  /// 판정한다. 이미 한 번 축하해준 감정은 [GardenStorage.transcendedEmotions]에
  /// 남아있으므로 두 번째부터는 조용히 넘어간다.
  Future<Emotion?> _maybeDetectTranscendence(
    Map<EmotionType, int> eatenByType,
  ) async {
    lastTranscendedEmotion = null;
    for (final type in eatenByType.keys) {
      final count = flowerCounts[type.name] ?? 0;
      if (!EmotionEvolutionService.isTranscended(count)) continue;
      if (_storage.hasCelebratedTranscendence(type.name)) continue;
      await _storage.markTranscendenceCelebrated(type.name);
      lastTranscendedEmotion = Emotion.byTypeName(type.name);
      return lastTranscendedEmotion;
    }
    return null;
  }

  /// 이번 세션으로 [score]가 갱신된 뒤 호출한다. 아직 보상을 받지 않은
  /// 성장나무 단계(새싹/나무/꽃/열매)에 새로 도달했다면, 그 사이 모든 단계의
  /// 마일스톤 보너스(빛의 정수)를 한 번에 지급한다 - 처벌형이 아니라
  /// "자랄수록 더 큰 보상을 준다"는 보상 차등형 설계.
  /// (연속으로 여러 판을 오래 안 하다가 한 번에 몰아서 크게 올랐을 경우에도
  /// 놓친 단계 보상이 누락되지 않도록 범위 전체를 채워준다.)
  Future<void> _maybeAwardTreeMilestone() async {
    lastTreeMilestoneBonusLight = 0;
    final claimed = _storage.treeMilestoneClaimedStage;
    final current = treeStageIndex;
    if (current <= claimed) return;
    int bonus = 0;
    for (var i = claimed + 1; i <= current; i++) {
      bonus += TreeGrowth.stageMilestoneLightEssence[i];
    }
    await _storage.markTreeMilestoneClaimed(current);
    if (bonus > 0) {
      await _storage.addLightEssence(bonus);
      lightEssence = _storage.lightEssence;
      lastTreeMilestoneBonusLight = bonus;
    }
  }

  // ── 몽이의 하루 (다마고치) ─────────────────────────

  /// 최근 3일간의 [diaryEntries]를 바탕으로 오늘 몽이의 표정/기분 종류를 계산한다.
  MongiMoodResult get todayMood =>
      MongiMoodService.computeMood(diaryEntries: diaryEntries);

  /// 오늘의 이스터에그 대사 인덱스를 준비한다. 이미 오늘 뽑았다면 저장된
  /// 인덱스를 그대로 쓰고, 아직이면 새로 랜덤 추첨해서 저장한다. 실제
  /// 문구로 바꾸는 건 화면 쪽에서 AppLocalizations로 처리한다.
  Future<int> ensureTodayEasterEgg() async {
    if (todayEasterEggIndex != null) return todayEasterEggIndex!;
    final stored = _storage.todayEasterEggIndex;
    if (stored != null) {
      todayEasterEggIndex = stored;
      notifyListeners();
      return stored;
    }
    final index = MongiMoodService.randomEasterEggIndex();
    await _storage.saveTodayEasterEggIndex(index);
    todayEasterEggIndex = index;
    notifyListeners();
    return index;
  }

  /// 지금 유저 상태(스트릭/컬렉션/성장나무 근접도)를 바탕으로 오늘 알림에
  /// 넣을 개인화 문구를 계산한다. 해당하는 게 없으면 null(호출부에서 기존
  /// 고정 문구 중 하나를 랜덤으로 대신 쓴다).
  String? get _personalizedReminderMessage =>
      EmotionInsightService.buildPersonalizedReminder(
        diaryEntries: diaryEntries,
        streakDays: streakDays,
        pointsToNextTreeStage: pointsToNextTreeStage,
      );

  // 잠긴 무료 아이템의 "지금 얼마나 진행됐는지" 다국어 문구는 이 Provider가
  // 아니라 UI 계층의 decorationProgressLabel 헬퍼(l10n/garden_decoration_l10n.dart)
  // 에서 조립한다 - 이 헬퍼는 streakDays/progress/seedCounts와
  // isDecorationUnlocked(decoration)을 그대로 사용한다.

  /// [notificationContent]는 [BuildContext]를 가진 호출부(main.dart 부트스트랩)
  /// 에서 `notificationContent(AppLocalizations.of(context))`로 만들어
  /// 넘겨주는 지역화된 알림 콘텐츠. 이 Provider 자체는 [BuildContext]가 없는
  /// [ChangeNotifier]이므로 직접 만들 수 없어 호출부에서 주입받는다. 넘기지
  /// 않으면 [NotificationService]의 한국어 기본값이 그대로 쓰인다(하위 호환).
  Future<void> init({NotificationContent? notificationContent}) async {
    await _storage.init();
    await _storage.refreshDailyMissionsIfNeeded();
    _loadFromStorage();
    _initialized = true;
    MongiGardenStore.instance.removeListener(_sharedChanged);
    MongiGardenStore.instance.addListener(_sharedChanged);
    notifyListeners();
    await _syncHomeWidget();
    // 이전에 알림을 켜둔 상태라면, 앱을 새로 시작할 때마다 예약을 다시 걸어준다.
    // (기기 재부팅 등으로 예약이 풀렸을 가능성에 대비 + 매번 새 문구로 갱신)
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleDaily(
        notificationHour,
        notificationMinute,
        personalizedMessage: _personalizedReminderMessage,
        content: notificationContent,
      );
    }
    // 인앱 결제 스트림을 구독해서, 구매/복원이 확인되면 즉시 잠금을 해제한다.
    PurchaseService.instance.registerProduct(kPremiumFramesProductId, () {
      if (!premiumFramesUnlocked) {
        _storage.setPremiumFramesUnlocked(true);
        premiumFramesUnlocked = true;
        notifyListeners();
      }
    });
    PurchaseService.instance.registerProduct(
      kGardenDecorationPackProductId,
      () {
        if (!decorationPackUnlocked) {
          _storage.setDecorationPackUnlocked(true);
          decorationPackUnlocked = true;
          notifyListeners();
        }
      },
    );
    PurchaseService.instance.registerProduct(kSeasonPassProductId, () {
      _grantSeasonPassPremium();
    });
    // 빛의 정수 충전팩(소모성) - 구매가 확인될 때마다 팩 수량만큼 즉시 지급한다.
    for (final pack in LightEssencePack.all) {
      PurchaseService.instance.registerProduct(pack.productId, () {
        _grantLightEssencePack(pack);
      });
    }
    await PurchaseService.instance.init();
  }

  Future<void> _grantLightEssencePack(LightEssencePack pack) async {
    await _storage.addLightEssence(pack.amount);
    lightEssence = _storage.lightEssence;
    notifyListeners();
  }

  /// 처음 실행 시 튜토리얼을 다 보여줬을 때(또는 건너뛰었을 때) 호출한다.
  Future<void> markOnboardingSeen() async {
    await _storage.markOnboardingSeen();
    hasSeenOnboarding = true;
    notifyListeners();
  }

  /// 홈 화면에 처음 들어왔을 때 "오늘 기분은 어때?" 질문에 답했을 때 호출.
  /// (Finch식 감정 체크인 데일리 루틴 - 현실의 감정을 게임 속 캐릭터화의 출발점으로 삼는다)
  /// 이미 오늘 체크인했다면 아무 것도 하지 않고 조용히 반환한다.
  Future<void> recordDailyCheckIn(EmotionType type) async {
    if (hasCheckedInToday) return;
    final newStreak = await _storage.recordDailyCheckIn(type.name);
    hasCheckedInToday = true;
    todayCheckInEmotionName = type.name;
    checkInStreak = newStreak;
    bestCheckInStreak = _storage.bestCheckInStreak;
    // 매일 첫 체크인마다 시즌 경험치를 소량 지급해, 하루에 한 번은 반드시
    // 시즌 패스가 앞으로 나아가도록 한다(습관 리텐션과 시즌 진행을 연결).
    await _addSeasonXp(12);
    // 진행 중인 "마음 챌린지"가 있다면, 오늘의 체크인을 그대로 챌린지
    // 진행도로도 반영한다(새로운 강제 행동 없이 기존 체크인 지표 재사용).
    await _markMindChallengeDayFromCheckIn();
    notifyListeners();
  }

  /// 엔드리스 모드(무한의 계단식 "오늘 내 최고기록" 모드) 한 판이 끝난 뒤 호출.
  /// [eatenByType]: 이번 판에서 감정 타입별로 먹은 개수 - 그대로 정원에 꽃이 심어진다.
  /// [survivedSeconds]: 이번 판에서 살아남은 시간(초).
  /// 반환값: 이번 판이 새 최고기록을 세웠는지 여부.
  ///
  /// ⚠️ 설계 원칙: 무한도전은 "그냥 재미로" 즐기는 모드다. 점수/빛의 정수/
  /// 별조각/시즌 경험치/일일 미션 진행도/나무 마일스톤/황금 프레임/6번
  /// 히든 초월 축하 같은 모든 "적립·보상" 요소는 스테이지(본 게임) 모드에만
  /// 있으며, 여기서는 절대 지급하지 않는다. 다만 "감정을 먹으면 정원에 꽃이
  /// 핀다"는 앱의 핵심 테마([_storage.plantFlower])와, 재미를 위한 순수
  /// "오늘 내 최고기록" 갱신만은 그대로 유지한다. (참고: [flowerCounts]는
  /// 여기서도 갱신되므로 도감 진화 자체는 계속 정상적으로 진행되고, 다음
  /// 스테이지 세션에서 문턱을 넘으면 그때 축하 팝업이 뜬다 - "몰래 채워지다
  /// 어느 날 발견"이라는 히든 요소의 취지와도 자연스럽게 맞는다.)
  Future<bool> recordEndlessSession(Map<EmotionType, int> eatenByType, {
    required int survivedSeconds, String? sessionId,
  }) async {
    final result = await MongiGardenStore.instance.commitSession(
      sessionId ?? SessionTransaction.newId(), () async {
        _loadFromStorage();
        final isNew = await _recordEndlessDraft(eatenByType, survivedSeconds: survivedSeconds);
        return {'isNew': isNew};
      });
    _loadFromStorage();
    lastEarnedScore = 0; lastEarnedLightEssence = 0; lastEarnedStarShard = 0;
    notifyListeners(); await _syncHomeWidget();
    return result['isNew'] as bool;
  }

  Future<bool> _recordEndlessDraft(
    Map<EmotionType, int> eatenByType, {
    required int survivedSeconds,
  }) async {
    final totalEaten = eatenByType.values.fold(0, (sum, c) => sum + c);
    for (final entry in eatenByType.entries) {
      await _storage.plantFlower(entry.key.name, entry.value);
    }
    flowerCounts = _storage.flowerCounts;
    // 이번 판에서는 어떤 보상도 지급하지 않으므로, 결과 화면에 옛 값이
    // 남아 잘못 표시되지 않도록 관련 필드를 모두 0/null로 초기화한다.
    lastEarnedScore = 0;
    lastEarnedLightEssence = 0;
    lastEarnedStarShard = 0;
    lastTreeMilestoneBonusLight = 0;
    lastGoldenFrameUnlocked = null;
    lastTranscendedEmotion = null;
    final isNewRecord = await _storage.recordEndlessResult(
      eatenCount: totalEaten,
      survivedSeconds: survivedSeconds,
    );
    bestEndlessCount = _storage.bestEndlessCount;
    bestEndlessSeconds = _storage.bestEndlessSeconds;
    notifyListeners();
    await _syncHomeWidget();
    return isNewRecord;
  }

  /// 3번(벤치마킹 제안: "고요 모드/활동 모드" 이원화) - 러너 게임을 전혀
  /// 거치지 않고, 감정을 고르는 것만으로 곧바로 "마음에 심는" 저자극 흐름.
  ///
  /// ⚠️ 설계 원칙: 고요 모드는 엔드리스 모드보다도 더 철저하게 "게임화/수익화
  /// 요소와 분리된 순수 웰니스 기능"이어야 한다(5번 우선순위와 직결). 점수/
  /// 빛의 정수/별조각/시즌 경험치/일일 미션/트리 마일스톤 등 어떤 보상도
  /// 지급하지 않고, 오직 "감정마다 정원에 꽃이 핀다"는 핵심 테마([_storage.
  /// plantFlower])와 선택적 다이어리 기록만 수행한다. 되풀이해서 눌러도
  /// 아무 이득이 없으므로, "빨리 여러 번 돌리기" 유인이 원천적으로 없다.
  Future<void> recordQuietSession(
    List<EmotionType> emotionTypes, {
    String? targetName, String? note, int? intensity, String? sessionId,
  }) async {
    if (emotionTypes.isEmpty) return;
    await MongiGardenStore.instance.commitSession(
      sessionId ?? SessionTransaction.newId(), () async {
        for (final type in emotionTypes) { await _storage.plantFlower(type.name, 1); }
        await _storage.addDiaryEntry(emotionTypeName: emotionTypes.first.name,
          targetName: targetName, eatenCount: emotionTypes.length, note: note, intensity: intensity);
        await MongiGardenStore.instance.claimCompletedCare();
        return {'quiet': true};
      });
    _loadFromStorage();
    notifyListeners();
    await _syncHomeWidget();
  }

  /// 러너 게임 한 판이 끝난 뒤 호출.
  /// [eatenByType]: 이번 판에서 감정 타입별로 먹은 감정 몬스터 수 (여러 감정을 동시에
  /// 골랐을 경우 타입별로 나뉘어 들어온다) - 그만큼 정원에 해당 꽃이 각각 심어진다
  /// [choseLove]: 마지막 선택 화면에서 "마음을 심을래요"를 선택했는지 여부 (선택 시 보너스 회복)
  /// [seedType]: 선택 시 구체적으로 고른 씨앗 종류 id (용서/사랑/평안 등) - 고르지 않았으면 null.
  /// [earlyStop]: 목숨을 다 써서 목표를 다 채우지 못하고 마친 경우 true.
  /// [target]: 이번 판의 감정 목표 개수(스테이지별로 6/10/20/30... 다르다) - 정원
  /// 진행도 계산과 "목표를 다 채웠는지" 완료 보너스 판정에 사용된다.
  ///
  /// 점수 규칙: 감정 하나를 먹을 때마다 2점 + 스테이지 목표를 끝까지 다 채우면
  /// (earlyStop이 아니고, 먹은 개수가 목표 이상이면) 완료 보너스 (10 + 스테이지*5)점을
  /// 추가로 얻는다. 이 점수가 쌓여서 몽이의 성장나무([TreeGrowth])가 자라난다.
  ///
  /// 빛의 정수(소프트 화폐) 규칙: 엔드리스 모드와 동일하게 감정 하나당 1개씩,
  /// 목표를 끝까지 채우면 완료 보너스를 더 얹어준다. 스테이지 모드는 매번
  /// 확실히 끝이 나는 구조라, 엔드리스보다 완료 보너스 비중을 더 크게 둬서
  /// "끝까지 깨는 재미"를 강화한다(처벌이 아니라 보상 차등).
  @override
  void notifyListeners() {
    if (SessionTransaction.draft == null) super.notifyListeners();
  }

  Future<bool> recordSession(Map<EmotionType, int> eatenByType, {
    required bool choseLove, String? seedType, bool earlyStop = false,
    int? target, int? playedStage, String? sessionId,
  }) async {
    try {
      final result = await MongiGardenStore.instance.commitSession(
        sessionId ?? SessionTransaction.newId(), () async {
          _loadFromStorage();
          final bloomed = await _recordSessionDraft(eatenByType,
            choseLove: choseLove, seedType: seedType, earlyStop: earlyStop,
            target: target, playedStage: playedStage);
          return {'bloomed': bloomed, 'score': lastEarnedScore,
            'light': lastEarnedLightEssence, 'treeBonus': lastTreeMilestoneBonusLight,
            'golden': lastGoldenFrameUnlocked?.type.name,
            'transcended': lastTranscendedEmotion?.type.name,
            'season': lastSeasonMilestoneLevel};
        });
      _loadFromStorage();
      lastEarnedScore = result['score'] as int;
      lastEarnedLightEssence = result['light'] as int;
      lastTreeMilestoneBonusLight = result['treeBonus'] as int;
      lastGoldenFrameUnlocked = result['golden'] == null ? null : Emotion.byTypeName(result['golden'] as String);
      lastTranscendedEmotion = result['transcended'] == null ? null : Emotion.byTypeName(result['transcended'] as String);
      lastSeasonMilestoneLevel = result['season'] as int?;
      notifyListeners();
      await _syncHomeWidget();
      return result['bloomed'] as bool;
    } catch (_) {
      _loadFromStorage();
      rethrow;
    }
  }

  Future<bool> _recordSessionDraft(
    Map<EmotionType, int> eatenByType, {
    required bool choseLove,
    String? seedType,
    bool earlyStop = false,
    int? target,
    int? playedStage,
  }) async {
    final rewardStage = (playedStage ?? stage).clamp(1, 1 << 30);
    final beforeProgress = progress;
    final totalEaten = eatenByType.values.fold(0, (sum, c) => sum + c);
    final safeTarget = (target != null && target > 0)
        ? target
        : totalEaten.clamp(1, 1 << 30);
    await _storage.recordEaten(
      totalEaten,
      bonus: choseLove ? 0.1 : 0.0,
      target: safeTarget,
    );
    for (final entry in eatenByType.entries) {
      await _storage.plantFlower(entry.key.name, entry.value);
    }
    progress = _storage.progress;
    todayFedCount = _storage.todayFedCount;
    streakDays = _storage.streakDays;
    flowerCounts = _storage.flowerCounts;
    await _maybeAwardGoldenFrame(eatenByType);
    await _maybeDetectTranscendence(eatenByType);
    final justBloomed = beforeProgress < 1.0 && progress >= 1.0;
    if (justBloomed && !hasBloomedOnce) {
      await _storage.markBloomedOnce();
      hasBloomedOnce = true;
    }
    if (seedType != null) {
      await _storage.plantSeed(seedType);
      seedCounts = _storage.seedCounts;
    }
    // 스테이지 완료 점수 부여: 감정을 먹을 때마다 2점 + 목표를 끝까지 채우면 완료 보너스.
    final fullyCompleted = !earlyStop && totalEaten >= safeTarget;
    final earnedScore = totalEaten * 2 + (fullyCompleted ? 10 + rewardStage * 5 : 0);
    lastEarnedScore = earnedScore;
    if (earnedScore > 0) {
      await _storage.addScore(earnedScore);
      score = _storage.score;
    }
    // ── 빛의 정수(소프트 화폐) 지급: 먹은 감정 하나당 1개 + 목표를 끝까지
    // 채우면 완료 보너스(3 + 스테이지). 스테이지 모드에도 재화 획득 경로를
    // 열어줘서, 가챠/기력 충전을 위한 재화가 엔드리스 모드에만 몰리지 않게 한다.
    final earnedLight = totalEaten + (fullyCompleted ? 3 + rewardStage : 0);
    lastEarnedLightEssence = earnedLight;
    if (earnedLight > 0) {
      await _storage.addLightEssence(earnedLight);
      lightEssence = _storage.lightEssence;
    }
    // ── 성장나무 마일스톤: 이번 판으로 score가 올라 나무가 새 단계(새싹/나무/
    // 꽃/열매)에 처음 도달했다면, 그 사이 모든 단계 보너스를 한 번에 지급한다.
    // score가 이미 갱신된 뒤(addScore 이후)에 호출해야 treeStageIndex가
    // 최신 점수를 기준으로 계산된다.
    await _maybeAwardTreeMilestone();
    // ── 일일 미션: "감정 몬스터 먹기" + "스테이지 완료" + "마음 심기" 진행도를
    // 이번 판 결과에 맞춰 자연스럽게 채운다(새로운 강제 행동 없이 기존 플레이
    // 지표를 그대로 반영하는 방식).
    await _addDailyMissionProgress(DailyMissionType.emotionsEaten, totalEaten);
    if (fullyCompleted) {
      await _addDailyMissionProgress(DailyMissionType.stageCompleted, 1);
    }
    if (choseLove) {
      await _addDailyMissionProgress(DailyMissionType.plantedLove, 1);
    }
    // ── 시즌 경험치: 먹은 감정 하나당 3xp, 스테이지 목표를 완료하면 보너스 10xp.
    await _addSeasonXp(totalEaten * 3 + (fullyCompleted ? 10 : 0));
    notifyListeners();
    await _syncHomeWidget();
    return justBloomed;
  }

  /// 스테이지를 실제로 클리어했을 때(목숨을 다 쓰지 않고 목표를 다 채웠을
  /// 때)만 [ChoiceScreen]의 "다음 단계로 넘어갈까요?" 확인 화면에서 명시적으로
  /// 호출된다. 예전에는 "마음을 심을래요"(choseLove) 선택과 스테이지 상승이
  /// 뒤섞여 있어서 "왜 스테이지가 올랐는지/안 올랐는지" 애매했는데, 이제는
  /// 완전히 분리해 "클리어 -> (명시적 확인) -> 다음 단계"만이 유일한 상승
  /// 경로가 된다. 돌멩이 크기/속도 등 난이도도 이 시점에만 올라간다.
  Future<void> advanceToNextStage({String? sessionId}) async {
    await MongiGardenStore.instance.commitSession(
      sessionId ?? SessionTransaction.newId(), () async {
        await _storage.advanceStage();
        return {'stage': _storage.stage};
      });
    stage = _storage.stage;
    notifyListeners();
    await _syncHomeWidget();
  }

  Future<void> resetGardenCycle() async {
    await _storage.resetGardenCycle();
    progress = 0.0;
    notifyListeners();
  }

  /// 개발/테스트용 - 이 기기의 몽이 진행도(스테이지, 재화, 코스튬, 온보딩
  /// 여부 등 전부)를 지우고 처음부터 다시 시작한다. 되돌릴 수 없으므로
  /// 호출하는 UI 쪽에서 반드시 확인 다이얼로그를 먼저 보여줘야 한다.
  Future<void> resetAllProgress() async {
    await _storage.resetAllProgress();
    // Hive를 통째로 비운 뒤, init()과 동일한 방식으로 모든 필드를 기본값으로
    // 다시 읽어들인다(코드 중복을 피하려고 _loadFromStorage로 뽑아둔 것을 재사용).
    _loadFromStorage();
    notifyListeners();
    await _syncHomeWidget();
  }

  /// [_storage]에 저장된 값들을 현재 인메모리 필드로 다시 읽어온다.
  /// [init]과 [resetAllProgress]에서 공통으로 쓰인다.
  void _loadFromStorage() {
    progress = _storage.progress;
    todayFedCount = _storage.todayFedCount;
    streakDays = _storage.streakDays;
    stage = _storage.stage;
    flowerCounts = _storage.flowerCounts;
    seedCounts = _storage.seedCounts;
    diaryEntries = _storage.diaryEntries;
    premiumFrameInterestCount = _storage.premiumFrameInterestCount;
    hasSeenOnboarding = _storage.hasSeenOnboarding;
    notificationsEnabled = _storage.notificationsEnabled;
    notificationHour = _storage.notificationHour;
    notificationMinute = _storage.notificationMinute;
    languageCode = _storage.languageCode;
    premiumFramesUnlocked = _storage.premiumFramesUnlocked;
    hasBloomedOnce = _storage.hasBloomedOnce;
    equippedDecorationIds = _storage.equippedDecorations;
    decorationPackUnlocked = _storage.decorationPackUnlocked;
    score = _storage.score;
    hasCheckedInToday = _storage.hasCheckedInToday;
    todayCheckInEmotionName = _storage.todayCheckInEmotionName;
    checkInStreak = _storage.checkInStreak;
    bestCheckInStreak = _storage.bestCheckInStreak;
    bestEndlessCount = _storage.bestEndlessCount;
    bestEndlessSeconds = _storage.bestEndlessSeconds;
    hasSeenGrowthMilestone = _storage.hasSeenGrowthMilestone;
    hasShownWeeklyReportRecently = _storage.hasShownWeeklyReportRecently;
    goldenFrameEmotions = _storage.goldenFrameEmotions;
    todayEasterEggIndex = _storage.todayEasterEggIndex;
    lightEssence = _storage.lightEssence;
    starShard = _storage.starShard;
    powerCharmCount = _storage.powerCharmCount;
    mongiCareCounts = _storage.mongiCareCounts;
    ownedCostumes = _storage.ownedCostumes;
    equippedCostumeId = _storage.equippedCostumeId;
    gachaTotalPulls = _storage.gachaTotalPulls;
    seasonNumber = _storage.seasonNumber;
    seasonSecondsRemaining = _storage.seasonSecondsRemaining;
    seasonXp = _storage.seasonXp;
    seasonPremiumPurchased = _storage.seasonPremiumPurchased;
    seasonClaimedFreeLevels = _storage.seasonClaimedFreeLevels;
    seasonClaimedPremiumLevels = _storage.seasonClaimedPremiumLevels;
    hasUnreadMongiLetter = _storage.hasUnreadMongiLetter;
    safetyPlan = _storage.safetyPlan;
    gratitudeEntries = _storage.gratitudeEntries;
    mindChallengeActiveId = _storage.mindChallengeActiveId;
    mindChallengeStartDate = _storage.mindChallengeStartDate;
    mindChallengeCheckedDates = _storage.mindChallengeCheckedDates;
    mindChallengeCompletedIds = _storage.mindChallengeCompletedIds;
    hasSentCheerToday = _storage.hasSentCheerToday;
    hasReceivedCheerToday = _storage.hasReceivedCheerToday;
    todayCheerReceivedIndex = _storage.todayCheerReceivedIndex;
    cheerSentTotalCount = _storage.cheerSentTotalCount;
    hasBreathingRewardToday = _storage.hasBreathingRewardToday;
    breathingLibraryTotalCompletions =
        _storage.breathingLibraryTotalCompletions;
    aiReflectionOptIn = _storage.aiReflectionOptIn;
    _reloadDailyMissionState();
  }

  // ── 몽이의 마음 성찰 / 옵트인 AI 리플렉션 (벤치마킹 제안 #6) ─────────────

  /// 설정 화면에서 "마음 성찰" 기능 사용 동의를 켜거나 끌 때 호출한다.
  /// 완전히 로컬(Hive)에만 저장되며, 서버나 외부 AI로 어떤 데이터도
  /// 전송하지 않는다 - 이 앱의 다른 인사이트 기능들과 동일한 원칙이다.
  Future<void> setAiReflectionOptIn(bool value) async {
    await _storage.setAiReflectionOptIn(value);
    aiReflectionOptIn = value;
    notifyListeners();
  }

  /// 안전 계획을 이미 하나라도 작성해뒀는지 여부(홈/설정 화면에서 "작성됨"
  /// 배지를 보여줄 때 사용).
  bool get hasSafetyPlan => safetyPlan.isNotEmpty;

  /// 안전 계획의 [sectionId] 섹션을 저장/수정한다. [text]가 비어있으면
  /// 해당 섹션을 지운다. 완전히 로컬(Hive)에만 저장되고 서버로 전송되지 않는다.
  Future<void> saveSafetyPlanSection(String sectionId, String text) async {
    await _storage.saveSafetyPlanSection(sectionId, text);
    safetyPlan = _storage.safetyPlan;
    notifyListeners();
  }

  /// 오늘 이미 감사/성취 기록을 하나라도 남겼는지 여부(홈 화면 배지용).
  bool get hasGratitudeEntryToday => _storage.hasGratitudeEntryToday;

  /// 감사(gratitude) 또는 작은 성취(achievement) 한 줄을 새로 남긴다.
  /// [type]은 'gratitude' 또는 'achievement'.
  ///
  /// "1번 개선": 시즌 패스가 "게임을 더 많이 해야만 진행되는 소비 트랙"이
  /// 아니라 "일상의 작은 습관도 인정받는 마음여정"이 되도록, 오늘의
  /// 첫 감사/성취 기록에도 소량의 시즌 경험치를 지급한다(체크인과 마찬가지로
  /// 하루 한 번만 - 여러 개를 몰아서 적어도 추가 지급되지 않는다).
  Future<void> addGratitudeEntry({
    required String type,
    required String text,
  }) async {
    final isFirstToday = !hasGratitudeEntryToday;
    await _storage.addGratitudeEntry(type: type, text: text);
    gratitudeEntries = _storage.gratitudeEntries;
    if (isFirstToday) {
      await _addSeasonXp(8);
    }
    notifyListeners();
  }

  /// [entryIndex]번째(최신순 인덱스) 감사/성취 기록을 지운다.
  Future<void> removeGratitudeEntry(int entryIndex) async {
    await _storage.removeGratitudeEntry(entryIndex);
    gratitudeEntries = _storage.gratitudeEntries;
    notifyListeners();
  }

  // ── 몽이의 숨결 도감 (Calm/Headspace 벤치마킹) ─────────────

  /// 호흡 기법 하나를 끝까지 마쳤을 때 호출한다(인터스티셜이 자연 완료로
  /// 끝났을 때만 호출부에서 부른다 - 중간에 건너뛰면 호출하지 않음). 누적
  /// 완료 횟수는 항상 늘어나고, 오늘 처음 완료한 것이라면 [technique]에
  /// 정의된 보상을 지급한다. 반환값: 실제로 지급된 빛의 정수(0이면 오늘
  /// 이미 보상을 받아 지급되지 않음).
  Future<int> completeBreathingTechnique(
    BreathingTechniqueDef technique,
  ) async {
    final rewardEligible = await _storage.recordBreathingCompletion();
    hasBreathingRewardToday = _storage.hasBreathingRewardToday;
    breathingLibraryTotalCompletions =
        _storage.breathingLibraryTotalCompletions;
    var reward = 0;
    if (rewardEligible && technique.rewardLightEssence > 0) {
      reward = technique.rewardLightEssence;
      await _storage.addLightEssence(reward);
      lightEssence = _storage.lightEssence;
    }
    notifyListeners();
    return reward;
  }

  /// 일주일에 한 번, 데이터가 충분히 쌓였다면 "몽이의 주간 편지" 새 편지
  /// 배지를 켠다. 자동으로 화면을 열지는 않고(주간 리포트와 달리 편지는
  /// 유저가 스스로 열어보는 편이 더 소중하게 느껴진다는 판단), 홈 화면의
  /// 편지 아이콘에 "새 편지" 표시만 띄운다.
  Future<void> maybeIssueMongiLetter() async {
    if (_storage.hasIssuedMongiLetterRecently) return;
    final now = DateTime.now();
    final cutoff = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final recentCount = diaryEntries.where((entry) {
      final raw = entry['date'] as String?;
      if (raw == null) return false;
      final parts = raw.split('-');
      if (parts.length != 3) return false;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y == null || m == null || d == null) return false;
      return !DateTime(y, m, d).isBefore(cutoff);
    }).length;
    if (recentCount < 3) return;
    await _storage.issueMongiLetter();
    hasUnreadMongiLetter = true;
    notifyListeners();
  }

  /// 유저가 편지 화면을 열었을 때 - 배지를 끈다.
  Future<void> markMongiLetterRead() async {
    if (!hasUnreadMongiLetter) return;
    await _storage.markMongiLetterRead();
    hasUnreadMongiLetter = false;
    notifyListeners();
  }

  /// 러너 게임 한 판이 끝난 뒤(선택 화면에서) 한 줄 감정 일기를 남긴다.
  /// [note], [intensity](1~5), [triggers](트리거 태그 id 목록)는 모두 선택사항.
  Future<void> addDiaryEntry({
    required EmotionType emotionType,
    String? targetName,
    required int eatenCount,
    String? note,
    int? intensity,
    List<String>? triggers,
    String? sessionId,
  }) async {
    await MongiGardenStore.instance.commitSession(
      sessionId ?? SessionTransaction.newId(), () async {
      await _storage.addDiaryEntry(
      emotionTypeName: emotionType.name,
      targetName: targetName,
      eatenCount: eatenCount,
      note: note,
      intensity: intensity,
      triggers: triggers,
    );
      return <String, dynamic>{};
    });
    diaryEntries = _storage.diaryEntries;
    notifyListeners();
  }

  /// 아직 출시되지 않은 프리미엄 카드 프레임에 "출시 알림 받기"를 요청했을 때 호출.
  /// 실제 결제 붙이기 전, 코스메틱 유료화 수요를 확인하기 위한 로컬 집계 지표.
  Future<void> registerPremiumFrameInterest() async {
    await _storage.registerPremiumFrameInterest();
    premiumFrameInterestCount = _storage.premiumFrameInterestCount;
    notifyListeners();
  }

  /// 설정 화면에서 "매일 알림" 토글을 켜거나 끌 때 호출한다.
  /// 켤 때는 실제 권한 요청 + 예약까지 수행하고, 성공 여부를 반환한다
  /// (권한이 거부되면 토글이 다시 꺼진 상태로 유지되도록 UI에서 이 반환값을 사용).
  ///
  /// [notificationContent]는 호출부(settings_screen.dart)에서
  /// `notificationContent(AppLocalizations.of(context))`로 만들어 넘겨주는
  /// 지역화된 알림 콘텐츠 - 자세한 설명은 [init]의 문서 참고.
  Future<bool> setNotificationsEnabled(
    bool enabled, {
    NotificationContent? notificationContent,
  }) async {
    if (enabled) {
      final scheduled = await NotificationService.instance.scheduleDaily(
        notificationHour,
        notificationMinute,
        personalizedMessage: _personalizedReminderMessage,
        content: notificationContent,
      );
      if (!scheduled) return false;
    } else {
      await NotificationService.instance.cancelDaily();
    }
    await _storage.setNotificationsEnabled(enabled);
    notificationsEnabled = enabled;
    notifyListeners();
    return true;
  }

  /// 설정 화면에서 언어를 직접 바꿀 때 호출한다. null을 넘기면 다시
  /// 시스템 언어를 따라가도록 되돌린다.
  Future<void> setLanguageCode(String? code) async {
    await _storage.setLanguageCode(code);
    languageCode = code;
    notifyListeners();
  }

  /// 알림 시각을 변경한다. 이미 알림이 켜져 있으면 새 시각으로 즉시 재예약한다.
  ///
  /// [notificationContent]는 호출부(settings_screen.dart)에서
  /// `notificationContent(AppLocalizations.of(context))`로 만들어 넘겨주는
  /// 지역화된 알림 콘텐츠 - 자세한 설명은 [init]의 문서 참고.
  Future<void> setNotificationTime(
    int hour,
    int minute, {
    NotificationContent? notificationContent,
  }) async {
    await _storage.setNotificationTime(hour, minute);
    notificationHour = hour;
    notificationMinute = minute;
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleDaily(
        hour,
        minute,
        personalizedMessage: _personalizedReminderMessage,
        content: notificationContent,
      );
    }
    notifyListeners();
  }

  /// 프리미엄 카드 프레임 팩 구매를 시작한다. 실제 잠금 해제는 구매가 확인된 뒤
  /// [PurchaseService]에 등록해둔 콜백을 통해 비동기로 반영된다.
  Future<bool> buyPremiumFrames() =>
      PurchaseService.instance.buyProduct(kPremiumFramesProductId);

  /// 재설치/기기 변경 후 이전 구매 내역을 복원한다 (카드 프레임 + 정원 장식팩 공통).
  Future<void> restorePremiumFramesPurchase() =>
      PurchaseService.instance.restorePurchases();

  /// 프리미엄 정원 장식팩 구매를 시작한다. 실제 잠금 해제는 구매가 확인된 뒤
  /// [PurchaseService]에 등록해둔 콜백을 통해 비동기로 반영된다.
  Future<bool> buyDecorationPack() =>
      PurchaseService.instance.buyProduct(kGardenDecorationPackProductId);

  /// 재설치/기기 변경 후 정원 장식팩 구매 내역을 복원한다.
  Future<void> restoreDecorationPackPurchase() =>
      PurchaseService.instance.restorePurchases();

  // ── 시즌 패스("몽이의 마음여정") ─────────────────────────

  /// 시즌 경험치를 [amount]만큼 더한다(내부 전용 - 각 세션/체크인/감사기록
  /// 메서드가 함께 호출한다). 시즌이 이미 끝났으면 저장소가 알아서 새 시즌으로
  /// 넘긴 뒤 그 새 시즌에 경험치를 쌓는다.
  ///
  /// "1번 개선": 이번 지급으로 "마음 마일스톤"(5의 배수 레벨)을 새로
  /// 넘겼다면 [lastSeasonMilestoneMessage]에 그 격려 문구를 남긴다 - 화면에서
  /// 굳이 시즌 패스 페이지를 열지 않아도, 딱 그 순간(체크인/세션 결과/감사
  /// 기록 저장 직후)에 "마음이 성장했다"는 걸 알아챌 수 있게 한다.
  Future<void> _addSeasonXp(int amount) async {
    if (amount <= 0) return;
    await _storage.refreshSeasonIfNeeded();
    final levelBefore = SeasonPass.levelForXp(_storage.seasonXp);
    await _storage.addSeasonXp(amount);
    final levelAfter = SeasonPass.levelForXp(_storage.seasonXp);
    _reloadSeasonState();
    String? milestoneMessage;
    int? milestoneLevel;
    for (var lvl = levelBefore + 1; lvl <= levelAfter; lvl++) {
      final message = SeasonPass.milestoneMessageForLevel(lvl);
      if (message != null) {
        milestoneMessage = message;
        milestoneLevel = lvl;
      }
    }
    lastSeasonMilestoneMessage = milestoneMessage;
    lastSeasonMilestoneLevel = milestoneLevel;
  }

  void _reloadSeasonState() {
    seasonNumber = _storage.seasonNumber;
    seasonSecondsRemaining = _storage.seasonSecondsRemaining;
    seasonXp = _storage.seasonXp;
    seasonPremiumPurchased = _storage.seasonPremiumPurchased;
    seasonClaimedFreeLevels = _storage.seasonClaimedFreeLevels;
    seasonClaimedPremiumLevels = _storage.seasonClaimedPremiumLevels;
  }

  /// 화면에 들어올 때마다 호출해서, 시즌 카운트다운을 최신화하고(끝났으면
  /// 새 시즌으로 자동 전환) UI에 반영한다.
  Future<void> refreshSeasonPass() async {
    await _storage.refreshSeasonIfNeeded();
    _reloadSeasonState();
    notifyListeners();
  }

  /// 시즌 패스 프리미엄 트랙 구매를 시작한다. 실제 보상 반영은 구매가 확인된
  /// 뒤 [PurchaseService] 콜백([_grantSeasonPassPremium])을 통해 이뤄진다.
  Future<bool> buySeasonPassPremium() =>
      PurchaseService.instance.buyProduct(kSeasonPassProductId);

  /// 재설치/기기 변경 후 시즌 패스 프리미엄 구매 내역을 복원한다.
  Future<void> restoreSeasonPassPurchase() =>
      PurchaseService.instance.restorePurchases();

  Future<void> _grantSeasonPassPremium() async {
    if (seasonPremiumPurchased) return;
    await _storage.setSeasonPremiumPurchased(true);
    seasonPremiumPurchased = true;
    notifyListeners();
  }

  /// [pack] 빛의 정수 충전팩(소모성) 구매를 시작한다. 실제 지급은 구매가
  /// 확인된 뒤 [PurchaseService] 콜백([_grantLightEssencePack])을 통해 이뤄진다.
  /// 소모성 상품은 구매 즉시 소비되는 성격이라 별도의 "복원" 개념이 없다.
  Future<bool> buyLightEssencePack(LightEssencePack pack) =>
      PurchaseService.instance.buyConsumable(pack.productId);

  /// [level] 무료 보상을 수령한다. 아직 그 레벨에 도달하지 못했거나 이미
  /// 수령했으면 false를 반환하고 아무 것도 지급하지 않는다.
  Future<bool> claimSeasonFreeReward(int level) async {
    if (level > seasonLevel) return false;
    final claimed = await _storage.claimSeasonFreeLevel(level);
    if (!claimed) return false;
    final reward = SeasonPass.tierForLevel(level).free;
    await _grantSeasonReward(reward);
    seasonClaimedFreeLevels = _storage.seasonClaimedFreeLevels;
    notifyListeners();
    return true;
  }

  /// [level] 프리미엄 보상을 수령한다. 프리미엄 패스를 구매하지 않았거나,
  /// 아직 그 레벨에 도달하지 못했거나, 이미 수령했으면 false를 반환한다.
  Future<bool> claimSeasonPremiumReward(int level) async {
    if (!seasonPremiumPurchased || level > seasonLevel) return false;
    final claimed = await _storage.claimSeasonPremiumLevel(level);
    if (!claimed) return false;
    final reward = SeasonPass.tierForLevel(level).premium;
    await _grantSeasonReward(reward);
    seasonClaimedPremiumLevels = _storage.seasonClaimedPremiumLevels;
    notifyListeners();
    return true;
  }

  Future<void> _grantSeasonReward(SeasonRewardItem reward) async {
    if (reward.lightEssence > 0) {
      await _storage.addLightEssence(reward.lightEssence);
      lightEssence = _storage.lightEssence;
    }
    if (reward.starShard > 0) {
      await _storage.addStarShard(reward.starShard);
      starShard = _storage.starShard;
    }
    if (reward.costumeId != null) {
      await _storage.unlockCostume(reward.costumeId!);
      ownedCostumes = _storage.ownedCostumes;
    }
  }

  // ── 일일 미션 ─────────────────────────

  void _reloadDailyMissionState() {
    dailyMissionProgress = _storage.dailyMissionProgress;
    dailyMissionClaimed = _storage.dailyMissionClaimed;
    dailyMissionAllClearClaimed = _storage.dailyMissionAllClearClaimed;
  }

  /// 화면에 들어올 때마다 호출해서, 날짜가 바뀌었으면 오늘의 미션을 새로
  /// 시작한다(어제 진행도/수령 기록은 자동으로 사라진다).
  Future<void> refreshDailyMissions() async {
    await _storage.refreshDailyMissionsIfNeeded();
    _reloadDailyMissionState();
    notifyListeners();
  }

  /// [type] 미션의 오늘 진행도를 [amount]만큼 올린다. 이미 오늘 목표를
  /// 넘겼더라도 계속 누적은 시켜두되(수령 판정은 target으로 클램프해서 하므로
  /// 문제 없음), 호출부(recordSession/recordEndlessSession)에서 세션이 끝날
  /// 때마다 자연스럽게 호출한다 - 새로운 강제 행동 없이 기존 플레이 지표를 그대로 반영.
  Future<void> _addDailyMissionProgress(
    DailyMissionType type,
    int amount,
  ) async {
    if (amount <= 0) return;
    for (final mission in DailyMission.all) {
      if (mission.type != type) continue;
      await _storage.addDailyMissionProgress(mission.id, amount);
    }
    dailyMissionProgress = _storage.dailyMissionProgress;
  }

  /// [mission] 보상을 수령한다. 아직 목표를 달성하지 못했거나 이미 수령했으면
  /// false를 반환하고 아무 것도 지급하지 않는다.
  Future<bool> claimDailyMission(DailyMissionDef mission) async {
    if (!isDailyMissionAchieved(mission)) return false;
    final claimed = await _storage.claimDailyMission(mission.id);
    if (!claimed) return false;
    dailyMissionClaimed = _storage.dailyMissionClaimed;
    if (mission.rewardLightEssence > 0) {
      await _storage.addLightEssence(mission.rewardLightEssence);
      lightEssence = _storage.lightEssence;
    }
    notifyListeners();
    return true;
  }

  /// 오늘의 올클리어 보너스(빛의 정수 + 별조각)를 수령한다. 3개 미션을 모두
  /// 수령하지 않았거나 이미 받았으면 false를 반환한다.
  Future<bool> claimDailyMissionAllClearBonus() async {
    if (!_canClaimAllClearBonus) return false;
    final claimed = await _storage.claimDailyMissionAllClearBonus();
    if (!claimed) return false;
    dailyMissionAllClearClaimed = true;
    await _storage.addLightEssence(DailyMission.allClearBonusLightEssence);
    await _storage.addStarShard(DailyMission.allClearBonusStarShard);
    lightEssence = _storage.lightEssence;
    starShard = _storage.starShard;
    notifyListeners();
    return true;
  }

  /// 몽이의 성장나무가 마지막 단계(열매)에 도달했을 때 나오는 "성장 마일스톤
  /// 회고" 화면을 봤다고 기록한다. 그 뒤로는 자동으로 다시 뜨지 않는다
  /// (원하면 도감 화면 등에서 다시 볼 수 있게 열어둘 수 있다).
  Future<void> markGrowthMilestoneSeen() async {
    if (hasSeenGrowthMilestone) return;
    await _storage.markGrowthMilestoneSeen();
    hasSeenGrowthMilestone = true;
    notifyListeners();
  }

  /// 주간 감정 리포트(2단계: "감정 데이터 되돌려주기")를 오늘 자동으로 보여줬다고
  /// 기록한다. 이후 7일 동안은 자동으로 다시 뜨지 않는다(홈 화면 배지로는 언제든
  /// 다시 볼 수 있다).
  Future<void> markWeeklyReportShown() async {
    await _storage.markWeeklyReportShown();
    hasShownWeeklyReportRecently = true;
    notifyListeners();
  }

  /// 꾸미기 화면에서 장식 아이템을 탭했을 때 호출. 잠금 해제된 아이템만 장착/해제할 수 있다.
  Future<void> toggleDecorationEquipped(GardenDecoration decoration) async {
    if (!isDecorationUnlocked(decoration)) return;
    final current = List<String>.from(equippedDecorationIds);
    if (current.contains(decoration.id)) {
      current.remove(decoration.id);
    } else {
      current.add(decoration.id);
    }
    await _storage.setEquippedDecorations(current);
    equippedDecorationIds = current;
    notifyListeners();
  }

  /// 코스튬을 몽이에게 장착/해제한다. [costumeId]가 null이면 해제(기본 모습).
  /// 보유하지 않은 코스튬은 장착되지 않는다.
  Future<void> equipCostume(String? costumeId) async {
    await _storage.setEquippedCostume(costumeId);
    equippedCostumeId = _storage.equippedCostumeId;
    notifyListeners();
  }

  /// 빛의 정수를 소비해서 "마음 상자"를 1회 연다. 화폐가 부족하거나, 이미
  /// 모든 선물을 다 모아서 더 열 게 없으면 null을 반환하고 아무 것도
  /// 소비하지 않는다.
  ///
  /// B2(순차 보장형): 확률/천장 없이, 아직 보유하지 않은 코스튬 중 무작위로
  /// 하나가 "확정" 지급된다 - 중복도 꽝도 없다.
  Future<GachaPullResult?> pullGachaOnce() async {
    if (hasCollectedAllCostumes) return null;
    final spent = await _storage.spendLightEssence(GachaService.singlePullCost);
    if (!spent) return null;
    lightEssence = _storage.lightEssence;
    final result = await _executeSinglePull();
    notifyListeners();
    return result;
  }

  /// 빛의 정수를 소비해서 "마음 상자"를 여러 개 연속으로 연다(편의 기능 -
  /// 가격 할인은 없고, 여러 번 여는 수고를 덜어줄 뿐이다). 남은 미보유
  /// 코스튬 수가 [count]보다 적으면, 그 개수만큼만 열고 나머지 비용은
  /// 소비하지 않는다. 화폐가 부족하거나 열 게 하나도 없으면 null.
  Future<List<GachaPullResult>?> pullGachaBulk({
    int count = GachaService.maxBulkOpenCount,
  }) async {
    if (hasCollectedAllCostumes) return null;
    final actualCount = count.clamp(1, remainingGachaCostumeCount);
    final totalCost = GachaService.singlePullCost * actualCount;
    final spent = await _storage.spendLightEssence(totalCost);
    if (!spent) return null;
    lightEssence = _storage.lightEssence;
    final results = <GachaPullResult>[];
    for (var i = 0; i < actualCount; i++) {
      results.add(await _executeSinglePull());
    }
    notifyListeners();
    return results;
  }

  /// 뽑기 로직(미보유 코스튬 중 무작위 선택 -> 저장) 한 번을 실행하고 결과를
  /// 반환한다. 화폐 차감은 호출부([pullGachaOnce]/[pullGachaBulk])에서 이미
  /// 처리했다고 가정한다.
  Future<GachaPullResult> _executeSinglePull() async {
    final costume = GachaService.pickUnownedCostume(ownedCostumes)!;
    await _storage.recordGachaPull();
    gachaTotalPulls = _storage.gachaTotalPulls;

    await _storage.unlockCostume(costume.id);
    ownedCostumes = _storage.ownedCostumes;

    return GachaPullResult(costume: costume);
  }

  /// "생명의 물" - 목숨을 다 썼을 때 광고 없이 빛의 정수([ReviveService.
  /// lightEssenceCost])를 내고 즉시 부활한다. 화폐가 부족하면 false를
  /// 반환하고 아무 것도 차감하지 않는다(호출부에서 "화폐가 모자라요" 안내로
  /// 처리).
  Future<bool> buyReviveWithLightEssence() async {
    final spent = await _storage.spendLightEssence(
      ReviveService.lightEssenceCost,
    );
    if (!spent) return false;
    lightEssence = _storage.lightEssence;
    notifyListeners();
    return true;
  }

  // ── 파워 부적(소모품 인벤토리) ─────────────────────────

  /// 파워 부적 1개를 빛의 정수로 구매해 인벤토리에 더한다. 화폐가 부족하면
  /// false를 반환하고 아무 것도 차감하지 않는다.
  Future<bool> buyPowerCharm() async {
    final spent = await _storage.spendLightEssence(
      PowerCharmOffer.lightEssenceCost,
    );
    if (!spent) return false;
    lightEssence = _storage.lightEssence;
    await _storage.addPowerCharm(1);
    powerCharmCount = _storage.powerCharmCount;
    notifyListeners();
    return true;
  }

  /// [PowerCharmOffer.bulkQuantity]개를 한 번에 구매한다(할인 없음, 여러
  /// 번 구매하는 수고만 덜어줌 - 마음 상자 묶음열기와 동일한 원칙). 화폐가
  /// 부족하면 false.
  Future<bool> buyPowerCharmBulk() async {
    final totalCost =
        PowerCharmOffer.lightEssenceCost * PowerCharmOffer.bulkQuantity;
    final spent = await _storage.spendLightEssence(totalCost);
    if (!spent) return false;
    lightEssence = _storage.lightEssence;
    await _storage.addPowerCharm(PowerCharmOffer.bulkQuantity);
    powerCharmCount = _storage.powerCharmCount;
    notifyListeners();
    return true;
  }

  /// 파워 부적 1개를 소비한다(게임 화면에서 "지금 바로 쓰기" 버튼을 눌렀을
  /// 때 호출). 보유 개수가 0이면 false를 반환하고 아무 것도 차감하지 않는다.
  /// 실제 무적 모드 발동([RunnerGame.activatePowerMode] 호출)은 호출부의
  /// 책임이다 - 이 메서드는 순수하게 인벤토리 차감만 담당한다.
  Future<bool> consumePowerCharm() async {
    final consumed = await _storage.consumePowerCharm();
    if (!consumed) return false;
    powerCharmCount = _storage.powerCharmCount;
    notifyListeners();
    return true;
  }

  // ── 몽이 돌봄 세트(참치캔/사료/맑은물/담요/몽이의 집) ─────────────

  /// [item] 돌봄 아이템 하나를 빛의 정수로 구매해 몽이에게 준다.
  /// 화폐가 부족하면 null을 반환하고 아무 것도 차감하지 않는다.
  /// keepsake(담요/몽이의 집)를 이번에 처음 획득했다면
  /// [MongiCareResult.isNewKeepsake]가 true가 되어 정원 씬에 영구 배치된다.
  Future<MongiCareResult?> giveMongiCareItem(MongiCareItem item) async {
    final spent = await _storage.spendLightEssence(item.lightEssenceCost);
    if (!spent) return null;
    lightEssence = _storage.lightEssence;
    final wasOwnedBefore = (mongiCareCounts[item.id] ?? 0) > 0;
    await _storage.giveMongiCareItem(item.id);
    mongiCareCounts = _storage.mongiCareCounts;
    notifyListeners();
    return MongiCareResult(
      item: item,
      isNewKeepsake: item.isKeepsake && !wasOwnedBefore,
    );
  }

  /// 이 돌봄 아이템을 지금까지 준 누적 횟수(0이면 아직 한 번도 안 줌).
  int mongiCareCountFor(MongiCareItem item) => mongiCareCounts[item.id] ?? 0;

  /// keepsake(담요/몽이의 집)를 한 번이라도 받아서 지금 정원에 놓여 있는지.
  bool hasMongiKeepsake(MongiCareItem item) => mongiCareCountFor(item) > 0;

  /// 안드로이드 홈 화면 위젯(GardenWidgetProvider)에 최신 진행도를 반영한다.
  /// 위젯 기능은 Android 전용이므로 웹/기타 플랫폼에서는 조용히 무시한다.
  Future<void> _syncHomeWidget() async {
    if (kIsWeb || SessionTransaction.draft != null) return;
    try {
      final percent = (progress.clamp(0.0, 1.0) * 100).round();
      await HomeWidget.saveWidgetData<int>(_kWidgetProgressPercent, percent);
      await HomeWidget.saveWidgetData<int>(_kWidgetStage, stage);
      await HomeWidget.saveWidgetData<int>(_kWidgetStreak, streakDays);
      await HomeWidget.updateWidget(
        androidName: 'GardenWidgetProvider',
        qualifiedAndroidName: 'com.mysticcat.journal.GardenWidgetProvider',
      );
    } catch (_) {
      // 위젯 플러그인이 없는 플랫폼(iOS 미설정, 테스트 환경 등)에서는 무시한다.
    }
  }
}
