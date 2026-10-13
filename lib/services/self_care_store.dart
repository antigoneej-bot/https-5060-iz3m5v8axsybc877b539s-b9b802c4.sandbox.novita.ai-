import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/self_care_entry.dart';
import 'hive_encryption.dart';

/// This app keeps one local garden per device, also across sign-out.
/// Included in the user's existing encrypted file/cloud backup, never Analytics.
class SelfCareStore {
  SelfCareStore._();
  static final instance = SelfCareStore._();
  static const boxName = 'self_care_local_user';
  final revision = ValueNotifier<int>(0);
  Future<void> _tail = Future.value();
  Future<Box> _box() => HiveEncryption.openBox(boxName);

  Future<List<SelfCareEntry>> load() async {
    await _tail;
    final box = await _box();
    return [for (final key in box.keys) _read(key, box.get(key))]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  SelfCareEntry _read(dynamic key, dynamic data) {
    if (data is! Map) throw const FormatException('돌봄 기록 형식이 달라요.');
    final entry = SelfCareEntry.fromMap(data);
    if (entry.id != key) throw const FormatException('돌봄 기록이 일치하지 않아요.');
    return entry;
  }

  Future<void> _write(Future<void> Function(Box) action) {
    final result = _tail.then((_) async {
      final box = await _box();
      await action(box);
      await box.flush();
      revision.value++;
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> save(SelfCareEntry entry) {
    SelfCareEntry.fromMap(entry.toMap());
    return _write((box) async {
      if (box.containsKey(entry.id)) {
        // Same editor can retry after a flush failure, but not replace another record.
        final existing = _read(entry.id, box.get(entry.id));
        if (existing.createdAt != entry.createdAt) {
          throw StateError('이미 다른 기록이 있어요.');
        }
      }
      await box.put(entry.id, entry.toMap());
    });
  }

  Future<void> review(String id, CareFeedback feedback, int? afterComfort) =>
      _write((box) async {
        if (!box.containsKey(id)) throw StateError('이 기록이 삭제되었어요.');
        final entry = _read(id, box.get(id));
        final updated = entry.withFeedback(
          feedback,
          afterComfort,
          DateTime.now(),
        );
        SelfCareEntry.fromMap(updated.toMap());
        await box.put(id, updated.toMap());
      });

  Future<void> remove(String id) => _write((box) => box.delete(id));
}
