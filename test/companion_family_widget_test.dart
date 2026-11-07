import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/screens/companion_coat_screen.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/services/cat_care_service.dart';

void main() {
  testWidgets('adopt, return to adult and reopen keep two residents', (
    tester,
  ) async {
    CatCareService.setCurrentUser("local_user");
    SharedPreferences.setMockInitialValues({
      'local_user_companion_journey_v1': const CompanionJourney(
        previousCareDays: 90,
        coat: CompanionCoat.ginger,
      ).encode(),
    });
    final care = CatCareProvider();
    await care.loadJourney();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: care,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const CompanionCoatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final adopt = find.byKey(const ValueKey('adopt-white'));
    await tester.scrollUntilVisible(adopt, 150, scrollable:find.byType(Scrollable).first);
    await tester.ensureVisible(adopt);
    await tester.tap(adopt);
    await tester.pumpAndSettle();
    expect(care.journey.activeGrowthDays, 0);
    expect(care.journey.residents.length, 2);
    expect(find.byKey(const ValueKey('adopt-black')), findsNothing);
    await care.selectCoat(CompanionCoat.ginger);
    await care.loadJourney();
    expect(care.journey.stage, 3);
    expect(care.journey.residents[CompanionCoat.white], 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    care.dispose();
  });
  testWidgets(
    'family is visible in own garden and absent from visited garden',
    (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const destination = String.fromEnvironment('FAMILY_CAPTURE_DIR');
      if (destination.isNotEmpty) {
        for (final font in ['GowunDodum', 'GamjaFlower']) {
          final loader = FontLoader(font)
            ..addFont(rootBundle.load('assets/fonts/$font-Regular.ttf'));
          await tester.runAsync(loader.load);
        }
        final icons = FontLoader("MaterialIcons")
          ..addFont(rootBundle.load("fonts/MaterialIcons-Regular.otf"));
        await tester.runAsync(icons.load);
      }
      final care = CatCareProvider()
        ..journey = const CompanionJourney(
          previousCareDays: 90,
          coat: CompanionCoat.white,
          family: {
            CompanionCoat.ginger: 90,
            CompanionCoat.white: 0,
            CompanionCoat.black: 90,
          },
        );
      final boundary = GlobalKey();
      Widget screen(bool readOnly) => ChangeNotifierProvider.value(
        value: care,
        child: MaterialApp(
          theme: appTheme,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: Scaffold(
            appBar: AppBar(title: const Text('함께 자라는 고양이 정원')),
            body: RepaintBoundary(
              key: boundary,
              child: ColoredBox(
                color: AppColors.bg0,
                child: GardenWorldView(
                  readOnly: readOnly,
                  fillViewport: true,
                  motionEnabled: false,
                  family: care.journey.residents,
                  activeCoat: CompanionCoat.white,
                  companionScale: .82,
                  layout: GardenLayout(spaces: 3),
                  seeds: const {'love': 3, 'peace': 8},
                  decorations: const ['bench'],
                  onMove: (_, __) async {},
                  onMemory: (_) {},
                  onPlant: () {},
                  onDecorate: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(screen(false));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('resident-ginger')), findsOneWidget);
      expect(find.byKey(const ValueKey('resident-black')), findsOneWidget);
      expect(find.byKey(const ValueKey('resident-white')), findsNothing);
      if (destination.isNotEmpty) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(seconds: 2));
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final img =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1.5);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          await Directory(destination).create(recursive: true);
          await File(
            '$destination/Mindnyang-Growing-Family-v47.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          img.dispose();
        });
      }
      await tester.pumpWidget(screen(true));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('resident-ginger')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      care.dispose();
    },
  );
}
