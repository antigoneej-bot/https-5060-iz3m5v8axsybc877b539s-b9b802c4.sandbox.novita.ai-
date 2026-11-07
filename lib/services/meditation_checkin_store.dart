import 'local_record_transaction.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hive_encryption.dart';

/// The backup key is retained for compatibility; on-device data is encrypted.
class MeditationCheckInStore {
  static const key = 'meditation.checkins';
  static const boxName = 'meditation_history_local_user';
  static final _queue = LocalRecordQueue();
  static Future<T> _run<T>(Future<T> Function(Box) action) =>
      _queue.run(() async {
        final name = '${boxName}__enc';
        final box = Hive.isBoxOpen(name)
            ? Hive.box(name)
            : await HiveEncryption.openBox(boxName);
        await _migrate(box);
        return action(box);
      });

  static Future<String?> read() => _run((box) async => box.get(key) as String?);

  /// Read/merge/write is serialized across library edits and backup restores.
  /// null means preserve the current record, including an unreadable legacy one.
  static Future<String?> update(String? Function(String?) change) =>
      _run((box) async {
        final current = box.get(key) as String?;
        final next = change(current);
        if (next != null && next != current) {
          await box.put(key, next);
          await box.flush();
        }
        return next ?? current;
      });

  static List<Map<String, dynamic>> rows(String raw) =>
      (jsonDecode(raw) as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();

  static Future<void> _migrate(Box box) async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(key);
    if (legacy != null) {
      final current = box.get(key) as String?;
      var merged = legacy;
      if (current != null && current != legacy) {
        try {
          final local = rows(current);
          final seen = local.map((row) => row['session']).toSet();
          merged = jsonEncode([
            ...local,
            ...rows(legacy).where((row) => seen.add(row['session'])),
          ]);
        } catch (_) {
          // Retain even malformed original bytes, without keeping plaintext.
          await box.put('unreadable_legacy', legacy);
          merged = current;
        }
      }
      await box.put(key, merged);
      await box.flush();
      if (box.get(key) != merged) throw StateError('checkin-migration');
      if (!await prefs.remove(key)) {
        await prefs.reload();
        throw StateError('checkin-plaintext-removal');
      }
    }
    // Pre-1.0.9 used individual records in this already encrypted box.
    if (box.get('legacy_box_imported') == true) return;
    const oldName = 'meditation_checkins_local_user';
    if (await Hive.boxExists(oldName) ||
        await Hive.boxExists('${oldName}__enc')) {
      final old = await HiveEncryption.openBox(oldName);
      final raw = box.get(key) as String?;
      List<Map<String, dynamic>> local;
      try {
        local = raw == null ? [] : rows(raw);
      } catch (_) {
        // Preserve both sources; a malformed primary must not be overwritten.
        return;
      }
      final seen = local.map((row) => row['session']).toSet();
      for (final value in old.values) {
        if (value is Map &&
            value['session'] is String &&
            seen.add(value['session'])) {
          local.add(Map<String, dynamic>.from(value));
        }
      }
      if (local.isNotEmpty) await box.put(key, jsonEncode(local));
    }
    await box.put('legacy_box_imported', true);
    await box.flush();
  }
}
