import 'dart:math';
import 'package:flutter/material.dart';
import '../models/cat_care_state.dart';
import '../models/cat_accessory.dart';
import '../models/cat_achievement.dart';
import '../services/cat_care_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../data/shadow_cats_data.dart';

/// 다마고치식 '마음 돌보기' 상태를 화면에 공급하는 Provider
class CatCareProvider extends ChangeNotifier {
  CatCareState state = CatCareState(
    temperature: CatCareService.startTemperature,
    fedToday: false,
    wateredToday: false,
    bathedToday: false,
    cleanedToday: false,
    companionCatId: shadowCats.first.id,
    growthDays: 0,
  );
  bool isLoading = true;

  /// 웰컴 투어에서 사용자가 지어준 아기고양이의 이름. 없으면 null.
  String? companionName;

  /// 유료 구독자 여부. 100도 달성 시 포인트 적립은 구독자에게만 적용됩니다.
  bool isPremium = false;

  /// 방금 성장 단계가 올라간 경우, 새로 도달한 단계. 레벨업 애니메이션을
  /// 보여준 뒤 [clearLevelUp]으로 비워줍니다. 평소에는 null.
  CatGrowthStage? justReachedStage;

  /// 몸 돌보기 4가지(밥/물/목욕/청소)를 방금 막 모두 마쳤을 때 보여줄
  /// 축하 말풍선 문구. 화면에서 보여준 뒤 [clearBodyCareCelebration]으로
  /// 비웁니다. 평소에는 null.
  String? bodyCareCelebrationMessage;

  /// 마음 돌보기까지 포함해 오늘의 돌봄 8가지를 방금 막 모두 마쳤을 때
  /// 보여줄 축하 말풍선 문구(마음 온도 +1도 안내). 화면에서 보여준 뒤
  /// [clearAllCareCelebration]으로 비웁니다. 평소에는 null.
  String? allCareCelebrationMessage;

  void clearBodyCareCelebration() {
    bodyCareCelebrationMessage = null;
  }

  void clearAllCareCelebration() {
    allCareCelebrationMessage = null;
  }

  /// 🐛 디버그 전용 - 실제 출석일수 대신 이 값으로 성장 단계를 미리보기
  /// 위한 오버라이드. null이면 실제 [state.growthDays]를 사용합니다.
  /// 실제 저장 데이터([state.growthDays])는 건드리지 않고 화면 표시만
  /// 바꿔주므로 안전하게 켜고 끌 수 있습니다.
  int? debugGrowthDaysOverride;

  void setDebugGrowthDays(int? days) {
    debugGrowthDaysOverride = days;
    notifyListeners();
  }

  /// 화면에서 실제로 사용할 성장일수(디버그 오버라이드가 있으면 그 값을 사용).
  int get effectiveGrowthDays => debugGrowthDaysOverride ?? state.growthDays;

  /// 화면에서 실제로 사용할 성장 단계(디버그 오버라이드 반영).
  CatGrowthStage get effectiveGrowthStage =>
      CatCareState.stageForGrowthDays(effectiveGrowthDays);

  /// 지금까지 구매한 착용형/가구 아이템 id 목록(소모품은 별도로 관리).
  List<String> ownedAccessoryIds = [];

  /// 부위별로 현재 장착 중인 아이템 id.
  Map<CatWearSlot, String> equippedBySlot = {};

  /// 소모품(사료/츄루/빗질 등)별로 보관함에 남아있는 개수.
  Map<String, int> consumableInventory = {};

  /// 지금까지 졸업(성체까지 다 키움)한 고양이들의 (catId, 졸업일) 목록.
  List<(String, DateTime)> graduatedCats = [];

  /// 방금 졸업을 완료했는지 여부 - 졸업 축하 오버레이를 보여준 뒤
  /// [clearJustGraduated]로 비워줍니다.
  bool justGraduated = false;

