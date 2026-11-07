import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

/// Coordinates related private records before any individual store queue is
/// entered. A backup therefore observes either side of a deletion, never an
/// old copied quote together with an already deleted source.
///
/// Nested store operations join the current transaction. The owner stays held
/// until writes and rollback finish, even if a caller stops waiting. Detached
/// callbacks cannot reuse ownership after the transaction has completed.
class LocalRecordTransaction {
  static final _zoneKey = Object();
  static final _queue = LocalRecordQueue();

  static _RecordOperation? get _current {
    final value = Zone.current[_zoneKey];
    return value is _RecordOperation && value.active ? value : null;
  }

  /// Nested callers must await the real work; timing out inside an outer
  /// transaction could otherwise start its rollback while a write is running.
  static bool get isActive => _current != null;

  /// A consistent read or resumable merge. This serializes with atomic writes
  /// without rolling back an existing restore journal's incremental progress.
  static Future<T> run<T>(Future<T> Function() action) {
    if (_current != null) return action();
    return _queue.run(() async {
      final owner = _RecordOperation();
      try {
        return await runZoned(action, zoneValues: {_zoneKey: owner});
      } finally {
        owner.active = false;
      }
    });
  }

  /// Failed deletes restore all participating Hive records, including private
  /// copies already removed by nested stores. Capture each box before writing.
  /// This is an in-process transaction; it does not claim crash-safe atomicity
  /// across Hive files or protect against an unavailable physical storage disk.
  static Future<T> atomic<T>(Future<T> Function() action) => run(() async {
    final owner = _current!;
    if (owner.transaction != null) return action();
    final transaction = _RecordRollback();
    owner.transaction = transaction;
    try {
      return await action();
    } catch (error, stack) {
      final failures = await transaction.restore();
      if (failures.isNotEmpty) {
        Error.throwWithStackTrace(
          LocalRecordRollbackFailure(error, failures),
          stack,
        );
      }
      Error.throwWithStackTrace(error, stack);
    } finally {
      owner.transaction = null;
    }
  });

  static void capture(Box box, {Future<void> Function()? afterRollback}) {
    final transaction = _current?.transaction;
    if (transaction == null) {
      throw StateError('Private record write requires an atomic transaction');
    }
    transaction.boxes.putIfAbsent(
      box,
      () => {for (final key in box.keys) key: _copy(box.get(key))},
    );
    if (afterRollback != null) {
      transaction.refreshers[box] = afterRollback;
    }
  }

  static Object? _copy(Object? value) {
    if (value is Map) {
      return {for (final entry in value.entries) entry.key: _copy(entry.value)};
    }
    if (value is List) return value.map(_copy).toList();
    return value;
  }
}

/// A serial queue which releases completed caller-zone futures when idle.
/// Retaining a completed Future can strand a new caller in an obsolete
/// FakeAsync/request zone. In-flight successors still retain their predecessor.
class LocalRecordQueue {
  Future<void>? _tail;
  Object? _lastQueued;

  Future<void> get settled => _tail ?? Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final ticket = Object();
    final previous = _tail ?? Future<void>.value();
    _lastQueued = ticket;
    final operation = previous.then((_) async {
      try {
        return await action();
      } finally {
        if (identical(_lastQueued, ticket)) {
          _tail = null;
          _lastQueued = null;
        }
      }
    });
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }
}

class _RecordOperation {
  bool active = true;
  _RecordRollback? transaction;
}

class _RecordRollback {
  final boxes = <Box, Map<dynamic, dynamic>>{};
  final refreshers = <Box, Future<void> Function()>{};

  Future<List<Object>> restore() async {
    final failures = <Object>[];
    // Restore every box even if one storage operation fails. Report incomplete
    // recovery explicitly rather than silently claiming a successful rollback.
    for (final entry in boxes.entries.toList().reversed) {
      try {
        final box = entry.key;
        final previous = entry.value;
        await box.deleteAll(
          box.keys.where((key) => !previous.containsKey(key)).toList(),
        );
        await box.putAll(previous);
        await box.flush();
      } catch (error) {
        failures.add(error);
      }
    }
    for (final refresh in refreshers.values) {
      try {
        await refresh();
      } catch (error) {
        failures.add(error);
      }
    }
    return failures;
  }
}

class LocalRecordRollbackFailure implements Exception {
  final Object originalError;
  final List<Object> recoveryErrors;
  LocalRecordRollbackFailure(this.originalError, List<Object> errors)
    : recoveryErrors = List.unmodifiable(errors);

  @override
  String toString() =>
      '저장 공간 오류로 작업과 복구를 완료하지 못했어요. 앱 데이터를 지우지 말고 저장 공간을 확인해 주세요.';
}
