import 'dart:async';
import 'package:flutter/widgets.dart';
import '../mongi/services/sound_manager.dart';
import 'sound_service.dart';
import 'media_coordinator.dart';

/// A session timer. Expiry latches music off until the user explicitly resumes.
class GardenSoundTimer extends ChangeNotifier with WidgetsBindingObserver {
  GardenSoundTimer._() { WidgetsBinding.instance.addObserver(this); }
  static final instance = GardenSoundTimer._();
  DateTime? deadline;
  Timer? _timer;
  bool stopped = false, _expiring = false;
  Duration get remaining => deadline == null ? Duration.zero : deadline!.difference(DateTime.now());
  void setMinutes(int? minutes) {
    if (minutes != null && ![5, 15, 30, 60].contains(minutes)) throw ArgumentError.value(minutes);
    _timer?.cancel(); deadline = minutes == null ? null : DateTime.now().add(Duration(minutes: minutes));
    if (deadline != null) _timer = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(tick()));
    notifyListeners();
  }
  Future<void> tick({DateTime? now}) async {
    if (deadline == null || _expiring) return;
    if (deadline!.isAfter(now ?? DateTime.now())) { notifyListeners(); return; }
    _expiring = true; _timer?.cancel(); deadline = null; stopped = true;
    final sound = SoundService(), nature = SoundManager.instance;
    sound.sleepStopped = true; nature.sleepStopped = true;
    notifyListeners();
    try {
      // Stop the existing media owner without claiming completion or a reward.
      try { await MediaCoordinator.instance.stopAll(); } catch (_) {}
      try { await sound.stopAll(); } catch (_) {}
      await nature.stopForSleep();
    } finally { _expiring = false; notifyListeners(); }
  }
  Future<void> resumeSound() async {
    if (_expiring) return;
    stopped = false; SoundService().sleepStopped = false; SoundManager.instance.sleepStopped = false;
    await SoundService().tryStartBgm();
    if (SoundManager.instance.ambientRequested && !SoundService().narrationPlaying) await SoundManager.instance.startAmbientNature();
    notifyListeners();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(tick());
  }
}
