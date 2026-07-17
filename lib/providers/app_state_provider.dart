import 'package:flutter/material.dart';
import '../models/shadow_cat.dart';
import '../models/letter_entry.dart';
import '../models/buried_emotion_entry.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../services/garden_weather_service.dart';
import '../services/weekly_shadow_map_service.dart';
import '../services/buried_emotion_service.dart';
import '../services/subscription_service.dart';
import '../services/analytics_service.dart';

/// 명상 저널 플로우 단계
/// selecting: 7마리 중 지금 내 기분과 닮은 고양이 선택
/// story: 고양이의 사연(제3자 시점)
/// letter: 고양이에게 편지 쓰기 (위로 + 해결 방법) - 전송 즉시 저장되고
///         마음 온도가 +1도 오릅니다.
/// meditation: 편지를 보낸 뒤, 원한다면(완전히 선택사항) 추천 명상/움직임을
///         실천해서 추가로 +1도를 더 올릴 수 있는 단계. 건너뛰어도 편지와
///         답장 예약은 이미 확정되어 있어 전혀 영향이 없습니다.
/// done: 완료 화면 (레벨업 여부 안내)
enum FlowStage { selecting, story, letter, meditation, done }

class AppStateProvider extends ChangeNotifier {
  int streak = 0;
  List<LetterEntry> history = [];

  /// 이번에 앱을 열기 직전, 마지막 방문일로부터 며칠이 지났었는지
  /// (결석일수). 모찌(아기고양이)의 반가움/그리움/걱정 표정을 결정하는
  /// 데 사용됩니다. [CatEmotion.forDaysAway] 참고.
  int daysAwayOnOpen = 0;

  /// 디버그/테스트 전용 - 값이 설정되면 [effectiveDaysAway]가 실제 결석일수
  /// 대신 이 값을 반환합니다(모찌 감정 미리보기용). 릴리즈 로직에는 영향을
  /// 주지 않으며, 디버그 UI([kDebugMode])에서만 노출됩니다.
  int? debugDaysAwayOverride;

  /// 모찌 감정을 계산할 때 실제로 사용해야 하는 결석일수.
  /// [debugDaysAwayOverride]가 설정돼 있으면 그 값을, 아니면 실제
  /// [daysAwayOnOpen]을 반환합니다.
  int get effectiveDaysAway => debugDaysAwayOverride ?? daysAwayOnOpen;

  /// 디버그 패널에서 모찌의 결석 감정을 강제로 바꿔볼 때 사용합니다.
  /// null을 전달하면 실제 값으로 복원됩니다.
  void setDebugDaysAway(int? days) {
    debugDaysAwayOverride = days;
    notifyListeners();
  }

  int growthLevel = 1;
  int growthPoints = 0; // 이번 14일 도전에서 적립한 온도(=완수한 일수)
  int growthElapsedDays = 0; // 도전 시작 후 지난 일수 (1~14, 도전 전이면 0)
  static const int growthGoalPoints = StorageService.growthGoalPoints;
  static const int growthWindowDays = StorageService.growthWindowDays;
  bool justLeveledUp = false;

  // current flow
  FlowStage flowStage = FlowStage.selecting;
  ShadowCat? selectedCat;

  /// 방금 저장한(이미 확정된) 편지의 id. 편지 전송 즉시 저장되므로, 그
  /// 뒤에 이어지는 명상 단계에서 "이 편지에 명상 실천 결과를 덧붙인다"는
  /// 의미로 사용합니다. 명상을 건너뛰어도 이 값과 무관하게 편지는 이미
  /// 안전하게 저장되어 있습니다.
  String? currentLetterId;
  String? selectedMeditationKey;

  // ── 최초 1회 온보딩(편지쓰기 → 가입유도 → 알림동의 → 홈)에서 쓰는 상태 ──
  bool showFirstMeetingBanner = false;
  int? requestedTabIndex;

  // ── 유료(Basic 구독) 캐릭터 잠금 해제 상태 ──
  // Provider 상태로 들고 있어, 구독을 시작하는 즉시(재시작/재로그인 없이도)
  // 이 값을 구독하는 모든 화면(감정체크 화면 등)이 바로 리빌드되어
  // 10마리 유료 캐릭터가 즉시 잠금 해제됩니다.
  bool isPremiumUser = false;

