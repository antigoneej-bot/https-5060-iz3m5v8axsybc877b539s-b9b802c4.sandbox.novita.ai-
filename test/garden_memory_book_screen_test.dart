import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/screens/garden_memory_book_screen.dart';
import 'package:flutter_app/services/garden_memory_book_store.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/services/private_letter_memory_source.dart';
import 'package:flutter_app/services/care_journal_store.dart';
import 'package:flutter_app/mongi/integration/garden_layout_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('garden_book_ui_');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
    await StorageService.setCurrentUser('local_user');
    await PrivateLetterMemorySource.bookLetters();
    // Open persistent handles outside the fake-async widget zone, as in app startup.
    await Future.wait([
      GardenMemoryBookStore.instance.reload(),
      CareJournalStore.instance.reload(),
      GardenLayoutStore.instance.reload(),
      PlantMemoryStore.instance.reload(),
      MongiGardenStore.instance.reload(),
    ]);
  });
  tearDownAll(() async {
    await StorageService.clearCurrentUser();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<void> settleIo(WidgetTester tester, Finder ready) async {
    for (var frame = 0; frame < 80; frame++) {
      await tester.pump(const Duration(milliseconds: 25));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      if (ready.evaluate().isNotEmpty) return;
    }
    expect(ready, findsWidgets);
  }

  testWidgets(
    'monthly editor opens at mobile and desktop widths with large text',
    (tester) async {
      for (final width in [360.0, 960.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(
          () => GardenMemoryBookStore.instance.clear(resetPolicy: true),
        );
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: GardenMemoryBookScreen(initialMonth: DateTime.now()),
          ),
        );
        await settleIo(tester, find.text('담을 달 고르기'));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('담을 달 고르기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('이 달 선택'));
        await tester.pump();
        await settleIo(tester, find.textContaining('아무것도 고르지 않으면 정원 구성만 남아요.'));
        await tester.pump(const Duration(milliseconds: 350));
        expect(find.textContaining('아무것도 고르지 않으면 정원 구성만 남아요.'), findsOneWidget);
        expect(find.textContaining('선택한 달의 과거 사진이 아니라'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final preview = find.widgetWithText(OutlinedButton, '미리보기');
        await tester.scrollUntilVisible(preview, 200);
        await tester.pump();
        expect(tester.getRect(preview).width, lessThanOrEqualTo(width));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        var drained = false;
        GardenMemoryBookStore.instance.reload().then((_) => drained = true);
        for (var frame = 0; frame < 40 && !drained; frame++) {
          await tester.pump(const Duration(milliseconds: 20));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        expect(drained, isTrue);
      }
    },
  );
}
