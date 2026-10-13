import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/services/draft_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('shared-drafts-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  tearDownAll(() async {
    await DraftTextController.flushAll();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'returning from self care cannot overwrite a newer reflection',
    () async {
      const key = 'reflection_week_shared';
      final statistics = DraftTextController(key);
      await statistics.flush();
      statistics.text = '먼저 쓴 회고';
      await statistics.flush();
      final selfCare = DraftTextController(key);
      await selfCare.flush();
      expect(selfCare.text, '먼저 쓴 회고');
      selfCare.text = '돌봄 화면에서 고친 회고';
      await selfCare.flush();
      expect(statistics.text, selfCare.text);
      selfCare.dispose();
      statistics.didChangeAppLifecycleState(AppLifecycleState.paused);
      await DraftTextController.flushAll();
      statistics.dispose();
      await DraftTextController.flushAll();
      expect((await DraftService.box()).get(key), '돌봄 화면에서 고친 회고');
    },
  );

  test(
    'opening and closing an unchanged editor never rewrites its snapshot',
    () async {
      const key = 'unchanged_reader';
      final editor = DraftTextController(key);
      await editor.flush();
      final box = await DraftService.box();
      await box.put(key, '복원된 더 최신 기록');
      editor.dispose();
      await DraftTextController.flushAll();
      expect(box.get(key), '복원된 더 최신 기록');
    },
  );

  test(
    'discard reaches all editors and an old editor cannot resurrect it',
    () async {
      const key = 'discard_shared';
      final a = DraftTextController(key);
      final b = DraftTextController(key);
      await a.flush();
      a.text = '전송할 편지';
      await b.flush();
      await b.discard();
      expect(a.text, isEmpty);
      expect(b.text, isEmpty);
      b.dispose();
      a.dispose();
      await DraftTextController.flushAll();
      expect((await DraftService.box()).containsKey(key), isFalse);
    },
  );

  test(
    'editing while initial storage loads wins over the older saved value',
    () async {
      const key = 'early_typing';
      final box = await DraftService.box();
      await box.put(key, '지난 초안');
      final a = DraftTextController(key);
      a.text = '방금 쓴 내용';
      final b = DraftTextController(key);
      await DraftTextController.flushAll();
      expect(a.text, '방금 쓴 내용');
      expect(b.text, '방금 쓴 내용');
      expect(box.get(key), '방금 쓴 내용');
      a.dispose();
      b.dispose();
      await DraftTextController.flushAll();
    },
  );

  test(
    'rapid edits from both screens keep the final edit after disposal',
    () async {
      const key = 'rapid_edits';
      final a = DraftTextController(key);
      final b = DraftTextController(key);
      await a.flush();
      a.text = '첫째';
      final firstSave = a.flush();
      b.text = '둘째';
      final secondSave = b.flush();
      a.text = '마지막 실제 편집';
      a.dispose();
      b.dispose();
      await Future.wait([firstSave, secondSave]);
      await DraftTextController.flushAll();
      expect((await DraftService.box()).get(key), '마지막 실제 편집');
    },
  );

  test('different reflection keys remain independent', () async {
    final week = DraftTextController('separate_week');
    final month = DraftTextController('separate_month');
    week.text = '이번 주';
    month.text = '이번 달';
    await DraftTextController.flushAll();
    expect(week.text, '이번 주');
    expect(month.text, '이번 달');
    week.dispose();
    month.dispose();
    await DraftTextController.flushAll();
  });
}
