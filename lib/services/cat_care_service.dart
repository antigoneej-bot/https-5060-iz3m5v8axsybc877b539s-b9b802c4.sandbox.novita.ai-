import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat_care_state.dart';
import '../models/cat_accessory.dart';
import '../models/cat_achievement.dart';
import 'storage_service.dart';
import 'subscription_service.dart';

/// 다마고치식 '마음 돌보기' 데이터를 계정별로 관리하는 서비스.
///
/// 마음 온도 규칙(전면 개편):
/// - 온도는 0도에서 시작해 100도까지 오를 수 있습니다.
/// - 오늘 한 가지 이상 돌봄을 실천하면 그날 한 번 +1도.
/// - 앱에 출석(방문)한 날마다 +1도, 누적 출석일수(growthDays)도 +1.
/// - "오늘의 약속"을 하나 지킬 때마다 +1도.
/// - 돌보지 않고 쉬었던 날에도 온도는 유지됩니다.
/// - 100도에 도달하면(구독자 한정) 포인트가 1점 적립되고 온도는 다시 0도부터 시작합니다.
///   (구독자가 아니면 100도에서 더 오르지 않고 유지됩니다.)
/// - growthDays(누적 출석일수) 30일마다 성장 단계가 하나씩 올라갑니다.
class CatCareService {
  static String _uid = 'guest';
  static const int maxTemperature = 100;
  static const int minTemperature = 0;
  static const int startTemperature = 0;

  static void setCurrentUser(String userId) {
    _uid = userId;
  }

  static void clearCurrentUser() {
    _uid = 'guest';
  }

  /// 온도·히스토리 prefs 쓰기를 직렬화합니다.
  /// [loadAndApplyDailyDecay]가 await 도중 끝난 값을 다시 쓰면서
  /// 편지 보너스(+1)를 0으로 덮어쓰는 레이스를 막습니다.
  static Future<void>? _tempOpTail;