  /// 업적(뱃지) 판단용 누적 통계 스냅샷.
  CatAchievementStats achievementStats = const CatAchievementStats();

  /// 지금까지(이번 세션 포함) 달성한 뱃지 id 목록.
  Set<String> unlockedAchievementIds = {};

  /// 아직 축하 팝업을 보여주지 않은, 새로 달성한 뱃지들의 대기열.
  /// 화면에서 하나씩 꺼내 보여준 뒤 [dequeueNewAchievement]로 비웁니다.
  final List<CatAchievement> newlyUnlockedQueue = [];

  void clearLevelUp() {
    justReachedStage = null;
  }

  void clearJustGraduated() {
    justGraduated = false;
  }

  /// 축하 팝업을 보여준 뱃지를 대기열에서 제거하고, "이미 봤음"으로
  /// 영구 기록합니다.
  Future<void> dequeueNewAchievement() async {
    if (newlyUnlockedQueue.isEmpty) return;
    final shown = newlyUnlockedQueue.removeAt(0);
    await CatCareService.markAchievementsSeen([shown.id]);
    notifyListeners();
  }

  /// 최신 통계를 기반으로 뱃지 달성 여부를 다시 계산합니다. 새로 달성된
  /// (그리고 아직 축하하지 않은) 뱃지가 있으면 [newlyUnlockedQueue]에
  /// 추가합니다.
  Future<void> _refreshAchievements() async {
    achievementStats = await CatCareService.getAchievementStats(
      growthDays: state.growthDays,
      graduatedCount: graduatedCats.length,
    );
    final seen = await CatCareService.getSeenUnlockedAchievementIds();
    final unlockedNow = catAchievements
        .where((a) => a.isUnlocked(achievementStats))
        .map((a) => a.id)
        .toSet();
    unlockedAchievementIds = unlockedNow;
    final freshlyUnlocked = catAchievements.where(
      (a) => unlockedNow.contains(a.id) && !seen.contains(a.id),
    );
    for (final a in freshlyUnlocked) {
      if (!newlyUnlockedQueue.any((q) => q.id == a.id)) {
        newlyUnlockedQueue.add(a);
      }
    }
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    isPremium = await SubscriptionService().isPremium();
    // 회원가입(온보딩)을 아직 마치지 않았다면 출석 카운팅을 시작하지 않습니다.
    // 회원가입 + 아기고양이 이름짓기 + 로그인을 모두 마친 시점부터 비로소
    // '출석 1일차'가 기록되기 시작합니다.
    final signedUp = await StorageService.isOnboardingCompleted();
    state = await CatCareService.loadAndApplyDailyDecay(
      defaultCompanionCatId: shadowCats.first.id,
      isPremium: isPremium,
      countAttendance: signedUp,
    );
    companionName = await StorageService.getCompanionName();
    ownedAccessoryIds = await CatCareService.getOwnedAccessoryIds();
    equippedBySlot = await CatCareService.getEquippedBySlot();
    consumableInventory = await CatCareService.getConsumableInventory();
    graduatedCats = await CatCareService.getGraduatedCats();
    await _refreshAchievements();
    isLoading = false;
    notifyListeners();
  }

  /// 이름이 지어져 있으면 이름을, 없으면 기본 문구를 반환합니다.
  String get displayName =>
      (companionName != null && companionName!.trim().isNotEmpty)
      ? companionName!.trim()
      : '아기 고양이';

  /// 100도를 달성할 때마다 적립된 포인트(구독자 전용 보상). 화면에서
  /// 구독 여부와 무관하게 조회할 수 있도록 노출합니다.
  int get points => state.points;