  /// 구독 상태를 SubscriptionService에서 다시 읽어와 반영합니다.
  /// 앱 시작 시(init) 및 구독 시작/해지 직후에 호출해주세요.
  Future<void> refreshPremiumStatus() async {
    isPremiumUser = await SubscriptionService().isPremium();
    notifyListeners();
  }

  void triggerFirstMeetingBanner() {
    showFirstMeetingBanner = true;
    notifyListeners();
  }

  void dismissFirstMeetingBanner() {
    showFirstMeetingBanner = false;
    notifyListeners();
  }

  /// 홈 셸(HomeScreen)에게 특정 탭으로 이동해달라고 요청합니다.
  void requestHomeTab(int index) {
    requestedTabIndex = index;
    notifyListeners();
  }

  void clearRequestedTab() {
    requestedTabIndex = null;
  }

  /// 로그인된 사용자(userId)의 데이터 영역으로 전환한 뒤 불러옵니다.
  Future<void> init(String userId) async {
    await StorageService.setCurrentUser(userId);
    await _refreshStreakInternal();
    history = StorageService.getAllLetters();
    growthLevel = await StorageService.getGrowthLevel();
    final (points, elapsed) = await StorageService.getGrowthProgress();
    growthPoints = points;
    growthElapsedDays = elapsed;
    isPremiumUser = await SubscriptionService().isPremium();
    notifyListeners();
  }

  /// 회원가입(온보딩)을 아직 마치지 않았다면 "N일째 함께하는 중" 날짜
  /// 카운팅을 시작하지 않고 0으로 고정합니다. 회원가입 + 아기고양이
  /// 이름짓기 + 로그인을 모두 마친 시점부터 출석 스트릭이 기록됩니다.
  Future<void> _refreshStreakInternal() async {
    final signedUp = await StorageService.isOnboardingCompleted();
    if (!signedUp) {
      streak = 0;
      daysAwayOnOpen = 0;
      return;
    }
    // ⚠️ 순서 중요: daysSinceLastVisit()는 updateStreakOnOpen()이 마지막
    // 방문일을 오늘 날짜로 덮어쓰기 전에 먼저 읽어야 정확합니다.
    daysAwayOnOpen = await StorageService.daysSinceLastVisit();
    streak = await StorageService.updateStreakOnOpen();
  }

  /// 온보딩(회원가입)이 막 완료된 시점에 호출해, 그 즉시 오늘을 스트릭
  /// 1일차로 반영합니다.
  Future<void> refreshStreak() async {
    await _refreshStreakInternal();
    notifyListeners();
  }

  /// 로그아웃 시 화면 상태를 초기화합니다.
  void reset() {
    streak = 0;
    daysAwayOnOpen = 0;
    debugDaysAwayOverride = null;
    history = [];
    growthLevel = 1;
    growthPoints = 0;
    growthElapsedDays = 0;
    justLeveledUp = false;
    flowStage = FlowStage.selecting;
    selectedCat = null;
    currentLetterId = null;
    selectedMeditationKey = null;
    notifyListeners();
  }

  /// 고양이를 선택하면 사연 화면으로 이동.
  /// 안전장치: 아직 구독하지 않은 사용자가 유료 캐릭터로 이 메서드를 직접
  /// 호출하는 경로가 생기더라도(예: 과거 코드 경로), 여기서 다시 한번
  /// 막아 유료 캐릭터가 새어나가지 않도록 합니다. 정상 플로우에서는
  /// CatSelectionScreen이 이미 잠금 캐릭터의 탭을 안내 다이얼로그로
  /// 가로채므로 이 메서드까지 도달하지 않습니다.
  void selectCat(ShadowCat cat) {
    if (cat.isPremium && !isPremiumUser) return;
    selectedCat = cat;
    flowStage = FlowStage.story;
    currentLetterId = null;
    selectedMeditationKey = null;
    SoundService().playMeow();
    justLeveledUp = false;
    notifyListeners();
  }

  void backToSelecting() {
    selectedCat = null;
    flowStage = FlowStage.selecting;
    notifyListeners();
  }

  void goToLetter() {
    flowStage = FlowStage.letter;
    notifyListeners();
  }

