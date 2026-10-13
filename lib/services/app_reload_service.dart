import 'package:shared_preferences/shared_preferences.dart';
import '../mongi/integration/mongi_garden_store.dart';
import 'draft_service.dart';
import 'auto_backup_service.dart';
import 'meditation_completion_service.dart';
import 'meditation_course_store.dart';
import 'meditation_library_store.dart';
import 'sound_service.dart';

/// The application owns disposing/recreating its tree. Data screens never close
/// a browser tab or terminate an iOS/Android process to apply restored records.
class AppReloadService {
  static Future<void> Function()? reloadApp;
  static Future<void>? _running;
  static bool _needsReload = false;
  static bool get isReloading => _running != null;
  static bool get needsReload => _needsReload || isReloading;

  static Future<void> reload() {
    final current = _running;
    if (current != null) return current;
    final action = reloadApp;
    if (action == null) {
      return Future.error(StateError('복원한 정원을 여는 기능을 준비하지 못했어요.'));
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
        // A retry screen remains available. Do not back up half-reloaded state.
        AutoBackupService.instance.paused = true;
      },
    );
    return result;
  }

  /// Call only after the previous widget tree was disposed and a frame elapsed.
  static Future<void> reloadStores() async {
    // Disposed draft controllers finish releasing their shared key caches.
    await DraftTextController.flushAll();
    await (await SharedPreferences.getInstance()).reload();
    await MongiGardenStore.instance.reload();
    await MeditationCourseStore.instance.reload();
    await MeditationLibraryStore.instance.reload();
    await MeditationCompletionService.instance.reload();
    // Audio device failures must not trap users after a successful restore.
    try {
      await SoundService().stopAll();
      await SoundService().init();
    } catch (_) {}
  }
}
