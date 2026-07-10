import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';

/// 데일리 내면소통 - 타로카드처럼 36마리 고양이 카드를 스프레드에서 골라
/// 오늘의 위로와 지침을 받는 기능. 하루에 한 번만 뽑을 수 있습니다.
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

  static String _dateOnlyString(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();

  /// 오늘 이미 카드를 뽑았는지 확인합니다.
  static Future<bool> hasDrawnToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastDrawDateKey);
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

    final rand = Random();
    final cat = shadowCats[rand.nextInt(shadowCats.length)];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDrawDateKey, _dateOnlyString(DateTime.now()));
    await prefs.setString(_lastDrawCatIdKey, cat.id);
    return cat;
  }
}
