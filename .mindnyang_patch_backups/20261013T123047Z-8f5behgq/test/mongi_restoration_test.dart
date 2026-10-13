import 'dart:convert';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/services/garden_storage.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late GardenStorage original;
  final shared = MongiGardenStore.instance;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mongi-restore-');
    Hive.init(directory.path);
    final secrets = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      if (call.method == 'read') return secrets[args['key']];
      if (call.method == 'write') secrets[args['key']] = args['value'];
      return null;
    });
    SharedPreferences.setMockInitialValues({MongiGardenStore.storageKey: jsonEncode(MongiGardenData(stage: 9, essence: 100, seedTokens: 2, seeds: {'pine': 4}).toJson())});
    original = GardenStorage();
    await original.init();
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  test('original game reads existing unified stage, plants and currency', () {
    expect(original.stage, 9);
    expect(original.seedCounts['pine'], 4);
    expect(original.lightEssence, 100);
  });
  test('original reward and unified planting update the same garden', () async {
    await original.plantSeed('love');
    await shared.plant('pine');
    await shared.reload();
    expect(original.seedCounts, {'pine': 5, 'love': 1});
    expect(shared.value.seedTokens, 1);
    await original.advanceStage();
    expect(shared.value.stage, 10);
  });
  test('competing original shop debits cannot overspend shared currency', () async {
    final results = await Future.wait([original.spendLightEssence(80), original.spendLightEssence(80)]);
    expect(results.where((v) => v).length, 1);
    expect(shared.value.essence, 20);
    await original.addLightEssence(15);
    expect(shared.value.essence, 35);
    expect(await original.spendLightEssence(-1), false);
  });
  test('original decoration placement is visible in unified garden', () async {
    await original.setEquippedDecorations(['bench']);
    expect(shared.value.placed, {'bench'});
    expect(shared.value.owned, contains('bench'));
    await shared.toggle('bench');
    expect(original.equippedDecorations, isEmpty);
  });
  test('Mongi encrypted state is backed up without purchase entitlements', () async {
    final box = await HiveEncryption.openBox('mongi_progress_local_user');
    await box.put('owned_costumes', ['ribbon']);
    await box.put('diary_entries', [{'date': '2026-09-14', 'note': '기억'}]);
    await box.put('premium_frames_unlocked', true);
    final data = await BackupService.snapshot();
    BackupService.validate(data);
    final rows = (data['boxes'] as Map)['mongi_progress'] as List;
    expect(rows.any((row) => row['key'] == 'owned_costumes'), isTrue);
    expect(rows.any((row) => row['key'] == 'premium_frames_unlocked'), isFalse);
    rows.add({'key': 'premium_frames_unlocked', 'value': true});
    expect(() => BackupService.validate(data), throwsFormatException);
  });
  test('clear rewards use played stage even after choosing next stage', () async {
    final garden=GardenProvider(); await garden.ensureInitialized();
    final played=garden.stage; await garden.advanceToNextStage();
    await garden.recordSession({Emotion.all.first.type:20},choseLove:false,target:20,playedStage:played);
    expect(garden.lastEarnedScore,40+10+played*5);
    expect(garden.lastEarnedLightEssence,20+3+played);
    garden.dispose();
  });

}