  static Future<T> _serializedTempOp<T>(Future<T> Function() op) async {
    final previous = _tempOpTail;
    final gate = Completer<void>();
    _tempOpTail = gate.future;
    try {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      return await op();
    } finally {
      gate.complete();
    }
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
  static String get _pointsKey => '${_uid}_care_points';
  static String get _tempHistoryKey => '${_uid}_care_temp_history';
  static String get _ownedAccessoriesKey => '${_uid}_care_owned_accessories';
  // 부위별 착용 상태를 "slotName|itemId" 형태로 저장합니다(예: head|hat).
  // 부위가 다르면 여러 개를 동시에 착용할 수 있습니다.
  static String get _equippedSlotsKey => '${_uid}_care_equipped_slots';
  // 소모품(사료/츄루/빗질 등) 보관함 개수를 "itemId|개수" 형태로 저장합니다.
  static String get _consumableInventoryKey =>
      '${_uid}_care_consumable_inventory';
  static String get _graduatedCatsKey => '${_uid}_care_graduated_cats';
  // ── 업적(뱃지) 판단을 위한 누적 통계 ──
  // 포인트는 상점에서 쓰이면 줄어들지만, 뱃지는 "평생 모은 포인트"를 기준으로
  // 판단하기 위해 별도로 누적치만 증가하는 카운터를 둡니다.
  static String get _totalPointsEarnedKey => '${_uid}_care_total_points_earned';
  static String get _totalFullCareDaysKey =>
      '${_uid}_care_total_full_care_days';
  static String get _totalConsumablesUsedKey =>
      '${_uid}_care_total_consumables_used';
  static String get _totalPatsKey => '${_uid}_care_total_pats';
  static String get _unlockedAchievementsKey =>
      '${_uid}_care_unlocked_achievements';
  // 회원가입(온보딩) 완료 전에는 출석 카운팅을 시작하지 않기 위해, '출석 보너스를
  // 이미 지급한 날짜'를 [_lastCareDateKey](체크리스트 초기화용 날짜)와는 별도로
  // 추적합니다.
  static String get _attendanceCountedDateKey =>
      '${_uid}_care_attendance_counted_date';

  /// 달력 날짜만 `yyyy-MM-dd`로 저장합니다.
  /// (예전 toIso8601String 값은 읽을 때 [_parseDateOnly]로 정규화합니다.)
  static String _dateOnlyString(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// 히스토리/lastCare 키를 로컬 달력 날짜로 파싱합니다.
  static DateTime? _parseDateOnly(String raw) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw.trim());
    if (m != null) {
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
    }
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  /// 포인트가 늘어난 만큼 "평생 누적 포인트" 카운터에도 더합니다. 뱃지는
  /// 상점에서 다 써버려도 사라지지 않도록, 현재 보유 포인트가 아니라 이
  /// 누적치를 기준으로 판단합니다.
  static Future<void> _trackPointsEarned(
    SharedPreferences prefs,
    int oldPoints,
    int newPoints,
  ) async {
    if (newPoints <= oldPoints) return;
    final total = prefs.getInt(_totalPointsEarnedKey) ?? 0;
    await prefs.setInt(_totalPointsEarnedKey, total + (newPoints - oldPoints));
  }

  /// 온도에 delta를 더합니다. 구독자([isPremium])라면 100도를 넘길 때마다
  /// 포인트가 1점씩 적립되고 온도는 넘친 만큼만 남긴 채(0부터) 다시 시작합니다.
  /// 구독자가 아니면 100도에서 더 오르지 않고 그대로 유지됩니다.
  /// 반환값: (새 온도, 새 포인트)
  static (int, int) _gainTemperature({
    required int current,
    required int delta,
    required int currentPoints,
    required bool isPremium,
  }) {
    int temp = current + delta;
    int points = currentPoints;
    if (temp < minTemperature) temp = minTemperature;
    if (delta > 0 && isPremium) {
      while (temp >= maxTemperature) {
        points += 1;
        temp -= maxTemperature;
      }
    } else if (temp > maxTemperature) {
      temp = maxTemperature;
    }
    return (temp, points);
  }

  static Map<String, int> _readTempHistoryMap(SharedPreferences prefs) {
    final raw = prefs.getStringList(_tempHistoryKey) ?? [];
    final map = <String, int>{};
    for (final line in raw) {
      final parts = line.split('|');
      if (parts.length != 2) continue;
      final day = _parseDateOnly(parts[0]);
      final t = int.tryParse(parts[1]);
      if (day == null || t == null) continue;
      map[_dateOnlyString(day)] = t;
    }
    return map;
  }

  static Future<void> _writeTempHistoryMap(
    SharedPreferences prefs,
    Map<String, int> map,
  ) async {
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final trimmed = entries.length > 120
        ? entries.sublist(entries.length - 120)
        : entries;
    await prefs.setStringList(
      _tempHistoryKey,
      trimmed.map((e) => '${e.key}|${e.value}').toList(),
    );
  }

  /// 오늘(또는 [forDate])의 마음 온도를 기록합니다. 하루에 여러 번 호출되어도
  /// 그날의 마지막 온도만 남습니다. 최근 120일치만 보관합니다.
  static Future<void> _recordTempHistory(
    SharedPreferences prefs,
    int temperature, {
    DateTime? forDate,
  }) async {
    final map = _readTempHistoryMap(prefs);
    map[_dateOnlyString(forDate ?? DateTime.now())] = temperature;
    await _writeTempHistoryMap(prefs, map);
  }

  /// 오늘 보낸 편지/명상 보너스가 온도에 누락됐는지 맞춥니다.
  /// claimed 카운터와 실제 편지 수 차이만 적용합니다.
  /// (출석으로 온도만 오른 경우를 "편지 보너스 완료"로 오판하지 않습니다.)
  static Future<(int, int)> _reconcileActivityBonuses(
    SharedPreferences prefs, {
    required int temperature,
    required int points,
    required bool isPremium,
  }) async {
    try {
      final today = _dateOnlyString(DateTime.now());
      final claimedKey = '${_uid}_care_activity_bonus_claimed_$today';
      int expected = 0;
      for (final e in StorageService.getAllLetters()) {
        if (_dateOnlyString(e.date) != today) continue;
        expected += 1;
        if (e.meditationKey != null && e.meditationKey!.isNotEmpty) {
          expected += 1;
        }
      }
      final claimed = prefs.getInt(claimedKey) ?? 0;
      if (expected <= claimed) return (temperature, points);

      final delta = expected - claimed;
      final (newTemp, newPoints) = _gainTemperature(
        current: temperature,
        delta: delta,
        currentPoints: points,
        isPremium: isPremium,
      );
      await _trackPointsEarned(prefs, points, newPoints);
      await prefs.setInt(claimedKey, expected);
      return (newTemp, newPoints);
    } catch (_) {
      return (temperature, points);
    }
  }

  /// (날짜, 온도) 기록을 오래된 날짜 → 최신 날짜 순으로 반환합니다.
  /// 오늘 현재 온도를 동기화하고, 편지가 있는 날은 최소 온도 하한을 보정합니다.
  static Future<List<MapEntry<DateTime, int>>> getTempHistory() async {
    return _serializedTempOp(() async {
      final prefs = await SharedPreferences.getInstance();
      int currentTemp = prefs.getInt(_tempKey) ?? startTemperature;
      int points = prefs.getInt(_pointsKey) ?? 0;

      // 오늘 편지 보너스가 온도에 안 들어간 경우(앱 기동 레이스 등) 보정합니다.
      final premium = await SubscriptionService().isPremium();
      final reconciled = await _reconcileActivityBonuses(
        prefs,
        temperature: currentTemp,
        points: points,
        isPremium: premium,
      );
      if (reconciled.$1 != currentTemp || reconciled.$2 != points) {
        currentTemp = reconciled.$1;
        points = reconciled.$2;
        await prefs.setInt(_tempKey, currentTemp);
        await prefs.setInt(_pointsKey, points);
      }
      await _recordTempHistory(prefs, currentTemp);

      final map = _readTempHistoryMap(prefs);
      try {
        final floors = <String, int>{};
        for (final e in StorageService.getAllLetters()) {
          final key = _dateOnlyString(e.date);
          floors[key] = (floors[key] ?? 0) + 1;
          if (e.meditationKey != null && e.meditationKey!.isNotEmpty) {
            floors[key] = floors[key]! + 1;
          }
        }
        var changed = false;
        floors.forEach((key, floor) {
          final existing = map[key];
          if (existing == null || existing < floor) {
            map[key] = floor;
            changed = true;
          }
        });
        if (changed) await _writeTempHistoryMap(prefs, map);
      } catch (_) {}

      final result = <MapEntry<DateTime, int>>[];
      for (final e in map.entries) {
        final d = _parseDateOnly(e.key);
        if (d != null) result.add(MapEntry(d, e.value));
      }
      result.sort((a, b) => a.key.compareTo(b.key));
      return result;
    });
  }

  /// 화면 진입 시 항상 먼저 호출해서, 날짜가 바뀌었는지 확인하고
  /// 쉬었던 날의 온도를 유지하고 오늘 체크리스트를 초기화합니다.
  /// [countAttendance]가 true이고 오늘 출석 보너스를 아직 받지 않았다면
  /// 출석 보너스(+1도, 누적 출석일수 +1)를 적용합니다. 회원가입(온보딩)을
  /// 아직 마치지 않은 사용자는 [countAttendance]를 false로 넘겨, 가입을
  /// 완료하는 순간부터 출석 카운팅이 시작되도록 합니다.
  static Future<CatCareState> loadAndApplyDailyDecay({
    required String defaultCompanionCatId,
    required bool isPremium,
    required bool countAttendance,
  }) async {
    return _serializedTempOp(() async {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = _dateOnlyString(DateTime.now());
      final lastDateRaw = prefs.getString(_lastCareDateKey);
      final lastDate = lastDateRaw != null ? _parseDateOnly(lastDateRaw) : null;
      final lastDateStr = lastDate != null ? _dateOnlyString(lastDate) : null;

      int temperature = prefs.getInt(_tempKey) ?? startTemperature;
      int points = prefs.getInt(_pointsKey) ?? 0;
      int growthDays = prefs.getInt(_growthDaysKey) ?? 0;
      String companionId =
          prefs.getString(_companionKey) ?? defaultCompanionCatId;
      if (prefs.getString(_companionKey) == null) {
        await prefs.setString(_companionKey, companionId);
      }

      if (lastDateStr == null) {
        // 첫 방문: 오늘부터 출석 시작
        await prefs.setString(_lastCareDateKey, todayStr);
      } else if (lastDateStr != todayStr && lastDate != null) {
        // 자정이 바뀌기 전 마지막 온도를 어제 칸에 확정해 둡니다.
        await _recordTempHistory(prefs, temperature, forDate: lastDate);

        // 쉬었던 날에도 온도를 깎지 않습니다. 오늘은 다시 시작하면 됩니다.

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
      } else if (lastDateStr != todayStr) {
        // 파싱 실패 시에도 오늘로 키를 갱신해 반복 decay를 막습니다.
        await prefs.setString(_lastCareDateKey, todayStr);
      }

      if (countAttendance) {
        final attendanceRaw = prefs.getString(_attendanceCountedDateKey);
        final attendanceDay = attendanceRaw != null
            ? _parseDateOnly(attendanceRaw)
            : null;
        final attendanceCountedToday =
            attendanceDay != null &&
            _dateOnlyString(attendanceDay) == todayStr;
        if (!attendanceCountedToday) {
          growthDays += 1;
          final (newTemp, newPoints) = _gainTemperature(
            current: temperature,
            delta: 1,
            currentPoints: points,
            isPremium: isPremium,
          );
          await _trackPointsEarned(prefs, points, newPoints);
          temperature = newTemp;
          points = newPoints;
          await prefs.setInt(_growthDaysKey, growthDays);
          await prefs.setString(_attendanceCountedDateKey, todayStr);
        }

        // 「N일째 함께하는 중」(설치일)과 출석일수가 어긋난 경우 소급 맞춤.
        // 온보딩 전에는 출석이 안 쌓여 1~2일 벌어지는 경우가 흔함.
        // 긴 공백 결석 치팅을 막기 위해 최대 3일 차이만 보정한다.
        final together = await StorageService.daysTogetherSinceInstall();
        if (together > growthDays && together - growthDays <= 3) {
          growthDays = together;
          await prefs.setInt(_growthDaysKey, growthDays);
        }
      }

      final reconciled = await _reconcileActivityBonuses(
        prefs,
        temperature: temperature,
        points: points,
        isPremium: isPremium,
      );
      temperature = reconciled.$1;
      points = reconciled.$2;

      await prefs.setInt(_tempKey, temperature);
      await prefs.setInt(_pointsKey, points);
      await _recordTempHistory(prefs, temperature);

      return CatCareState(
        temperature: temperature,
        fedToday: prefs.getBool(_fedKey) ?? false,
        wateredToday: prefs.getBool(_wateredKey) ?? false,
        bathedToday: prefs.getBool(_bathedKey) ?? false,
        cleanedToday: prefs.getBool(_cleanedKey) ?? false,
        breathingDoneToday: prefs.getBool(_breathingKey) ?? false,
        walkingDoneToday: prefs.getBool(_walkingKey) ?? false,
        journalingDoneToday: prefs.getBool(_journalingKey) ?? false,
        gratitudeDoneToday: prefs.getBool(_gratitudeKey) ?? false,
        companionCatId: prefs.getString(_companionKey) ?? defaultCompanionCatId,
        growthDays: growthDays,
        points: points,
      );
    });
  }

  /// 8가지 돌봄 미션(몸 4가지 + 마음 4가지) 중 하나를 완료 처리합니다.
  /// 여덜 가지를 모두 마친 "이번" 순간에만 온도가 1도 오릅니다(중복 방지).
  static Future<CatCareState> completeTask(
    CareTask task, {
    required bool isPremium,
  }) async {
    return _serializedTempOp(() async {
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
      int points = prefs.getInt(_pointsKey) ?? 0;
      final growthDays = prefs.getInt(_growthDaysKey) ?? 0;

      // 여덜 가지를 모두 완료한 "이번" 순간에만 보너스 온도 상승(+1도, 중복 방지)
      final justCompletedAll =
          fed || watered || bathed || cleaned ||
          breathing || walking || journaling || gratitude;
      final bonusGivenKey =
          '${_uid}_care_bonus_given_${_dateOnlyString(DateTime.now())}';
      final bonusAlreadyGiven = prefs.getBool(bonusGivenKey) ?? false;
      if (justCompletedAll && !bonusAlreadyGiven) {
        final (newTemp, newPoints) = _gainTemperature(
          current: temperature,
          delta: 1,
          currentPoints: points,
          isPremium: isPremium,
        );
        await _trackPointsEarned(prefs, points, newPoints);
        temperature = newTemp;
        points = newPoints;
        await prefs.setInt(_tempKey, temperature);
        await prefs.setInt(_pointsKey, points);
        await prefs.setBool(bonusGivenKey, true);
        await _recordTempHistory(prefs, temperature);
        // 돌봄을 실천한 하루 누적 카운트(뱃지 판단용)
        final fullDays = prefs.getInt(_totalFullCareDaysKey) ?? 0;
        await prefs.setInt(_totalFullCareDaysKey, fullDays + 1);
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
        points: points,
      );
    });
  }

  /// 함께할 고양이(케어 대상)를 변경합니다.
  static Future<void> setCompanionCat(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companionKey, catId);
  }

