import 'dart:async';

/// Optional online work never controls whether the locally saved garden opens.
/// Calls for one account coalesce; a late result from another account cannot
/// replace the current screen's status. Each operation retains its own outbox.
class GardenBackgroundSync {
  void Function()? onChanged;
  bool syncing = false;
  bool failed = false;
  int _generation = 0;
  String? _owner;
  Future<void>? _pending;

  Future<void> refresh({
    required String owner,
    required bool Function() isCurrentOwner,
    required Future<void> Function() sendPendingFlowers,
    required Future<void> Function() receiveCheers,
  }) {
    if (_owner == owner && _pending != null) return _pending!;
    if (!isCurrentOwner()) return Future.value();
    _owner = owner;
    final generation = ++_generation;
    syncing = true;
    failed = false;
    onChanged?.call();
    final task = Future<void>(() async {
      var failure = false;
      try {
        await Future.wait<void>([
          Future<void>.sync(sendPendingFlowers),
          Future<void>.sync(receiveCheers),
        ]);
      } catch (_) {
        failure = true;
      }
      if (generation != _generation) return;
      _pending = null;
      syncing = false;
      failed = isCurrentOwner() && failure;
      onChanged?.call();
    });
    _pending = task;
    return task;
  }

  void dispose() {
    ++_generation;
    onChanged = null;
    _pending = null;
    syncing = false;
  }
}
