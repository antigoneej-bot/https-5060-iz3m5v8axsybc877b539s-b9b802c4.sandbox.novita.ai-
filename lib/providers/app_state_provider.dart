import 'package:flutter/material.dart';
import '../models/shadow_cat.dart';
import '../models/letter_entry.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';

/// 명상 저널 플로우 단계
/// selecting: 7마리 중 지금 내 기분과 닮은 고양이 선택
/// story: 고양이의 사연(제3자 시점) + 실천 전 마음 온도 체크
/// letter: 고양이에게 편지 쓰기 (위로 + 해결 방법)
/// meditation: 추천 명상/움직임 중 선택해서 실천
/// tempCheck: 실천 후 마음 온도 체크
/// done: 완료 화면 (레벨업 여부 안내)
enum FlowStage { selecting, story, letter, meditation, tempCheck, done }

class AppStateProvider extends ChangeNotifier {
  int streak = 0;
  List<LetterEntry> history = [];

  int growthLevel = 1;
  int growthPoints = 0; // 이번 14일 도전에서 적립한 온도(=완수한 일수)
  int growthElapsedDays = 0; // 도전 시작 후 지난 일수 (1~14, 도전 전이면 0)
  static const int growthGoalPoints = StorageService.growthGoalPoints;
  static const int growthWindowDays = StorageService.growthWindowDays;
  bool justLeveledUp = false;

  // current flow
  FlowStage flowStage = FlowStage.selecting;
  ShadowCat? selectedCat;

  double tempBefore = 50;
  double tempAfter = 50;
  String? selectedMeditationKey;

  // ── 최초 1회 온보딩(편지쓰기 → 가입유도 → 알림동의 → 홈)에서 쓰는 상태 ──
  bool showFirstMeetingBanner = false;
  int? requestedTabIndex;

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
    streak = await StorageService.updateStreakOnOpen();
    history = StorageService.getAllLetters();
    growthLevel = await StorageService.getGrowthLevel();
    final (points, elapsed) = await StorageService.getGrowthProgress();
    growthPoints = points;
    growthElapsedDays = elapsed;
    notifyListeners();
  }

  /// 로그아웃 시 화면 상태를 초기화합니다.
  void reset() {
    streak = 0;
    history = [];
    growthLevel = 1;
    growthPoints = 0;
    growthElapsedDays = 0;
    justLeveledUp = false;
    flowStage = FlowStage.selecting;
    selectedCat = null;
    tempBefore = 50;
    tempAfter = 50;
    selectedMeditationKey = null;
    notifyListeners();
  }

  /// 고양이를 선택하면 사연 화면으로 이동
  void selectCat(ShadowCat cat) {
    selectedCat = cat;
    flowStage = FlowStage.story;
    tempBefore = 50;
    tempAfter = 50;
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

  void setTempBefore(double v) {
    tempBefore = v;
    notifyListeners();
  }

  void goToLetter() {
    flowStage = FlowStage.letter;
    notifyListeners();
  }

  void goToMeditation() {
    flowStage = FlowStage.meditation;
    notifyListeners();
  }

  void setSelectedMeditationKey(String? key) {
    selectedMeditationKey = key;
    notifyListeners();
  }

  void goToTempCheck() {
    tempAfter = tempBefore;
    flowStage = FlowStage.tempCheck;
    notifyListeners();
  }

  void setTempAfter(double v) {
    tempAfter = v;
    notifyListeners();
  }

  /// 편지를 저장하고, 오늘의 미션 완수를 성장 온도로 기록합니다.
  /// 마음은 늘 오르기만 하지 않으므로, 실제 온도 변화와 무관하게
  /// '오늘 미션(편지+명상)을 완수했는가'만으로 하루 1도씩 적립됩니다.
  Future<void> saveLetterAndFinish(String letterText) async {
    if (selectedCat == null) return;
    final entry = LetterEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      catId: selectedCat!.id,
      date: DateTime.now(),
      letterText: letterText,
      tempBefore: tempBefore,
      tempAfter: tempAfter,
      meditationKey: selectedMeditationKey,
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

    await SoundService().playChime();
    flowStage = FlowStage.done;
    notifyListeners();
  }

  /// 온보딩 중 쓴 첫 편지를 저장합니다. 온보딩에는 명상 단계가 없어
  /// 마음 온도는 편지 쓰기 전 값 그대로 유지됩니다.
  Future<void> saveOnboardingLetter(String letterText) async {
    if (selectedCat == null) return;
    final entry = LetterEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      catId: selectedCat!.id,
      date: DateTime.now(),
      letterText: letterText,
      tempBefore: tempBefore,
      tempAfter: tempBefore,
      meditationKey: null,
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

    await SoundService().playChime();
    notifyListeners();
  }

  void restartFlow() {
    selectedCat = null;
    flowStage = FlowStage.selecting;
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

  /// 지금까지 편지를 써서 만난 그림자 고양이들의 id 집합.
  /// '36 그림자 고양이 여정'의 수집 진행 상황(도감)을 계산하는 기준입니다.
  Set<String> get metCatIds => history.map((e) => e.catId).toSet();

  /// 지금까지 만난 고양이 수 (0~36)
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
}
