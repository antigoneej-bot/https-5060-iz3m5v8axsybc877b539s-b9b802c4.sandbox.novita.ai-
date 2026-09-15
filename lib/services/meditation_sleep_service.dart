import 'dart:async';
import 'package:flutter/foundation.dart';

/// One timer belongs to one active player. Absolute deadlines survive delayed
/// timer callbacks; changes never carry into a different media owner.
class MeditationSleepService extends ChangeNotifier {
  static final instance = MeditationSleepService();
  Object? owner;
  bool repeat = false;
  DateTime? deadline;
  Timer? _timer;
  Future<void> Function(double)? _volume;
  Future<void> Function()? _stop;
  bool _ticking = false;
  int _generation = 0;
  double factor = 1;
  Duration get remaining =>
      deadline == null ? Duration.zero : deadline!.difference(DateTime.now());
  void attach(
    Object value, {
    required Future<void> Function(double) volume,
    required Future<void> Function() stop,
  }) {
    if (identical(owner, value)) return;
    detach(owner);
    owner = value;
    _volume = volume;
    _stop = stop;
    notifyListeners();
  }

  void detach(Object? value) {
    if (!identical(owner, value)) return;
    _generation++;
    _timer?.cancel();
    _timer = null;
    owner = null;
    deadline = null;
    repeat = false;
    factor = 1;
    _volume = null;
    _stop = null;
    notifyListeners();
  }

  void setRepeat(bool value) {
    repeat = value;
    notifyListeners();
  }

  Future<void> setTimer(int? minutes) async {
    if (owner == null) return;
    if (minutes != null && ![15, 30, 60].contains(minutes)) return;
    final generation = ++_generation;
    _timer?.cancel();
    deadline = minutes == null
        ? null
        : DateTime.now().add(Duration(minutes: minutes));
    factor = 1;
    await _volume?.call(1);
    if (generation != _generation) return;
    if (deadline != null)
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(
          tick().catchError((Object _) {
            if (generation == _generation) detach(owner);
          }),
        ),
      );
    notifyListeners();
  }

  Future<void> tick({DateTime? now}) async {
    if (_ticking || deadline == null || owner == null) return;
    _ticking = true;
    final current = owner;
    final generation = _generation;
    final left = deadline!.difference(now ?? DateTime.now()).inMilliseconds;
    try {
      factor = (left / 10000).clamp(0.0, 1.0);
      await _volume?.call(factor);
      if (!identical(owner, current) || generation != _generation) return;
      if (left <= 0) {
        final stop = _stop;
        detach(current);
        await stop?.call();
      } else {
        notifyListeners();
      }
    } finally {
      _ticking = false;
    }
  }
}
