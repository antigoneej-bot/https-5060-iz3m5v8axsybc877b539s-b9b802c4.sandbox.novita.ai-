import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/self_care_entry.dart';
import 'hive_encryption.dart';
import 'local_record_transaction.dart';
import 'garden_memory_book_store.dart';

/// This app keeps one local garden per device, also across sign-out.
/// Included in the user's existing encrypted file/cloud backup, never Analytics.
class SelfCareStore {
  SelfCareStore._()
    : _openBox = (() => HiveEncryption.openBox(boxName)),
      _clock = DateTime.now;
  @visibleForTesting
  SelfCareStore.forTesting({
    required Future<Box> Function() openBox,
    DateTime Function()? clock,
  }) : _openBox = openBox,
       _clock = clock ?? DateTime.now;
  final Future<Box> Function() _openBox;
  final DateTime Function() _clock;
  static final instance = SelfCareStore._();
  static const boxName = 'self_care_local_user';
  final revision = ValueNotifier<int>(0);
  final _queue = LocalRecordQueue();
  Future<Box> _box() => _openBox();

  Future<List<SelfCareEntry>> load() => LocalRecordTransaction.run(() async {
    await _queue.settled;
    final box = await _box();
    return [for (final key in box.keys) _read(key, box.get(key))]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  SelfCareEntry _read(dynamic key, dynamic data) {
    if (data is! Map) throw const FormatException('돌봄 기록 형식이 달라요.');
    final entry = SelfCareEntry.fromMap(data);
    if (entry.id != key) throw const FormatException('돌봄 기록이 일치하지 않아요.');
    return entry;
  }

  Future<void> _write(Future<void> Function(Box) action) =>
      LocalRecordTransaction.atomic(() => _queuedWrite(action));

  Future<void> _queuedWrite(Future<void> Function(Box) action) =>
      _queue.run(() async {
        final box = await _box();
        LocalRecordTransaction.capture(
          box,
          afterRollback: () async {
            revision.value++;
          },
        );
        await action(box);
        await box.flush();
        revision.value++;
      });

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

  DateTime _eventTime(SelfCareEntry entry) {
    var floor = entry.reviewedAt ?? entry.completedAt ?? entry.createdAt;
    if (floor.isBefore(entry.createdAt)) floor = entry.createdAt;
    final now = _clock();
    return now.isBefore(floor) ? floor : now;
  }

  Future<void> review(String id, CareFeedback feedback, int? afterComfort) =>
      _write((box) async {
        if (!box.containsKey(id)) throw StateError('이 기록이 삭제되었어요.');
        final entry = _read(id, box.get(id));
        final updated = entry.withFeedback(
          feedback,
          afterComfort,
          _eventTime(entry),
        );
        SelfCareEntry.fromMap(updated.toMap());
        await box.put(id, updated.toMap());
      });

  Future<void> complete(String id, {CareFeedback? feedback}) =>
      _write((box) async {
        if (!box.containsKey(id)) throw StateError('이 기록이 삭제되었어요.');
        final entry = _read(id, box.get(id));
        if (entry.action == null) throw StateError('돌봄 행동이 아니에요.');
        final now = _eventTime(entry);
        final completed = entry.withCompletion(now);
        final updated = feedback == null
            ? completed
            : completed.withFeedback(feedback, null, now);
        SelfCareEntry.fromMap(updated.toMap());
        await box.put(id, updated.toMap());
      });

  Future<void> removeForLetter(String letterId) => _write((box) async {
    final ids = [
      for (final key in box.keys)
        if (_read(key, box.get(key)).sourceLetterId == letterId) key,
    ];
    await box.deleteAll(ids);
  });

  Future<void> clear() => _write((box) async {
    await box.clear();
  });

  Future<void> remove(String id) async {
    // Keep cross-store work outside the action queue: books may read actions.
    await GardenMemoryBookStore.instance.removeCareSource(
      'action:$id',
      () => _write((box) => box.delete(id)),
    );
  }
}
