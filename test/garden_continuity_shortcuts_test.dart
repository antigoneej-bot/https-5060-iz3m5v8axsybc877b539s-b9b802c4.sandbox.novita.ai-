import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/care_journal_screen.dart';
import 'package:flutter_app/screens/garden_memory_book_screen.dart';
import 'package:flutter_app/screens/premium_screen.dart';
import 'package:flutter_app/services/care_journal_store.dart';
import 'package:flutter_app/services/garden_memory_book_store.dart';
import 'package:flutter_app/widgets/garden_continuity_shortcuts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('garden_shortcuts_');
    Hive.init(directory.path);
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
    await CareJournalStore.instance.reload();
    await GardenMemoryBookStore.instance.reload();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  testWidgets(
    'home shortcuts open both real free destinations on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const Scaffold(body: GardenContinuityShortcuts()),
        ),
      );
      final care = find.byKey(const ValueKey('open-care-journal'));
      final book = find.byKey(const ValueKey('open-garden-memory-book'));
      expect(care.hitTestable(), findsOneWidget);
      expect(book.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(care);
      await tester.pump();
      for (var frame = 0; frame < 20; frame++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      expect(find.byType(CareJournalScreen), findsOneWidget);
      expect(find.byType(PremiumScreen), findsNothing);
      expect(find.text('지금 나에게 해줄 작은 일'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(book);
      await tester.pump();
      for (var frame = 0; frame < 20; frame++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
      expect(find.byType(GardenMemoryBookScreen), findsOneWidget);
      expect(find.byType(PremiumScreen), findsNothing);
      expect(find.textContaining('첫 기본 기록집은 무료'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
