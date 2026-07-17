import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter_entry.dart';
import 'cat_care_service.dart';

/// '오늘의 그림자 방울 터뜨리기' - 감정체크(편지쓰기)를 마친 뒤에만 열리는
/// 하루 1회 짜리 작은 의식(ritual)을 관리하는 서비스.
///
/// 핵심 규칙:
/// - 오늘 감정체크를 하지 않았다면 방울이 생기지 않습니다(오락이 아니라
///   "오늘 기록한 감정을 해소하는 의식"이기 때문에, 감정체크를 대체하지
///   않고 반드시 선행 조건으로 둡니다).
/// - 하루에 딱 한 번만 방울밭이 만들어지며, 그날 다 터뜨리지 않아도
///   다음날로 이어지지 않습니다(그날의 그림자는 그날 안에서만 다룬다는
///   컨셉을 지키기 위함).
/// - 포인트는 구독 여부와 무관하게 누구나 모을 수 있고, 코스메틱(옷/장식/
///   가구) 상점에서만 쓸 수 있습니다. 프리미엄 리포트·저널 확장·명상
///   콘텐츠 등 핵심 기능 잠금 해제에는 절대 쓰이지 않습니다.
class BubbleGardenService {
  static String _uid = 'guest';

  static void setCurrentUser(String userId) {
    _uid = userId;
  }

  static void clearCurrentUser() {
    _uid = 'guest';
  }

  static String get _lastSessionDateKey => '${_uid}_bubble_last_date';
  static String get _sessionCatIdsKey => '${_uid}_bubble_session_cat_ids';
  static String get _poppedIndicesKey => '${_uid}_bubble_popped_indices';

  static String _dateOnlyString(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();

  /// 방울 하나를 터뜨렸을 때 얻는 포인트(경쟁/등급 개념 없이 항상 동일).
  static const int pointsPerBubble = 1;

  /// 최소/최대 방울 개수. 감정 강도(=오늘 기록한 글자 수/기록 횟수)에 따라
  /// 이 범위 안에서 스케일됩니다.
  static const int minBubbles = 3;
  static const int maxBubbles = 7;

  /// 오늘 이미 방울밭 세션을 만들었는지 여부.
  static Future<bool> hasSessionToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastSessionDateKey);
    return lastDate == _dateOnlyString(DateTime.now());
  }

  /// 오늘 세션에서 이미 터뜨린 방울들의 순번(index) 집합.
  static Future<Set<int>> getPoppedIndicesToday() async {
    final already = await hasSessionToday();
    if (!already) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_poppedIndicesKey) ?? [];
    return raw.map((s) => int.tryParse(s) ?? -1).where((i) => i >= 0).toSet();
  }

  /// 오늘 세션에 속한 방울들의 catId 목록(색상 결정용)을 반환합니다.
  /// 세션이 없다면 빈 목록.
  static Future<List<String>> getSessionCatIdsToday() async {
    final already = await hasSessionToday();
    if (!already) return [];
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_sessionCatIdsKey) ?? [];
  }

  /// 감정 강도(오늘 기록한 편지들)를 바탕으로 방울 개수를 계산합니다.
  /// - 편지를 여러 번 남겼다면(하루 중 여러 번 기록) 그만큼 감정을 많이
  ///   마주한 것으로 보아 방울이 조금 더 많아집니다.
  /// - 글자 수가 많을수록(마음을 많이 적어낼수록) 방울이 조금 더 많아집니다.
  /// - 항상 [minBubbles]~[maxBubbles] 사이로 제한됩니다.
  static int _bubbleCountFor(List<LetterEntry> todaysLetters) {
    if (todaysLetters.isEmpty) return minBubbles;
    final totalLength = todaysLetters.fold<int>(
      0,
      (sum, e) => sum + e.letterText.length,
    );
    final entryBonus = (todaysLetters.length - 1).clamp(0, 2);
    final lengthBonus = (totalLength / 40).floor().clamp(0, 2);
    final count = minBubbles + entryBonus + lengthBonus;
    return count.clamp(minBubbles, maxBubbles);
  }

  /// 오늘 감정체크(편지)에서 등장한 고양이 id들을 순환시켜 방울마다
  /// 하나씩 배정합니다. 감정체크가 하나뿐이라면 모든 방울이 같은 색을
  /// 입고, 여러 감정을 마주한 날이라면 그 감정들이 골고루 섞입니다.
  static List<String> _assignCatIds(
    List<LetterEntry> todaysLetters,
    int count,
  ) {
    final catIds = todaysLetters.map((e) => e.catId).toList();
    if (catIds.isEmpty) return List.filled(count, '');
    final rand = Random(DateTime.now().day + count);
    // 오늘 마주한 감정들을 살짝 무작위로 섞어 방울마다 배정합니다.
    final shuffled = List<String>.from(catIds)..shuffle(rand);
    return List.generate(count, (i) => shuffled[i % shuffled.length]);
  }

  /// 오늘 감정체크를 마쳤다면(=[todaysLetters]가 비어있지 않다면) 오늘의
  /// 방울밭 세션을 새로 만들거나, 이미 만들어져 있다면 그 세션을 그대로
  /// 반환합니다(하루 1회, 멱등적). 감정체크가 없다면 빈 목록을 반환합니다.
  static Future<List<String>> ensureSessionToday(
    List<LetterEntry> todaysLetters,
  ) async {
    if (todaysLetters.isEmpty) return [];
    final already = await hasSessionToday();
    if (already) return getSessionCatIdsToday();

    final count = _bubbleCountFor(todaysLetters);
    final catIds = _assignCatIds(todaysLetters, count);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSessionDateKey, _dateOnlyString(DateTime.now()));
    await prefs.setStringList(_sessionCatIdsKey, catIds);
    await prefs.setStringList(_poppedIndicesKey, []);
    return catIds;
  }

  /// 방울 하나를 터뜨립니다. 이미 터뜨린 방울이면 아무 일도 하지 않고
  /// 현재 포인트만 반환합니다. 새로 터뜨린 방울이면 포인트가 적립됩니다
  /// (구독 여부와 무관하게 누구나 적립되는, 코스메틱 전용 포인트입니다).
  /// 반환값: (적립 후 총 포인트, 이번에 새로 터뜨렸는지 여부)
  static Future<(int, bool)> popBubble(int index) async {
    final popped = await getPoppedIndicesToday();
    if (popped.contains(index)) {
      final points = await CatCareService.getPoints();
      return (points, false);
    }
    final prefs = await SharedPreferences.getInstance();
    final next = {...popped, index};
    await prefs.setStringList(
      _poppedIndicesKey,
      next.map((i) => i.toString()).toList(),
    );
    final newPoints = await CatCareService.awardBonusPoints(pointsPerBubble);
    return (newPoints, true);
  }
}