  Future<void> _complete(CareTask task) async {
    final prevStage = state.growthStage;
    final wasBodyCareDone = state.bodyCareDoneToday;
    final wasAllDone = state.allDoneToday;
    state = await CatCareService.completeTask(task, isPremium: isPremium);
    await SoundService().playMeow();
    final newStage = state.growthStage;
    if (newStage != prevStage) {
      // 성장 단계가 올라간 순간 - 화면에서 레벨업 애니메이션을 띄울 수 있도록 표시
      justReachedStage = newStage;
    }

    // 몸을 돌보기 4가지(밥/물/목욕/청소)를 방금 막 모두 마친 순간 - 골골송과
    // 함께 축하 말풍선을 띄워줍니다.
    if (!wasBodyCareDone && state.bodyCareDoneToday) {
      await SoundService().playPurr();
      bodyCareCelebrationMessage = '골골골... 몸을 다 돌봐줘서 행복해요 😽💕';
    }

    // 마음 돌보기까지 포함해 오늘의 돌봄 8가지를 방금 막 모두 마친 순간 -
    // 마음 온도가 1도 오른 것을 축하 말풍선 + 축하 사운드로 알려줍니다.
    if (!wasAllDone && state.allDoneToday) {
      await SoundService().playChime();
      allCareCelebrationMessage = '오늘 돌봄을 모두 마쳤어요! 마음 온도가 1도 올랐어요 🌡️✨';
    }

    await _refreshAchievements();
    notifyListeners();
  }

  /// 랜덤으로 고를 애정 표현 대사 후보 (착용 아이템이 없을 때 사용).
  static const List<String> _patLinesDefault = [
    '골골골... 기분 좋아요 💕',
    '더 만져주세요~ 냐옹!',
    '당신 손길이 참 따뜻해요.',
    '오늘 하루 중 최고의 순간이에요.',
    '냐옹~ 사랑해요!',
  ];

  /// 반려 고양이를 쓰다듬어줍니다(탭 인터랙션). 착용 중인 아이템에 따라
  /// 다른 대사를 골라 반환합니다. 애정 표현 누적 횟수도 함께 늘어나며,
  /// 뱃지 달성 여부도 다시 계산합니다.
  Future<String> patCat() async {
    final total = await CatCareService.recordPat();
    await SoundService().playMeow();
    await _refreshAchievements();
    notifyListeners();

    // 착용 중인 아이템이 있으면, 그 아이템에 맞는 특별 대사를 우선 보여줍니다.
    final equippedIds = equippedBySlot.values.toList();
    if (equippedIds.isNotEmpty) {
      final rng = Random(total);
      final pickedId = equippedIds[rng.nextInt(equippedIds.length)];
      final line = _wearLine(pickedId);
      if (line != null) return line;
    }
    final rng = Random(total * 31 + 7);
    return _patLinesDefault[rng.nextInt(_patLinesDefault.length)];
  }

  /// 특정 착용 아이템에 어울리는 반응 대사. 매칭되는 대사가 없으면 null.
  String? _wearLine(String accessoryId) {
    switch (accessoryId) {
      case 'headset':
        return '음악 듣는 중이에요~ 🎧';
      case 'crown':
        return '오늘의 왕(?)이에요, 냐옹!';
      case 'hat':
        return '모자가 마음에 들어요, 멋지죠?';
      case 'glasses':
        return '이 안경 쓰니까 더 똑똑해 보이지 않나요? 👓';
      case 'scarf':
        return '목도리가 포근해요, 고마워요.';
      case 'bowtie':
        return '오늘은 신사(?) 고양이랍니다.';
      case 'dress':
        return '이 옷 예쁘죠? 골라줘서 고마워요.';
      case 'hoodie':
        return '후드가 편안해요, 나른한 오후네요.';
      case 'vest':
        return '조끼 입으니까 든든해요!';
      case 'sneakers':
        return '운동화 신으니 팡팡 뛰고 싶어져요!';
      case 'ribbon':
      case 'flower':
      case 'star':
        return '이 장식, 저한테 잘 어울리죠? ✨';
      default:
        return null;
    }
  }

