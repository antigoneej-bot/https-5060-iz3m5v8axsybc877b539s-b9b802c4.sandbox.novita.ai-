// Run only with tool/run_release_recovery_probe.cjs. Synthetic data only.
// Hive and backup encryption use real files; OS preferences and secure storage
// are test adapters, not Android Keystore/SharedPreferences verification.
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flutter_app/services/backup_codec.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';

class FileFixturePreferences extends InMemorySharedPreferencesStore {
  FileFixturePreferences(this.file, Map<String, Object> values)
    : super.withData(values);
  final File file;
  String? failKey;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == failKey) return false;
    final ok = await super.setValue(type, key, value);
    await file.writeAsString(jsonEncode(await getAll()), flush: true);
    return ok;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = Platform.environment['MINDNYANG_RECOVERY_RUN'];
  final phase = Platform.environment['MINDNYANG_RECOVERY_PHASE'];
  if (root == null || phase == null) {
    throw StateError('Run tool/run_release_recovery_probe.cjs with an isolated output directory.');
  }
  const gardenKey = 'local_user_mongi_garden_v1';
  const password = 'synthetic-recovery-fixture-only';
  const secure = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final destination = switch (phase) {
    'source' => 'source',
    'fresh' || 'reopen' => 'fresh',
    'interrupt' || 'resume' => 'interrupted',
    _ => 'damaged-copy',
  };
  final folder = Directory('$root/$destination');
  late FileFixturePreferences prefsStore;
  setUp(() async {
    expect(File('$root/SYNTHETIC-ONLY').existsSync(), isTrue);
    await folder.create(recursive: true);
    Hive.init(folder.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, (call) async {
          if (call.method == 'read') {
            return base64Encode(List<int>.generate(32, (i) => i + 1));
          }
          return null;
        });
    final file = File('${folder.path}/fixture-preferences.json');
    final values = await file.exists()
        ? Map<String, Object>.from(jsonDecode(await file.readAsString()) as Map)
        : <String, Object>{};
    prefsStore = FileFixturePreferences(file, values);
    SharedPreferencesStorePlatform.instance = prefsStore;
  });
  tearDown(() async {
    await Hive.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, null);
  });
  Future<Map<String, dynamic>> readBackup() async => BackupCodec.decrypt(
    await File('$root/export.mindnyang').readAsBytes(),
    password,
  );
  Future<void> expectFreshState() async {
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('companion_name'), '테스트 고양이');
    final data = MongiGardenData.fromJson(
      Map<String, dynamic>.from(jsonDecode(prefs.getString(gardenKey)!) as Map),
    );
    expect(data.stage, 7);
    expect(data.essence, 230);
    expect(data.seeds['pine'], 3);
    final drafts = await HiveEncryption.openBox('drafts_local_user');
    expect(drafts.toMap(), {'same': '백업에 있던 테스트 기록', 'new': '추가 테스트 기록'});
    final layout = GardenLayout.fromJson(
      (await HiveEncryption.openBox('garden_layout_local_user')).get('layout'),
    );
    expect(layout.spaces, 3);
    expect(layout.positions['seed:pine'], const Offset(.23, .76));
    expect(await BackupService.hasPending(), isFalse);
  }

  test('separate process: $phase', () async {
    final prefs = await SharedPreferences.getInstance();
    if (phase == 'source') {
      await prefs.setString('companion_name', '테스트 고양이');
      await prefs.setString(
        gardenKey,
        jsonEncode(
          MongiGardenData(stage: 7, essence: 230, seeds: {'pine': 3}).toJson(),
        ),
      );
      await prefs.setBool('bgm_enabled', true);
      final drafts = await HiveEncryption.openBox('drafts_local_user');
      await drafts.putAll({'same': '백업에 있던 테스트 기록', 'new': '추가 테스트 기록'});
      await (await HiveEncryption.openBox('garden_layout_local_user')).put(
        'layout',
        GardenLayout(
          spaces: 3,
          positions: {'seed:pine': const Offset(.23, .76)},
        ).toJson(),
      );
      final snapshot = await BackupService.snapshot();
      BackupService.validate(snapshot);
      final bytes = await BackupCodec.encrypt(snapshot, password);
      await File('$root/export.mindnyang').writeAsBytes(bytes, flush: true);
      expect(utf8.decode(bytes), isNot(contains('테스트 기록')));
    } else if (phase == 'fresh') {
      final file = File('$root/export.mindnyang');
      final bytes = await file.readAsBytes();
      await expectLater(
        BackupCodec.decrypt(bytes, 'wrong-fixture-password'),
        throwsA(anything),
      );
      final envelope = jsonDecode(utf8.decode(bytes)) as Map;
      final tag = base64Decode(envelope['mac'] as String)..[0] ^= 1;
      envelope['mac'] = base64Encode(tag);
      await expectLater(
        BackupCodec.decrypt(utf8.encode(jsonEncode(envelope)), password),
        throwsA(anything),
      );
      expect(await BackupService.hasLocalRecords(), isFalse);
      expect(await file.readAsBytes(), orderedEquals(bytes));
      expect(await BackupService.restore(await readBackup()), 3);
      await expectFreshState();
    } else if (phase == 'reopen') {
      await expectFreshState();
      expect(await BackupService.restore(await readBackup()), 0);
      await expectFreshState();
    } else if (phase == 'interrupt') {
      await prefs.setString('companion_name', '현재 이름 유지');
      await prefs.setString(
        gardenKey,
        jsonEncode(
          MongiGardenData(stage: 12, essence: 999, seeds: {'pine': 8}).toJson(),
        ),
      );
      await (await HiveEncryption.openBox(
        'drafts_local_user',
      )).putAll({'same': '현재 기록 우선', 'unrelated': '별도 기존 기록'});
      await (await HiveEncryption.openBox('garden_layout_local_user')).put(
        'layout',
        GardenLayout(
          spaces: 2,
          positions: {'seed:pine': const Offset(.62, .81)},
        ).toJson(),
      );
      prefsStore.failKey = 'flutter.bgm_enabled';
      await expectLater(
        BackupService.restore(await readBackup()),
        throwsStateError,
      );
      expect(await BackupService.hasPending(), isTrue);
      final drafts = await HiveEncryption.openBox('drafts_local_user');
      expect(drafts.get('same'), '현재 기록 우선');
      expect(drafts.get('new'), '추가 테스트 기록');
      expect(drafts.length, 3);
      // Exit with the real encrypted recovery journal still on disk.
    } else if (phase == 'resume') {
      expect(await BackupService.hasPending(), isTrue);
      expect(await BackupService.resumePending(), 0);
      expect(await BackupService.resumePending(), 0);
      final drafts = await HiveEncryption.openBox('drafts_local_user');
      expect(drafts.toMap(), {
        'same': '현재 기록 우선',
        'unrelated': '별도 기존 기록',
        'new': '추가 테스트 기록',
      });
      expect(prefs.getString('companion_name'), '현재 이름 유지');
      final garden = jsonDecode(prefs.getString(gardenKey)!) as Map;
      expect(garden['stage'], 12);
      expect(garden['essence'], 999);
      expect(prefs.getBool('bgm_enabled'), isTrue);
      final layout = GardenLayout.fromJson(
        (await HiveEncryption.openBox(
          'garden_layout_local_user',
        )).get('layout'),
      );
      expect(layout.spaces, 2);
      expect(layout.positions['seed:pine'], const Offset(.62, .81));
      expect(await BackupService.hasPending(), isFalse);
    } else if (phase == 'corrupt') {
      final file = File('${folder.path}/drafts_local_user__enc.hive');
      final bytes = await File(
        '$root/source/drafts_local_user__enc.hive',
      ).readAsBytes();
      bytes[0] ^= 0xff;
      await file.writeAsBytes(bytes, flush: true);
      await expectLater(
        HiveEncryption.openBox('drafts_local_user'),
        throwsA(anything),
      );
      expect(await file.readAsBytes(), orderedEquals(bytes));
    } else {
      fail('Unknown phase');
    }
    await File('$root/$phase-result.json').writeAsString(
      jsonEncode({'phase': phase, 'passed': true, 'pid': pid}),
      flush: true,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
