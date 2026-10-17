import 'dart:convert';
import '../mongi/integration/mongi_garden_store.dart';
import '../mongi/integration/session_transaction.dart';
import 'personal_reply_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter_entry.dart';
import '../models/reflection_letter_entry.dart';
import '../models/daily_draw_entry.dart';
import '../models/bubble_memo_entry.dart';
import 'hive_encryption.dart';
import 'legacy_record_migration.dart';

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

  static const legacyRecoveryLabels = <String, String>{
    'letter_entries': '편지',
    'reflection_letters': '성찰 편지',
    'daily_draw_entries': '오늘의 고양이 기록',
    'bubble_memo_entries': '마음 거품 메모',
    'buried_emotions': '묻어둔 마음',
    'cat_memories': '고양이와의 추억',
    'usage_history': '이용 기록',
    'promise_entries': '오늘의 약속',
    'special_letters': '특별 편지',
  };
  static Future<void> _legacyMigrationTail = Future.value();

  static Future<T> _legacySerial<T>(Future<T> Function() action) {
    final next = _legacyMigrationTail.then((_) => action());
    _legacyMigrationTail = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return next;
  }

  /// 예전 기본 UID(`guest`)에 쌓인 prefs/Hive를 [userId](`local_user`)로
  /// 한 번만 복사합니다. B-1에서 계정 없이 로컬 UID로 바꾼 뒤, 기존
  /// 누적 데이터가 "사라진 것처럼" 보이던 문제를 막습니다.
  ///
  /// 중단된 복사를 키 단위로 재개합니다. v1 완료 플래그가 남아 있어도
  /// 누락된 대상 키가 있을 수 있지만(의도적으로 삭제됐을 가능성도 있음),
  /// 자동 복사는 완료되지 않은 경우에만 수행하고, 완료된 이후의 복구는
  /// 아래의 명시적 수동 복구([getLegacyRecoverySummary], [restoreLegacyGuestData])를
  /// 통해서만 가능합니다. 어떤 경우에도 현재 값이 있는 키는 덮어쓰지 않습니다.
  static Future<void> migrateGuestScopeIfNeeded(String userId) =>
      _legacySerial(() async {
        if (userId.isEmpty || userId == _defaultScope) return;
        final prefs = await SharedPreferences.getInstance();
        final oldFlag = 'guest_scope_migrated_v1_to_$userId';
        final flag = LegacyRecordMigration.completionKey(userId);
        if (!LegacyRecordMigration.shouldAutoMerge(
          legacyCompleted: prefs.getBool(oldFlag) == true,
          currentCompleted: prefs.getBool(flag) == true,
        )) {
          await migrateMeditationCheckInsIfNeeded();
          return;
        }

        // SharedPreferences: guest_* → {userId}_* (대상 키가 비어 있을 때만)
        for (final key in prefs.getKeys().toList()) {
          if (!key.startsWith('${_defaultScope}_')) continue;
          // 완료 플래그 자체는 사용자 설정이 아니라 마이그레이션 메타데이터입니다.
          if (key.startsWith('guest_scope_migrated_')) continue;
          final newKey = '$userId${key.substring(_defaultScope.length)}';
          if (prefs.containsKey(newKey)) continue;
          final value = prefs.get(key);
          final stored = switch (value) {
            bool v => await prefs.setBool(newKey, v),
            int v => await prefs.setInt(newKey, v),
            double v => await prefs.setDouble(newKey, v),
            String v => await prefs.setString(newKey, v),
            List<String> v => await prefs.setStringList(newKey, v),
            _ => false,
          };
          if (!stored) throw StateError('이전 설정을 저장하지 못했어요. 다시 시도해 주세요.');
        }
        for (final prefix in legacyRecoveryLabels.keys) {
          await _mergeLegacyBox(prefix, userId);
        }
        if (!await prefs.setBool(flag, true)) {
          throw StateError('이전 기록의 복원 완료를 저장하지 못했어요. 다시 시도해 주세요.');
        }

        await migrateMeditationCheckInsIfNeeded();
      });

  /// 현재 범위(scope)에 없는 레코드 개수만 반환합니다. 본문은 절대
  /// storage 밖으로 노출하지 않습니다. 일부 후보는 v1 이후 의도적으로
  /// 삭제됐을 수 있으므로, 호출자는 명시적 복구를 제안하기 전에 이
  /// 사실을 사용자에게 안내해야 합니다.
  static Future<Map<String, int>> getLegacyRecoverySummary({
    String userId = 'local_user',
  }) => _legacySerial(() async {
    if (userId.isEmpty || userId == _defaultScope) return <String, int>{};
    final result = <String, int>{};
    for (final prefix in legacyRecoveryLabels.keys) {
      final missing = await _withLegacyBoxes<int>(
        prefix,
        userId,
        noSource: 0,
        createTarget: false,
        action: (source, target) async =>
            source.keys.where((key) => target?.containsKey(key) != true).length,
      );
      if (missing > 0) result[prefix] = missing;
    }
    return result;
  });

  /// 사용자 확인 후에만 호출하세요: 의도적으로 삭제했던 이전 기록이
  /// 되살아날 수 있습니다. 기존 값은 항상 우선하며, 쓰기나 flush가
  /// 실패하면 암호화된 guest 원본은 그대로 보존됩니다.
  static Future<int> restoreLegacyGuestData({String userId = 'local_user'}) =>
      _legacySerial(() async {
        if (userId.isEmpty || userId == _defaultScope) return 0;
        var added = 0;
        for (final prefix in legacyRecoveryLabels.keys) {
          added += await _mergeLegacyBox(prefix, userId);
        }
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setBool(
          LegacyRecordMigration.completionKey(userId),
          true,
        )) {
          throw StateError('이전 기록의 복원 완료를 저장하지 못했어요. 다시 시도해 주세요.');
        }
        return added;
      });

  static Future<int> _mergeLegacyBox(String prefix, String userId) =>
      _withLegacyBoxes<int>(
        prefix,
        userId,
        noSource: 0,
        createTarget: true,
        action: (source, target) => LegacyRecordMigration.mergeMissing(
          sourceKeys: source.keys.cast<Object>(),
          readSource: (key) => source.get(key),
          targetContains: (key) => target!.containsKey(key),
          writeTarget: (key, value) => target!.put(key, value),
          flushTarget: () => target!.flush(),
        ),
      );

  static Future<bool> _legacyBoxExists(String name) async =>
      await Hive.boxExists(name) || await Hive.boxExists('${name}__enc');

  static Future<T> _withLegacyBoxes<T>(
    String prefix,
    String userId, {
    required T noSource,
    required bool createTarget,
    required Future<T> Function(Box source, Box? target) action,
  }) async {
    final fromName = '${prefix}_$_defaultScope';
    final toName = '${prefix}_$userId';
    if (!await _legacyBoxExists(fromName)) return noSource;
    final closeSource = !Hive.isBoxOpen('${fromName}__enc');
    final closeTarget = !Hive.isBoxOpen('${toName}__enc');
    Box? source, target;
    try {
      source = await HiveEncryption.openBox(fromName);
      if (source.isEmpty) return noSource;
      if (createTarget || await _legacyBoxExists(toName)) {
        target = await HiveEncryption.openBox(toName);
      }
      return await action(source, target);
    } finally {
      // 이미 다른 서비스/provider가 쓰고 있는 박스는 닫지 않습니다.
      try {
        if (closeTarget && target?.isOpen == true) await target!.close();
      } finally {
        if (closeSource && source?.isOpen == true) await source!.close();
      }
    }
  }

  /// 구버전(1.0.8+11 이하)은 명상 체크인을 암호화된 Hive 박스
  /// (`meditation_checkins_local_user`, 레코드: session/guide/feeling/at)에
  /// 저장했습니다. 이후 버전은 SharedPreferences 키
  /// `meditation.checkins`(JSON 배열, 동일한 필드)로 단순화되었습니다.
  /// 두 형식의 필드가 완전히 동일하므로, 과거 Hive 기록을 1회만
  /// SharedPreferences 쪽으로 안전하게 병합합니다. 대상 키가 비어 있을
  /// 때만 동작하며, 이미 있는 기록은 건드리지 않습니다.
  static const String _meditationCheckInMigratedKey =
      'meditation_checkins_migrated_v1';
  static const String _legacyMeditationCheckInBoxName =
      'meditation_checkins_local_user';
  static const String _meditationCheckInPrefsKey = 'meditation.checkins';

  static Future<void> migrateMeditationCheckInsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_meditationCheckInMigratedKey) == true) return;
    try {
      final legacyExists =
          await Hive.boxExists(_legacyMeditationCheckInBoxName) ||
          await Hive.boxExists('${_legacyMeditationCheckInBoxName}__enc');
      if (!legacyExists) {
        await prefs.setBool(_meditationCheckInMigratedKey, true);
        return;
      }

      final box = await HiveEncryption.openBox(
        _legacyMeditationCheckInBoxName,
      );
      if (box.isEmpty) {
        await box.close();
        await prefs.setBool(_meditationCheckInMigratedKey, true);
        return;
      }

      // 이미 신규 형식으로 기록이 있다면(현재 기기 값 우선), Hive 쪽은
      // 건드리지 않고 마이그레이션 완료로만 표시합니다.
      final existingRaw = prefs.getString(_meditationCheckInPrefsKey);
      final existing = <Map<String, dynamic>>[];
      if (existingRaw != null) {
        try {
          final decoded = jsonDecode(existingRaw);
          if (decoded is List) {
            existing.addAll(
              decoded
                  .whereType<Map>()
                  .map((v) => Map<String, dynamic>.from(v)),
            );
          }
        } catch (_) {
          /* 손상된 기존 값은 무시하고 아래에서 새로 구성합니다. */
        }
      }

      final existingSessions = existing
          .map((v) => v['session'])
          .whereType<String>()
          .toSet();

      final merged = <Map<String, dynamic>>[...existing];
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is! Map) continue;
        final session = value['session'];
        final guide = value['guide'];
        final feeling = value['feeling'];
        final at = value['at'];
        if (session is! String ||
            session.trim().isEmpty ||
            guide is! String ||
            feeling is! String ||
            !const {'better', 'same', 'worse'}.contains(feeling) ||
            at is! String ||
            DateTime.tryParse(at) == null) {
          continue; // 형식이 다른 레코드는 건너뜀 (기존 기록 보존 우선)
        }
        if (existingSessions.contains(session)) continue;
        merged.add({
          'session': session,
          'guide': guide,
          'feeling': feeling,
          'at': at,
        });
        existingSessions.add(session);
      }

      merged.sort((a, b) {
        final da = DateTime.tryParse(a['at'] as String? ?? '');
        final db = DateTime.tryParse(b['at'] as String? ?? '');
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
      final limited = merged.take(90).toList();

      if (!await prefs.setString(
        _meditationCheckInPrefsKey,
        jsonEncode(limited),
      )) {
        return; // 저장 실패 시 플래그를 남기지 않아 다음 실행에 재시도
      }
      await box.close();
      await prefs.setBool(_meditationCheckInMigratedKey, true);
    } catch (_) {
      // 실패 시 플래그를 남기지 않아 다음 앱 실행에서 재시도합니다.
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
    _reflectionLetterBox = await HiveEncryption.openBox(
      'reflection_letters_$_uid',
    );
    _dailyDrawBox = await HiveEncryption.openBox('daily_draw_entries_$_uid');
    _bubbleMemoBox = await HiveEncryption.openBox('bubble_memo_entries_$_uid');
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
    if (!letterBox.containsKey(entry.id)) {
      await letterBox.put(entry.id, entry.toMap());
    }
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
    await MongiGardenStore.instance.reconcileRecordedDays();
    final sourceBox = letterBox;
    Box? cache;
    Object? previousSource;
    Object? previousCache;
    var captured = false;
    await PersonalReplyService.remove(
      'letter:$id',
      deleteSource: () async {
        if (!sourceBox.isOpen || !identical(sourceBox, letterBox)) {
          throw StateError('사용자가 변경됐어요. 기록을 다시 열어 주세요.');
        }
        cache = await HiveEncryption.openBox('reply_cache_local_user');
        previousSource = sourceBox.get(id);
        previousCache = cache!.get(id);
        captured = true;
        await cache!.delete(id);
        await cache!.flush();
        await sourceBox.delete(id);
        await sourceBox.flush();
      },
      restoreSource: () async {
        if (!captured ||
            !sourceBox.isOpen ||
            !identical(sourceBox, letterBox)) {
          return;
        }
        if (previousSource != null) await sourceBox.put(id, previousSource);
        await sourceBox.flush();
        if (cache?.isOpen == true) {
          if (previousCache != null) await cache!.put(id, previousCache);
          await cache!.flush();
        }
      },
    );
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
    final lastVisit = lastVisitDay != null
        ? _dateOnlyString(lastVisitDay)
        : null;
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
    if (list.length != raw.length || list.any((e) => !raw.contains(e))) {
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
        : today
                  .difference(
                    DateTime(startDate.year, startDate.month, startDate.day),
                  )
                  .inDays +
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

  // -- 방문 알림 (3일 이상 미접속 시 조건부 발송, 신규 사용자는 명시 동의) --
  static Future<bool> getCrisisEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_crisisEnabledKey) ?? false;
  }

  static Future<void> setCrisisEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_crisisEnabledKey, v);
  }

  // -- 스트릭 임박 알림 (오늘 미완료일 때 조건부 발송, 신규 사용자는 명시 동의) --
  static Future<bool> getStreakEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_streakEnabledKey) ?? false;
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