  /// "오늘의 약속"을 지켰을 때 마음 온도에 +1도를 더합니다(성장일수는 늘리지
  /// 않고, 온도만 살짝 올려 '한 뼘 자란' 느낌을 줍니다). 약속 체크를 취소하면
  /// [delta]에 음수를 넘겨 되돌립니다.
  /// [countAsActivityBonus]가 true면 편지/명상 보너스 청구 카운터도 같이
  /// 올려, 앱 재시작 시 동일 보너스를 다시 주지 않게 합니다.
  /// 반환값은 (갱신된 온도, 갱신된 포인트)입니다.
  static Future<(int, int)> adjustBonusTemperature(
    int delta, {
    required bool isPremium,
    bool countAsActivityBonus = false,
  }) async {
    return _serializedTempOp(() async {
      final prefs = await SharedPreferences.getInstance();
      int temperature = prefs.getInt(_tempKey) ?? startTemperature;
      int points = prefs.getInt(_pointsKey) ?? 0;
      final (newTemp, newPoints) = _gainTemperature(
        current: temperature,
        delta: delta,
        currentPoints: points,
        isPremium: isPremium,
      );
      await _trackPointsEarned(prefs, points, newPoints);
      await prefs.setInt(_tempKey, newTemp);
      await prefs.setInt(_pointsKey, newPoints);
      if (countAsActivityBonus && delta > 0) {
        final claimedKey =
            '${_uid}_care_activity_bonus_claimed_${_dateOnlyString(DateTime.now())}';
        final claimed = prefs.getInt(claimedKey) ?? 0;
        await prefs.setInt(claimedKey, claimed + delta);
      }
      await _recordTempHistory(prefs, newTemp);
      return (newTemp, newPoints);
    });
  }

