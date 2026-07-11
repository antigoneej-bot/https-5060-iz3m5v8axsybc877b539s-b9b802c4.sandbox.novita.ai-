import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat_care_state.dart';

/// 다마고치식 '마음 돌보기' 데이터를 계정별로 관리하는 서비스.
/// 몸을 돌보는 4가지(밥주기·물주기·목욕시키기·청소하기)와
/// 마음을 돌보는 4가지(호흡명상·걷기명상·마음기록·감사 3가지 쓰기)를 모두 완료하면
/// 마음 온도가 유지/상승하고, 하루라도 돌보지 않고 지나가면(자정 기준) 마음 온도가 1도씩 내려갑니다.
/// 정성껏 모두 돌본 날이 누적될수록 반려 고양이는 아기 → 청년 → 성체로 자라납니다.
class CatCareService {
  static String _uid = 'guest';
  static const int maxTemperature = 100;
  static const int minTemperature = 0;
  static const int startTemperature = 70;

  static void setCurrentUser(String userId) {
    _uid = userId;
  }

  static void clearCurrentUser() {
    _uid = 'guest';
  }

  static String get _tempKey => '${_uid}_care_temperature';
  static String get _lastCareDateKey => '${_uid}_care_last_date';
  static String get _fedKey => '${_uid}_care_fed_today';
  static String get _wateredKey => '${_uid}_care_watered_today';
  static String get _bathedKey => '${_uid}_care_bathed_today';
  static String get _cleanedKey => '${_uid}_care_cleaned_today';
  static String get _breathingKey => '${_uid}_care_breathing_today';
  static String get _walkingKey => '${_uid}_care_walking_today';
  static String get _journalingKey => '${_uid}_care_journaling_today';
  static String get _gratitudeKey => '${_uid}_care_gratitude_today';
  static String get _companionKey => '${_uid}_care_companion_cat_id';
  static String get _growthDaysKey => '${_uid}_care_growth_days';

