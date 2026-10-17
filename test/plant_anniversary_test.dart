import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/garden_anniversary_section.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_editor.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';

PlantMemory memory({String day = '2026-07-09'}) => PlantMemory(
  plantId: 'pine',
  name: '우리의 나무',
  anniversaryOn: day,
  note: '나만의 두 번째 장면',
  updatedAt: DateTime(2026, 10, 16),
  entries: const [
    PlantMemoryEntry(id: 'first', on: '2026-07-09', note: '나만의 첫 장면'),
    PlantMemoryEntry(id: 'second', on: '2026-10-16', note: '나만의 두 번째 장면'),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy note remains in a dated timeline without inventing an anniversary',
    () {
      final old = {
        'plantId': 'pine',
        'name': '처음의 나무',
        'note': '기억할 장면',
        'updatedAt': '2026-07-09T23:12:34',
      };
      final parsed = PlantMemory.fromJson(old);
      expect(parsed.anniversaryOn, isNull);
      expect(parsed.timeline.single.note, '기억할 장면');
      expect(parsed.timeline.single.on, '2026-07-09');
      final restored = PlantMemory.fromJson(parsed.toJson());
      expect(restored.timeline.single.id, parsed.timeline.single.id);
      expect(restored.note, '기억할 장면');
    },
  );

  test(
    'milestones count calendar days inclusively including leap and future days',
    () {
      final value = memory(day: '2024-02-01');
      expect(value.daysTogether(DateTime(2024, 2, 29, 23, 59)), 29);
      expect(value.milestonesReached(DateTime(2024, 3, 1)), [30]);
      expect(value.milestonesReached(DateTime(2024, 5, 9, 0, 1)), [30]);
      expect(value.milestonesReached(DateTime(2024, 5, 10, 23, 59)), [30, 100]);
      expect(value.daysTogether(DateTime(2024, 1, 31)), 0);
      expect(value.milestonesReached(DateTime(2024, 1, 31)), isEmpty);
      expect(memory().milestonesReached(DateTime(2026, 10, 16)), [30, 100]);
    },
  );

  test(
    'invalid dates duplicate entries unsupported schemas and overflow reject',
    () {
      final bad = <Map<String, dynamic>>[
        memory().toJson()..['anniversaryOn'] = '2026-02-30',
        memory().toJson()..['anniversaryOn'] = '2026-10-16T00:00:00',
        memory().toJson()..['version'] = 99,
        memory().toJson()
          ..['entries'] = [
            {'id': 'a', 'on': '2026-10-16', 'note': '같음'},
            {'id': 'a', 'on': '2026-10-17', 'note': '다름'},
          ],
        memory().toJson()
          ..['entries'] = [
            {'id': 'a', 'on': '2026-02-30', 'note': '잘못된 날짜'},
          ],
        memory().toJson()
          ..['entries'] = List.generate(
            61,
            (i) => {'id': '$i', 'on': '2026-10-16', 'note': '나만의 두 번째 장면'},
          ),
      ];
      for (final input in bad) {
        expect(() => PlantMemory.fromJson(input), throwsFormatException);
      }
    },
  );

  test(
    'encrypted backup preserves anniversary and all scenes on fresh restore',
    () async {
      SharedPreferences.setMockInitialValues({});
      final directory = await Directory.systemTemp.createTemp('plant-memory-');
      Hive.init(directory.path);
      const channel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => call.method == 'read'
                ? base64Encode(List<int>.filled(32, 7))
                : null,
          );
      try {
        await PlantMemoryStore.instance.saveMemory(memory());
        // Old callers append without removing earlier dated scenes or the date.
        await PlantMemoryStore.instance.save('pine', '우리의 나무', '세 번째 장면');
        final saved = PlantMemoryStore.instance.value['pine']!;
        expect(saved.timeline.length, 3);
        expect(saved.anniversaryOn, '2026-07-09');
        final snapshot = await BackupService.snapshot();
        BackupService.validate(snapshot);
        final box = await HiveEncryption.openBox(PlantMemoryStore.boxName);
        await box.clear();
        await box.flush();
        await BackupService.restore(snapshot);
        await PlantMemoryStore.instance.reload();
        final restored = PlantMemoryStore.instance.value['pine']!;
        expect(restored.toJson(), saved.toJson());
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        PlantMemoryStore.instance.value = const {};
      }
    },
  );

  testWidgets(
    'private milestone card opens only the chosen editable caption at 360px',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      final care = CatCareProvider()..companionName = '밤';
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        PlantMemoryStore.instance.value = const {};
        care.dispose();
      });
      PlantMemoryStore.instance.value = {'pine': memory()};
      await tester.pumpWidget(
        ChangeNotifierProvider<CatCareProvider>.value(
          value: care,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GardenAnniversarySection(
                  data: MongiGardenData(seeds: const {'pine': 1}),
                  cats: const [],
                  now: DateTime(2026, 10, 16),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('함께한 지 100일 · 2026-07-09'), findsOneWidget);
      expect(find.text('30일 기념 엽서'), findsOneWidget);
      expect(find.text('100일 기념 엽서'), findsOneWidget);
      expect(find.textContaining('나만의 첫 장면'), findsNothing);
      await tester.tap(find.text('100일 기념 엽서'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '우리의 나무 · 함께한 100일');
      expect(find.textContaining('나만의 두 번째 장면'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('360px memory editor keeps old scenes and cancels draft edits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    final oldGarden = MongiGardenStore.instance.value;
    final original = memory();
    PlantMemoryStore.instance.value = {'pine': original};
    MongiGardenStore.instance.value = MongiGardenData(
      seeds: const {'pine': 1},
      plantedOn: const {'pine': '2026-07-09'},
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      PlantMemoryStore.instance.value = const {};
      MongiGardenStore.instance.value = oldGarden;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PlantMemoryEditor(plant: SeedType.byId('pine')),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('기념 시작일 · 2026-07-09'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      isEmpty,
    );
    await tester.ensureVisible(find.text('수정').first);
    await tester.tap(find.text('수정').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == '그날의 한 장면',
      ),
      '다듬은 추억',
    );
    await tester.tap(find.text('변경'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('다듬은 추억'), findsOneWidget);
    expect(
      PlantMemoryStore.instance.value['pine']!.toJson(),
      original.toJson(),
    );
    await tester.tap(find.text('취소'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(PlantMemoryEditor), findsNothing);
    expect(
      PlantMemoryStore.instance.value['pine']!.toJson(),
      original.toJson(),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
