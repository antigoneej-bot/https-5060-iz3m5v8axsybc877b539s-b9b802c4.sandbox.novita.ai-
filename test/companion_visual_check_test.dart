import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/widgets/companion_care_panel.dart';

void main() {
  testWidgets('grown appearance keeps the same cat, name and baby preference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loader = FontLoader('GowunDodum')
      ..addFont(rootBundle.load('assets/fonts/GowunDodum-Regular.ttf'));
    await tester.runAsync(loader.load);
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await tester.runAsync(icons.load);
    var journey = const CompanionJourney();
    for (var i = 0; i < 7; i++) {
      journey = journey.record(CompanionMoment.pet, DateTime(2026, 10, 1 + i));
    }
    SharedPreferences.setMockInitialValues({
      'local_user_companion_journey_v1': journey.encode(),
    });
    CatCareService.setCurrentUser('local_user');
    final care = CatCareProvider()..companionName = '햇살';
    final boundary = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: care,
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'GowunDodum',
              scaffoldBackgroundColor: const Color(0xFFFAF7EF),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF50785C),
              ),
            ),
            home: Scaffold(
              appBar: AppBar(title: const Text('고양이 돌보기')),
              body: const SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: CompanionCarePanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/living_garden/cat_idle_front.webp'),
        tester.element(find.byType(CompanionCarePanel)),
      );
    });
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/living_garden/cat_idle_front_blink.webp'),
        tester.element(find.byType(CompanionCarePanel)),
      );
    });
    await tester.pump();
    expect(find.text('함께 돌본 7일'), findsOneWidget);
    expect(care.journey.visualScale, .88);
    const destination = String.fromEnvironment('COMPANION_CAPTURE_DIR');
    if (destination.isNotEmpty) {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(destination).create(recursive: true);
        await File(
          '$destination/companion-care-390.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    if (destination.isNotEmpty &&
        const bool.fromEnvironment('COMPANION_MOTION_CAPTURE')) {
      final directory = '$destination/frames';
      await tester.runAsync(() => Directory(directory).create(recursive: true));
      for (var frame = 0; frame < 96; frame++) {
        await tester.pump(const Duration(microseconds: 83333));
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$directory/${frame.toString().padLeft(3, '0')}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    final toggle = find.byKey(const Key('companion-keep-baby'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(care.journey.keepBaby, true);
    expect(care.journey.growthDays, 7);
    expect(care.displayName, '햇살');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    care.dispose();
  });
}