  /// 편지를 쓰고 "보내기"를 누른 즉시(=명상/온도체크와 완전히 독립적으로)
  /// 편지를 저장하고, 마음 온도를 자동으로 +1도 올립니다. 사용자가 직접
  /// 온도 값을 입력하는 절차는 없습니다 - 편지를 보냈다는 사실 자체가
  /// 온도가 오르는 이유입니다.
  ///
  /// 저장이 끝나면 [FlowStage.meditation]으로 넘어가 "명상은 선택사항"임을
  /// 안내합니다. 이 단계에서 사용자가 명상을 하지 않고 건너뛰어도, 이미
  /// 저장된 편지와 예약된 답장에는 전혀 영향이 없습니다("통으로 묶지 않음").
  ///
  /// [moodEmoji]는 오늘의 기분을 나타내는 이모티콘(날씨처럼 고르는 선택형
  /// UI)입니다. 글쓰기가 힘들거나 귀찮을 때는 [letterText]를 비워두고
  /// [moodEmoji]만 남겨도 기록이 저장됩니다.
  Future<void> sendLetter(
    String letterText, {
    String? moodEmoji,
    required Future<void> Function() onTemperatureBonus,
  }) async {
    if (selectedCat == null) return;
    final entry = LetterEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      catId: selectedCat!.id,
      date: DateTime.now(),
      letterText: letterText,
      moodEmoji: moodEmoji,
    );
    await StorageService.saveLetter(entry);
    history = StorageService.getAllLetters();
    currentLetterId = entry.id;

    final (leveledUp, level, points, elapsed) =
        await StorageService.recordGrowthDay();
    growthLevel = level;
    growthPoints = points;
    growthElapsedDays = elapsed;
    justLeveledUp = leveledUp;

    await AnalyticsService().logEvent(AnalyticsEvents.letterSent, {
      'cat_id': entry.catId,
      'has_text': letterText.trim().isNotEmpty,
    });

    // 편지를 보냈다는 사실 자체로 마음 온도 +1도 (사용자가 값을 입력하는
    // 것이 아니라 시스템이 자동으로 처리합니다). 명상 여부와는 완전히
    // 독립적인 별개의 트리거입니다.
    await onTemperatureBonus();

    await NotificationService().notifyMissionCompletedToday();
    await NotificationService().scheduleCatReplyNotification(
      catName: selectedCat!.nameKr,
      scheduledAt: entry.replyAvailableAt,
    );

