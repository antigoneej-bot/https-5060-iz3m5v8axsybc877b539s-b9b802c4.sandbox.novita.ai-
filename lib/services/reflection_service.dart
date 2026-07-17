import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/daily_draw_entry.dart';
import 'storage_service.dart';

/// 감정 인식 루프: 주간/월간 회고의 '진입 조건 판단'과 '규칙 기반 문장 생성'을
/// 담당하는 서비스. 그래프/차트보다 문장형 서술을 우선하고, 위로/평가 언어를
/// 절대 쓰지 않는다는 앱 전체 원칙을 이 서비스에서 지킵니다.
///
/// 회고 데이터는 로컬(Hive/SharedPreferences)에만 저장되며 제3자와 공유하지
/// 않습니다.
class ReflectionService {
  ReflectionService._();

  /// 오늘 기준 이번 주를 식별하는 키('yyyy-MM-dd', 이번 주 월요일 날짜).
  /// 자동 노출 배너를 '이번 주 안에서는 한 번만' 보여주는 데 사용합니다.
  static String weekKeyFor(DateTime now) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime(monday.year, monday.month, monday.day));
  }

  /// 오늘 기준 이번 달을 식별하는 키('yyyy-MM').
  static String monthKeyFor(DateTime now) => DateFormat('yyyy-MM').format(now);

  /// 가입 후 7일이 지났는지 여부 (주간 회고 자동 노출 조건 중 하나).
  static Future<bool> isWeeklyReflectionDue() async {
    final days = await StorageService.daysSinceInstall();
    return days >= 7;
  }

  /// 가입 후 30일이 지났는지, 혹은 오늘이 이달 1일인지 여부
  /// (월간 회고 자동 노출 조건).
  static Future<bool> isMonthlyReflectionDue({DateTime? now}) async {
    final ref = now ?? DateTime.now();
    final days = await StorageService.daysSinceInstall(now: ref);
    if (ref.day == 1) return true;
    return days >= 30;
  }

  /// 자동 노출 배너(홈 화면)를 지금 보여줘야 하는지 여부.
  /// - 데이터가 최소 1건이라도 있어야 함(관찰할 것이 있어야 하므로)
  /// - 이미 이번 주/이번 달에 봤다면 다시 강제로 띄우지 않음
  ///   (사용자가 직접 들어와 보는 것은 언제든 가능, 이 조건과 무관)
  static Future<bool> shouldShowWeeklyBanner(
    AppStateProvider app, {
    DateTime? now,
  }) async {
    final ref = now ?? DateTime.now();
    if (app.weeklyEntryCount == 0) return false;
    final due = await isWeeklyReflectionDue();
    if (!due) return false;
    final key = weekKeyFor(ref);
    final seen = await StorageService.hasSeenWeeklyReflection(key);
    return !seen;
  }

  static Future<bool> shouldShowMonthlyBanner(
    AppStateProvider app, {
    DateTime? now,
  }) async {
    final ref = now ?? DateTime.now();
    if (!app.hasAnyEntryThisMonth(now: ref)) return false;
    final due = await isMonthlyReflectionDue(now: ref);
    if (!due) return false;
    final key = monthKeyFor(ref);
    final seen = await StorageService.hasSeenMonthlyReflection(key);
    return !seen;
  }

  static Future<void> markWeeklySeen({DateTime? now}) async {
    final ref = now ?? DateTime.now();
    await StorageService.markWeeklyReflectionSeen(weekKeyFor(ref));
  }

  static Future<void> markMonthlySeen({DateTime? now}) async {
    final ref = now ?? DateTime.now();
    await StorageService.markMonthlyReflectionSeen(monthKeyFor(ref));
  }

  /// 고양이 id로 한글 이름을 찾습니다. 도감에 없는 id면 빈 문자열.
  static String catNameFor(String? catId) {
    if (catId == null) return '';
    return shadowCatById(catId).nameKr;
  }

  /// 화면3(월간 서술형 요약)의 문장을 규칙 기반(빈도 비교 + 템플릿)으로
  /// 생성합니다. AI 생성 없이, 전반부/후반부 최빈 고양이를 비교해 딱 두 갈래
  /// 템플릿 중 하나를 고릅니다. 위로·평가형 표현은 절대 포함하지 않습니다.
  static String buildMonthlySummarySentence({
    required String? firstHalfCatId,
    required String? secondHalfCatId,
  }) {
    if (firstHalfCatId == null && secondHalfCatId == null) {
      return '이번 달은 아직 기록이 충분하지 않아요. 편지를 몇 번 더 써보면\n흐름을 함께 살펴볼 수 있어요.';
    }
    if (firstHalfCatId == null) {
      final b = catNameFor(secondHalfCatId);
      return '이번 달, 당신은 $b와 함께했어요.';
    }
    if (secondHalfCatId == null) {
      final a = catNameFor(firstHalfCatId);
      return '이번 달, 당신은 $a와 함께했어요.';
    }
    if (firstHalfCatId == secondHalfCatId) {
      final a = catNameFor(firstHalfCatId);
      return '이번 달, 당신은 꾸준히 $a와 함께했어요.';
    }
    final a = catNameFor(firstHalfCatId);
    final b = catNameFor(secondHalfCatId);
    return '이번 달, 당신의 감정은 초반엔 $a에서\n후반엔 $b로 흘러갔어요.';
  }

  // ── 데일리 카드뽑기(무의식) 발전: 동시성 비교 · 반복되는 그림자 ──
  // 의식(직접 선택한 편지의 고양이)과 무의식(완전 무작위 카드뽑기 결과)을
  // 나란히 두고 관찰하는 기능입니다. 위로/평가 언어는 쓰지 않고, '같았다/
  // 달랐다'는 사실만 서술합니다.

  /// 오늘 '의식적으로 선택한' 고양이(편지)와 '무의식이 보여준' 고양이(카드뽑기)가
  /// 같았는지 다른지를 문장으로 만듭니다. 둘 중 하나라도 없으면 null.
  static String? synchronicitySentence({
    required String? consciousCatId,
    required String? unconsciousCatId,
  }) {
    if (consciousCatId == null || unconsciousCatId == null) return null;
    if (consciousCatId == unconsciousCatId) {
      final name = catNameFor(consciousCatId);
      return '오늘 편지에서 고른 마음과, 무작위로 뽑힌 카드가\n똑같이 $name였어요. 의식과 무의식이 같은 곳을 보고 있었나 봐요.';
    }
    final a = catNameFor(consciousCatId);
    final b = catNameFor(unconsciousCatId);
    return '오늘 편지에서는 $a를 골랐지만,\n무작위로 뽑힌 카드는 $b였어요. 서로 다른 결을 보여준 하루예요.';
  }

  /// 이번 달(달력 기준) 안에서 뽑힌 데일리 카드(무의식)만 골라냅니다.
  static List<DailyDrawEntry> drawsThisMonth(
    List<DailyDrawEntry> draws, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    return draws
        .where((d) => d.date.year == ref.year && d.date.month == ref.month)
        .toList();
  }

  /// 이번 달 데일리 카드뽑기(무의식) 결과의 고양이별 빈도(catId → 횟수).
  static Map<String, int> monthlyDrawFrequency(
    List<DailyDrawEntry> draws, {
    DateTime? now,
  }) {
    final entries = drawsThisMonth(draws, now: now);
    final freq = <String, int>{};
    for (final e in entries) {
      freq[e.catId] = (freq[e.catId] ?? 0) + 1;
    }
    return freq;
  }

  /// 이번 달 무의식(카드뽑기)에서 같은 그림자가 threshold회 이상 반복해서
  /// 나타났다면, 그 사실을 알려주는 문장을 만듭니다. 없으면 null.
  /// (위로/평가 없이 '몇 번 나타났다'는 관찰만 전달합니다)
  static String? repeatedShadowSentence(
    List<DailyDrawEntry> draws, {
    DateTime? now,
    int threshold = 3,
  }) {
    final freq = monthlyDrawFrequency(draws, now: now);
    if (freq.isEmpty) return null;
    String? topId;
    int topCount = -1;
    freq.forEach((catId, count) {
      if (count > topCount) {
        topCount = count;
        topId = catId;
      }
    });
    if (topId == null || topCount < threshold) return null;
    final name = catNameFor(topId);
    return '이번 달 무작위 카드뽑기에서 $name가 $topCount번\n나타났어요. 무의식이 자꾸 같은 그림자를 보여주고 있어요.';
  }
}
