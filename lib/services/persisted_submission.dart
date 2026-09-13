import 'dart:async';

/// One immutable payload per send attempt. Retrying a failed flush reuses its ID.
/// Post-save work cannot change a successful save into a failed submission.
class PersistedSubmission<T> {
  final T payload;
  final Future<void> Function(T) persist;
  final void Function(T) onSaved;
  final Future<void> Function(T) afterSaved;
  bool _saved = false;
  Future<void>? _flight;
  PersistedSubmission({required this.payload, required this.persist,
    required this.onSaved, required this.afterSaved});
  Future<void> submit() {
    if (_saved) return Future.value();
    return _flight ??= _run();
  }
  Future<void> _run() async {
    try {
      await persist(payload);
      _saved = true;
      // Post-commit callbacks must not trigger a resend of the same letter.
      try { onSaved(payload); } catch (_) {}
      unawaited(_finish());
    } finally { _flight = null; }
  }
  Future<void> _finish() async {
    try { await afterSaved(payload); } catch (_) {}
  }
}
