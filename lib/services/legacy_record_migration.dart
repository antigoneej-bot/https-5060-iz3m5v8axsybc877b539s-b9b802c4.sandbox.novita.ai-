/// Resumes an interrupted copy without replacing records already in use.
/// The caller retains the source and only marks migration complete after this
/// method succeeds for every store.
class LegacyRecordMigration {
  static String completionKey(String scope) =>
      'guest_scope_migrated_v2_to_$scope';

  static bool shouldAutoMerge({
    required bool legacyCompleted,
    required bool currentCompleted,
  }) => !legacyCompleted && !currentCompleted;

  static Future<int> mergeMissing({
    required Iterable<Object> sourceKeys,
    required Object? Function(Object key) readSource,
    required bool Function(Object key) targetContains,
    required Future<void> Function(Object key, Object? value) writeTarget,
    required Future<void> Function() flushTarget,
  }) async {
    final keys = sourceKeys.toList(growable: false);
    var copied = 0;
    for (final key in keys) {
      if (targetContains(key)) continue;
      await writeTarget(key, readSource(key));
      copied++;
    }
    // Even a retry that finds every key must flush: a previous attempt may
    // have copied the final value but failed before durable completion.
    await flushTarget();
    if (keys.any((key) => !targetContains(key))) {
      throw StateError('이전 기록의 복사를 마치지 못했어요. 다시 시도해 주세요.');
    }
    return copied;
  }
}
