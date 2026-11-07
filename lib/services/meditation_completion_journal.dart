import 'local_record_transaction.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_encryption.dart';

/// Durable outbox. Remove an event only after every idempotent effect succeeds.
/// This is local recovery metadata, deliberately excluded from transferable backups.
class MeditationCompletionJournal {
  static const boxName = 'meditation_completions_local_user';
  static final _queue = LocalRecordQueue();
  static Future<T> _run<T>(Future<T> Function(Box) action) =>
      _queue.run(() async {
        final name = '${boxName}__enc';
        final box = Hive.isBoxOpen(name)
            ? Hive.box(name)
            : await HiveEncryption.openBox(boxName);
        return action(box);
      });
  static Future<void> enqueue(Map<String, dynamic> event) => _run((box) async {
    await box.put(event['id'], event);
    await box.flush();
  });
  static Future<void> drain(
    Future<void> Function(Map<String, dynamic>) apply, {
    bool courseOnly = false,
  }) => _run((box) async {
    for (final key in box.keys.toList()) {
      final event = Map<String, dynamic>.from(box.get(key) as Map);
      if (courseOnly && event['reward'] == true) continue;
      await apply(event);
      await box.delete(key);
      await box.flush();
    }
  });
}
