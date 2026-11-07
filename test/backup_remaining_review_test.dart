import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/auto_backup_service.dart';
import 'package:flutter_app/models/backup_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'REVIEW: disabling during an upload must keep the display off',
    () async {
      SharedPreferences.setMockInitialValues({});
      var enabled = true;
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'delete') enabled = false;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final started = Completer<void>();
      final receipt = Completer<Map<String, dynamic>>();
      final service = AutoBackupService.forTesting(
        owner: () => 'synthetic-review',
        enabled: () async => enabled,
        snapshot: () async => {
          'schema': 1,
          'createdAt': '2026-11-06',
          'boxes': {},
          'settings': {},
        },
        upload: (_, __) {
          started.complete();
          return receipt.future;
        },
        password: (_) async => 'synthetic-test-password',
        restoring: () async => false,
        now: () => DateTime.utc(2026, 11, 6),
      );
      final pending = service.run();
      await started.future;
      await service.disable();
      expect(service.status.value.phase, BackupPhase.off);
      receipt.complete({'savedAt': '2026-11-06T00:00:00Z'});
      await pending;
      expect(await service.isEnabled(), false);
      expect(
        service.status.value.phase,
        BackupPhase.off,
        reason:
            'An already submitted upload can finish, but must not overwrite the disabled status.',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'REVIEW: manual backup must wait for the already running backup',
    () async {
      SharedPreferences.setMockInitialValues({});
      final started = Completer<void>();
      final receipt = Completer<Map<String, dynamic>>();
      final service = AutoBackupService.forTesting(
        owner: () => 'synthetic-review',
        enabled: () async => true,
        snapshot: () async => {
          'schema': 1,
          'createdAt': '2026-11-06',
          'boxes': {},
          'settings': {},
        },
        upload: (_, __) {
          started.complete();
          return receipt.future;
        },
        password: (_) async => 'synthetic-test-password',
        restoring: () async => false,
        now: () => DateTime.utc(2026, 11, 6),
      );
      final automatic = service.run();
      await started.future;
      var manualCompleted = false;
      final manual = service
          .run(force: true)
          .then((_) => manualCompleted = true);
      // Flush queued futures; no elapsed-time guess is used to complete the upload.
      await Future<void>.value();
      await Future<void>.value();
      final completedBeforeReceipt = manualCompleted;
      receipt.complete({'savedAt': '2026-11-06T00:00:00Z'});
      await automatic;
      await manual;
      expect(
        completedBeforeReceipt,
        false,
        reason: 'The caller must be able to await a confirmed manual backup.',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
