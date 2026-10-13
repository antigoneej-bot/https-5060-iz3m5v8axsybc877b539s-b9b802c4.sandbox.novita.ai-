import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/meditation_check_in_record.dart';
import 'hive_encryption.dart';

/// Private local history, included only in the user's encrypted backup.
class MeditationCheckInStore {
  MeditationCheckInStore._();
  static final instance = MeditationCheckInStore._();
  static const boxName = 'meditation_checkins_local_user';
  static const legacyKey = 'meditation.checkins';
  Future<void> _tail = Future.value();

  Future<T> _run<T>(Future<T> Function(Box) action) {
    final result = _tail.then((_) async {
      final box = await HiveEncryption.openBox(boxName);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(legacyKey);
      if (raw != null) {
        final entries = MeditationCheckInRecord.parseLegacy(jsonDecode(raw));
        for (final entry in entries) {
          if (!box.containsKey(entry.session)) {
            await box.put(entry.session, entry.toMap());
          }
          final saved = box.get(entry.session);
          if (saved is! Map ||
              MeditationCheckInRecord.fromMap(saved).session != entry.session) {
            throw const FormatException('보호 저장된 명상 후기가 일치하지 않아요.');
          }
        }
        await box.flush();
        // Only remove plaintext once the encrypted copy is durably stored.
        if (!await prefs.remove(legacyKey)) {
          throw StateError('명상 후기의 보호 저장을 마치지 못했어요. 다시 시도해 주세요.');
        }
      }
      return action(box);
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> prepareBackup() => _run((box) => box.flush());

  Future<List<Map<String, dynamic>>> load() => _run((box) async {
    final entries = <MeditationCheckInRecord>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is! Map) throw const FormatException('명상 후기 형식이 달라요.');
      final record = MeditationCheckInRecord.fromMap(value);
      if (record.session != key)
        throw const FormatException('명상 후기가 일치하지 않아요.');
      entries.add(record);
    }
    entries.sort((a, b) => b.at.compareTo(a.at));
    return entries.take(90).map((v) => v.toMap()).toList();
  });

  Future<void> remove(String session) => _run((box) async {
    await box.delete(session);
    await box.flush();
  });

  Future<MeditationCheckInRecord?> find(String session) => _run((box) async {
    final value = box.get(session);
    if (value == null) return null;
    if (value is! Map) throw const FormatException('명상 후기 형식이 달라요.');
    final record = MeditationCheckInRecord.fromMap(value);
    if (record.session != session)
      throw const FormatException('명상 후기가 일치하지 않아요.');
    return record;
  });

  Future<MeditationCheckInRecord> save(MeditationCheckInRecord entry) =>
      _run((box) async {
        MeditationCheckInRecord.fromMap(entry.toMap());
        if (!box.containsKey(entry.session)) {
          await box.put(entry.session, entry.toMap());
        }
        await box.flush();
        final stored = box.get(entry.session);
        if (stored is! Map) throw const FormatException('명상 후기 형식이 달라요.');
        final record = MeditationCheckInRecord.fromMap(stored);
        if (record.session != entry.session)
          throw const FormatException('명상 후기가 일치하지 않아요.');
        return record;
      });
}
