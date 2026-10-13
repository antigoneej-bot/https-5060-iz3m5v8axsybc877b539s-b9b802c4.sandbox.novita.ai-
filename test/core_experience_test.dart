import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/widgets/home_core_actions.dart';
import 'package:flutter_app/mongi/integration/plant_memory_editor.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('three home actions remain usable at 360px with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final chosen = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.4),
          ),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                HomeCoreActions(
                  onWrite: () => chosen.add('write'),
                  onGarden: () => chosen.add('garden'),
                  onReflect: () => chosen.add('reflect'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (final name in ['home-write', 'home-garden', 'home-reflect']) {
      final button = find.byKey(ValueKey(name));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }
    expect(chosen, ['write', 'garden', 'reflect']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'back protects an edited plant memory until explicitly discarded',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      PlantMemoryEditor(plant: SeedType.byId('pine')),
                ),
                child: const Text('open memory'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open memory'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '내 첫 나무');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('작성 중인 추억을 닫을까요?'), findsOneWidget);
      await tester.tap(find.text('계속 쓰기'));
      await tester.pumpAndSettle();
      expect(find.text('내 첫 나무'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(PlantMemoryEditor), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'old plant memories remain readable; impossible commemorative dates are rejected',
    () {
      final old = {
        'plantId': 'pine',
        'name': '첫 나무',
        'note': '조용한 하루',
        'updatedAt': DateTime(2026, 10, 1).toIso8601String(),
      };
      expect(PlantMemory.fromJson(old).memoryDate, isNull);
      expect(
        PlantMemory.fromJson({...old, 'memoryDate': '2026-10-14'}).memoryDate,
        DateTime(2026, 10, 14),
      );
      expect(
        () => PlantMemory.fromJson({...old, 'memoryDate': '2026-02-30'}),
        throwsFormatException,
      );
    },
  );

  test(
    'private commemorative date and note persist and validate in encrypted backup',
    () async {
      final dir = await Directory.systemTemp.createTemp('garden-memory-core-');
      Hive.init(dir.path);
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (_) async => null,
          );
      try {
        await PlantMemoryStore.instance.save(
          'pine',
          '우리 우정',
          '우리만의 기억',
          memoryDate: DateTime(2026, 10, 14),
        );
        await PlantMemoryStore.instance.reload();
        expect(
          PlantMemoryStore.instance.value['pine']!.memoryDate,
          DateTime(2026, 10, 14),
        );
        final backup = await BackupService.snapshot();
        BackupService.validate(backup);
        final entries = backup['boxes']['garden_memories'] as List;
        expect(entries.single['value']['memoryDate'], '2026-10-14');
        expect(entries.single['value']['note'], '우리만의 기억');
        await PlantMemoryStore.instance.remove('pine');
        expect(PlantMemoryStore.instance.value, isEmpty);
      } finally {
        await Hive.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
