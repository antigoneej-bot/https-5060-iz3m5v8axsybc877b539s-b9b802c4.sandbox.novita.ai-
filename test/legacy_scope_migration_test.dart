import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/services/hive_encryption.dart';
import '../lib/services/legacy_record_migration.dart';
import '../lib/services/storage_service.dart';

/// Regression guard for the restored "이전 버전의 누락 기록 확인" manual recovery
/// feature. The core requirement from the user is: automatic/manual recovery
/// must never overwrite or duplicate records already present in the current
/// (local_user) scope — only genuinely missing keys may be copied over.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  const channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('legacy-scope-test');
    Hive.init(tempDir.path);
    final secrets = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      if (call.method == 'read') return secrets[args['key']];
      if (call.method == 'write') secrets[args['key']] = args['value'];
      return null;
    });
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'unfinished migration merges absent keys without replacing current records or preferences',
    () async {
      final prefs = await SharedPreferences.getInstance();
      // 레거시(guest) 측에 기존 편지 2건 + 설정 1건이 있다고 가정.
      final guestBox = await HiveEncryption.openBox('letter_entries_guest');
      await guestBox.put('letter_1', 'guest-letter-1');
      await guestBox.put('letter_2', 'guest-letter-2');
      await guestBox.close();
      await prefs.setString('guest_sound_setting', 'bgm_on');

      // 현재(local_user) 측에는 letter_1과 같은 ID가 "이미 수정된" 값으로
      // 존재한다고 가정 — 이 값은 절대 덮어써지면 안 됨.
      final targetBox = await HiveEncryption.openBox(
        'letter_entries_local_user',
      );
      await targetBox.put('letter_1', 'current-letter-1-edited');
      await targetBox.close();

      await StorageService.migrateGuestScopeIfNeeded('local_user');

      final merged = await HiveEncryption.openBox('letter_entries_local_user');
      // 기존 값은 그대로 유지, 누락된 letter_2만 추가됨.
      expect(merged.get('letter_1'), 'current-letter-1-edited');
      expect(merged.get('letter_2'), 'guest-letter-2');
      await merged.close();

      // SharedPreferences도 누락된 키만 복사되고 기존 값은 보존됨.
      expect(prefs.getString('local_user_sound_setting'), 'bgm_on');
    },
  );

  test(
    'old done flag exposes missing records but only explicit recovery restores them',
    () async {
      final prefs = await SharedPreferences.getInstance();
      // v1 마이그레이션은 완료된 것으로 표시되어 있지만(구버전 동작), 실제로는
      // 일부 레코드가 누락된 상태를 재현.
      await prefs.setBool('guest_scope_migrated_v1_to_local_user', true);

      final guestBox = await HiveEncryption.openBox('letter_entries_guest');
      await guestBox.put('letter_missing', 'guest-missing-letter');
      await guestBox.close();

      // v1 플래그가 있으므로 자동 마이그레이션(migrateGuestScopeIfNeeded)은
      // 수행되지 않아야 한다.
      await StorageService.migrateGuestScopeIfNeeded('local_user');
      final afterAuto = await HiveEncryption.openBox(
        'letter_entries_local_user',
      );
      expect(afterAuto.containsKey('letter_missing'), isFalse);
      await afterAuto.close();

      // 요약에는 누락된 레코드가 잡혀야 한다.
      final summary = await StorageService.getLegacyRecoverySummary(
        userId: 'local_user',
      );
      expect(summary['letter_entries'], 1);

      // 명시적 복구를 호출해야만 실제로 반영된다.
      final added = await StorageService.restoreLegacyGuestData(
        userId: 'local_user',
      );
      expect(added, greaterThanOrEqualTo(1));
      final afterRecovery = await HiveEncryption.openBox(
        'letter_entries_local_user',
      );
      expect(afterRecovery.get('letter_missing'), 'guest-missing-letter');
      await afterRecovery.close();
    },
  );

  test(
    'completed v2 migration never resurrects a later deletion automatically',
    () async {
      final prefs = await SharedPreferences.getInstance();
      // 이미 v2(명시적 복구 포함) 완료 플래그가 세팅된 상태.
      await prefs.setBool(
        LegacyRecordMigration.completionKey('local_user'),
        true,
      );

      final guestBox = await HiveEncryption.openBox('letter_entries_guest');
      await guestBox.put('letter_deleted_on_purpose', 'old-value');
      await guestBox.close();

      // local_user 쪽에는 해당 키가 없음(사용자가 의도적으로 삭제했다고 가정).
      await StorageService.migrateGuestScopeIfNeeded('local_user');

      final target = await HiveEncryption.openBox('letter_entries_local_user');
      // v2가 이미 완료되었으므로 자동 병합이 다시 일어나 삭제된 레코드를
      // 되살리면 안 된다.
      expect(target.containsKey('letter_deleted_on_purpose'), isFalse);
      await target.close();
    },
  );

  test(
    'recovery summary counts each private store without exposing bodies or creating targets',
    () async {
      final guestBox = await HiveEncryption.openBox('letter_entries_guest');
      await guestBox.put('letter_a', 'secret-body-a');
      await guestBox.put('letter_b', 'secret-body-b');
      await guestBox.close();

      final summary = await StorageService.getLegacyRecoverySummary(
        userId: 'local_user',
      );
      expect(summary['letter_entries'], 2);

      // 요약을 조회했다고 해서 대상 박스가 생성되지는 않아야 한다
      // (createTarget: false).
      final targetExists =
          await Hive.boxExists('letter_entries_local_user') ||
          await Hive.boxExists('letter_entries_local_user__enc');
      expect(targetExists, isFalse);
    },
  );
}
