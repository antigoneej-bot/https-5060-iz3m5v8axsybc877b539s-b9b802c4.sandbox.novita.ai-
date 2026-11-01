import 'dart:async';
import 'local_record_transaction.dart';
import 'sound_service.dart';

/// One serialized playback lane shared by meditation audio and every video.
class MediaCoordinator {
  MediaCoordinator({SoundService? sound}) : _sound = sound ?? SoundService();
  static final instance = MediaCoordinator();
  final SoundService _sound;
  final _queue = LocalRecordQueue();
  Object? _owner;
  Future<void> Function()? _stop;
  Future<void> run(Future<void> Function() action) => _queue.run(action);

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
    _sound.narrationPlaying = true;
    await _sound.stopAll();
  }

  void release(Object owner) {
    if (_owner != owner) return;
    _owner = null;
    _stop = null;
    _sound.narrationPlaying = false;
    unawaited(_sound.tryStartBgm());
  }

  Future<void> stopAll() => run(() async {
    final stop = _stop;
    _owner = null;
    _stop = null;
    if (stop != null) await stop();
    _sound.narrationPlaying = false;
  });
}