  /// 현재까지 적립된 포인트(구독자 전용 보상)를 반환합니다.
  static Future<int> getPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  /// 구독 여부와 무관하게 포인트를 직접 더해줍니다.
  ///
  /// '오늘의 그림자 방울 터뜨리기'처럼, 마음 온도 100도 적립 규칙([_gainTemperature])과는
  /// 별개로 누구에게나 열려 있는 리텐션 훅에서 사용합니다. 이렇게 쌓인 포인트도
  /// 결과적으로는 동일한 [_pointsKey] 저장소를 쓰기 때문에, 기존 상점(옷/장식/가구 등
  /// 꾸미기 전용 아이템)에서 그대로 사용할 수 있고 — 프리미엄 리포트·저널 확장·명상
  /// 콘텐츠 같은 핵심 기능 잠금 해제에는 애초에 포인트를 쓸 수 없으므로 구독 전환을
  /// 방해하지 않습니다. 반환값은 갱신된 포인트 총량입니다.
  static Future<int> awardBonusPoints(int amount) async {
    if (amount <= 0) return getPoints();
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt(_pointsKey) ?? 0;
    final newPoints = points + amount;
    await _trackPointsEarned(prefs, points, newPoints);
    await prefs.setInt(_pointsKey, newPoints);
    return newPoints;
  }

