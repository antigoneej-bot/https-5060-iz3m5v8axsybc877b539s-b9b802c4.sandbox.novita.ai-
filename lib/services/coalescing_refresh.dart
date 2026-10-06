import 'dart:async';

/// A request arriving during a read schedules another read before completion.
/// All callers wait for the same drain; reads never overlap.
class CoalescingRefresh {
  CoalescingRefresh(this.refresh);
  final Future<void> Function() refresh;
  Future<void>? _flight;
  bool _requested = false;
  bool get isRunning => _flight != null;

  Future<void> request() {
    _requested = true;
    if (_flight != null) return _flight!;
    final done = Completer<void>();
    _flight = done.future;
    unawaited(_drain(done));
    return done.future;
  }

  Future<void> _drain(Completer<void> done) async {
    try {
      while (_requested) {
        _requested = false;
        await refresh();
      }
      _flight = null;
      done.complete();
    } catch (error, stack) {
      _flight = null;
      done.completeError(error, stack);
    }
  }
}