  Future<void> feed() => _complete(CareTask.feed);
  Future<void> water() => _complete(CareTask.water);
  Future<void> bath() => _complete(CareTask.bath);
  Future<void> clean() => _complete(CareTask.clean);
  Future<void> breathing() => _complete(CareTask.breathing);
  Future<void> walking() => _complete(CareTask.walking);
  Future<void> journaling() => _complete(CareTask.journaling);
  Future<void> gratitude() => _complete(CareTask.gratitude);

  Future<void> setCompanionCat(String catId) async {
    await CatCareService.setCompanionCat(catId);
    state = CatCareState(
      temperature: state.temperature,
      fedToday: state.fedToday,
      wateredToday: state.wateredToday,
      bathedToday: state.bathedToday,
      cleanedToday: state.cleanedToday,
      breathingDoneToday: state.breathingDoneToday,
      walkingDoneToday: state.walkingDoneToday,
      journalingDoneToday: state.journalingDoneToday,
      gratitudeDoneToday: state.gratitudeDoneToday,
      companionCatId: catId,
      growthDays: state.growthDays,
      points: state.points,
    );
    notifyListeners();
  }

  /// "오늘의 약속"을 지켰을 때 마음 온도에 +1도를 더합니다(성장일수는 늘리지
  /// 않고, 온도만 살짝 올려 '한 뼘 자란' 느낌을 줍니다). 프리미엄 여부와
  /// 무관하게 누구나 약속을 지키면 온도가 오릅니다. 약속 체크를 취소하면
  /// [delta]에 음수를 넘겨 되돌립니다.
  Future<void> applyPromiseBonus({int delta = 1}) async {
    final (newTemp, newPoints) = await CatCareService.adjustBonusTemperature(
      delta,
      isPremium: isPremium,
    );
    state = CatCareState(
      temperature: newTemp,
      fedToday: state.fedToday,
      wateredToday: state.wateredToday,
      bathedToday: state.bathedToday,
      cleanedToday: state.cleanedToday,
      breathingDoneToday: state.breathingDoneToday,
      walkingDoneToday: state.walkingDoneToday,
      journalingDoneToday: state.journalingDoneToday,
      gratitudeDoneToday: state.gratitudeDoneToday,
      companionCatId: state.companionCatId,
      growthDays: state.growthDays,
      points: newPoints,
    );
    notifyListeners();
  }

  /// 편지를 써서 보낸 것 자체로 마음 온도에 +1도를 더합니다. 사용자가 직접
  /// 온도 값을 입력하는 절차 없이, "편지를 보냈다"는 사실만으로 자동
  /// 적용되는 보너스입니다. 명상 실천 여부와는 완전히 독립적입니다.
  Future<void> applyLetterSentBonus() => applyPromiseBonus(delta: 1);

  /// 편지를 보낸 뒤 (완전히 선택사항인) 명상/움직임까지 실천했을 때, 추가로
  /// +1도를 더 올립니다. 편지 전송 보너스와는 별개의 독립적인 트리거이며,
  /// 명상을 하지 않고 건너뛰어도 이미 적용된 편지 보너스에는 영향이
  /// 없습니다.
  Future<void> applyMeditationBonus() => applyPromiseBonus(delta: 1);

  void reset() {
    state = CatCareState(
      temperature: CatCareService.startTemperature,
      fedToday: false,
      wateredToday: false,
      bathedToday: false,
      cleanedToday: false,
      companionCatId: shadowCats.first.id,
      growthDays: 0,
    );
    isLoading = true;
    notifyListeners();
  }

  // ── 정원 플러스 포인트 상점 (아이템 구매/장착/사용) ──

