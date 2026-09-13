import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../models/daily_draw_entry.dart';
import 'storage_service.dart';

/// 데일리 내면소통 - 타로카드처럼 42마리 고양이 카드를 스프레드에서 골라
/// 오늘의 위로와 지침을 받는 기능. 하루에 한 번만 뽑을 수 있습니다.
///
/// v2부터는 매일 뽑힌 카드를 [StorageService]의 daily draw 히스토리에도
/// 영구적으로 남깁니다('오늘 이미 뽑았는지' 판단용 SharedPreferences 값은
/// 그대로 유지하되, 별도로 Hive에 전체 기록을 축적합니다). 이 히스토리는
/// 완전 무작위(무의식)로 뽑힌 고양이를 시간이 지나도 돌이켜볼 수 있게
/// 해주며, 동시성 비교/반복되는 그림자 관찰에 사용됩니다.
class DailyCardService {
  static String _uid = 'guest';

  static void setCurrentUser(String userId) {
    _uid = userId;
  }

  static void clearCurrentUser() {
    _uid = 'guest';
  }

  static String get _lastDrawDateKey => '${_uid}_daily_card_last_date';
  static String get _lastDrawCatIdKey => '${_uid}_daily_card_last_cat_id';

  static String _dateOnlyString(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String? _normalizeStoredDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw.trim());
    if (m != null) {
      return '${m.group(1)}-${m.group(2)}-${m.group(3)}';
    }
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return _dateOnlyString(d);
  }

  /// 오늘 이미 카드를 뽑았는지 확인합니다.
  static Future<bool> hasDrawnToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = _normalizeStoredDay(prefs.getString(_lastDrawDateKey));
    return lastDate == _dateOnlyString(DateTime.now());
  }

  /// 오늘 이미 뽑은 카드가 있다면 그 카드를 반환합니다 (없으면 null).
  static Future<ShadowCat?> getTodayCard() async {
    final already = await hasDrawnToday();
    if (!already) return null;
    final prefs = await SharedPreferences.getInstance();
    final catId = prefs.getString(_lastDrawCatIdKey);
    if (catId == null) return null;
    try {
      return shadowCatById(catId);
    } catch (_) {
      return null;
    }
  }

  /// 사용자가 스프레드에서 카드를 골랐을 때 호출합니다.
  /// 오늘 이미 뽑았다면 처음 뽑았던 카드를 그대로 반환합니다 (하루 1회 제한).
  static Future<ShadowCat> drawCard() async {
    final existing = await getTodayCard();
    if (existing != null) return existing;

    // 보류(reserved)된 캐릭터와 유료(Basic 구독) 캐릭터는 데일리
    // 카드뽑기(무의식/무작위)에서도 제외합니다. 무료 사용자가 결제 없이
    // 무작위로 유료 캐릭터를 뽑게 되는 우회 경로를 막기 위함입니다.
    final drawable = shadowCats
        .where((c) => c.selectable && !c.isPremium)
        .toList();
    final rand = Random();
    final cat = drawable[rand.nextInt(drawable.length)];

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDrawDateKey, _dateOnlyString(now));
    await prefs.setString(_lastDrawCatIdKey, cat.id);

    // v2: 히스토리 영구 기록 (동시성 비교 · 반복되는 그림자 관찰용)
    final dayKey = DateTime(now.year, now.month, now.day).toIso8601String();
    await StorageService.saveDailyDraw(
      DailyDrawEntry(id: dayKey, catId: cat.id, date: now),
    );

    return cat;
  }

  /// 지금까지 축적된 데일리 카드뽑기(무의식) 히스토리 전체를 최신순으로
  /// 반환합니다. 동시성 비교/반복되는 그림자 계산에 사용합니다.
  static List<DailyDrawEntry> getAllDraws() {
    return StorageService.getAllDailyDraws();
  }
}
