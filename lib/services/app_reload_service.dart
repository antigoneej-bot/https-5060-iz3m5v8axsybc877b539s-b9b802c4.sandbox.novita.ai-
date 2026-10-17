import 'package:shared_preferences/shared_preferences.dart';
import '../mongi/integration/mongi_garden_store.dart';
import 'draft_service.dart';
import 'auto_backup_service.dart';
import 'meditation_course_store.dart';
import 'meditation_library_store.dart';
import 'sound_service.dart';

/// The application owns disposing/recreating its tree. Data screens never
/// force-close the app to apply restored records: [reload] re-runs the root
/// widget via [reloadApp], and a failed attempt leaves a retry path instead
/// of silently continuing with half-restored in-memory caches.
class AppReloadService {
  static Future<void> Function()? reloadApp;
  static Future<void>? _running;
  static bool _needsReload = false;
  static bool get isReloading => _running != null;

  /// True while a restore has been applied to storage but the in-memory
  /// caches (providers/stores) have not been confirmed reloaded yet. Screens
  /// should treat the app as "not yet safe to use normally" during this
  /// window — e.g. pausing auto-backup so it cannot read half-reloaded state.
  static bool get needsReload => _needsReload || isReloading;

  static Future<void> reload() {
    final current = _running;
    if (current != null) return current;
    final action = reloadApp;
    if (action == null) {
      return Future.error(StateError('복원한 기록을 다시 불러오는 기능을 준비하지 못했어요.'));
    }
    _needsReload = true;
    AutoBackupService.instance.paused = true;
    final result = Future<void>.sync(action);
    _running = result;
    result.then<void>(
      (_) {
        _running = null;
        _needsReload = false;
        AutoBackupService.instance.paused = false;
      },
      onError: (Object _, StackTrace __) {
        _running = null;
        // Keep auto-backup paused and _needsReload=true: a retry screen
        // remains available, and we must not back up half-reloaded state.
      },
    );
    return result;
  }

  /// Call only after the previous widget tree has been disposed and a frame
  /// has elapsed. Invalidates every in-memory cache that a restore/legacy
  /// recovery may have changed on disk, so stale state is never shown.
  static Future<void> reloadStores() async {
    // Disposed draft controllers finish releasing their shared key caches.
    await DraftTextController.flushAll();
    await (await SharedPreferences.getInstance()).reload();
    await MongiGardenStore.instance.reload();
    await MeditationCourseStore.instance.reload();
    await MeditationLibraryStore.instance.reload();
    // Audio device failures must not trap users after a successful restore.
    try {
      await SoundService().stopAll();
      await SoundService().init();
    } catch (_) {}
  }
}