  static String _dateOnlyString(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String();

  /// 화면 진입 시 항상 먼저 호출해서, 날짜가 바뀌었는지 확인하고
  /// 어제 돌보지 못한 만큼 온도를 내린 뒤 오늘 체크리스트를 초기화합니다.
  static Future<CatCareState> loadAndApplyDailyDecay({
    required String defaultCompanionCatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _dateOnlyString(DateTime.now());
    final lastDateStr = prefs.getString(_lastCareDateKey);

    int temperature = prefs.getInt(_tempKey) ?? startTemperature;
    String companionId =
        prefs.getString(_companionKey) ?? defaultCompanionCatId;
    if (prefs.getString(_companionKey) == null) {
      await prefs.setString(_companionKey, companionId);
    }

    if (lastDateStr == null) {
      // 첫 방문: 오늘부터 시작 (아기 고양이 단계)
      await prefs.setString(_lastCareDateKey, todayStr);
      await prefs.setInt(_tempKey, temperature);
      if (prefs.getInt(_growthDaysKey) == null) {
        await prefs.setInt(_growthDaysKey, 0);
      }
    } else if (lastDateStr != todayStr) {
      final lastDate = DateTime.parse(lastDateStr);
      final missedDays = DateTime.now()
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;
      // 어제 하루를 다 못 돌봤다면(8가지 미션 중 하나라도 안 했으면) 그만큼 온도 하락
      final wasFullyCaredYesterday =
          (prefs.getBool(_fedKey) ?? false) &&
          (prefs.getBool(_wateredKey) ?? false) &&
          (prefs.getBool(_bathedKey) ?? false) &&
          (prefs.getBool(_cleanedKey) ?? false) &&
          (prefs.getBool(_breathingKey) ?? false) &&
          (prefs.getBool(_walkingKey) ?? false) &&
          (prefs.getBool(_journalingKey) ?? false) &&
          (prefs.getBool(_gratitudeKey) ?? false);

      int daysMissed = missedDays;
      if (wasFullyCaredYesterday && missedDays > 0) {
        daysMissed = missedDays - 1; // 마지막으로 기록된 날은 이미 다 돌봤으므로 하락 대상에서 제외
      }
      if (daysMissed > 0) {
        temperature = (temperature - daysMissed).clamp(
          minTemperature,
          maxTemperature,
        );
      }

      // 오늘 체크리스트 초기화
      await prefs.setBool(_fedKey, false);
      await prefs.setBool(_wateredKey, false);
      await prefs.setBool(_bathedKey, false);
      await prefs.setBool(_cleanedKey, false);
      await prefs.setBool(_breathingKey, false);
      await prefs.setBool(_walkingKey, false);
      await prefs.setBool(_journalingKey, false);
      await prefs.setBool(_gratitudeKey, false);
      await prefs.setString(_lastCareDateKey, todayStr);
      await prefs.setInt(_tempKey, temperature);
    }

    return CatCareState(
      temperature: prefs.getInt(_tempKey) ?? startTemperature,
      fedToday: prefs.getBool(_fedKey) ?? false,
      wateredToday: prefs.getBool(_wateredKey) ?? false,
      bathedToday: prefs.getBool(_bathedKey) ?? false,
      cleanedToday: prefs.getBool(_cleanedKey) ?? false,
      breathingDoneToday: prefs.getBool(_breathingKey) ?? false,
      walkingDoneToday: prefs.getBool(_walkingKey) ?? false,
      journalingDoneToday: prefs.getBool(_journalingKey) ?? false,
      gratitudeDoneToday: prefs.getBool(_gratitudeKey) ?? false,
      companionCatId: prefs.getString(_companionKey) ?? defaultCompanionCatId,
      growthDays: prefs.getInt(_growthDaysKey) ?? 0,
    );
  }

  /// 8가지 돌봄 미션(몸 4가지 + 마음 4가지) 중 하나를 완료 처리합니다.
  /// 여덜 가지를 모두 마치면 온도가 3도 오르고(최대 100), 성장 일수가 하루 늘어납니다.
  static Future<CatCareState> completeTask(CareTask task) async {
    final prefs = await SharedPreferences.getInstance();
    switch (task) {
      case CareTask.feed:
        await prefs.setBool(_fedKey, true);
        break;
      case CareTask.water:
        await prefs.setBool(_wateredKey, true);
        break;
      case CareTask.bath:
        await prefs.setBool(_bathedKey, true);
        break;
      case CareTask.clean:
        await prefs.setBool(_cleanedKey, true);
        break;
      case CareTask.breathing:
        await prefs.setBool(_breathingKey, true);
        break;
      case CareTask.walking:
        await prefs.setBool(_walkingKey, true);
        break;
      case CareTask.journaling:
        await prefs.setBool(_journalingKey, true);
        break;
      case CareTask.gratitude:
        await prefs.setBool(_gratitudeKey, true);
        break;
    }

    final fed = prefs.getBool(_fedKey) ?? false;
    final watered = prefs.getBool(_wateredKey) ?? false;
    final bathed = prefs.getBool(_bathedKey) ?? false;
    final cleaned = prefs.getBool(_cleanedKey) ?? false;
    final breathing = prefs.getBool(_breathingKey) ?? false;
    final walking = prefs.getBool(_walkingKey) ?? false;
    final journaling = prefs.getBool(_journalingKey) ?? false;
    final gratitude = prefs.getBool(_gratitudeKey) ?? false;
    int temperature = prefs.getInt(_tempKey) ?? startTemperature;
    int growthDays = prefs.getInt(_growthDaysKey) ?? 0;

    // 여덜 가지를 모두 완료한 "이번" 순간에만 보너스 온도 상승 + 성장일수 증가 (중복 방지)
    final justCompletedAll =
        fed &&
        watered &&
        bathed &&
        cleaned &&
        breathing &&
        walking &&
        journaling &&
        gratitude;
    final bonusGivenKey =
        '${_uid}_care_bonus_given_${_dateOnlyString(DateTime.now())}';
    final bonusAlreadyGiven = prefs.getBool(bonusGivenKey) ?? false;
    if (justCompletedAll && !bonusAlreadyGiven) {
      temperature = (temperature + 3).clamp(minTemperature, maxTemperature);
      growthDays += 1;
      await prefs.setInt(_tempKey, temperature);
      await prefs.setInt(_growthDaysKey, growthDays);
      await prefs.setBool(bonusGivenKey, true);
    }

    return CatCareState(
      temperature: temperature,
      fedToday: fed,
      wateredToday: watered,
      bathedToday: bathed,
      cleanedToday: cleaned,
      breathingDoneToday: breathing,
      walkingDoneToday: walking,
      journalingDoneToday: journaling,
      gratitudeDoneToday: gratitude,
      companionCatId: prefs.getString(_companionKey) ?? '',
      growthDays: growthDays,
    );
  }

  /// 함께할 고양이(케어 대상)를 변경합니다.
  static Future<void> setCompanionCat(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companionKey, catId);
  }

  /// "오늘의 약속"에서 프리미엄 유저가 약속을 지켰을 때 마음 온도에 소량의
  /// 보너스를 더합니다(성장일수는 늘리지 않고, 온도만 살짝 올려 '한 뼘 자란'
  /// 느낌을 줍니다). 약속 체크를 취소하면 [delta]에 음수를 넘겨 되돌립니다.
  /// 반환값은 갱신된 온도입니다.
  static Future<int> adjustBonusTemperature(int delta) async {
    final prefs = await SharedPreferences.getInstance();
    int temperature = prefs.getInt(_tempKey) ?? startTemperature;
    temperature = (temperature + delta).clamp(minTemperature, maxTemperature);
    await prefs.setInt(_tempKey, temperature);
    return temperature;
  }
}

enum CareTask {
  feed,
  water,
  bath,
  clean,
  breathing,
  walking,
  journaling,
  gratitude,
}
