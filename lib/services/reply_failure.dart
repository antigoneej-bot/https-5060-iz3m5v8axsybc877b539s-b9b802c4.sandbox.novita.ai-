import 'dart:async';
import 'access_policy.dart';

/// Stage and exception type only: never expose diary text, tokens or key data.
class ReplyFailure implements Exception {
  final String stage;
  final String kind;
  const ReplyFailure(this.stage, this.kind);
  static Future<T> step<T>(String stage, Future<T> Function() action,
      {Duration? timeout}) async {
    try {
      final task = Future<T>.sync(action);
      return await (timeout == null ? task : task.timeout(timeout));
    } on SubscriptionRequired { rethrow;
    } on ReplyFailure { rethrow;
    } catch (error) { throw ReplyFailure(stage, error.runtimeType.toString()); }
  }
  static String description(Object? error) {
    if (error is ReplyFailure) return '확인 번호: R11-${error.stage}-${error.kind}';
    if (error is TimeoutException) return '확인 번호: R11-WAIT-TimeoutException';
    return '확인 번호: R11-UI-${error.runtimeType}';
  }
  @override
  String toString() => description(this);
}
