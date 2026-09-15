import 'package:flutter_app/services/backup_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/session_transaction.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/services/hive_encryption.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late GardenProvider garden;
  final shared=MongiGardenStore.instance;
  setUp(() async {
    directory=await Directory.systemTemp.createTemp('mongi-transaction-');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'), (_) async => null);
    SessionTransaction.fault=null;
    garden=GardenProvider(); await garden.ensureInitialized();
  });
  tearDown(() async {
    SessionTransaction.fault=null;
    garden.dispose(); await Hive.close(); await directory.delete(recursive:true);
  });
  test('quiet completion retries atomically and shares daily reward with other care', () async {
    final type=Emotion.all.first.type;
    Future<void> quiet()=>garden.recordQuietSession([type], note:'조용히 쉬었어요',sessionId:'quiet-upgrade');
    SessionTransaction.fault=(point) async { if(point=='garden_written') throw StateError('injected'); };
    await expectLater(quiet(),throwsStateError);
    SessionTransaction.fault=null;
    garden.dispose(); await Hive.close(); Hive.init(directory.path);
    garden=GardenProvider(); await garden.ensureInitialized();
    await Future.wait([quiet(),quiet(),shared.claimCompletedCare()]);
    expect(shared.value.seedTokens,1); expect(shared.value.essence,20);
    expect(garden.flowerCounts[type.name],1); expect(garden.diaryEntries.length,1);
    final snapshot=await BackupService.snapshot();
    BackupService.validate(snapshot);
    final raw=jsonDecode(snapshot['settings'][MongiGardenStore.storageKey]['value'] as String) as Map;
    expect((raw['careDays'] as List).length,1);
  });
  Future<bool> save() => garden.recordSession({Emotion.all.first.type:20},
    choseLove:true,seedType:'love',target:20,playedStage:1,sessionId:'run-result');
  for(final phase in ['before_journal','journal_flushed','hive_write','hive_flushed','garden_written','commit_finished']) {
    test('failure at $phase, restart, and repeated retry grant one result', () async {
      SessionTransaction.fault=(point) async {if(point==phase) throw StateError('injected $phase');};
      await expectLater(save(),throwsStateError);
      SessionTransaction.fault=null;
      // Reopen the actual encrypted on-disk Hive box, rather than relying on memory.
      garden.dispose(); await Hive.close(); Hive.init(directory.path);
      garden=GardenProvider(); await garden.ensureInitialized();
      if(phase=='before_journal') {
        expect(garden.score,0); expect(shared.value.seeds['love'],isNull);
      } else {
        expect(garden.score,55); expect(shared.value.seeds['love'],1);
        expect(garden.flowerCounts[Emotion.all.first.type.name],20);
      }
      await save();
      final box=await HiveEncryption.openBox(SessionTransaction.boxName);
      final original=jsonEncode(box.toMap());
      final balance=shared.value.essence;
      await save(); await save();
      expect(jsonEncode(box.toMap()),original);
      expect(shared.value.essence,balance);
      expect(garden.score,55); expect(shared.value.seeds['love'],1);
      expect(garden.lastEarnedScore,55); expect(garden.lastEarnedLightEssence,24);
      expect(box.get(SessionTransaction.pendingKey),isNull);
    });
  }
  test('double submit is serialized and both callers receive same result', () async {
    final results=await Future.wait([save(),save()]);
    expect(results[0],results[1]); expect(garden.score,55);
    expect(shared.value.seeds['love'],1);
  });
  test('advance retry after durable write never skips a stage', () async {
    SessionTransaction.fault=(point) async {if(point=='garden_written') throw StateError('disk');};
    await expectLater(garden.advanceToNextStage(sessionId:'run-advance'),throwsStateError);
    SessionTransaction.fault=null;
    await garden.advanceToNextStage(sessionId:'run-advance');
    await garden.advanceToNextStage(sessionId:'run-advance');
    expect(garden.stage,2);
  });
  test('next garden action first recovers pending result and keeps both changes', () async {
    SessionTransaction.fault=(point) async {if(point=='hive_flushed') throw StateError('disk');};
    await expectLater(save(),throwsStateError);
    SessionTransaction.fault=null;
    await shared.addOriginalEssence(7);
    final before=shared.value.essence;
    await save();
    expect(shared.value.essence,before); expect(before,greaterThanOrEqualTo(31));
    expect(shared.value.seeds['love'],1);
  });
  test('endless and diary retry do not duplicate flowers or entries', () async {
    for(var i=0;i<2;i++) {
      await garden.recordEndlessSession({Emotion.all.first.type:3},survivedSeconds:12,sessionId:'endless');
      await garden.addDiaryEntry(emotionType:Emotion.all.first.type,eatenCount:3,note:'테스트',sessionId:'diary');
    }
    expect(garden.flowerCounts[Emotion.all.first.type.name],3);
    expect(garden.diaryEntries.length,1);
  });

  test('backup waits for recovery and contains complete rewards', () async {
    SessionTransaction.fault=(point) async {if(point=='hive_flushed') throw StateError('disk');};
    await expectLater(save(),throwsStateError); SessionTransaction.fault=null;
    final snapshot=await BackupService.snapshot();
    final data=jsonDecode(snapshot['settings'][MongiGardenStore.storageKey]['value'] as String) as Map;
    expect(data['seeds']['love'],1);
    final rows=snapshot['boxes']['mongi_progress'] as List;
    expect(rows.any((r)=>r['key']==SessionTransaction.pendingKey),isFalse);
    expect(rows.any((r)=>r['key']==SessionTransaction.receiptsKey),isFalse);
    await save(); expect(shared.value.seeds['love'],1);
  });

}
