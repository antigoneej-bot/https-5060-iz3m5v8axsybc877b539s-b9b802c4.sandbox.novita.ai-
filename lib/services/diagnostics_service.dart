import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_record_transaction.dart';

/// Separate opt-in. Never log exception messages, IDs, tokens or written text.
class DiagnosticsService {
  static const preferenceKey = 'diagnostics_sharing_v1';
  static final enabled = ValueNotifier<bool>(false);
  static bool _installed = false;
  static final _changes = LocalRecordQueue();
  static String safeKind(Object error) {
    final name = error.runtimeType.toString();
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,79}$').hasMatch(name)
        ? name
        : 'ApplicationError';
  }

  static Future<void> initialize() => _changes.run(() async {
    if (Firebase.apps.isEmpty) return;
    _installHandlers();
    try {
      final prefs = await SharedPreferences.getInstance();
      final allowed = prefs.getBool(preferenceKey) ?? false;
      // Discard reports created while collection was off instead of sending
      // pre-consent native crashes on a later opt-in.
      if (!allowed) {
        await _apply(prefs, false);
      } else {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );
      }
      enabled.value = allowed;
    } catch (_) {
      enabled.value =
          false; // Diagnostics must never stop local records opening.
      try {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          false,
        );
      } catch (_) {}
    }
  });

  static void _installHandlers() {
    if (_installed) return;
    _installed = true;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      unawaited(
        record(
          details.exception,
          details.stack ?? StackTrace.current,
          'flutter',
          fatal: true,
        ),
      );
    };
    final previousAsync = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(record(error, stack, 'async', fatal: true));
      return previousAsync?.call(error, stack) ?? false;
    };
  }

  static Future<void> setEnabled(bool value) => _changes.run(() async {
    enabled.value = false;
    final prefs = await SharedPreferences.getInstance();
    await _apply(prefs, value);
  });

  static Future<void> _apply(SharedPreferences prefs, bool value) async {
    // Remember opt-out even if native cleanup fails. Attempt all shutdown steps;
    // failure of one must not leave the other steps unattempted.
    enabled.value = false;
    Object? failure;
    StackTrace? failureStack;
    Future<void> attempt(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stack) {
        failure ??= error;
        failureStack ??= stack;
      }
    }

    Future<void> save(bool allowed) async {
      if (!await prefs.setBool(preferenceKey, allowed)) {
        throw StateError('Diagnostics preference could not be saved');
      }
    }

    await attempt(() => save(false));
    await attempt(
      () => FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false),
    );
    await attempt(() => FirebaseCrashlytics.instance.deleteUnsentReports());
    if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
    if (!value) return;
    try {
      // An explicit new opt-in never releases pre-consent reports.
      await save(true);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      enabled.value = true;
    } catch (error, stack) {
      await attempt(() => save(false));
      await attempt(
        () =>
            FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false),
      );
      Error.throwWithStackTrace(error, stack);
    }
  }

  static Future<void> record(
    Object error,
    StackTrace stack,
    String stage, {
    bool fatal = false,
  }) async {
    if (!enabled.value || Firebase.apps.isEmpty) return;
    const allowedStages = {
      'flutter',
      'async',
      'startup',
      'backup',
      'neighbor_entry',
    };
    try {
      await FirebaseCrashlytics.instance.recordError(
        safeKind(error),
        stack,
        reason: allowedStages.contains(stage) ? stage : 'application',
        fatal: fatal,
        printDetails: false,
      );
    } catch (_) {}
  }

  static Future<void> recordDuration(String stage, int milliseconds) async {
    if (!enabled.value || Firebase.apps.isEmpty) return;
    final key = switch (stage) {
      'authentication-timeout' => 'last_auth_ms',
      'attestation-timeout' => 'last_attestation_ms',
      'network-timeout' => 'last_http_ms',
      'neighbor_entry' => 'last_neighbor_entry_ms',
      _ => null,
    };
    if (key == null) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(
        key,
        milliseconds.clamp(0, 300000),
      );
    } catch (_) {}
  }
}
