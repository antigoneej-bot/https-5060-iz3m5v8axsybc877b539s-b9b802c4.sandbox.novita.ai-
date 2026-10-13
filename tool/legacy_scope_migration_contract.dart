import '../lib/services/legacy_record_migration.dart';

int checked = 0;
void check(bool condition, String message) {
  if (!condition) throw StateError(message);
  checked++;
}

Future<void> rejects(Future<void> Function() action, String message) async {
  try {
    await action();
  } catch (_) {
    checked++;
    return;
  }
  throw StateError(message);
}

Future<void> main() async {
  final source = <Object, Object?>{'a': 'old', 'b': 'second', 'c': 'third'};
  final target = <Object, Object?>{'a': 'current', 'local': 'keep'};
  var writes = 0, flushes = 0;
  var failWrite = 2;
  var failFlush = false, loseKeyOnFlush = false;
  Future<int> merge() => LegacyRecordMigration.mergeMissing(
    sourceKeys: source.keys,
    readSource: (key) => source[key],
    targetContains: target.containsKey,
    writeTarget: (key, value) async {
      writes++;
      if (writes == failWrite) throw StateError('injected write failure');
      target[key] = value;
    },
    flushTarget: () async {
      flushes++;
      if (failFlush) throw StateError('injected flush failure');
      if (loseKeyOnFlush) target.remove('c');
    },
  );

  await rejects(() async {
    await merge();
  }, 'partial failure must surface');
  check(target['a'] == 'current', 'existing ID is never overwritten');
  check(
    target['b'] == 'second' && !target.containsKey('c'),
    'partial copy remains retryable',
  );
  check(target['local'] == 'keep', 'local-only record survives');
  check(source.length == 3, 'source remains intact');
  failWrite = -1;
  check(await merge() == 1, 'retry only copies the missing record');
  check(target['c'] == 'third', 'retry restores remaining record');
  final writesBeforeRepeat = writes;
  check(
    await merge() == 0 && writes == writesBeforeRepeat,
    'repeated merge is idempotent',
  );
  check(flushes == 2, 'every successful pass flushes, including no-op retry');

  target.remove('c');
  failFlush = true;
  await rejects(() async {
    await merge();
  }, 'flush failure must prevent completion');
  check(target.containsKey('c'), 'flush failure may follow a visible write');
  failFlush = false;
  final previousFlushes = flushes;
  check(
    await merge() == 0 && flushes == previousFlushes + 1,
    'retry re-flushes an uncertain final write',
  );

  loseKeyOnFlush = true;
  await rejects(() async {
    await merge();
  }, 'verification detects a missing key despite flush success');
  loseKeyOnFlush = false;
  check(await merge() == 1, 'verification failure can be retried');
  check(
    target.length == 4 && target['a'] == 'current',
    'all source keys and current values survive',
  );

  check(
    LegacyRecordMigration.shouldAutoMerge(
      legacyCompleted: false,
      currentCompleted: false,
    ),
    'unfinished v1 migration resumes automatically',
  );
  check(
    !LegacyRecordMigration.shouldAutoMerge(
      legacyCompleted: true,
      currentCompleted: false,
    ),
    'v1 completion requires explicit recovery, never revives deletions on launch',
  );
  check(
    !LegacyRecordMigration.shouldAutoMerge(
      legacyCompleted: false,
      currentCompleted: true,
    ),
    'v2 completion does not revive subsequently deleted records',
  );
  check(
    LegacyRecordMigration.completionKey('local_user') ==
        'guest_scope_migrated_v2_to_local_user',
    'new completion is versioned independently from the old marker',
  );
  print(
    'PASS: $checked legacy migration failure, retry, preservation and consent checks.',
  );
}
