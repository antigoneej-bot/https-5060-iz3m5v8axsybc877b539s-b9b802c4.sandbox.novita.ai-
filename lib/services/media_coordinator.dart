import 'sound_service.dart';

/// One serialized playback lane shared by meditation audio and every video.
class MediaCoordinator {
  static final instance = MediaCoordinator();
  Future<void> _tail = Future.value();
  Object? _owner;
  Future<void> Function()? _stop;
  Future<void> run(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.catchError((Object _) {});
    return result;
  }

  // Called only inside run; stop callbacks must not enqueue into this lane.
  Future<void> claim(Object owner, Future<void> Function() stop) async {
    if (_owner != owner) {
      final previous = _stop;
      _owner = null;
      _stop = null;
      if (previous != null) await previous();
    }
    _owner = owner;
    _stop = stop;
    SoundService().narrationPlaying = true;
    await SoundService().stopAll();
  }

  void release(Object owner) {
    if (_owner != owner) return;
    _owner = null;
    _stop = null;
    SoundService().narrationPlaying = false;
  }

  Future<void> stopAll() => run(() async {
    final stop = _stop;
    _owner = null;
    _stop = null;
    if (stop != null) await stop();
    SoundService().narrationPlaying = false;
  });
}
