import '../models/meditation_completion_record.dart';
import 'hive_encryption.dart';

/// Device-local recovery queue, not an exportable reward entitlement.
class MeditationCompletionJournal {
  static final instance = MeditationCompletionJournal();
  static const boxName = 'meditation_completion_pending_local_user';
  Future<void> _tail = Future.value();
  Future<T> _run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> save(MeditationCompletionRecord record) => _run(() async {
    MeditationCompletionRecord.fromMap(record.toMap());
    final box = await HiveEncryption.openBox(boxName);
    if (!box.containsKey(record.id)) await box.put(record.id, record.toMap());
    await box.flush();
  });
  Future<List<MeditationCompletionRecord>> load() => _run(() async {
    final box = await HiveEncryption.openBox(boxName);
    final records = <MeditationCompletionRecord>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is! Map) throw const FormatException('명상 완료 기록 형식이 달라요.');
      final record = MeditationCompletionRecord.fromMap(value);
      if (record.id != key) throw const FormatException('명상 완료 기록이 일치하지 않아요.');
      records.add(record);
    }
    records.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return records;
  });
  Future<void> remove(String id) => _run(() async {
    final box = await HiveEncryption.openBox(boxName);
    await box.delete(id);
    await box.flush();
  });
}
