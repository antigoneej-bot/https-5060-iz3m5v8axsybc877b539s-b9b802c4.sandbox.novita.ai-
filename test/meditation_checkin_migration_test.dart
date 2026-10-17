import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  const channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'meditation-migration-test',
    );
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
    '구버전 암호화 Hive 명상 체크인 기록이 SharedPreferences로 이전된다',
    () async {
      // 1.0.8+11 구버전과 동일한 방식으로 암호화 박스에 기록을 미리 써둔다.
      final box = await HiveEncryption.openBox(
        'meditation_checkins_local_user',
      );
      await box.put('session-1', {
        'session': 'session-1',
        'guide': 'ocean-breath',
        'feeling': 'better',
        'at': '2026-09-01T10:00:00.000Z',
      });
      await box.put('session-2', {
        'session': 'session-2',
        'guide': 'forest-rest',
        'feeling': 'same',
        'at': '2026-09-05T20:30:00.000Z',
      });
      await box.close();

      // 신규 버전 마이그레이션 로직 실행.
      await StorageService.migrateMeditationCheckInsIfNeeded();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('meditation.checkins');
      expect(raw, isNotNull);
      final list = (jsonDecode(raw!) as List)
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();

      expect(list.length, 2);
      final sessions = list.map((v) => v['session']).toSet();
      expect(sessions, {'session-1', 'session-2'});

      final migrated = list.firstWhere((v) => v['session'] == 'session-1');
      expect(migrated['guide'], 'ocean-breath');
      expect(migrated['feeling'], 'better');
      expect(migrated['at'], '2026-09-01T10:00:00.000Z');

      // 재실행해도 중복으로 쌓이지 않아야 한다(멱등성).
      await StorageService.migrateMeditationCheckInsIfNeeded();
      final rawAgain = prefs.getString('meditation.checkins');
      final listAgain = (jsonDecode(rawAgain!) as List).length;
      expect(listAgain, 2);
    },
  );

  test(
    '신규 형식에 이미 기록이 있으면 기존 값을 유지한 채 과거 기록만 병합한다',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'meditation.checkins',
        jsonEncode([
          {
            'session': 'existing-session',
            'guide': 'rain-sound',
            'feeling': 'worse',
            'at': '2026-10-01T09:00:00.000Z',
          },
        ]),
      );

      final box = await HiveEncryption.openBox(
        'meditation_checkins_local_user',
      );
      await box.put('legacy-session', {
        'session': 'legacy-session',
        'guide': 'ocean-breath',
        'feeling': 'better',
        'at': '2026-08-01T10:00:00.000Z',
      });
      await box.close();

      await StorageService.migrateMeditationCheckInsIfNeeded();

      final raw = prefs.getString('meditation.checkins');
      final list = (jsonDecode(raw!) as List)
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();

      expect(list.length, 2);
      final sessions = list.map((v) => v['session']).toSet();
      expect(sessions, {'existing-session', 'legacy-session'});
    },
  );

  test('레거시 박스가 없으면 아무 것도 하지 않고 정상 종료한다', () async {
    await StorageService.migrateMeditationCheckInsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('meditation.checkins'), isNull);
  });
}
