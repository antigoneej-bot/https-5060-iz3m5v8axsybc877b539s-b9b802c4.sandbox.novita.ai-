import 'dart:async';
import 'cloud_service.dart';
import 'diagnostics_service.dart';

/// A timeout never retries a mutation. The caller must reconcile its receipt.
Future<T> awaitRequestStage<T>(
  Future<T> future,
  String code, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final clock = Stopwatch()..start();
  try {
    return await future.timeout(
      timeout,
      onTimeout: () => throw CloudException(code),
    );
  } finally {
    clock.stop();
    unawaited(
      DiagnosticsService.recordDuration(code, clock.elapsedMilliseconds),
    );
  }
}
