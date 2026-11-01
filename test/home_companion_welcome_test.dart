import 'dart:convert';
import 'dart:async';
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
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/widgets/companion_coat_art.dart';
import 'package:flutter_app/widgets/companion_motion_art.dart';
import 'package:flutter_app/widgets/companion_presence.dart';
import 'package:flutter_app/widgets/home_companion_touch.dart';
import 'package:flutter_app/widgets/companion_welcome_home.dart';
import 'package:flutter_app/widgets/pastel_garden_shell.dart';
import 'package:flutter_app/screens/home_screen.dart';
import 'package:flutter_app/screens/cat_flow_tab_screen.dart';
import 'package:flutter_app/mongi/screens/garden_world_screen.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/utils/feature_flags.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';

class _PendingGarden extends GardenProvider {
  @override
  Future<void> ensureInitialized() => Completer<void>().future;
}

const output = String.fromEnvironment('HOME_WELCOME_CAPTURE');
const exportVideo = bool.fromEnvironment('HOME_WELCOME_VIDEO');

Future<CatCareProvider> reopen() async {
  final care = CatCareProvider();
  await care.loadJourney();
  care.companionName = await StorageService.getCompanionName();
  care.isLoading = false;
  return care;
}

Map<String, Object> snapshot(SharedPreferences prefs) => {
  for (final key in prefs.getKeys()) key: prefs.get(key)!,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final e in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
    for (final coat in CompanionCoat.values) {
      final atlas = await CompanionSpriteAtlas.load(coat);
      expect(atlas.frames.length, 12);
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('local_user');
  });

  Future<void> mount(
    WidgetTester t,
    CatCareProvider care,
    GlobalKey shot,
    List<PastelAction> actions, {
    bool motion = true,
    double scale = 1,
    bool reducedMotion = false,
    List<int>? moods,
  }) async {
    await t.pumpWidget(
      ChangeNotifierProvider.value(
        value: care,
        child: RepaintBoundary(
          key: shot,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: reducedMotion,
              ),
              child: child!,
            ),
            home: Consumer<CatCareProvider>(
              builder: (context, value, _) => PastelGardenShell(
                onAction: actions.add,
                onCoat: (_) {},
                onMoodSelected: moods?.add,
                coat: value.journey.coat,
                companionName: value.companionName,
                companionStage: value.journey.keepBaby
                    ? 0
                    : value.journey.stage,
                motionEnabled: motion,
                companionBondStage: value.journey.stage,
                companionAutomaticBehavior: value.journey.automaticBehavior,
                gardenPreview: const SizedBox(),
                // Garden's real storage/planting is exercised by garden_world_offline_test.
                actualGarden: const SizedBox(
                  key: Key('garden-tab-placeholder'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/storybook_ui_v2/home-room.png'),
        shot.currentContext!,
      );
      await precacheImage(
        const AssetImage('assets/storybook_ui_v1/illustration-atlas.png'),
        shot.currentContext!,
      );
    });
    await t.pump();
  }

  Future<void> capture(WidgetTester t, GlobalKey key, String file) async {
    if (output.isEmpty) return;
    await t.runAsync(() async {
      final target = File('$output/$file');
      await target.parent.create(recursive: true);
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await target.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  CompanionCoatArt cat(WidgetTester t) => t.widget<CompanionCoatArt>(
    find
        .descendant(
          of: find.byType(CompanionWelcomeHome),
          matching: find.byType(CompanionCoatArt),
        )
        .first,
  );

  Future<void> revealHomeControl(WidgetTester t, Finder control) async {
    final scroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('pastel-page-0')),
          matching: find.byType(Scrollable),
        )
        .first;
    await t.scrollUntilVisible(control, 120, scrollable: scroll);
    await t.pump();
    await Scrollable.ensureVisible(t.element(control), alignment: .5);
    await t.pump();
  }

  const names = ['보리', '구름', '토리', '밤', '두부', '나비'];
  for (final coat in CompanionCoat.values) {
    testWidgets(
      'home ${coat.name}: saved identity, real blink frames and restart retain name and garden data',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final name = names[coat.index];
        SharedPreferences.setMockInitialValues({
          'local_user_companion_journey_v1': const CompanionJourney(
            previousCareDays: 7,
          ).encode(),
        });
        await CompanionJourneyStore.setCoat('local_user', coat);
        await StorageService.setCompanionName(name);
        final care = await reopen();
        final initial = snapshot(await SharedPreferences.getInstance());
        final shot = GlobalKey();
        await mount(t, care, shot, []);
        expect(cat(t).coat, coat);
        expect(find.text(name), findsOneWidget);
        expect(cat(t).motion!.frame, 0);
        expect(
          find.descendant(
            of: find.byType(CompanionPresence).first,
            matching: find.byType(Transform),
          ),
          findsNothing,
        );
        final presence = t.getRect(find.byType(CompanionPresence).first);
        final greeting = t.getRect(find.byKey(const Key('home-greeting')));
        expect(greeting.bottom, lessThanOrEqualTo(presence.top));
        expect(presence.left, greaterThanOrEqualTo(0));
        expect(presence.right, lessThanOrEqualTo(390));
        await capture(t, shot, 'home-${coat.name}.png');
        final frames = <int>{cat(t).motion!.frame};
        final timeline = <int>[];
        if (exportVideo && output.isNotEmpty) {
          for (var i = 0; i < 75; i++) {
            if (i > 0) await t.pump(const Duration(microseconds: 66667));
            frames.add(cat(t).motion!.frame);
            timeline.add(cat(t).motion!.frame);
            if (i == 26) {
              await capture(t, shot, 'home-${coat.name}-blink.png');
            }
            if (i == 51) {
              for (var tap = 0; tap < 3; tap++) {
                await t.tap(find.byKey(const Key('home-companion-touch')));
              }
              await t.pump();
              expect(
                find.byKey(const Key('home-petting-heart')),
                findsOneWidget,
              );
            }
            if (i == 58)
              await capture(t, shot, 'home-${coat.name}-petting.png');
            await capture(
              t,
              shot,
              'home-video-frames/${coat.name}/frame-${i.toString().padLeft(5, '0')}.png',
            );
          }
          expect(frames, containsAll([0, 1, 2, 3]));
          await t.runAsync(
            () => File('$output/home-${coat.name}-execution.json').writeAsString(
              jsonEncode({
                'coat': coat.name,
                'testName': name,
                'frames': 75,
                'fps': 15,
                'observedSpritePoses': frames.toList(),
                'poseTimeline': timeline,
                'renderer': 'CompanionPresence / CompanionMotionArt',
                'pettingStartsAtFrame': 51,
                'environment':
                    'Flutter widget test; actual production controller in virtual time; synthetic local data; not Android device recording',
              }),
            ),
          );
        } else {
          await t.pump(const Duration(milliseconds: 1750));
          expect(cat(t).motion!.frame, 2);
          await t.pump(const Duration(milliseconds: 1250));
          expect(cat(t).motion!.frame, 3);
        }
        expect(
          snapshot(await SharedPreferences.getInstance()),
          initial,
          reason:
              'Welcoming animation and viewing the home must not change stored records',
        );
        await t.pumpWidget(const SizedBox());
        care.dispose();
        // Recreate the preferences cache and provider, not just the widget state.
        SharedPreferences.setMockInitialValues(initial);
        final restarted = await reopen();
        await mount(t, restarted, GlobalKey(), [], motion: false);
        expect(cat(t).coat, coat);
        expect(find.text(name), findsOneWidget);
        expect(restarted.journey.previousCareDays, 7);
        expect(snapshot(await SharedPreferences.getInstance()), initial);
        await t.pumpWidget(const SizedBox());
        restarted.dispose();
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'petting ignores repeated taps and stops for coat, tab, background and reduced motion',
    (t) async {
      final care = await reopen();
      await care.selectCoat(CompanionCoat.black);
      final before = snapshot(await SharedPreferences.getInstance());
      await mount(t, care, GlobalKey(), []);
      AnimationController reaction() =>
          t
                  .widget<AnimatedBuilder>(
                    find
                        .descendant(
                          of: find.byType(HomeCompanionTouch),
                          matching: find.byType(AnimatedBuilder),
                        )
                        .first,
                  )
                  .animation
              as AnimationController;
      final touch = find.byKey(const Key('home-companion-touch'));
      await t.tap(touch);
      await t.pump();
      await t.pump(const Duration(milliseconds: 700));
      final progress = reaction().value;
      for (var i = 0; i < 8; i++) await t.tap(touch);
      await t.pump();
      expect(reaction().value, progress);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(reaction().isAnimating, false);
      expect(find.byKey(const Key('home-petting-heart')), findsNothing);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.tap(touch);
      await t.pump();
      await care.selectCoat(CompanionCoat.white);
      await t.pump();
      expect(cat(t).coat, CompanionCoat.white);
      expect(reaction().isAnimating, false);
      await t.tap(touch);
      await t.pump();
      await t.tap(find.text('정원').last);
      for (var i = 0; i < 20; i++)
        await t.pump(const Duration(milliseconds: 50));
      expect(
        find.byKey(const Key('home-petting-heart'), skipOffstage: false),
        findsNothing,
      );
      await t.tap(find.text('홈').last);
      for (var i = 0; i < 20; i++)
        await t.pump(const Duration(milliseconds: 50));
      await mount(t, care, GlobalKey(), [], reducedMotion: true);
      expect(cat(t).motion!.frame, 0);
      await t.tap(touch);
      await t.pump(const Duration(seconds: 2));
      expect(reaction().isAnimating, false);
      expect(cat(t).motion!.frame, 0);
      // Only the explicit coat selection changed stored data; touching did not.
      final after = snapshot(await SharedPreferences.getInstance());
      expect(after.keys, unorderedEquals(before.keys));
      final stored = await CompanionJourneyStore.load('local_user');
      expect(stored.growthDays, care.journey.growthDays);
      expect(stored.firstMoments, isEmpty);
      await t.pumpWidget(const SizedBox());
      care.dispose();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'selection and custom rename update the mounted home; mood never changes companion',
    (t) async {
      final care = await reopen();
      await care.selectCoat(CompanionCoat.ginger);
      final actions = <PastelAction>[], moods = <int>[];
      await mount(t, care, GlobalKey(), actions, motion: false, moods: moods);
      for (final coat in CompanionCoat.values) {
        await care.selectCoat(coat);
        await t.pump();
        expect(cat(t).coat, coat);
      }
      await care.renameCompanion('내가 정한 이름');
      await t.pump();
      expect(find.text('내가 정한 이름'), findsOneWidget);
      final before = care.journey.coat;
      for (final mood in ['좋아요', '평온해요', '보통', '힘들어요', '지쳤어요']) {
        await t.ensureVisible(find.text(mood));
        await t.tap(find.text(mood));
        await t.pump();
        expect(cat(t).coat, before);
      }
      expect(moods, [0, 1, 2, 3, 4]);
      await revealHomeControl(t, find.byKey(const Key('home-record')));
      await t.tap(find.byKey(const Key('home-record')));
      expect(actions.last, PastelAction.write);
      await revealHomeControl(t, find.byKey(const Key('home-garden')));
      await t.tap(find.byKey(const Key('home-garden')));
      expect(actions.last, PastelAction.garden);
      await t.ensureVisible(find.byKey(const Key('home-companion-touch')));
      final actionCount = actions.length;
      final storedBeforePet = snapshot(await SharedPreferences.getInstance());
      await t.tap(find.byKey(const Key('home-companion-touch')));
      await t.pump();
      expect(actions.length, actionCount);
      expect(find.byKey(const Key('home-petting-heart')), findsOneWidget);
      expect(snapshot(await SharedPreferences.getInstance()), storedBeforePet);
      await t.pump(const Duration(milliseconds: 1700));
      expect(find.byKey(const Key('home-petting-heart')), findsNothing);
      await t.ensureVisible(find.byKey(const Key('home-companion-care')));
      await t.tap(find.byKey(const Key('home-companion-care')));
      expect(actions.last, PastelAction.companion);
      await t.pumpWidget(const SizedBox());
      care.dispose();
    },
  );

  testWidgets(
    'home clock stops on other tabs and background and resumes the same cat',
    (t) async {
      final care = await reopen();
      await care.selectCoat(CompanionCoat.tabby);
      await mount(t, care, GlobalKey(), []);
      AnimationController clock() =>
          t
                  .widget<AnimatedBuilder>(
                    find
                        .descendant(
                          of: find.byType(CompanionPresence).first,
                          matching: find.byType(AnimatedBuilder),
                        )
                        .first,
                  )
                  .animation
              as AnimationController;
      expect(clock().isAnimating, isTrue);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump();
      expect(clock().isAnimating, isFalse);
      final paused = clock().value;
      await t.pump(const Duration(seconds: 5));
      expect(clock().value, paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(clock().isAnimating, isTrue);
      final previousClock = clock();
      await t.tap(find.text('정원').last);
      Future<void> finishPageScroll() async {
        await t.pump();
        final controller = t
            .widget<PageView>(find.byKey(const Key('main-pastel-pager')))
            .controller!;
        var frames = 0;
        while (controller.position.isScrollingNotifier.value) {
          expect(
            frames++,
            lessThan(120),
            reason: 'Page transition must complete',
          );
          await t.pump(const Duration(milliseconds: 16));
        }
        await t.pump();
      }

      await finishPageScroll();
      expect(previousClock.isAnimating, isFalse);
      final offstage = find.byType(CompanionPresence, skipOffstage: false);
      for (final element in offstage.evaluate()) {
        final descendants = find.descendant(
          of: find.byWidget(element.widget, skipOffstage: false),
          matching: find.byType(AnimatedBuilder, skipOffstage: false),
          skipOffstage: false,
        );
        if (descendants.evaluate().isNotEmpty) {
          expect(
            (t.widget<AnimatedBuilder>(descendants.first).animation
                    as AnimationController)
                .isAnimating,
            isFalse,
          );
        }
      }
      await t.tap(find.text('홈').last);
      await finishPageScroll();
      expect(cat(t).coat, CompanionCoat.tabby);
      expect(clock().isAnimating, isTrue);
      await t.pumpWidget(const SizedBox());
      care.dispose();
    },
  );

  testWidgets(
    'stored automatic-motion off remains off without changing the selected cat',
    (t) async {
      final care = await reopen();
      await care.selectCoat(CompanionCoat.black);
      await care.setAutomaticBehavior(false);
      final before = snapshot(await SharedPreferences.getInstance());
      await mount(t, care, GlobalKey(), []);
      final builder = t.widget<AnimatedBuilder>(
        find
            .descendant(
              of: find.byType(CompanionPresence).first,
              matching: find.byType(AnimatedBuilder),
            )
            .first,
      );
      expect((builder.animation as AnimationController).isAnimating, isFalse);
      await t.pump(const Duration(seconds: 10));
      expect(cat(t).coat, CompanionCoat.black);
      expect(cat(t).motion!.frame, 0);
      expect(snapshot(await SharedPreferences.getInstance()), before);
      await t.pumpWidget(const SizedBox());
      care.dispose();
      final restarted = await reopen();
      expect(restarted.journey.automaticBehavior, isFalse);
      expect(restarted.journey.coat, CompanionCoat.black);
      restarted.dispose();
    },
  );

  testWidgets(
    'home keeps blinking with garden effects off and obeys its own switch',
    (t) async {
      final care = await reopen();
      await care.selectCoat(CompanionCoat.black);
      await mount(t, care, GlobalKey(), [], motion: false);
      final stored = snapshot(await SharedPreferences.getInstance());
      final observed = <int>{cat(t).motion!.frame};
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 100));
        observed.add(cat(t).motion!.frame);
      }
      expect(observed, contains(2));
      expect(snapshot(await SharedPreferences.getInstance()), stored);
      await care.setAutomaticBehavior(false);
      await t.pump();
      expect(
        t
            .widget<CompanionPresence>(find.byType(CompanionPresence).first)
            .enabled,
        isFalse,
      );
      await t.tap(find.byKey(const Key('home-companion-touch')));
      await t.pump();
      expect(find.byKey(const Key('home-petting-heart')), findsNothing);
      expect(cat(t).coat, CompanionCoat.black);
      await t.pumpWidget(const SizedBox());
      care.dispose();
    },
  );

  testWidgets(
    'legacy missing choice uses the existing resolver without persisting a new choice',
    (t) async {
      final care = await reopen();
      final before = snapshot(await SharedPreferences.getInstance());
      await mount(t, care, GlobalKey(), [], motion: false);
      expect(care.journey.coat, isNull);
      expect(find.byType(CompanionCoatArt), findsOneWidget);
      expect(snapshot(await SharedPreferences.getInstance()), before);
      expect((await CompanionJourneyStore.load('local_user')).coat, isNull);
      await t.pumpWidget(const SizedBox());
      care.dispose();
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets(
      'large text and system insets keep the face and both real entry buttons usable $size',
      (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.view.resetPadding);
        final care = await reopen();
        await care.selectCoat(CompanionCoat.calico);
        await care.renameCompanion('나의 소중한 고양이');
        final actions = <PastelAction>[];
        await mount(t, care, GlobalKey(), actions, motion: false, scale: 2);
        final viewport = t.getRect(
          find.byKey(const PageStorageKey('pastel-page-0')),
        );
        final presence = t.getRect(find.byType(CompanionPresence).first);
        expect(presence.left, greaterThanOrEqualTo(viewport.left));
        expect(presence.right, lessThanOrEqualTo(viewport.right));
        // Existing sprite uses the top 87% of this box; ears and eyes fit in
        // the initial viewport even before scrolling the long-name content.
        expect(presence.top, greaterThanOrEqualTo(viewport.top));
        expect(
          presence.top + presence.height * .65,
          lessThanOrEqualTo(viewport.bottom),
        );
        expect(
          t.getRect(find.byKey(const Key('home-greeting'))).overlaps(presence),
          isFalse,
        );
        await revealHomeControl(t, find.byKey(const Key('home-record')));
        await t.tap(find.byKey(const Key('home-record')));
        expect(actions.last, PastelAction.write);
        await revealHomeControl(t, find.byKey(const Key('home-garden')));
        await t.tap(find.byKey(const Key('home-garden')));
        expect(actions.last, PastelAction.garden);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        care.dispose();
      },
    );
  }
  testWidgets(
    'actual HomeScreen wires saved name, choices and record/garden destinations',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final oldFlag = FeatureFlags.debugUnlockAllPremium;
      FeatureFlags.debugUnlockAllPremium = true;
      addTearDown(() => FeatureFlags.debugUnlockAllPremium = oldFlag);
      final care = await reopen(),
          app = AppStateProvider(),
          garden = _PendingGarden();
      await care.selectCoat(CompanionCoat.tuxedo);
      await StorageService.setCompanionName('앱에서 저장한 이름');
      care.companionName = await StorageService.getCompanionName();
      await t.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CatCareProvider>.value(value: care),
            ChangeNotifierProvider<AppStateProvider>.value(value: app),
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
          ],
          child: MaterialApp(
            theme: appTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const HomeScreen(),
          ),
        ),
      );
      await t.pump();
      expect(
        t
            .widget<PastelGardenShell>(find.byType(PastelGardenShell))
            .companionName,
        '앱에서 저장한 이름',
      );
      expect(cat(t).coat, CompanionCoat.tuxedo);
      await care.selectCoat(CompanionCoat.white);
      await t.pump();
      expect(cat(t).coat, CompanionCoat.white);
      await revealHomeControl(t, find.byKey(const Key('home-record')));
      await t.tap(find.byKey(const Key('home-record')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      expect(find.byType(CatFlowTabScreen), findsOneWidget);
      Navigator.of(t.element(find.byType(CatFlowTabScreen))).pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      await revealHomeControl(t, find.byKey(const Key('home-garden')));
      await t.tap(find.byKey(const Key('home-garden')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      final screen = t.widget<GardenWorldScreen>(
        find.byType(GardenWorldScreen).last,
      );
      expect(screen.cultivation, isTrue);
      Navigator.of(t.element(find.byType(GardenWorldScreen).last)).pop();
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      care.dispose();
      app.dispose();
      garden.dispose();
    },
  );
}