  // ── 정원 플러스 포인트 상점 (아이템 구매/장착/사용) ──
  //
  // 아이템 종류별로 다르게 동작합니다:
  // - 착용형(wearable): 한 번 구매하면 계속 보유하며, 부위(slot)별로 장착/해제할
  //   수 있습니다. 부위가 다르면 여러 개를 동시에 착용할 수 있어요.
  // - 소모품(consumable): 구매할 때마다 보관함에 개수가 쌓이고, "사용하기"를
  //   누르면 1개가 줄어들며 마음 온도가 살짝 오릅니다.
  // - 가구(furniture): 착용형과 동일하게 한 번 구매하면 계속 보유하며,
  //   구매 즉시 '우리 집'에 놓인 것으로 취급합니다(장착 개념이 없음).

  /// 지금까지 구매한 착용형/가구 아이템 id 목록을 반환합니다(소모품 제외).
  static Future<List<String>> getOwnedAccessoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_ownedAccessoriesKey) ?? [];
  }

  /// 부위별로 현재 장착 중인 아이템 id를 반환합니다.
  static Future<Map<CatWearSlot, String>> getEquippedBySlot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_equippedSlotsKey) ?? [];
    final map = <CatWearSlot, String>{};
    for (final line in raw) {
      final parts = line.split('|');
      if (parts.length == 2) {
        final slot = CatWearSlot.values.where((s) => s.name == parts[0]);
        if (slot.isNotEmpty) map[slot.first] = parts[1];
      }
    }
    return map;
  }

  /// 소모품별로 지금 보관함에 몇 개씩 남아있는지 반환합니다.
  static Future<Map<String, int>> getConsumableInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_consumableInventoryKey) ?? [];
    final map = <String, int>{};
    for (final line in raw) {
      final parts = line.split('|');
      if (parts.length == 2) {
        final n = int.tryParse(parts[1]);
        if (n != null && n > 0) map[parts[0]] = n;
      }
    }
    return map;
  }

  static Future<void> _saveConsumableInventory(
    SharedPreferences prefs,
    Map<String, int> inv,
  ) async {
    final list = inv.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key}|${e.value}')
        .toList();
    await prefs.setStringList(_consumableInventoryKey, list);
  }

  /// 아이템을 포인트로 구매합니다. 포인트가 부족하면 구매하지 않고
  /// false를 반환합니다. 구매에 성공하면 남은 포인트를 반환합니다.
  /// - 착용형/가구: 이미 보유 중이면 추가 비용 없이 그대로 성공 처리합니다.
  /// - 소모품: 구매할 때마다 보관함 개수가 1개씩 늘어납니다(중복 구매 가능).
  static Future<(bool, int)> purchaseAccessory(CatAccessory accessory) async {
    final prefs = await SharedPreferences.getInstance();
    final points = prefs.getInt(_pointsKey) ?? 0;

    if (accessory.type == CatItemType.consumable) {
      if (points < accessory.pointCost) {
        return (false, points);
      }
      final newPoints = points - accessory.pointCost;
      final inv = await getConsumableInventory();
      inv[accessory.id] = (inv[accessory.id] ?? 0) + 1;
      await prefs.setInt(_pointsKey, newPoints);
      await _saveConsumableInventory(prefs, inv);
      return (true, newPoints);
    }

    final owned = prefs.getStringList(_ownedAccessoriesKey) ?? [];
    if (owned.contains(accessory.id)) {
      return (true, points); // 이미 보유 중이면 그대로 성공 처리
    }
    if (points < accessory.pointCost) {
      return (false, points);
    }
    final newPoints = points - accessory.pointCost;
    await prefs.setInt(_pointsKey, newPoints);
    await prefs.setStringList(_ownedAccessoriesKey, [...owned, accessory.id]);
    return (true, newPoints);
  }

  /// 보유 중인 착용형 아이템을 해당 부위에 장착합니다. null을 넘기면
  /// 그 부위의 장착을 해제합니다. 부위가 다르면 여러 개를 동시에 장착할 수
  /// 있어요.
  static Future<void> equipToSlot(CatWearSlot slot, String? accessoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getEquippedBySlot();
    if (accessoryId == null) {
      current.remove(slot);
    } else {
      current[slot] = accessoryId;
    }
    final list = current.entries
        .map((e) => '${e.key.name}|${e.value}')
        .toList();
    await prefs.setStringList(_equippedSlotsKey, list);
  }

  /// 보관함에 있는 소모품 하나를 사용합니다. 개수가 1개 줄고, 마음 온도가
  /// 살짝(+1도) 오릅니다. 보관함에 남은 개수가 없으면 아무 일도 일어나지
  /// 않고 실패를 반환합니다. 반환값: (성공 여부, 새 온도, 새 포인트)
  static Future<(bool, int, int)> useConsumable(
    CatAccessory accessory, {
    required bool isPremium,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final inv = await getConsumableInventory();
    final count = inv[accessory.id] ?? 0;
    final temperature = prefs.getInt(_tempKey) ?? startTemperature;
    final points = prefs.getInt(_pointsKey) ?? 0;
    if (count <= 0) {
      return (false, temperature, points);
    }
    inv[accessory.id] = count - 1;
    await _saveConsumableInventory(prefs, inv);

    final (newTemp, newPoints) = _gainTemperature(
      current: temperature,
      delta: 1,
      currentPoints: points,
      isPremium: isPremium,
    );
    await _trackPointsEarned(prefs, points, newPoints);
    await prefs.setInt(_tempKey, newTemp);
    await prefs.setInt(_pointsKey, newPoints);
    await _recordTempHistory(prefs, newTemp);
    final usedTotal = prefs.getInt(_totalConsumablesUsedKey) ?? 0;
    await prefs.setInt(_totalConsumablesUsedKey, usedTotal + 1);
    return (true, newTemp, newPoints);
  }

  // ── 애정 표현(탭 쓰다듬기) & 업적(뱃지) 통계 ──

  /// 고양이를 한 번 쓰다듬어준(탭한) 것으로 기록합니다. 누적 횟수를
  /// 반환합니다.
  static Future<int> recordPat() async {
    final prefs = await SharedPreferences.getInstance();
    final total = (prefs.getInt(_totalPatsKey) ?? 0) + 1;
    await prefs.setInt(_totalPatsKey, total);
    return total;
  }

  /// 지금까지 쓰다듬은 누적 횟수를 반환합니다.
  static Future<int> getTotalPats() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalPatsKey) ?? 0;
  }

  /// 지금까지 화면에 보여준(달성 축하를 이미 띄운) 뱃지 id 목록을 반환합니다.
  static Future<List<String>> getSeenUnlockedAchievementIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_unlockedAchievementsKey) ?? [];
  }

  /// 새로 달성 축하를 띄운 뱃지 id들을 "이미 봤음"으로 기록합니다.
  static Future<void> markAchievementsSeen(List<String> ids) async {
    if (ids.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_unlockedAchievementsKey) ?? [];
    final merged = {...current, ...ids}.toList();
    await prefs.setStringList(_unlockedAchievementsKey, merged);
  }

  /// 업적(뱃지) 판단에 필요한 모든 누적 통계를 한 번에 모아 반환합니다.
  static Future<CatAchievementStats> getAchievementStats({
    required int growthDays,
    required int graduatedCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ownedIds = await getOwnedAccessoryIds();
    final ownedWearableCount = ownedIds
        .map(catAccessoryById)
        .whereType<CatAccessory>()
        .where((a) => a.type == CatItemType.wearable)
        .length;
    final ownedFurnitureCount = ownedIds
        .map(catAccessoryById)
        .whereType<CatAccessory>()
        .where((a) => a.type == CatItemType.furniture)
        .length;
    return CatAchievementStats(
      growthDays: growthDays,
      graduatedCount: graduatedCount,
      ownedWearableCount: ownedWearableCount,
      ownedFurnitureCount: ownedFurnitureCount,
      totalConsumablesUsed: prefs.getInt(_totalConsumablesUsedKey) ?? 0,
      totalPointsEarned: prefs.getInt(_totalPointsEarnedKey) ?? 0,
      totalFullCareDays: prefs.getInt(_totalFullCareDaysKey) ?? 0,
      totalPats: prefs.getInt(_totalPatsKey) ?? 0,
    );
  }

  // ── 졸업 앨범 (성체가 된 고양이를 기록하고, 새 아기고양이로 넘어가기) ──

  /// 지금까지 졸업(성체까지 다 키움)한 고양이들의 목록을
  /// "catId|졸업일ISO8601" 문자열로 반환합니다.
  static Future<List<String>> _rawGraduatedEntries() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_graduatedCatsKey) ?? [];
  }

  /// 졸업한 고양이 (catId, 졸업일) 목록을 졸업일 오름차순으로 반환합니다.
  static Future<List<(String, DateTime)>> getGraduatedCats() async {
    final raw = await _rawGraduatedEntries();
    final result = <(String, DateTime)>[];
    for (final line in raw) {
      final parts = line.split('|');
      if (parts.length == 2) {
        final d = DateTime.tryParse(parts[1]);
        if (d != null) result.add((parts[0], d));
      }
    }
    result.sort((a, b) => a.$2.compareTo(b.$2));
    return result;
  }

  /// 현재 반려 고양이(companionCatId)를 졸업 명단에 추가하고, 성장 상태를
  /// 초기화해 새 아기고양이를 키울 수 있게 합니다. 포인트와 보유
  /// 액세서리는 그대로 유지됩니다(장착 상태만 해제).
  static Future<CatCareState> graduateAndStartNewBaby({
    required String newCompanionCatId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final graduatingId = prefs.getString(_companionKey);
    if (graduatingId != null) {
      final raw = prefs.getStringList(_graduatedCatsKey) ?? [];
      raw.add('$graduatingId|${DateTime.now().toIso8601String()}');
      await prefs.setStringList(_graduatedCatsKey, raw);
    }
    // 새 아기고양이로 다시 시작 - 온도/성장일수만 초기화하고, 포인트는 유지합니다.
    await prefs.setInt(_tempKey, startTemperature);
    await prefs.setInt(_growthDaysKey, 0);
    await prefs.setString(_companionKey, newCompanionCatId);
    await prefs.remove(_equippedSlotsKey);
    await prefs.setBool(_fedKey, false);
    await prefs.setBool(_wateredKey, false);
    await prefs.setBool(_bathedKey, false);
    await prefs.setBool(_cleanedKey, false);
    await prefs.setBool(_breathingKey, false);
    await prefs.setBool(_walkingKey, false);
    await prefs.setBool(_journalingKey, false);
    await prefs.setBool(_gratitudeKey, false);
    final points = prefs.getInt(_pointsKey) ?? 0;

    return CatCareState(
      temperature: startTemperature,
      fedToday: false,
      wateredToday: false,
      bathedToday: false,
      cleanedToday: false,
      companionCatId: newCompanionCatId,
      growthDays: 0,
      points: points,
    );
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