    await SoundService().playChime();
    flowStage = FlowStage.meditation;
    notifyListeners();
  }

  /// 명상 단계에서 "실천했어요"를 눌렀을 때 호출합니다. 이미 저장된 편지에
  /// 실천한 명상 키만 덧붙이고(편지 자체는 다시 저장하지 않음), 완료
  /// 화면으로 이동합니다. 온도(+1도 추가)는 [onTemperatureBonus] 콜백에서
  /// 처리하며, 이 보너스는 편지 전송 보너스와는 완전히 독립적입니다.
  Future<void> completeMeditation(
    String? meditationKey, {
    required Future<void> Function() onTemperatureBonus,
  }) async {
    selectedMeditationKey = meditationKey;
    if (currentLetterId != null && meditationKey != null) {
      await StorageService.updateLetterMeditation(
        currentLetterId!,
        meditationKey,
      );
      history = StorageService.getAllLetters();
      await onTemperatureBonus();
      await AnalyticsService().logEvent(AnalyticsEvents.meditationCompleted, {
        'meditation_key': meditationKey,
      });
    }
    flowStage = FlowStage.done;
    notifyListeners();
  }

  /// 명상 단계를 건너뜁니다. "명상은 선택이지 의무가 아니다"라는 원칙에
  /// 따라, 온도 보너스나 저장 로직 없이 그대로 완료 화면으로 넘어갑니다.
  /// 이미 저장된 편지와 예약된 답장에는 전혀 영향이 없습니다.
  void skipMeditation() {
    flowStage = FlowStage.done;
    notifyListeners();
  }

  /// 온보딩 중 쓴 첫 편지를 저장합니다. 온보딩에는 명상 단계가 없습니다.
  ///
  /// 온보딩은 앱 부트스트랩 단계(고양이를 아직 선택하지 않은 상태)에서도
  /// 트리거될 수 있으므로, [selectedCat]에 의존하지 않고 대상 고양이를
  /// 인자로 직접 받습니다.
  Future<void> saveOnboardingLetter(
    String letterText,
    ShadowCat cat, {
    String? moodEmoji,
  }) async {
    final entry = LetterEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      catId: cat.id,
      date: DateTime.now(),
      letterText: letterText,
      moodEmoji: moodEmoji,
    );
    await StorageService.saveLetter(entry);
    history = StorageService.getAllLetters();

    final (leveledUp, level, points, elapsed) =
        await StorageService.recordGrowthDay();
    growthLevel = level;
    growthPoints = points;
    growthElapsedDays = elapsed;
    justLeveledUp = leveledUp;
    await NotificationService().notifyMissionCompletedToday();
    await NotificationService().scheduleCatReplyNotification(
      catName: cat.nameKr,
      scheduledAt: entry.replyAvailableAt,
    );

    await SoundService().playChime();
    notifyListeners();
  }

  void restartFlow() {
    selectedCat = null;
    flowStage = FlowStage.selecting;
    currentLetterId = null;
    selectedMeditationKey = null;
    justLeveledUp = false;
    notifyListeners();
  }

  /// 최초 1회 온보딩(편지쓰기→가입유도→알림동의)을 마치고 홈으로 자연스럽게 이동합니다.
  void finishOnboarding() {
    selectedCat = null;
    flowStage = FlowStage.selecting;
    justLeveledUp = false;
    showFirstMeetingBanner = true;
    requestedTabIndex = 0;
    notifyListeners();
  }

  Future<void> deleteHistoryEntry(String id) async {
    await StorageService.deleteLetter(id);
    history = StorageService.getAllLetters();
    notifyListeners();
  }

  /// 방금 열어본 편지의 고양이 답장을 "읽음"으로 표시합니다.
  /// 홈 화면의 "답장이 도착했어요" 배너를 다시 띄우지 않기 위함입니다.
  Future<void> markReplySeen(String id) async {
    await StorageService.markReplySeen(id);
    history = StorageService.getAllLetters();
    notifyListeners();
  }

  /// 답장이 이미 도착했지만(다음날 아침이 지남) 아직 열어보지 않은 편지가
  /// 있다면 반환합니다(가장 최근 편지 기준). 홈 화면 "답장이 도착했어요"
  /// 배너 노출 조건으로 사용됩니다.
  LetterEntry? get letterWithUnseenReadyReply {
    for (final e in history) {
      if (e.isReplyReady && !e.replySeen) return e;
    }
    return null;
  }

  /// 지금까지 편지를 써서 만난 그림자 고양이들의 id 집합.
  /// '42 그림자 고양이 여정'의 수집 진행 상황(도감)을 계산하는 기준입니다.
  Set<String> get metCatIds => history.map((e) => e.catId).toSet();

  /// 지금까지 만난 고양이 수 (0~42)
  int get metCatCount => metCatIds.length;

  /// 특정 고양이를 이미 만난 적이 있는지
  bool hasMetCat(String catId) => metCatIds.contains(catId);

  /// 특정 고양이에게 지금까지 편지를 쓴 횟수(= 만난 횟수).
  /// 도감에서 '벌써 N번째 만남' 같은 관계 누적감을 보여주는 데 쓰입니다.
  int meetingCountFor(String catId) =>
      history.where((e) => e.catId == catId).length;

  /// 오늘 날짜에 만난 고양이(가장 최근 편지 기준)가 있다면 반환합니다.
  /// SNS 공유 카드에서 '오늘 만난 고양이'를 보여줄 때 사용합니다.
  LetterEntry? get todaysLetter {
    final now = DateTime.now();
    for (final e in history) {
      if (e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day) {
        return e;
      }
    }
    return null;
  }

  /// 오늘 기록한 모든 편지(감정체크)를 오래된 순으로 반환합니다.
  /// '오늘의 그림자 방울 터뜨리기'에서 오늘 마주한 감정(들)을 색상으로
  /// 반영할 때, 하루에 여러 번 기록했다면 그 감정들을 모두 반영하기 위해
  /// 사용합니다.
  List<LetterEntry> get todaysLetters {
    final now = DateTime.now();
    return history
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .toList()
        .reversed
        .toList();
  }

  /// 최근 7일간의 감정 기록 패턴을 반영한 정원 날씨.
  /// history를 그대로 순수 계산하므로 앱 실행 시(init 완료 후)와, 편지를
  /// 새로 저장하는 등 history가 바뀔 때마다(자정이 지나 '오늘'의 기준이
  /// 달라지는 경우도 포함) 매번 새로 계산됩니다 - 별도로 캐시하지 않아
  /// 캐시가 낡아버릴 걱정이 없습니다.
  GardenWeatherState get gardenWeather => GardenWeatherService.compute(history);

  // ── 감정 인식 루프: 주간/월간 회고(관찰 결과) ──
  // 위로가 아니라 '이런 패턴이 있었다'는 관찰을 제시하기 위한 순수 집계
  // 로직입니다. 좋다/나쁘다 판단 없이 빈도와 흐름만 계산합니다.

  /// 기준 시각(now)으로부터 최근 [days]일간(오늘 포함)의 편지만 골라냅니다.
  List<LetterEntry> _entriesWithinDays(int days, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final cutoff = todayStart.subtract(Duration(days: days - 1));
    return history.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(cutoff) && !d.isAfter(todayStart);
    }).toList();
  }

  /// 최근 7일간 고양이 선택 빈도(catId → 횟수)를 계산합니다.
  Map<String, int> weeklyCatFrequency({DateTime? now}) {
    final entries = _entriesWithinDays(7, now: now);
    final freq = <String, int>{};
    for (final e in entries) {
      freq[e.catId] = (freq[e.catId] ?? 0) + 1;
    }
    return freq;
  }

  /// 최근 7일간 가장 자주 나타난 그림자 고양이의 id.
  /// 편지가 없다면 null을 반환합니다(회고 화면에서 '아직 데이터가 부족해요' 처리용).
  String? get mostFrequentCatIdThisWeek {
    final freq = weeklyCatFrequency();
    if (freq.isEmpty) return null;
    String? topId;
    int topCount = -1;
    freq.forEach((catId, count) {
      if (count > topCount) {
        topCount = count;
        topId = catId;
      }
    });
    return topId;
  }

  /// 최근 7일간 기록된 편지 수(=감정을 마주한 횟수).
  int get weeklyEntryCount => _entriesWithinDays(7).length;

  /// 최근 7일을 오래된 날짜→오늘 순으로, (날짜, 그날 대표 고양이 id) 목록으로 반환합니다.
  /// 하루에 여러 번 기록했다면 그 날 가장 마지막(최신)에 선택한 고양이를 대표로 삼습니다.
  /// 기록이 없는 날은 catId가 null입니다(화면에서는 '미기록'이 아니라 빈 칸으로만 표시).
  List<MapEntry<DateTime, String?>> last7DaysCatIds({DateTime? now}) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final result = <MapEntry<DateTime, String?>>[];
    for (int i = 6; i >= 0; i--) {
      final day = todayStart.subtract(Duration(days: i));
      String? catId;
      for (final e in history) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        if (d == day) {
          // history는 이미 최신순이라 이 날짜의 첫 항목이 그 날의 가장 최근 기록입니다.
          catId = e.catId;
          break;
        }
      }
      result.add(MapEntry(day, catId));
    }
    return result;
  }

  /// 최근 7일 중 실제로 기록이 있었던 날의 수(= 관찰 결과의 'M'에 해당).
  int get weeklyRecordedDayCount =>
      last7DaysCatIds().where((e) => e.value != null).length;

  // ── 주간 그림자 지도(무료: Top 3 / 프리미엄: 비교·패턴 인사이트) ──
  // 아래 게터들은 WeeklyShadowMapService(순수 계산)에 history/weeklyCatFrequency를
  // 그대로 전달하는 얇은 래퍼입니다. 캐시하지 않으므로 history가 바뀔 때마다
  // (자정 경과, 새 편지 저장 등) 항상 최신 상태로 재계산됩니다.

  /// 이번 주 가장 자주 등장한 감정 Top 3: (catId, 횟수) 목록(무료 티어).
  List<(String, int)> get weeklyTopEmotions =>
      WeeklyShadowMapService.topEmotionsThisWeek(weeklyCatFrequency());

  /// 이번 달 vs 지난 달 빈도 비교(프리미엄 티어).
  (Map<String, int>, Map<String, int>) get monthVsLastMonthFrequency =>
      WeeklyShadowMapService.compareThisMonthVsLastMonth(history);

  /// 이번 분기 vs 지난 분기 빈도 비교(프리미엄 티어).
  (Map<String, int>, Map<String, int>) get quarterVsLastQuarterFrequency =>
      WeeklyShadowMapService.compareThisQuarterVsLastQuarter(history);

  /// '다시 떠오른 감정' 인사이트(프리미엄 티어)의 원본 데이터. '묻어두기'
  /// 기능의 전체 기록(BuriedEmotionService)을 그대로 노출하는 얇은 래퍼로,
  /// 캐시하지 않고 호출 시점마다 최신 기록을 반환합니다. 문장 생성은
  /// WeeklyShadowMapService.buriedResurfaceTrendSentence()에서 담당합니다.
  List<BuriedEmotionEntry> get buriedEmotionEntries =>
      BuriedEmotionService.getAllEntries();

  /// 최근 4주(28일)간, 1주 단위로 가장 빈번했던 고양이 id 목록을 시간순으로
  /// 반환합니다(0번째=4주 전 주, 3번째=이번 주). 데이터가 없는 주는 null.
  List<String?> monthlyWeeklyDominantCatIds({DateTime? now}) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final result = <String?>[];
    for (int w = 3; w >= 0; w--) {
      final weekEnd = todayStart.subtract(Duration(days: w * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final weekEntries = history.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
      });
      final freq = <String, int>{};
      for (final e in weekEntries) {
        freq[e.catId] = (freq[e.catId] ?? 0) + 1;
      }
      if (freq.isEmpty) {
        result.add(null);
        continue;
      }
      String? topId;
      int topCount = -1;
      freq.forEach((catId, count) {
        if (count > topCount) {
          topCount = count;
          topId = catId;
        }
      });
      result.add(topId);
    }
    return result;
  }

  /// 지정한 기간(양끝 포함, 날짜 단위) 안에서 가장 빈번했던 그림자 고양이 id.
  String? _dominantCatIdInRange(DateTime start, DateTime end) {
    final entries = history.where((e) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      return !d.isBefore(start) && !d.isAfter(end);
    });
    final freq = <String, int>{};
    for (final e in entries) {
      freq[e.catId] = (freq[e.catId] ?? 0) + 1;
    }
    if (freq.isEmpty) return null;
    String? topId;
    int topCount = -1;
    freq.forEach((catId, count) {
      if (count > topCount) {
        topCount = count;
        topId = catId;
      }
    });
    return topId;
  }

  /// 이번 달(최근 28일)을 전반부(1~2주)/후반부(3~4주)로 나눠 각각 최빈 고양이 id를
  /// 반환합니다. 월간 회고 화면3의 서술형 요약(변화 있음/없음 비교)에 사용합니다.
  (String?, String?) monthlyHalvesDominantCatIds({DateTime? now}) {
    final ref = now ?? DateTime.now();
    final todayStart = DateTime(ref.year, ref.month, ref.day);
    final periodEnd = todayStart;
    final periodStart = todayStart.subtract(const Duration(days: 27));
    final firstHalfEnd = periodStart.add(const Duration(days: 13));
    final secondHalfStart = periodStart.add(const Duration(days: 14));
    final firstHalf = _dominantCatIdInRange(periodStart, firstHalfEnd);
    final secondHalf = _dominantCatIdInRange(secondHalfStart, periodEnd);
    return (firstHalf, secondHalf);
  }

  /// 이번 달(달력 기준) 동안 만난 그림자 고양이 id들을, 처음 만난 순서(오래된 날부터)로
  /// 중복 없이 반환합니다. 리플렉션 레터에서 '이번 달 순서대로 등장'시키는 데 사용합니다.
  List<String> catIdsMetThisMonth({DateTime? now}) {
    final ref = now ?? DateTime.now();
    final monthEntries =
        history
            .where((e) => e.date.year == ref.year && e.date.month == ref.month)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final seen = <String>{};
    final ordered = <String>[];
    for (final e in monthEntries) {
      if (seen.add(e.catId)) ordered.add(e.catId);
    }
    return ordered;
  }

  /// 이번 달에 기록된 편지가 하나라도 있는지 여부(월간 회고 진입 가능 조건에 사용).
  bool hasAnyEntryThisMonth({DateTime? now}) {
    final ref = now ?? DateTime.now();
    return history.any(
      (e) => e.date.year == ref.year && e.date.month == ref.month,
    );
  }
}