  /// 아이템을 포인트로 구매합니다. 포인트가 부족하면 false를 반환합니다.
  /// 소모품은 구매할 때마다 보관함 개수가 늘어나고, 착용형/가구는 한 번만
  /// 보유하면 됩니다.
  Future<bool> purchaseAccessory(CatAccessory accessory) async {
    final (success, newPoints) = await CatCareService.purchaseAccessory(
      accessory,
    );
    if (success) {
      if (accessory.type == CatItemType.consumable) {
        consumableInventory = {
          ...consumableInventory,
          accessory.id: (consumableInventory[accessory.id] ?? 0) + 1,
        };
      } else if (!ownedAccessoryIds.contains(accessory.id)) {
        ownedAccessoryIds = [...ownedAccessoryIds, accessory.id];
      }
      state = CatCareState(
        temperature: state.temperature,
        fedToday: state.fedToday,
        wateredToday: state.wateredToday,
        bathedToday: state.bathedToday,
        cleanedToday: state.cleanedToday,
        breathingDoneToday: state.breathingDoneToday,
        walkingDoneToday: state.walkingDoneToday,
        journalingDoneToday: state.journalingDoneToday,
        gratitudeDoneToday: state.gratitudeDoneToday,
        companionCatId: state.companionCatId,
        growthDays: state.growthDays,
        points: newPoints,
      );
      await _refreshAchievements();
      notifyListeners();
    }
    return success;
  }

  /// 보유 중인 착용형 아이템을 해당 부위에 장착합니다(해제하려면 null을 넘김).
  /// 부위가 다르면 여러 개를 동시에 착용할 수 있어요.
  Future<void> equipToSlot(CatWearSlot slot, String? accessoryId) async {
    await CatCareService.equipToSlot(slot, accessoryId);
    final next = Map<CatWearSlot, String>.from(equippedBySlot);
    if (accessoryId == null) {
      next.remove(slot);
    } else {
      next[slot] = accessoryId;
    }
    equippedBySlot = next;
    notifyListeners();
  }

  /// 보관함에 있는 소모품 하나를 사용합니다. 사용에 성공하면 개수가 1개
  /// 줄고, 마음 온도가 살짝 올라갑니다. 보관함에 남은 개수가 없으면
  /// false를 반환합니다.
  Future<bool> useConsumable(CatAccessory accessory) async {
    final (success, newTemp, newPoints) = await CatCareService.useConsumable(
      accessory,
      isPremium: isPremium,
    );
    if (success) {
      final next = Map<String, int>.from(consumableInventory);
      final left = (next[accessory.id] ?? 1) - 1;
      if (left > 0) {
        next[accessory.id] = left;
      } else {
        next.remove(accessory.id);
      }
      consumableInventory = next;
      state = CatCareState(
        temperature: newTemp,
        fedToday: state.fedToday,
        wateredToday: state.wateredToday,
        bathedToday: state.bathedToday,
        cleanedToday: state.cleanedToday,
        breathingDoneToday: state.breathingDoneToday,
        walkingDoneToday: state.walkingDoneToday,
        journalingDoneToday: state.journalingDoneToday,
        gratitudeDoneToday: state.gratitudeDoneToday,
        companionCatId: state.companionCatId,
        growthDays: state.growthDays,
        points: newPoints,
      );
      await _refreshAchievements();
      notifyListeners();
    }
    return success;
  }

  // ── 졸업 앨범 (성체가 된 고양이를 졸업시키고 새 아기고양이로 넘어가기) ──

  /// 현재 반려 고양이를 졸업 명단에 올리고, 새 아기고양이([newCompanionCatId])로
  /// 다시 키우기를 시작합니다. 포인트는 유지되고, 온도/성장일수/오늘의 돌봄
  /// 체크리스트만 초기화됩니다.
  Future<void> graduateAndStartNewBaby(String newCompanionCatId) async {
    state = await CatCareService.graduateAndStartNewBaby(
      newCompanionCatId: newCompanionCatId,
    );
    equippedBySlot = {};
    graduatedCats = await CatCareService.getGraduatedCats();
    justGraduated = true;
    await _refreshAchievements();
    notifyListeners();
  }
}
