import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/self_care_entry.dart';
import 'package:flutter_app/services/self_care_store.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/screens/self_care_entry_screen.dart';
import 'package:flutter_app/screens/care_connection_screen.dart';
import '../tool/self_care_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('mindnyang_selfcare_');
    Hive.init(directory.path);
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
    SharedPreferences.setMockInitialValues({});
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('self-care data contract and statistics', verifySelfCareContract);
  test('encrypted save, reload, review, backup and deletion', () async {
    final store = SelfCareStore.instance;
    final entry = SelfCareEntry(
      id: 'private',
      createdAt: DateTime(2026, 1, 1),
      reflection: '나만 보는 기록',
      action: CareAction.rest,
    );
    await store.save(entry);
    expect(await Hive.boxExists('${SelfCareStore.boxName}__enc'), isTrue);
    expect(await Hive.boxExists(SelfCareStore.boxName), isFalse);
    await store.review(entry.id, CareFeedback.unchanged, 3);
    expect((await store.load()).single.feedback, CareFeedback.unchanged);
    final snapshot = await BackupService.snapshot();
    BackupService.validate(snapshot); // Null cat and null baseline are valid.
    final rows = (snapshot['boxes'] as Map)['self_care'] as List;
    expect(rows.single['key'], 'private');
    await store.remove(entry.id);
    expect(await store.load(), isEmpty);
    await BackupService.restore(snapshot);
    expect((await store.load()).single.reflection, '나만 보는 기록');
    await store.remove(entry.id);
    await expectLater(
      store.review(entry.id, CareFeedback.helped, null),
      throwsStateError,
    );
    // A failed write must not poison later queue operations.
    await store.save(entry);
    expect((await store.load()).single.id, entry.id);
    await store.remove(entry.id);
  });
  test('map link contains category only', () {
    final uri = CareConnectionScreen.mapSearch('명상센터');
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters, {'api': '1', 'query': '명상센터'});
  });
  testWidgets('score starts empty and fits small screens with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    int? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: SingleChildScrollView(
              child: ComfortPicker(value: null, onChanged: (v) => chosen = v),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .every((chip) => !chip.selected),
      isTrue,
    );
    await tester.tap(find.text('4'));
    expect(chosen, 4);
  });
}
