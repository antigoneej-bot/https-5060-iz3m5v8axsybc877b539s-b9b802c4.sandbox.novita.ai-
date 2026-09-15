import '../mongi/integration/mongi_garden_store.dart';
import '../mongi/integration/session_transaction.dart';
import '../mongi/integration/mongi_backup_schema.dart';
import '../mongi/integration/plant_memory.dart';
import '../mongi/integration/mongi_garden_data.dart';
import 'draft_service.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/letter_entry.dart';
import '../models/reflection_letter_entry.dart';
import '../models/daily_draw_entry.dart';
import '../models/bubble_memo_entry.dart';
import '../models/buried_emotion_entry.dart';
import '../models/memory_entry.dart';
import '../models/usage_history_entry.dart';
import '../models/promise_entry.dart';
import '../models/special_letter_entry.dart';
import '../data/shadow_cats_data.dart';
import 'hive_encryption.dart';

/// Additive restore: existing records always win. Pending journal makes a
/// partially applied merge resumable without deleting current records.
class BackupService {
  static const boxes = [
    'letter_entries','reflection_letters','daily_draw_entries','bubble_memo_entries',
    'buried_emotions','cat_memories','usage_history','promise_entries','special_letters',
    'drafts','reply_cache','personal_replies','reply_feedback','garden_memories','mongi_progress',
  ];
  static const globals = {'companion_name','onboarding_completed_v1',
    'welcome_intro_completed_v1','cat_browse_favorites_v1','bgm_enabled','sfx_enabled','bgm_volume'};
  static String? prefType(String key) {
    const globalTypes = {'companion_name':'string', 'onboarding_completed_v1':'bool',
      'welcome_intro_completed_v1':'bool', 'cat_browse_favorites_v1':'strings',
      'bgm_enabled':'bool', 'sfx_enabled':'bool', 'bgm_volume':'double'};
    if (globalTypes.containsKey(key)) return globalTypes[key];
    if (!key.startsWith('local_user_')) return null;
    final name = key.substring('local_user_'.length);
    const ints = {'care_temperature','care_growth_days','care_points',
      'care_total_points_earned','care_total_full_care_days','care_total_consumables_used',
      'care_total_pats','streak_count','growth_level'};
    const strings = {'mongi_garden_v1','care_last_date','care_companion_cat_id','care_attendance_counted_date',
      'daily_card_last_date','daily_card_last_cat_id','bubble_last_date',
      'last_visit_date','growth_challenge_start'};
    const lists = {'care_temp_history','care_owned_accessories','care_equipped_slots',
      'care_consumable_inventory','care_graduated_cats','care_unlocked_achievements',
      'bubble_session_cat_ids','bubble_popped_indices','growth_completed_days','journey_done'};
    const bools = {'care_fed_today','care_watered_today','care_bathed_today','care_cleaned_today',
      'care_breathing_today','care_walking_today','care_journaling_today','care_gratitude_today'};
    if (ints.contains(name) || RegExp(r'^care_activity_bonus_claimed_\d{4}-\d{2}-\d{2}$').hasMatch(name)) return 'int';
    if (bools.contains(name) || RegExp(r'^care_bonus_given_\d{4}-\d{2}-\d{2}$').hasMatch(name)) return 'bool';
    if (strings.contains(name)) return 'string';
    if (lists.contains(name)) return 'strings';
    return null;
  }
  static bool allowedPref(String key) => prefType(key) != null;
  static Future<Box> _journal() async => Hive.isBoxOpen('restore_journal__enc')
      ? Hive.box('restore_journal__enc')
      : Hive.openBox('restore_journal__enc', encryptionCipher: await HiveEncryption.cipher());
  static Future<Box?> _existing(String name) async {
    final logical = '${name}_local_user';
    if (!await Hive.boxExists(logical) && !await Hive.boxExists('${logical}__enc')) return null;
    return HiveEncryption.openBox(logical);
  }
  static Future<Map<String, dynamic>> snapshot() async {
    await DraftTextController.flushAll();
    return MongiGardenStore.instance.consistentRead(_snapshotCommitted);
  }
  static Future<Map<String, dynamic>> _snapshotCommitted() async {
    await SessionTransaction.recover();
    final data = <String, dynamic>{};
    for (final name in boxes) {
      final box = await _existing(name);
      if (box == null) { data[name] = []; continue; }
      await box.flush();
      data[name] = [for (final key in box.keys.toList()) if (name != 'mongi_progress' || MongiBackupSchema.allows(key)) {'key': key, 'value': box.get(key)}];
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final settings = <String, dynamic>{};
    for (final key in prefs.getKeys().where(allowedPref)) {
      final value = prefs.get(key);
      settings[key] = {'type': value is bool ? 'bool' : value is int ? 'int'
          : value is double ? 'double' : value is String ? 'string' : 'strings', 'value': value};
    }
    final result = <String, dynamic>{'schema': 1, 'createdAt': DateTime.now().toUtc().toIso8601String(), 'boxes': data, 'settings': settings};
    // Converts Hive nested maps to JSON-safe maps, rejecting unsupported values.
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(result)) as Map);
  }
  static void validate(Map<String, dynamic> snapshot) {
    if (snapshot['schema'] != 1 || snapshot['boxes'] is! Map || snapshot['settings'] is! Map ||
        DateTime.tryParse(snapshot['createdAt']?.toString() ?? '') == null) throw const FormatException('백업 구조가 올바르지 않아요.');
    final catIds = shadowCats.map((cat) => cat.id).toSet();
    var total = 0;
    for (final entry in (snapshot['boxes'] as Map).entries) {
      if (!boxes.contains(entry.key) || entry.value is! List) throw const FormatException('알 수 없는 기록 종류예요.');
      final seen = <Object>{};
      for (final row in entry.value as List) {
        if (++total > 50000 || row is! Map || (row['key'] is! String && row['key'] is! int) || !seen.add(row['key'] as Object)) throw const FormatException('잘못된 기록 항목이에요.');
        final value = row['value'];
        if (entry.key == 'mongi_progress') {
          MongiBackupSchema.validate(row['key'] as Object, value);
          continue;
        }
        if (entry.key == 'personal_replies') {
          if (row['key'] is! String || value is! String || value.length > 100000) throw const FormatException('잘못된 답장 기록이에요.');
          final metadata = jsonDecode(value);
          if (metadata is! Map || metadata['version'] != 1 || metadata['id'] != row['key'] ||
              metadata['reply'] is! String || metadata['parts'] is! List ||
              !(metadata['parts'] as List).every((part) => part is String) ||
              !{'listen','reflect','suggest'}.contains(metadata['style'])) throw const FormatException('잘못된 답장 기록이에요.');
          continue;
        }
        if (entry.key == 'garden_memories') {
          if (value is! Map) throw const FormatException('잘못된 식물 기록이에요.');
          final memory = PlantMemory.fromJson(value);
          if (row['key'] != memory.plantId) throw const FormatException('식물 기록이 일치하지 않아요.');
          continue;
        }
        if (entry.key == 'reply_feedback') {
          if (row['key'] is! String || !{'matched','off_topic','repeated'}.contains(value)) throw const FormatException('잘못된 답장 평가예요.');
          continue;
        }
        if (entry.key == 'drafts' || entry.key == 'reply_cache') {
          if (value is! String || value.length > 100000) throw const FormatException('잘못된 편지예요.');
          continue;
        }
        if (value is! Map) throw const FormatException('잘못된 기록이에요.');
        if (value.containsKey('catId') && !catIds.contains(value['catId'])) throw const FormatException('지원하지 않는 고양이 기록이에요.');
        switch (entry.key) {
          case 'letter_entries': LetterEntry.fromMap(value); break;
          case 'reflection_letters': ReflectionLetterEntry.fromMap(value); break;
          case 'daily_draw_entries': DailyDrawEntry.fromMap(value); break;
          case 'bubble_memo_entries': BubbleMemoEntry.fromMap(value); break;
          case 'buried_emotions': BuriedEmotionEntry.fromMap(value); break;
          case 'cat_memories': MemoryEntry.fromMap(value); break;
          case 'usage_history': UsageHistoryEntry.fromMap(value); break;
          case 'promise_entries': PromiseEntry.fromMap(value); break;
          case 'special_letters': SpecialLetterEntry.fromMap(value); break;
        }
      }
    }
    for (final entry in (snapshot['settings'] as Map).entries) {
      if (entry.key is! String || !allowedPref(entry.key as String) || entry.value is! Map) throw const FormatException('허용되지 않은 설정이에요.');
      final v = entry.value['value'];
      final valid = switch (entry.value['type']) {
        'bool' => v is bool, 'int' => v is int, 'double' => v is num,
        'string' => v is String, 'strings' => v is List && v.every((e) => e is String), _ => false,
      };
      if (!valid || entry.value['type'] != prefType(entry.key as String)) throw const FormatException('설정 값이 올바르지 않아요.');
      if (entry.key == 'local_user_mongi_garden_v1') {
        MongiGardenData.fromJson(Map<String, dynamic>.from(jsonDecode(v as String) as Map));
      }
    }
  }
  static int count(Map<String, dynamic> data) => (data['boxes'] as Map).values.fold<int>(0, (sum, rows) => sum + (rows as List).length);
  static Future<bool> hasLocalRecords() async {
    // Game progress exists independently of journal entries. Preserve even an
    // unreadable snapshot so importing a backup cannot silently erase it.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('local_user_mongi_garden_v1')) return true;
    for (final name in boxes.where((name) => !{'drafts','reply_cache','personal_replies','reply_feedback'}.contains(name))) {
      final box = await _existing(name);
      if (box != null && box.isNotEmpty) return true;
    }
    return false;
  }
  static Future<int> restore(Map<String, dynamic> data) async {
    validate(data);
    final journal = await _journal();
    if (journal.containsKey('pending') || journal.containsKey('deferred')) throw StateError('이전 복원을 마치려면 앱을 다시 열어 주세요.');
    await journal.put('pending', {'data': data, 'restoreProfile': !await hasLocalRecords()});
    await journal.flush();
    return resumePending();
  }
  // Keep the source journal for later retry; do not roll back merged records.
  static Future<void> deferPending() async {
    final journal = await _journal();
    final pending = journal.get('pending');
    if (pending == null) return;
    if (journal.containsKey('deferred') &&
        jsonEncode(journal.get('deferred')['data']) != jsonEncode(pending['data'])) {
      throw StateError('다른 보류 복원이 이미 있어요.');
    }
    await journal.put('deferred', {'data': pending['data'], 'restoreProfile': false});
    await journal.flush();
    await journal.delete('pending');
    await journal.flush();
  }
  static Future<void> archiveDeferred() async {
    final journal = await _journal();
    if (journal.containsKey('pending')) throw StateError('진행 중인 복원이 있어요. 앱을 다시 열어 보류해 주세요.');
    final deferred = journal.get('deferred');
    if (deferred == null) return;
    await journal.put('archived_${DateTime.now().microsecondsSinceEpoch}', deferred);
    await journal.flush();
    await journal.delete('deferred');
    await journal.flush();
  }
  static Future<bool> hasPending() async => (await _journal()).containsKey('pending');
  static Future<bool> hasDeferred() async => (await _journal()).containsKey('deferred');
  static Future<int> retryDeferred() async {
    final journal = await _journal();
    final deferred = journal.get('deferred');
    if (deferred == null) return resumePending();
    if (!journal.containsKey('pending')) {
      await journal.put('pending', deferred);
      await journal.flush();
    }
    final added = await resumePending();
    await journal.delete('deferred');
    await journal.flush();
    return added;
  }
  static Future<int> resumePending() async {
    final journal = await _journal();
    final pending = journal.get('pending');
    if (pending == null) return 0;
    final data = Map<String, dynamic>.from(pending['data'] as Map);
    validate(data);
    var added = 0;
    for (final entry in (data['boxes'] as Map).entries) {
      final box = await HiveEncryption.openBox('${entry.key}_local_user');
      for (final row in entry.value as List) {
        if (!box.containsKey(row['key'])) { await box.put(row['key'], row['value']); added++; }
      }
      await box.flush();
    }
    final prefs = await SharedPreferences.getInstance();
    for (final entry in (data['settings'] as Map).entries) {
      // Also protect snapshots written since a restore was queued, including
      // journals created by an older app version with restoreProfile=true.
      if (entry.key == 'local_user_mongi_garden_v1' &&
          prefs.containsKey(entry.key)) {
        continue;
      }
      if (pending['restoreProfile'] != true && prefs.containsKey(entry.key)) continue;
      final v = entry.value['value'];
      final key = entry.key as String;
      final stored = switch (entry.value['type']) {
        'bool' => await prefs.setBool(key, v as bool),
        'int' => await prefs.setInt(key, v as int),
        'double' => await prefs.setDouble(key, (v as num).toDouble()),
        'string' => await prefs.setString(key, v as String),
        'strings' => await prefs.setStringList(key, List<String>.from(v as List)),
        _ => false,
      };
      if (!stored) throw StateError('복원 설정을 저장하지 못했어요.');
    }
    await journal.delete('pending');
    await journal.flush();
    return added;
  }
}
