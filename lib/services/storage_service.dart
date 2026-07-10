import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter_entry.dart';

/// 계정별로 편지 기록 · 연속 방문일 · 성장 단계를 저장합니다.
/// (사운드 설정처럼 기기 전체에 공통인 값은 계정과 무관하게 유지됩니다)
class StorageService {
  static const String _defaultScope = 'guest';
  static String _uid = _defaultScope;

  static Box? _letterBox;

  static Future<void> init() async {
    await Hive.initFlutter();
  }

  /// 로그인/자동 로그인 성공 시 호출해서 해당 계정 전용 저장 공간으로 전환합니다.
  static Future<void> setCurrentUser(String userId) async {
    if (_uid == userId && _letterBox != null && _letterBox!.isOpen) return;
    _uid = userId;
    if (_letterBox != null && _letterBox!.isOpen) {
      await _letterBox!.close();
    }
    _letterBox = await Hive.openBox('letter_entries_$_uid');
  }

  /// 로그아웃 시 호출해서 계정 전용 데이터 접근을 닫습니다.
  static Future<void> clearCurrentUser() async {
    if (_letterBox != null && _letterBox!.isOpen) {
      await _letterBox!.close();
    }
    _letterBox = null;
    _uid = _defaultScope;
  }

  static Box get letterBox {
    if (_letterBox == null || !_letterBox!.isOpen) {
      throw Exception('StorageService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)');
    }
    return _letterBox!;
  }

  static Future<void> saveLetter(LetterEntry entry) async {
    await letterBox.put(entry.id, entry.toMap());
  }

  static List<LetterEntry> getAllLetters() {
    final entries = letterBox.values
        .map((e) => LetterEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  static Future<void> deleteLetter(String id) async {
    await letterBox.delete(id);
  }

  // ---- Streak tracking (연속 방문일) via SharedPreferences (계정별 키) ----
  static String get _lastVisitKey => '${_uid}_last_visit_date';
  static String get _streakKey => '${_uid}_streak_count';

  static Future<int> updateStreakOnOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _dateOnlyString(DateTime.now());
    final lastVisit = prefs.getString(_lastVisitKey);
    int streak = prefs.getInt(_streakKey) ?? 0;

    if (lastVisit == null) {
      streak = 1;
    } else if (lastVisit == todayStr) {
      return streak == 0 ? 1 : streak;
    } else {
      final lastDate = DateTime.parse(lastVisit);
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

  static String _dateOnlyString(DateTime d) {
    return DateTime(d.year, d.month, d.day).toIso8601String();
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
    final days = prefs.getStringList(_growthDaysKey) ?? [];
    if (startStr == null) return (0, 0);

    final startDate = DateTime.parse(startStr);
    final elapsed = DateTime.now().difference(startDate).inDays;
    if (elapsed >= growthWindowDays) {
      return (0, 0);
    }
    return (days.length, elapsed + 1);
  }

  /// 오늘 미션(편지+명상)을 완수했을 때 호출합니다. 하루에 한 번만 온도가 오릅니다.
  static Future<(bool, int, int, int)> recordGrowthDay() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = _dateOnlyString(DateTime.now());
    String? startStr = prefs.getString(_growthStartKey);
    List<String> days = prefs.getStringList(_growthDaysKey) ?? [];
    int level = prefs.getInt(_growthLevelKey) ?? 1;

    bool expired = false;
    if (startStr != null) {
      final startDate = DateTime.parse(startStr);
      final elapsed = DateTime.now().difference(startDate).inDays;
      if (elapsed >= growthWindowDays) expired = true;
    }

    if (startStr == null || expired) {
      startStr = todayStr;
      days = [];
      await prefs.setString(_growthStartKey, startStr);
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

    final startDate = DateTime.parse(startStr);
    final elapsedNow = leveledUp
        ? 0
        : DateTime.now().difference(startDate).inDays + 1;
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

  // ---- Welcome Intro (앱 최초 실행 시 1회만 보여주는 프리미엄 웰컴 투어) ----
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

  // ---- Video Intro (앱 최초 실행 시 1회만 보여주는 짧은 인트로 영상) ----
  static const String _videoIntroDoneKey = 'video_intro_completed_v1';

  static Future<bool> isVideoIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_videoIntroDoneKey) ?? false;
  }

  static Future<void> setVideoIntroCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_videoIntroDoneKey, true);
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
  static const String _reminderEnabledKey = 'daily_reminder_enabled';
  static const String _reminderHourKey = 'daily_reminder_hour';
  static const String _reminderMinuteKey = 'daily_reminder_minute';

  static Future<bool> getReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledKey) ?? false;
  }

  static Future<void> setReminderEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, v);
  }

  /// 저장된 리마인더 시각을 반환합니다: (시, 분). 기본값은 오후 8시입니다.
  static Future<(int, int)> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_reminderHourKey) ?? 20;
    final minute = prefs.getInt(_reminderMinuteKey) ?? 0;
    return (hour, minute);
  }

  static Future<void> setReminderTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
  }
}
