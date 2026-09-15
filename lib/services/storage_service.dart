import '../mongi/integration/session_transaction.dart';
import 'personal_reply_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter_entry.dart';
import '../models/reflection_letter_entry.dart';
import '../models/daily_draw_entry.dart';
import '../models/bubble_memo_entry.dart';
import 'hive_encryption.dart';

/// 계정별로 편지 기록 · 연속 방문일 · 성장 단계를 저장합니다.
/// (사운드 설정처럼 기기 전체에 공통인 값은 계정과 무관하게 유지됩니다)
class StorageService {
  static const String _defaultScope = 'guest';
  static String _uid = _defaultScope;

  static Box? _letterBox;
  static Box? _reflectionLetterBox;
  static Box? _dailyDrawBox;
  static Box? _bubbleMemoBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    await SessionTransaction.initialize();
  }

  /// 예전 기본 UID(`guest`)에 쌓인 prefs/Hive를 [userId](`local_user`)로
  /// 한 번만 복사합니다. B-1에서 계정 없이 로컬 UID로 바꾼 뒤, 기존
  /// 누적 데이터가 "사라진 것처럼" 보이던 문제를 막습니다.
  static Future<void> migrateGuestScopeIfNeeded(String userId) async {
    if (userId.isEmpty || userId == _defaultScope) return;
    final prefs = await SharedPreferences.getInstance();
    final flag = 'guest_scope_migrated_v1_to_$userId';
    if (prefs.getBool(flag) == true) return;

    // SharedPreferences: guest_* → {userId}_* (대상 키가 비어 있을 때만)
    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith('${_defaultScope}_')) continue;
      final newKey = '$userId${key.substring(_defaultScope.length)}';
      if (prefs.containsKey(newKey)) continue;
      final value = prefs.get(key);
      if (value is bool) {
        await prefs.setBool(newKey, value);
      } else if (value is int) {
        await prefs.setInt(newKey, value);
      } else if (value is double) {
        await prefs.setDouble(newKey, value);
      } else if (value is String) {
        await prefs.setString(newKey, value);
      } else if (value is List<String>) {
        await prefs.setStringList(newKey, value);
      }
    }

    // Hive 박스 — 하나라도 실패하면 플래그를 남기지 않아 다음 실행에 재시도
    final hiveOk = <bool>[
      await _copyHiveBoxIfTargetEmpty(
        'letter_entries_$_defaultScope',
        'letter_entries_$userId',
      ),
      await _copyHiveBoxIfTargetEmpty(
        'reflection_letters_$_defaultScope',
        'reflection_letters_$userId',
      ),
      await _copyHiveBoxIfTargetEmpty(
        'daily_draw_entries_$_defaultScope',
        'daily_draw_entries_$userId',
      ),
      await _copyHiveBoxIfTargetEmpty(
        'bubble_memo_entries_$_defaultScope',
        'bubble_memo_entries_$userId',
      ),
      await _copyHiveBoxIfTargetEmpty(
        'buried_emotions_$_defaultScope',
        'buried_emotions_$userId',
      ),
      await _copyHiveBoxIfTargetEmpty(
        'cat_memories_$_defaultScope',
        'cat_memories_$userId',
      ),
      await _copyHiveBoxIfTargetEmpty(
        'usage_history_$_defaultScope',
        'usage_history_$userId',
      ),
      await _copyHiveBoxIfTargetEmpty(
        'promise_entries_$_defaultScope',
        'promise_entries_$userId',
      ),
      await _copyHiveBoxIfTargetEmpty(
        'special_letters_$_defaultScope',
        'special_letters_$userId',
      ),
    ];

    if (hiveOk.every((ok) => ok)) {
      await prefs.setBool(flag, true);
    }
  }

  /// 성공(또는 복사할 것 없음)이면 true, 예외/실패면 false.
  static Future<bool> _copyHiveBoxIfTargetEmpty(
    String fromName,
    String toName,
  ) async {
    try {
      final fromExists =
          await Hive.boxExists(fromName) ||
          await Hive.boxExists('${fromName}__enc');
      if (!fromExists) return true;

      final from = await HiveEncryption.openBox(fromName);
      if (from.isEmpty) {
        await from.close();
        return true;
      }

      final to = await HiveEncryption.openBox(toName);
      if (to.isNotEmpty) {
        await to.close();
        await from.close();
        return true;
      }
      for (final key in from.keys) {
        await to.put(key, from.get(key));
      }
      final ok = to.length >= from.length;
      await to.close();
      await from.close();
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// 로그인/자동 로그인 성공 시 호출해서 해당 계정 전용 저장 공간으로 전환합니다.
  static Future<void> setCurrentUser(String userId) async {
    if (_uid == userId && _letterBox != null && _letterBox!.isOpen) return;
    _uid = userId;
    if (_letterBox != null && _letterBox!.isOpen) {
      await _letterBox!.close();
    }
    if (_reflectionLetterBox != null && _reflectionLetterBox!.isOpen) {
      await _reflectionLetterBox!.close();
    }
    if (_dailyDrawBox != null && _dailyDrawBox!.isOpen) {
      await _dailyDrawBox!.close();
    }
    if (_bubbleMemoBox != null && _bubbleMemoBox!.isOpen) {
      await _bubbleMemoBox!.close();
    }
    _letterBox = await HiveEncryption.openBox('letter_entries_$_uid');
    _reflectionLetterBox =
        await HiveEncryption.openBox('reflection_letters_$_uid');
    _dailyDrawBox = await HiveEncryption.openBox('daily_draw_entries_$_uid');
    _bubbleMemoBox =
        await HiveEncryption.openBox('bubble_memo_entries_$_uid');
  }

  /// 로그아웃 시 호출해서 계정 전용 데이터 접근을 닫습니다.
  static Future<void> clearCurrentUser() async {
    if (_letterBox != null && _letterBox!.isOpen) {
      await _letterBox!.close();
    }
    if (_reflectionLetterBox != null && _reflectionLetterBox!.isOpen) {
      await _reflectionLetterBox!.close();
    }
    if (_dailyDrawBox != null && _dailyDrawBox!.isOpen) {
      await _dailyDrawBox!.close();
    }
    if (_bubbleMemoBox != null && _bubbleMemoBox!.isOpen) {
      await _bubbleMemoBox!.close();
    }
    _letterBox = null;
    _reflectionLetterBox = null;
    _dailyDrawBox = null;
    _bubbleMemoBox = null;
    _uid = _defaultScope;
  }

  static Box get letterBox {
    if (_letterBox == null || !_letterBox!.isOpen) {
      throw Exception('StorageService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)');
    }
    return _letterBox!;
  }

  static Future<void> saveLetter(LetterEntry entry) async {
    // A retry after an uncertain write uses the same immutable ID.
    if (!letterBox.containsKey(entry.id)) await letterBox.put(entry.id, entry.toMap());
    await letterBox.flush();
  }

  /// 이미 저장된 편지에 명상 실천 여부(meditationKey)만 덧붙여 갱신합니다.
  /// 편지 저장(=편지 전송)과 명상 실천은 서로 다른 시점에 독립적으로
  /// 일어나는 별개의 행동이므로, 편지가 이미 저장된 뒤에도 안전하게 이
  /// 필드만 보완할 수 있게 합니다.
  static Future<void> updateLetterMeditation(
    String id,
    String? meditationKey,
  ) async {
    final raw = letterBox.get(id);
    if (raw == null) return;
    final entry = LetterEntry.fromMap(Map<dynamic, dynamic>.from(raw as Map));
    await letterBox.put(id, entry.withMeditationKey(meditationKey).toMap());
  }

  static List<LetterEntry> getAllLetters() {
    final entries = letterBox.values
        .map((e) => LetterEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> deleteLetter(String id) async {
    await PersonalReplyService.remove('letter:$id');
    final cache = await HiveEncryption.openBox('reply_cache_local_user');
    await cache.delete(id);
    await cache.flush();
    await letterBox.delete(id);
    await letterBox.flush();
  }

  /// 가장 최근에 쓴 편지의 고양이 id를 반환합니다(없으면 null).
  /// '마지막으로 만난 고양이' 개인화 알림 문구에 사용됩니다.
  static String? getLastMetCatId() {
    if (_letterBox == null || !_letterBox!.isOpen) return null;
    final entries = getAllLetters(); // 이미 날짜 내림차순 정렬됨
    if (entries.isEmpty) return null;
    return entries.first.catId;
  }

  /// 이 편지의 고양이 답장을 열어봤다고 표시합니다(홈 배너를 다시 띄우지
  /// 않기 위함).
  static Future<void> markReplySeen(String id) async {
    final raw = letterBox.get(id);
    if (raw == null) return;
    final entry = LetterEntry.fromMap(Map<dynamic, dynamic>.from(raw as Map));
    await letterBox.put(id, entry.withReplySeen().toMap());
  }

  // ---- Streak tracking (연속 방문일) via SharedPreferences (계정별 키) ----
  static String get _lastVisitKey => '${_uid}_last_visit_date';
  static String get _streakKey => '${_uid}_streak_count';

  /// 달력 날짜만 `yyyy-MM-dd`로 통일합니다. (구버전 ISO 값은 [_parseDateOnly]로 읽음)
  static String _dateOnlyString(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

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

  static Future<int> updateStreakOnOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _dateOnlyString(DateTime.now());
    final lastVisitRaw = prefs.getString(_lastVisitKey);
    final lastVisitDay = lastVisitRaw != null
        ? _parseDateOnly(lastVisitRaw)
        : null;
    final lastVisit =
        lastVisitDay != null ? _dateOnlyString(lastVisitDay) : null;
    int streak = prefs.getInt(_streakKey) ?? 0;

    if (lastVisit == null) {
      streak = 1;
    } else if (lastVisit == todayStr) {
      return streak == 0 ? 1 : streak;
    } else {
      final lastDate = lastVisitDay!;
      final diff = DateTime.now()
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;
      if (diff == 1) {
        streak += 1;
      } else {
        streak = 1;
      }
    }
    await prefs.setString(_lastVisitKey, todayStr);
    await prefs.setInt(_streakKey, streak);
    return streak;
  }

  /// 현재 저장된 연속 방문일(스트릭) 수를 그대로 반환합니다(알림 문구용).
  static Future<int> getCurrentStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_streakKey) ?? 0;
    return streak == 0 ? 0 : streak;
  }

  /// 설치일 기준 "N일째 함께하는 중" 숫자.
  /// 설치한 날 = 1일째, 그다음 날 = 2일째 … (3일 전 설치면 보통 4일째).
  /// 설치일이 없으면 0.
  static Future<int> daysTogetherSinceInstall({DateTime? now}) async {
    final since = await daysSinceInstall(now: now);
    final installDate = await getInstallDate();
    if (installDate == null) return 0;
    return since + 1;
  }

  /// [updateStreakOnOpen]을 호출하기 *전에* 먼저 확인해야 합니다 - 그 값이
  /// 오늘 날짜로 갱신되어 버리기 때문에, "이번에 며칠 만에 돌아왔는지"를
  /// 알고 싶다면 이 함수를 streak 갱신보다 먼저 불러야 합니다.
  /// 반환값: 마지막 방문일로부터 오늘까지 며칠이 지났는지(0 = 오늘 이미 방문,
  /// 1 = 어제 방문해서 정상적으로 이어지는 하루, 2 이상 = 그만큼 결석).
  /// 아직 한 번도 방문한 적이 없다면 0을 반환합니다(신규 사용자는 결석으로
  /// 취급하지 않음).
  static Future<int> daysSinceLastVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final lastVisit = prefs.getString(_lastVisitKey);
    if (lastVisit == null) return 0;
    final lastDate = _parseDateOnly(lastVisit);
    if (lastDate == null) return 0;
    final diff = DateTime.now()
        .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
        .inDays;
    return diff < 0 ? 0 : diff;
  }

  /// 오늘 이미 성장 미션(편지+명상)을 완수했는지 여부.
  /// '스트릭 임박' 알림을 예약할지 판단하는 데 사용됩니다.
  static Future<bool> hasCompletedGrowthToday() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _dateOnlyString(DateTime.now());
    final days = await _normalizedGrowthDays(prefs);
    return days.contains(todayStr);
  }

  // ---- Growth Level (성장 단계, 계정별) ----
  // 하루에 미션(편지+명상)을 완수할 때마다 마음 온도가 1도씩 올라갑니다.
  // 14일 안에 10도를 채우면 레벨업! 14일 안에 못 채우면 도전이 초기화됩니다.
  static String get _growthLevelKey => '${_uid}_growth_level';
  static String get _growthStartKey => '${_uid}_growth_challenge_start';
  static String get _growthDaysKey => '${_uid}_growth_completed_days';
  static const int growthGoalPoints = 10; // 레벨업에 필요한 적립 온도(일수)
  static const int growthWindowDays = 14; // 도전 기간

  static Future<int> getGrowthLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_growthLevelKey) ?? 1;
  }

  /// 현재 도전 상태를 반환합니다: (적립 온도, 도전 시작 후 지난 일수 [1~14, 아직 시작 안했으면 0])
  static Future<(int, int)> getGrowthProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString(_growthStartKey);
    final days = await _normalizedGrowthDays(prefs);
    if (startStr == null) return (0, 0);

    final startDate = _parseDateOnly(startStr);
    if (startDate == null) return (0, 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final elapsed = today.difference(startDate).inDays;
    if (elapsed >= growthWindowDays) {
      return (0, 0);
    }
    return (days.length, elapsed + 1);
  }

  /// 성장 완료일 목록을 yyyy-MM-dd 로 정규화해 저장합니다.
  static Future<List<String>> _normalizedGrowthDays(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getStringList(_growthDaysKey) ?? [];
    final normalized = <String>{};
    for (final item in raw) {
      final d = _parseDateOnly(item);
      if (d != null) normalized.add(_dateOnlyString(d));
    }
    final list = normalized.toList()..sort();
    if (list.length != raw.length ||
        list.any((e) => !raw.contains(e))) {
      await prefs.setStringList(_growthDaysKey, list);
    }
    return list;
  }

  /// 오늘 미션(편지+명상)을 완수했을 때 호출합니다. 하루에 한 번만 온도가 오릅니다.
  static Future<(bool, int, int, int)> recordGrowthDay() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _dateOnlyString(DateTime.now());
    String? startStr = prefs.getString(_growthStartKey);
    List<String> days = await _normalizedGrowthDays(prefs);
    int level = prefs.getInt(_growthLevelKey) ?? 1;

    bool expired = false;
    if (startStr != null) {
      final startDate = _parseDateOnly(startStr);
      if (startDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final elapsed = today.difference(startDate).inDays;
        if (elapsed >= growthWindowDays) expired = true;
      } else {
        expired = true;
      }
    }

    if (startStr == null || expired) {
      startStr = todayStr;
      days = [];
      await prefs.setString(_growthStartKey, startStr);
    } else {
      // 구 ISO start 값도 yyyy-MM-dd 로 정규화
      final parsed = _parseDateOnly(startStr);
      if (parsed != null) {
        startStr = _dateOnlyString(parsed);
        await prefs.setString(_growthStartKey, startStr);
      }
    }

    if (!days.contains(todayStr)) {
      days = [...days, todayStr];
      await prefs.setStringList(_growthDaysKey, days);
    }

    bool leveledUp = false;
    if (days.length >= growthGoalPoints) {
      level += 1;
      leveledUp = true;
      days = [];
      await prefs.remove(_growthStartKey);
      await prefs.setStringList(_growthDaysKey, days);
    }
    await prefs.setInt(_growthLevelKey, level);

    final startDate = _parseDateOnly(startStr) ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final elapsedNow = leveledUp
        ? 0
        : today.difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays +
              1;
    return (leveledUp, level, days.length, elapsedNow);
  }

  // ---- Sound settings (기기 전체 공통, 계정과 무관) ----
  static const String _sfxKey = 'sfx_enabled';
  static const String _bgmKey = 'bgm_enabled';
  static const String _volKey = 'bgm_volume';

  static Future<bool> getSfxEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sfxKey) ?? true;
  }

  static Future<void> setSfxEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, v);
  }

  static Future<bool> getBgmEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bgmKey) ?? true;
  }

  static Future<void> setBgmEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgmKey, v);
  }

  static Future<double> getBgmVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_volKey) ?? 0.35;
  }

  static Future<void> setBgmVolume(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volKey, v);
  }

  // ---- Onboarding (기기 전체 공통, 최초 1회만 진행) ----
  static const String _onboardingDoneKey = 'onboarding_completed_v1';
  static const String _loginProviderKey = 'login_provider';
  static const String _notificationOptInKey = 'notification_opt_in';

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingDoneKey, true);
  }

  /// 온보딩에서 선택한 가입 경로(kakao/apple/google/email:주소)를 기억해둡니다.
  /// 실제 OAuth 연동 전까지는 로컬 전용 구조에 맞춰 표시용으로만 사용합니다.
  static Future<void> setLoginProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginProviderKey, provider);
  }

  static Future<void> setNotificationOptIn(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationOptInKey, v);
  }

  // ---- Welcome Intro (앱 최초 실행 시 1회만 보여주는 3단계 웰컴 투어) ----
  static const String _welcomeIntroDoneKey = 'welcome_intro_completed_v1';
  static const String _companionNameKey = 'companion_name';

  static Future<bool> isWelcomeIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeIntroDoneKey) ?? false;
  }

  static Future<void> setWelcomeIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeIntroDoneKey, true);
  }

  /// 사용자가 지어준 companion(아기고양이)의 이름을 저장합니다.
  static Future<void> setCompanionName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companionNameKey, name);
  }

  static Future<String?> getCompanionName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companionNameKey);
  }

  // ---- Daily Care Reminder (기기 전체 공통, 매일 돌보기 알림) ----
  // v1(레거시): 하나의 고정 알림만 지원했습니다. v2부터는 아침/저녁 알림을
  // 분리하고, '위기 알림'(3일+ 미접속)과 '스트릭 임박 알림'(오늘 미완료)을
  // 추가로 지원합니다. 레거시 설정은 [migrateLegacyReminderIfNeeded]에서
  // 저녁 알림으로 1회 자동 이전됩니다.
  static const String _reminderEnabledKey = 'daily_reminder_enabled';
  static const String _reminderHourKey = 'daily_reminder_hour';
  static const String _reminderMinuteKey = 'daily_reminder_minute';

  static const String _morningEnabledKey = 'reminder_morning_enabled';
  static const String _morningHourKey = 'reminder_morning_hour';
  static const String _morningMinuteKey = 'reminder_morning_minute';

  static const String _eveningEnabledKey = 'reminder_evening_enabled';
  static const String _eveningHourKey = 'reminder_evening_hour';
  static const String _eveningMinuteKey = 'reminder_evening_minute';

  static const String _crisisEnabledKey = 'reminder_crisis_enabled';
  static const String _streakEnabledKey = 'reminder_streak_enabled';

  static const String _reminderMigratedKey = 'reminder_migrated_v2';

  /// 레거시(v1) 알림 설정이 남아있다면, 1회만 저녁 알림 설정으로 옮겨줍니다.
  static Future<void> migrateLegacyReminderIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_reminderMigratedKey) ?? false) return;
    final legacyEnabled = prefs.getBool(_reminderEnabledKey) ?? false;
    if (legacyEnabled) {
      final hour = prefs.getInt(_reminderHourKey) ?? 20;
      final minute = prefs.getInt(_reminderMinuteKey) ?? 0;
      await prefs.setBool(_eveningEnabledKey, true);
      await prefs.setInt(_eveningHourKey, hour);
      await prefs.setInt(_eveningMinuteKey, minute);
    }
    await prefs.setBool(_reminderMigratedKey, true);
  }

  // -- 아침 알림 (기본 오전 9시) --
  static Future<bool> getMorningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_morningEnabledKey) ?? false;
  }

  static Future<void> setMorningEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_morningEnabledKey, v);
  }

  static Future<(int, int)> getMorningTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_morningHourKey) ?? 9;
    final minute = prefs.getInt(_morningMinuteKey) ?? 0;
    return (hour, minute);
  }

  static Future<void> setMorningTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_morningHourKey, hour);
    await prefs.setInt(_morningMinuteKey, minute);
  }

  // -- 저녁 알림 (기본 오후 8시) --
  static Future<bool> getEveningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_eveningEnabledKey) ?? false;
  }

  static Future<void> setEveningEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_eveningEnabledKey, v);
  }

  static Future<(int, int)> getEveningTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_eveningHourKey) ?? 20;
    final minute = prefs.getInt(_eveningMinuteKey) ?? 0;
    return (hour, minute);
  }

  static Future<void> setEveningTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_eveningHourKey, hour);
    await prefs.setInt(_eveningMinuteKey, minute);
  }

  // -- 위기 알림 (3일 이상 미접속 시에만 조건부 발송, 기본 켜짐) --
  static Future<bool> getCrisisEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_crisisEnabledKey) ?? true;
  }

  static Future<void> setCrisisEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crisisEnabledKey, v);
  }

  // -- 스트릭 임박 알림 (오늘 미완료일 때만 조건부 발송, 기본 켜짐) --
  static Future<bool> getStreakEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_streakEnabledKey) ?? true;
  }

  static Future<void> setStreakEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_streakEnabledKey, v);
  }

  // ── 감정 인식 루프: 설치일(가입일) 기록 ──
  // 주간/월간 회고의 진입 조건(가입 후 7일/30일 경과)을 계산하는 기준입니다.
  // 계정 전환과 무관하게 기기 최초 실행 시각을 기억합니다.
  static const String _installDateKey = 'install_date_v1';

  /// 앱을 최초로 실행한 날짜/시각을 기록합니다. 이미 기록되어 있다면 아무것도
  /// 하지 않습니다(최초 1회만 저장). main.dart의 부트스트랩에서 매번 호출해도
  /// 안전합니다.
  static Future<void> recordInstallDateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_installDateKey) != null) return;
    await prefs.setString(_installDateKey, DateTime.now().toIso8601String());
  }

  /// 앱을 최초로 실행한 날짜/시각. 아직 기록되지 않았다면 null.
  static Future<DateTime?> getInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_installDateKey);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// 설치(가입) 후 지난 일수. 아직 설치일이 기록되지 않았다면 0.
  static Future<int> daysSinceInstall({DateTime? now}) async {
    final installDate = await getInstallDate();
    if (installDate == null) return 0;
    final ref = now ?? DateTime.now();
    final installDay = DateTime(
      installDate.year,
      installDate.month,
      installDate.day,
    );
    final today = DateTime(ref.year, ref.month, ref.day);
    return today.difference(installDay).inDays;
  }

  // ── 감정 인식 루프: 회고를 이미 확인했는지(자동 노출 배너 중복 방지) ──
  // 주간 회고는 '이번 주(월요일 기준)를 이미 봤는지', 월간 회고는
  // '이번 달을 이미 봤는지'로 구분해 기록합니다. 사용자가 직접 들어와서 보는
  // 경우에는 이 기록과 무관하게 항상 열람할 수 있습니다.
  static const String _weeklyReflectionSeenKey = 'weekly_reflection_seen_week';
  static const String _monthlyReflectionSeenKey =
      'monthly_reflection_seen_month';

  static Future<bool> hasSeenWeeklyReflection(String weekKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weeklyReflectionSeenKey) == weekKey;
  }

  static Future<void> markWeeklyReflectionSeen(String weekKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weeklyReflectionSeenKey, weekKey);
  }

  static Future<bool> hasSeenMonthlyReflection(String monthKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_monthlyReflectionSeenKey) == monthKey;
  }

  static Future<void> markMonthlyReflectionSeen(String monthKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_monthlyReflectionSeenKey, monthKey);
  }

  // ── 감정 인식 루프: 월간 리플렉션 레터(프리미엄) 저장 ──
  static Box get reflectionLetterBox {
    if (_reflectionLetterBox == null || !_reflectionLetterBox!.isOpen) {
      throw Exception('StorageService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)');
    }
    return _reflectionLetterBox!;
  }

  static Future<void> saveReflectionLetter(ReflectionLetterEntry entry) async {
    await reflectionLetterBox.put(entry.id, entry.toMap());
  }

  static List<ReflectionLetterEntry> getReflectionLettersForMonth(
    String monthKey,
  ) {
    return reflectionLetterBox.values
        .map(
          (e) => ReflectionLetterEntry.fromMap(
            Map<dynamic, dynamic>.from(e as Map),
          ),
        )
        .where((e) => e.monthKey == monthKey)
        .toList();
  }

  // ── 데일리 카드뽑기(무의식) 히스토리 ──
  // 매일 완전 무작위로 뽑히는 카드를 영구적으로 축적합니다. '의식적 선택'
  // (LetterEntry)과 비교해 동시성/반복되는 그림자를 관찰하는 데 쓰입니다.
  static Box get dailyDrawBox {
    if (_dailyDrawBox == null || !_dailyDrawBox!.isOpen) {
      throw Exception('StorageService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)');
    }
    return _dailyDrawBox!;
  }

  static Future<void> saveDailyDraw(DailyDrawEntry entry) async {
    await dailyDrawBox.put(entry.id, entry.toMap());
  }

  static List<DailyDrawEntry> getAllDailyDraws() {
    final entries = dailyDrawBox.values
        .map(
          (e) => DailyDrawEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)),
        )
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  // ── 그림자 방울 한마디(BubbleMemo) ──
  // '오늘의 그림자 방울 터뜨리기' 중, 정식 편지보다 훨씬 가벼운 한마디를
  // 감정 고양이에게 남길 수 있는 선택 기록입니다. 편지(LetterEntry)와 같은
  // 저장 영역(Hive) 안에 별도 박스로 함께 관리되며, "짧은 메모" 타입으로
  // 뚜렷이 구분됩니다. 이후 같은 감정의 방울이 다시 생겼을 때, 그 고양이가
  // 이 한마디를 낮은 확률로 회상해주는 재료로 쓰입니다.
  static Box get bubbleMemoBox {
    if (_bubbleMemoBox == null || !_bubbleMemoBox!.isOpen) {
      throw Exception('StorageService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)');
    }
    return _bubbleMemoBox!;
  }

  static Future<void> saveBubbleMemo(BubbleMemoEntry entry) async {
    await bubbleMemoBox.put(entry.id, entry.toMap());
  }

  static List<BubbleMemoEntry> getAllBubbleMemos() {
    final entries = bubbleMemoBox.values
        .map(
          (e) => BubbleMemoEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)),
        )
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  /// 특정 감정 고양이에게 남겼던 한마디들을 최신순으로 반환합니다.
  static List<BubbleMemoEntry> getBubbleMemosForCat(String catId) {
    return getAllBubbleMemos().where((e) => e.catId == catId).toList();
  }

  /// 이 한마디를 방금 회상(캐릭터 대사창에 노출)했다고 표시합니다.
  /// 같은 한마디가 너무 자주 반복 회상되어 예측 가능해지지 않도록,
  /// 회상 빈도를 제한하는 데 쓰입니다.
  static Future<void> markBubbleMemoRecalled(String id) async {
    final raw = bubbleMemoBox.get(id);
    if (raw == null) return;
    final entry = BubbleMemoEntry.fromMap(
      Map<dynamic, dynamic>.from(raw as Map),
    );
    await bubbleMemoBox.put(
      id,
      entry.copyWith(lastRecalledAt: DateTime.now()).toMap(),
    );
  }

  // ── 유료(Basic 구독) 캐릭터 잠금 미리보기: 무료 사용자 안내/집계 ──
  // (기기 전체 공통, 계정과 무관 - 안내 배너는 기기당 1회만, 시도 집계는
  // 마케팅/전환 분석용 참고 지표이므로 계정 전환과 무관하게 누적됩니다)

  /// "42가지 감정으로도 충분히..." 안내 배너를 이미 봤는지 여부.
  /// 감정체크 화면 진입 시 1회만 노출하기 위한 플래그입니다.
  static const String _freeReassuranceSeenKey = 'free_tier_reassurance_seen_v1';

  static Future<bool> hasSeenFreeTierReassurance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_freeReassuranceSeenKey) ?? false;
  }

  static Future<void> markFreeTierReassuranceSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_freeReassuranceSeenKey, true);
  }

  /// 무료 사용자가 유료 캐릭터를 탭(선택 시도)한 횟수를 캐릭터별로 누적
  /// 집계합니다. 어떤 유료 감정이 구독 전환의 가장 강한 동기인지 분석하는
  /// 용도입니다(서버 없이 로컬에만 쌓이는 참고 지표).
  static const String _premiumAttemptPrefix = 'premium_attempt_count_';

  static Future<void> recordPremiumCatAttempt(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_premiumAttemptPrefix$catId';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  /// 특정 유료 캐릭터에 대한 누적 시도 횟수.
  static Future<int> getPremiumCatAttemptCount(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_premiumAttemptPrefix$catId') ?? 0;
  }

  /// 모든 유료 캐릭터의 누적 시도 횟수를 한 번에 조회합니다(분석/디버그용).
  static Future<Map<String, int>> getAllPremiumCatAttemptCounts(
    List<String> premiumCatIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, int>{};
    for (final id in premiumCatIds) {
      result[id] = prefs.getInt('$_premiumAttemptPrefix$id') ?? 0;
    }
    return result;
  }
}
