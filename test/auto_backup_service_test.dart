import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/auto_backup_service.dart';
import 'package:flutter_app/models/backup_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'new records upload before 24h; unchanged data, restore and failures cannot advance confirmation',
    () async {
      SharedPreferences.setMockInitialValues({});
      var now = DateTime.utc(2026, 10, 24);
      var text = 'first';
      var uploads = 0;
      var fail = false;
      var restoring = false;
      final service = AutoBackupService.forTesting(
        owner: () => 'a',
        enabled: () async => true,
        snapshot: () async => {
          'schema': 1,
          'createdAt': now.toIso8601String(),
          'boxes': {
            'letters': [
              {'key': 'one', 'value': text},
            ],
          },
          'settings': {},
        },
        upload: (payload, uid) async {
          uploads++;
          if (fail) throw StateError('offline');
          return {'savedAt': now.toIso8601String()};
        },
        password: (_) async => 'test-password-123456',
        restoring: () async => restoring,
        now: () => now,
      );
      await service.run();
      expect(uploads, 1);
      now = now.add(const Duration(minutes: 3));
      await service.run();
      expect(uploads, 1);
      text = 'second';
      await service.run();
      expect(uploads, 2);
      final prefs = await SharedPreferences.getInstance();
      final confirmed = prefs.getString('last_cloud_backup_a');
      now = now.add(const Duration(minutes: 3));
      text = 'third';
      fail = true;
      await service.run();
      expect(uploads, 3);
      expect(prefs.getString('last_cloud_backup_a'), confirmed);
      expect(service.status.value.phase, BackupPhase.failed);
      expect(service.status.value.confirmedAt, DateTime.parse(confirmed!));
      expect((await service.readSummary()).pendingChanges, true);
      fail = false;
      restoring = true;
      await service.run();
      expect(uploads, 3);
      restoring = false;
      await service.run();
      expect(uploads, 4);
      expect((await service.readSummary()).pendingChanges, false);
    },
    // Repeated real encryption can exceed the default 30s on Windows/CI.
    timeout: const Timeout(Duration(minutes: 2)),
  );
  test(
    'edits during upload remain pending; account changes never confirm another owner',
    () async {
      SharedPreferences.setMockInitialValues({});
      var text = 'first';
      String? owner = 'a';
      var swap = false;
      final service = AutoBackupService.forTesting(
        owner: () => owner,
        enabled: () async => true,
        snapshot: () async => {
          'schema': 1,
          'createdAt': 'date',
          'boxes': {
            'letters': [
              {'key': 'one', 'value': text},
            ],
          },
          'settings': {},
        },
        upload: (payload, uid) async {
          text = 'new during upload';
          if (swap) owner = 'b';
          return {'savedAt': DateTime.utc(2026).toIso8601String()};
        },
        password: (_) async => 'test-password-123456',
        restoring: () async => false,
        now: () => DateTime.utc(2026),
      );
      await service.run();
      expect((await service.readSummary()).pendingChanges, true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_cloud_backup_a');
      swap = true;
      await service.run(force: true);
      expect(prefs.getString('last_cloud_backup_a'), isNull);
      expect(prefs.getString('last_cloud_backup_b'), isNull);
      expect(service.status.value.phase, BackupPhase.off);
      expect(service.status.value.confirmedAt, isNull);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
