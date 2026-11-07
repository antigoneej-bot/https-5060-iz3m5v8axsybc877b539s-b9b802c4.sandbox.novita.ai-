import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'local_user_mongi_garden_v1';
  late Directory directory;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('garden-recovery-');
    Hive.init(directory.path);
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
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Map<String, dynamic> backup() => {
    'schema': 1,
    'createdAt': '2026-09-01T00:00:00Z',
    'boxes': <String, dynamic>{},
    'settings': {
      key: {
        'type': 'string',
        'value': jsonEncode(
          MongiGardenData(stage: 2, essence: 30, seeds: {'love': 1}).toJson(),
        ),
      },
    },
  };
  test('older backup preserves a game-only garden with no diary', () async {
    final current = jsonEncode(
      MongiGardenData(stage: 9, essence: 240, seeds: {'pine': 4}).toJson(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, current);
    expect(await BackupService.hasLocalRecords(), isTrue);
    await BackupService.restore(backup());
    expect(prefs.getString(key), current);
  });
  test('empty installation can recover its garden from a backup', () async {
    expect(await BackupService.hasLocalRecords(), isFalse);
    await BackupService.restore(backup());
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString(key)!)['stage'], 2);
  });
  test('legacy pending restore cannot replace a current garden', () async {
    final prefs = await SharedPreferences.getInstance();
    final current = jsonEncode(MongiGardenData(stage: 9).toJson());
    await prefs.setString(key, current);
    final journal = await Hive.openBox(
      'restore_journal__enc',
      encryptionCipher: await HiveEncryption.cipher(),
    );
    await journal.put('pending', {'data': backup(), 'restoreProfile': true});
    await journal.flush();
    await BackupService.resumePending();
    expect(prefs.getString(key), current);
    expect(journal.containsKey('pending'), isFalse);
  });
  test('corrected clock grants each date once across persistence', () {
    final future = DateTime(2027, 9, 13);
    final normal = DateTime(2026, 9, 14);
    var data = MongiGardenData().claimRecordDay(future);
    data = MongiGardenData.fromJson(data.toJson()).claimRecordDay(normal);
    expect(data.seedTokens, 2);
    data = MongiGardenData.fromJson(data.toJson());
    expect(data.claimRecordDay(normal).claimRecordDay(future).seedTokens, 2);
    expect(data.claimRecordDay(DateTime(2026, 9, 15)).seedTokens, 3);
  });
}
