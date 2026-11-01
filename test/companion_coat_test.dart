import 'dart:convert';
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
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/companion_journey_store.dart';
import 'package:flutter_app/screens/companion_coat_screen.dart';
import 'package:flutter_app/widgets/companion_coat_art.dart';
import 'package:flutter_app/widgets/companion_presence.dart';
import 'package:flutter_app/mongi/widgets/garden_cat_response.dart';
import 'package:flutter_app/mongi/widgets/garden_walking_cat.dart';
import 'package:flutter_app/mongi/models/garden_life.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('local_user');
  });
  test('legacy and unknown coat preserve records and fall back safely', () {
    final old = const CompanionJourney(
      previousCareDays: 12,
    ).record(CompanionMoment.pet, DateTime(2026, 10, 27));
    final raw = jsonDecode(old.encode()) as Map;
    raw.remove('coat');
    expect(CompanionJourney.decode(jsonEncode(raw)).coat, isNull);
    raw['coat'] = 'future_coat';
    final decoded = CompanionJourney.decode(jsonEncode(raw));
    expect(decoded.coat, isNull);
    expect(decoded.growthDays, 13);
    expect(decoded.firstMoments, old.firstMoments);
  });
  test(
    'all six are free, persist on reopen, and never reset care or other data',
    () async {
      final old = const CompanionJourney(
        previousCareDays: 30,
        keepBaby: true,
        automaticBehavior: false,
      ).record(CompanionMoment.pet, DateTime(2026, 10, 26));
      SharedPreferences.setMockInitialValues({
        'local_user_companion_journey_v1': old.encode(),
        'local_user_letter': 'keep private letter',
        'local_user_companion_name': '햇살',
      });
      final care = CatCareProvider()..companionName = '햇살';
      await care.loadJourney();
      expect(care.isPremium, false);
      for (final coat in CompanionCoat.values) {
        await care.selectCoat(coat);
        final reloaded = CatCareProvider();
        await reloaded.loadJourney();
        expect(reloaded.journey.coat, coat);
        expect(reloaded.journey.growthDays, 31);
        expect(reloaded.journey.firstMoments, old.firstMoments);
        expect(reloaded.journey.todayMoments, old.todayMoments);
        expect(reloaded.journey.keepBaby, true);
        expect(reloaded.journey.automaticBehavior, false);
        expect(care.displayName, '햇살');
        reloaded.dispose();
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('local_user_letter'), 'keep private letter');
      expect(prefs.getString('local_user_companion_name'), '햇살');
      care.dispose();
    },
  );
  test(
    'concurrent care, baby setting, and coat write survive backup encoding',
    () async {
      await Future.wait([
        CompanionJourneyStore.setCoat('local_user', CompanionCoat.calico),
        CompanionJourneyStore.record('local_user', CompanionMoment.water),
        CompanionJourneyStore.setBaby('local_user', true),
        CompanionJourneyStore.setAutomaticBehavior('local_user', false),
      ]);
      final saved = CompanionJourney.decode(
        (await CompanionJourneyStore.load('local_user')).encode(),
      );
      expect(saved.coat, CompanionCoat.calico);
      expect(saved.growthDays, 1);
      expect(saved.keepBaby, true);
      expect(saved.automaticBehavior, false);
      expect((await CompanionJourneyStore.load('other')).coat, isNull);
    },
  );
  test('unreadable history is not overwritten when selecting a cat', () async {
    SharedPreferences.setMockInitialValues({
      'local_user_companion_journey_v1': 'damaged-record',
    });
    await expectLater(
      CompanionJourneyStore.setCoat('local_user', CompanionCoat.black),
      throwsFormatException,
    );
    expect(
      (await SharedPreferences.getInstance()).getString(
        'local_user_companion_journey_v1',
      ),
      'damaged-record',
    );
  });
  testWidgets(
    'idle, walk and reaction update together; visited garden ignores local choice',
    (tester) async {
      final care = CatCareProvider();
      await care.selectCoat(CompanionCoat.black);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: care,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const SizedBox(
                    width: 150,
                    height: 150,
                    child: CompanionPresence(enabled: false),
                  ),
                  const SizedBox(
                    width: 150,
                    height: 150,
                    child: GardenWalkingCat(
                      frame: 0,
                      facing: GardenCatFacing.side,
                      faceLeft: false,
                    ),
                  ),
                  const SizedBox(
                    width: 150,
                    height: 150,
                    child: GardenCatResponse(
                      kind: 'heart',
                      progress: .5,
                      animated: false,
                    ),
                  ),
                  const CompanionCoatScope(
                    useLocalChoice: false,
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: CompanionPresence(enabled: false),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widgetList<CompanionCoatArt>(find.byType(CompanionCoatArt))
            .map((w) => w.coat),
        everyElement(CompanionCoat.black),
      );
      expect(find.byType(CompanionCoatArt), findsNWidgets(3));
      await tester.runAsync(() => care.selectCoat(CompanionCoat.white));
      await tester.pump();
      expect(
        tester
            .widgetList<CompanionCoatArt>(find.byType(CompanionCoatArt))
            .map((w) => w.coat),
        everyElement(CompanionCoat.white),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      care.dispose();
    },
  );
  for (final settings in [(390.0, 1.0), (320.0, 2.0), (700.0, 1.0)]) {
    testWidgets(
      'picker selects all free cats at width ${settings.$1}, scale ${settings.$2}',
      (tester) async {
        tester.view.physicalSize = Size(settings.$1, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const destination = String.fromEnvironment('COAT_CAPTURE_DIR');
        if (destination.isNotEmpty) {
          for (final font in ['GowunDodum', 'GamjaFlower']) {
            final loader = FontLoader(font)
              ..addFont(rootBundle.load('assets/fonts/$font-Regular.ttf'));
            await tester.runAsync(loader.load);
          }
          final loader = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await tester.runAsync(loader.load);
        }
        final care = CatCareProvider();
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
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF9A658E),
                  ),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(settings.$2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: const CompanionCoatScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pumpAndSettle();
        expect(find.text('6종 선택 · 성장 · 가족 · 구독 기능'), findsOneWidget);
        if (destination.isNotEmpty && settings.$2 == 1) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(destination).create(recursive: true);
            await File(
              '$destination/Mindnyang-Cats-${settings.$1.toInt()}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        for (final coat in CompanionCoat.values) {
          final option = find.byKey(ValueKey('coat-${coat.name}'));
          if (option.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              option,
              180,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(option);
          await tester.pumpAndSettle();
          await tester.tap(option);
          await tester.pumpAndSettle();
          expect(care.journey.coat, coat);
          expect(care.journey.growthDays, 0);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        care.dispose();
      },
    );
  }
}
