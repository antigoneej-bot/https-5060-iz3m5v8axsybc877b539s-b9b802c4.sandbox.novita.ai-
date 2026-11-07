import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/widgets/companion_presence.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/widgets/companion_motion_art.dart';
import 'package:flutter_app/services/sound_service.dart';
import 'package:flutter_app/services/garden_personal_gallery_store.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/local_record_transaction.dart';
import 'package:flutter_app/screens/garden_gallery_screen.dart';
import 'package:flutter_app/services/garden_style_store.dart';
import 'package:flutter_app/widgets/sound_panel.dart';
import 'package:flutter_app/screens/my_garden_screen.dart';
import 'package:flutter_app/widgets/feature_scaffold.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/widgets/pastel_garden_shell.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';
import 'manual/visual_review_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/garden_layout_store.dart';
import 'package:flutter_app/mongi/integration/session_transaction.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_editor.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/garden_world_screen.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Garden extends GardenProvider {
  String? owner = 'alice';
  final requests = <Completer<List<ReceivedCheer>>>[];
  _Garden() {
    gardenMotionEnabled = false;
  }
  @override
  String? get publicGardenAccount => owner;
  @override
  Future<void> ensureInitialized() async {}
  @override
  Future<List<ReceivedCheer>> loadMyPublicCheers() {
    final response = Completer<List<ReceivedCheer>>();
    requests.add(response);
    return response.future;
  }
}

/// Review captures use the binding's supported shadow policy, so its painting
/// invariants still run. Changing a debug global in setUpAll leaks between tests.
class _ReviewGardenBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get disableShadows => false;
}

void main() {
  if (Platform.environment['DIRECT_GARDEN_REVIEW_DIR'] != null) {
    _ReviewGardenBinding();
  }
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
    for (final font in ['GowunDodum', 'GamjaFlower']) {
      final loader = FontLoader(font)
        ..addFont(rootBundle.load('assets/fonts/$font-Regular.ttf'));
      await loader.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    if (Platform.environment['DIRECT_GARDEN_REVIEW_DIR'] != null) {
      await loadReviewEmojiFont();
    }
  });
  late Directory directory;
  var fixtureClosed = false;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final rotations = <List<dynamic>>[];
  final screenshot = GlobalKey();
  const offlineMessage = '내 정원은 사용할 수 있어요. 새로 받은 마음은 연결 후 다시 확인해 주세요.';

  setUp(() async {
    fixtureClosed = false;
    rotations.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations')
            rotations.add(List<dynamic>.from(call.arguments as List));
          return null;
        });
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('ko');
    directory = await Directory.systemTemp.createTemp('garden-offline-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 23))
              : null,
        );
    await StorageService.setCurrentUser('local_user');
  });
  Future<void> chooseMind(WidgetTester t, {bool note = false}) async {
    expect(find.byKey(const Key('mind-continue')), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('mind-emotion-weary')));
    await t.tap(find.byKey(const Key('mind-emotion-weary')));
    await t.pump();
    await t.ensureVisible(find.byKey(const Key('mind-continue')));
    await t.tap(find.byKey(const Key('mind-continue')));
    await t.pumpAndSettle();
    if (note) {
      await t.ensureVisible(find.byKey(const Key('mind-note')));
      await t.enterText(
        find.byKey(const Key('mind-note')),
        '많이 지쳤지만, 오늘도 하루를 보냈다.',
      );
      t.testTextInput.hide();
      await t.pumpAndSettle();
    }
  }

  Future<void> closeFixture() async {
    await LocalRecordTransaction.run(() async {});
    // A route transition may have queued an optional gallery read in the
    // widget's zone. Await that store's own open/read before closing Hive;
    // a generic queue barrier alone did not release its Windows file handle.
    await GardenPersonalGalleryStore.read(CatCareService.localOwner);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await StorageService.clearCurrentUser();
    await Hive.close();
    // Finish directory enumeration before deleting files on Windows. Keep each
    // close/delete awaited, and let any locked file or unexpected entry fail
    // with its own path instead of recursively deleting an enumerated folder.
    final remaining = await directory.list(followLinks: false).toList();
    for (final entry in remaining) {
      expect(
        entry,
        isA<File>(),
        reason: 'Unexpected fixture entry: ${entry.path}',
      );
      await entry.delete();
    }
    await directory.delete();
    expect(await directory.exists(), isFalse);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    fixtureClosed = true;
  }

  tearDown(() async {
    if (!fixtureClosed) await closeFixture();
  });

  Future<void> openGarden(
    WidgetTester tester,
    _Garden garden, {
    AppStateProvider? app,
    bool cultivation = false,
    bool ownerRoute = false,
    bool fullscreen = false,
    bool resting = false,
    String? focusPlant,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    final cat = CatCareProvider();
    // This suite checks layout and storage. The companion has an independent
    // repeating animation setting; background-motion=false does not stop it.
    await tester.runAsync(() => cat.setAutomaticBehavior(false));
    addTearDown(garden.dispose);
    addTearDown(cat.dispose);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            if (app != null)
              ChangeNotifierProvider<AppStateProvider>.value(value: app),
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
            ChangeNotifierProvider<CatCareProvider>.value(value: cat),
          ],
          child: RepaintBoundary(
            key: screenshot,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: AppLanguage.instance.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              theme: appTheme,
              home: focusPlant != null
                  ? GardenWorldScreen.owned(initialFocusPlantId: focusPlant)
                  : fullscreen
                  ? GardenWorldScreen(
                      cultivation: true,
                      initialLandscape: true,
                      initialResting: resting,
                    )
                  : cultivation
                  ? PastelGardenShell(
                      actualGarden: const GardenWorldScreen.owned(
                        embedded: true,
                      ),
                      onAction: (_) {},
                      onCoat: (_) {},
                      coat: CompanionCoat.ginger,
                      gardenPreview: const SizedBox(),
                      motionEnabled: false,
                      companionAutomaticBehavior: false,
                    )
                  : ownerRoute
                  ? FeatureScaffold(
                      title: '나의 넓은 정원',
                      child: MyGardenScreen(onGoMeetCat: () {}),
                    )
                  : const GardenWorldScreen.tools(),
            ),
          ),
        ),
      );
      if (cultivation) {
        await tester.tap(find.byKey(const ValueKey('main-tab-1')));
        await tester.pump();
      }
      // The real encrypted local stores use filesystem I/O, so let them finish
      // outside the widget test's fake clock. The server promise stays pending.
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (garden.requests.isEmpty) {
        if (DateTime.now().isAfter(deadline)) {
          fail(
            'Garden did not finish its local load before starting the optional network request',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
      }
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
    await tester.pump();
  }

  Future<void> flushNetworkFuture(WidgetTester tester) async {
    // These promises were created alongside real local I/O in runAsync.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1)),
    );
    await tester.pump();
  }

  Future<void> openFullscreen(WidgetTester t, Finder trigger) async {
    // A new route opens the encrypted stores. Let real file I/O complete before
    // settling fake-clock animations; otherwise its loading spinner never ends.
    await t.runAsync(() async {
      await t.tap(trigger);
      await t.pump();
      final route = ModalRoute.of(
        t.element(find.byType(GardenWorldScreen, skipOffstage: false).last),
      )!;
      for (
        var frame = 0;
        frame < 120 && route.animation!.status != AnimationStatus.completed;
        frame++
      ) {
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(route.animation!.status, AnimationStatus.completed);
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
        if (DateTime.now().isAfter(deadline))
          fail('Fullscreen garden local load did not finish');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await t.pump();
      }
    });
    await t.pumpAndSettle();
  }

  Future<void> captureSpace(WidgetTester t, String name) async {
    final out = Platform.environment['DIRECT_GARDEN_REVIEW_DIR'];
    if (out == null) return;
    // Show the persistent selected-plant controls after dismissing the temporary
    // success message through the same swipe available to the user.
    if (name.contains('moved-plant') ||
        (name.startsWith('79-') && !name.contains('before-undo'))) {
      final message = find.byType(SnackBar).hitTestable();
      if (message.evaluate().isNotEmpty) {
        await t.drag(message, const Offset(0, 120));
        await t.pumpAndSettle();
      }
    }
    await t.runAsync(() async {
      for (final asset in [
        'assets/living_garden/cultivation_day.png',
        'assets/living_garden/cultivation_night.png',
        'assets/storybook_garden/panorama.png',
        'assets/storybook_garden/foreground.png',
        'assets/living_garden/plants.webp',
      ]) {
        await precacheImage(AssetImage(asset), screenshot.currentContext!);
      }
      // Decode the very providers used by mounted Image widgets. MemoryImage
      // cache keys include byte-list identity, so decoding another copy of the
      // same PNG does not prove that the album's image is ready to paint.
      for (final element in find.byType(Image).evaluate().toList()) {
        final image = element.widget as Image;
        await precacheImage(image.image, element);
      }
    });
    await t.pump();
    await t.runAsync(() async {
      final image =
          await (screenshot.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$out/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('English actual garden, seed picker and plants $size $scale', (
        t,
      ) async {
        await t.runAsync(() async {
          await AppLanguage.instance.select('en');
          await (await SharedPreferences.getInstance()).setString(
            MongiGardenStore.storageKey,
            jsonEncode(
              MongiGardenData(seedTokens: 3, seeds: {'pine': 7}).toJson(),
            ),
          );
        });
        final garden = _Garden();
        await openGarden(
          t,
          garden,
          cultivation: true,
          size: size,
          textScale: scale,
        );
        await t.pumpAndSettle();
        expect(find.text('Plant seeds'), findsWidgets);
        expect(find.text('마음 심기'), findsNothing);
        expect(find.text('My plants'), findsWidgets);
        await captureSpace(t, 'en-actual-${size.width.toInt()}-$scale');
        await t.tap(find.byKey(const ValueKey('cultivation-tool-2')));
        await t.pumpAndSettle();
        expect(find.text('Pine'), findsWidgets);
        expect(find.text('소나무'), findsNothing);
        await captureSpace(t, 'en-plants-${size.width.toInt()}-$scale');
        final memories = find.text('Memories');
        await t.ensureVisible(memories);
        await t.runAsync(() async {
          await t.tap(memories);
          final deadline = DateTime.now().add(const Duration(seconds: 30));
          while (find.text('Pine · Memories').evaluate().isEmpty) {
            if (DateTime.now().isAfter(deadline)) {
              fail('Encrypted plant memory did not finish loading');
            }
            await Future<void>.delayed(const Duration(milliseconds: 5));
            await t.pump();
          }
        });
        await t.pumpAndSettle();
        expect(find.text('Pine · Memories'), findsOneWidget);
        expect(find.text('나만의 이름'), findsNothing);
        expect(
          t
              .widgetList<Text>(find.byType(Text))
              .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
              .where((text) => RegExp(r'[가-힣]').hasMatch(text)),
          isEmpty,
          reason:
              'The empty English memory editor must not contain Korean UI copy',
        );
        await captureSpace(t, 'en-memory-${size.width.toInt()}-$scale');
        await t.tap(find.text('Cancel').last);
        await t.pumpAndSettle();
        await t.tap(find.byKey(const ValueKey('cultivation-tool-0')));
        await t.pumpAndSettle();
        await chooseMind(t);
        expect(find.text('Fully grown preview'), findsWidgets);
        await captureSpace(t, 'en-picker-${size.width.toInt()}-$scale');
        expect(MongiGardenStore.instance.value.seedTokens, 3);
        expect(MongiGardenStore.instance.value.seeds['pine'], 7);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        for (final request in garden.requests) {
          if (!request.isCompleted) request.complete(<ReceivedCheer>[]);
        }
        await flushNetworkFuture(t);
        await t.runAsync(closeFixture);
        await AppLanguage.instance.select('ko');
      });
    }
  }

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'direct garden tools and planting controls stay usable $size text $scale',
        (t) async {
          await t.runAsync(() async {
            await (await SharedPreferences.getInstance()).setString(
              MongiGardenStore.storageKey,
              jsonEncode(MongiGardenData(seedTokens: 2).toJson()),
            );
          });
          final garden = _Garden();
          await openGarden(
            t,
            garden,
            cultivation: true,
            size: size,
            textScale: scale,
          );
          await t.pumpAndSettle();
          for (var i = 0; i < 4; i++) {
            final rect = t.getRect(find.byKey(ValueKey('cultivation-tool-$i')));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(size.width));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.bottom, lessThanOrEqualTo(size.height));
          }
          expect(
            t.getSize(find.byKey(const ValueKey('cultivation-canvas'))).height,
            greaterThan(40),
          );
          await t.tap(find.byKey(const ValueKey('cultivation-tool-0')));
          await t.pumpAndSettle();
          await chooseMind(t);
          final choose = find.text('소나무 심을 자리 고르기');
          await t.ensureVisible(choose);
          await t.pumpAndSettle();
          await t.tap(choose);
          await t.pumpAndSettle();
          expect(
            t
                .widget<PopupMenuButton<String>>(
                  find.byKey(const Key('portrait-garden-menu')),
                )
                .enabled,
            isFalse,
          );
          expect(
            t.getSize(find.byKey(const ValueKey('cultivation-canvas'))).height,
            greaterThan(25),
          );
          final cancel = find.byKey(const Key('cancel-plant-location'));
          await t.ensureVisible(cancel);
          await t.tap(cancel);
          await t.pumpAndSettle();
          expect(MongiGardenStore.instance.value.seedTokens, 2);
          await t.runAsync(() async {
            await (await SharedPreferences.getInstance()).setString(
              MongiGardenStore.storageKey,
              jsonEncode(
                MongiGardenData(
                  seedTokens: 2,
                  seeds: {'pine': 1, 'maple': 2},
                  plantedOn: {'pine': '2026-11-01', 'maple': '2026-11-01'},
                ).toJson(),
              ),
            );
            await MongiGardenStore.instance.reload();
          });
          await t.pumpAndSettle();
          await t.ensureVisible(
            find.byKey(const Key('recent-planted-location')),
          );
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('recent-planted-location')));
          await t.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('recent-candidate-pine')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('recent-candidate-maple')),
            findsOneWidget,
          );
          await t.tap(find.byKey(const ValueKey('recent-candidate-maple')));
          await t.pumpAndSettle();
          expect(find.byKey(const Key('focused-plant-name')), findsOneWidget);
          expect(
            t.getSize(find.byKey(const ValueKey('cultivation-canvas'))).height,
            greaterThan(40),
          );
          for (var i = 0; i < 4; i++) {
            expect(
              t.getRect(find.byKey(ValueKey('cultivation-tool-$i'))).bottom,
              lessThanOrEqualTo(size.height),
            );
          }
          final waterControl = find.byKey(const Key('focused-plant-water'));
          if (waterControl.hitTestable().evaluate().isEmpty) {
            // Scroll only the detail card, not the surrounding horizontal PageView.
            final scroll = Scrollable.of(t.element(waterControl));
            await scroll.position.ensureVisible(t.renderObject(waterControl));
          }
          await t.pump();
          expect(
            find.byKey(const Key('focused-plant-water')).hitTestable(),
            findsOneWidget,
          );
          Future<void> switchSpace(bool rest) async {
            await t.tap(find.byTooltip('정원 보조 메뉴'));
            await t.pumpAndSettle();
            await t.tap(find.text(rest ? '쉬어가는 정원' : '가꾸는 정원').last);
            await t.pumpAndSettle();
          }

          await switchSpace(true);
          expect(find.byKey(const Key('resting-garden-space')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('cultivation-tool-0')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('rest-garden-overview')).hitTestable(),
            findsOneWidget,
          );
          await switchSpace(false);
          expect(find.byKey(const Key('focused-plant-name')), findsOneWidget);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          if (garden.requests.isNotEmpty)
            garden.requests.single.complete(<ReceivedCheer>[]);
          await flushNetworkFuture(t);
        },
      );
    }
  }

  testWidgets(
    'two garden spaces keep cultivation data and camera while rest has no editing',
    (t) async {
      final store = MongiGardenStore.instance;
      final layouts = GardenLayoutStore.instance;
      final initial = MongiGardenData(
        seedTokens: 3,
        seeds: const {'pine': 4},
        owned: const {'bench'},
        placed: const {'bench'},
      );
      await t.runAsync(() async {
        await (await SharedPreferences.getInstance()).setString(
          MongiGardenStore.storageKey,
          jsonEncode(initial.toJson()),
        );
        await layouts.update(
          (_) => GardenLayout(
            spaces: 3,
            positions: const {
              'seed:pine': Offset(.36, .55),
              'decor:bench': Offset(.51, .8),
            },
          ),
        );
      });
      await openGarden(t, _Garden(), cultivation: true);
      await t.pumpAndSettle();
      final beforeData = jsonEncode(store.value.toJson());
      final beforeLayout = jsonEncode(layouts.value.toJson());
      expect(find.byKey(const Key('original-garden-backdrop')), findsOneWidget);
      expect(find.byKey(const Key('storybook-backdrop')), findsNothing);
      await t.tap(find.byTooltip('정원 보조 메뉴'));
      await t.pumpAndSettle();
      await t.tap(find.text('햇살 정원 보기'));
      await t.pumpAndSettle();
      expect(
        t.widget<GardenWorldView>(find.byType(GardenWorldView)).nightOverride,
        false,
      );
      await captureSpace(t, '07-cultivation-day');
      await t.tap(find.byTooltip('정원 보조 메뉴'));
      await t.pumpAndSettle();
      await t.tap(find.text('반딧불이 정원 보기'));
      await t.pumpAndSettle();
      expect(
        t.widget<GardenWorldView>(find.byType(GardenWorldView)).nightOverride,
        true,
      );
      await captureSpace(t, '09-cultivation-night');
      final camera = t
          .widget<InteractiveViewer>(
            find.byKey(const Key('garden-world-camera')),
          )
          .transformationController!;
      final cameraBefore = camera.value.clone();
      final gardenState = t.state(find.byType(GardenWorldView));
      await t.tap(find.byTooltip('정원 보조 메뉴'));
      await t.pumpAndSettle();
      await t.tap(find.text('쉬어가는 정원').last);
      await t.pumpAndSettle();
      expect(find.byKey(const Key('storybook-backdrop')), findsOneWidget);
      expect(find.byKey(const Key('original-garden-backdrop')), findsNothing);
      expect(find.byKey(const ValueKey('cultivation-tool-0')), findsNothing);
      final resting = t.widget<GardenWorldView>(find.byType(GardenWorldView));
      expect(resting.readOnly, isTrue);
      expect(resting.originalScenery, isFalse);
      expect(resting.seeds, isEmpty);
      expect(resting.decorations, isEmpty);
      expect(resting.onWater, isNull);
      expect(resting.onInspectPlant, isNull);
      await captureSpace(t, '08-resting-garden');
      await t.tap(find.byTooltip('쉬어가는 정원 낮·밤'));
      await t.pumpAndSettle();
      await t.tap(find.text('햇살 풍경'));
      await t.pumpAndSettle();
      await captureSpace(t, '10-resting-day');
      await t.tap(find.byTooltip('쉬어가는 정원 낮·밤'));
      await t.pumpAndSettle();
      await t.tap(find.text('별빛 풍경'));
      await t.pumpAndSettle();
      await captureSpace(t, '11-resting-night');
      await openFullscreen(t, find.byKey(const Key('rest-garden-overview')));
      final fullscreen = t.widget<GardenWorldScreen>(
        find.byType(GardenWorldScreen).last,
      );
      expect(fullscreen.initialLandscape, isTrue);
      expect(fullscreen.initialResting, isTrue);
      expect(
        t.widget<GardenWorldView>(find.byType(GardenWorldView)).cameraGestures,
        isTrue,
      );
      expect(
        t.widget<GardenWorldView>(find.byType(GardenWorldView)).readOnly,
        isTrue,
      );
      expect(rotations.last, [
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
      expect(jsonEncode(store.value.toJson()), beforeData);
      expect(jsonEncode(layouts.value.toJson()), beforeLayout);
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(rotations.last, ['DeviceOrientation.portraitUp']);
      await t.tap(find.byTooltip('정원 보조 메뉴'));
      await t.pumpAndSettle();
      await t.tap(find.text('가꾸는 정원').last);
      await t.pumpAndSettle();
      expect(
        identical(t.state(find.byType(GardenWorldView)), gardenState),
        isTrue,
      );
      expect(camera.value, cameraBefore);
      expect(
        find.byKey(const ValueKey('world-item-seed:pine')),
        findsOneWidget,
      );
      expect(jsonEncode(store.value.toJson()), beforeData);
      expect(jsonEncode(layouts.value.toJson()), beforeLayout);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(640, 320),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final resting in [false, true]) {
        testWidgets(
          'full landscape fills viewport, map restores camera and tools never resize resting=$resting $size font=$scale',
          (t) async {
            await t.runAsync(() async {
              await (await SharedPreferences.getInstance()).setString(
                MongiGardenStore.storageKey,
                jsonEncode(
                  MongiGardenData(seeds: {'pine': 7}, seedTokens: 3).toJson(),
                ),
              );
              await MongiGardenStore.instance.reload();
              await GardenLayoutStore.instance.reload();
            });
            await openGarden(
              t,
              _Garden(),
              fullscreen: true,
              resting: resting,
              size: size,
              textScale: scale,
            );
            await t.pumpAndSettle();
            final camera = t.widget<InteractiveViewer>(
              find.byKey(const Key('garden-world-camera')),
            );
            expect(camera.panEnabled, isTrue);
            expect(camera.scaleEnabled, isTrue);
            expect(
              t.getSize(find.byKey(const Key('garden-world-camera'))).height,
              equals(size.height),
            );
            expect(
              t.getSize(find.byKey(const Key('fullscreen-garden-canvas'))),
              size,
            );
            final controller = camera.transformationController!;
            final cover = controller.value.getMaxScaleOnAxis();
            expect(cover * 2400, greaterThanOrEqualTo(size.width));
            expect(cover * 800, greaterThanOrEqualTo(size.height));
            final cameraBeforeFold = controller.value.clone();
            expect(rotations.last, [
              'DeviceOrientation.landscapeLeft',
              'DeviceOrientation.landscapeRight',
            ]);
            await captureSpace(
              t,
              '78-${resting ? 'resting' : 'cultivation'}-${size.width.toInt()}x${size.height.toInt()}-$scale-open',
            );
            await t.tap(find.text('도구 접기'));
            await t.pumpAndSettle();
            expect(find.text('도구 펼치기'), findsOneWidget);
            expect(
              t.getSize(find.byKey(const Key('fullscreen-garden-canvas'))),
              size,
            );
            expect(controller.value, cameraBeforeFold);
            await captureSpace(
              t,
              '78-${resting ? 'resting' : 'cultivation'}-${size.width.toInt()}x${size.height.toInt()}-$scale-folded',
            );
            await t.ensureVisible(
              find.byKey(const Key('fullscreen-map-toggle')),
            );
            await t.tap(find.byKey(const Key('fullscreen-map-toggle')));
            await t.pumpAndSettle();
            expect(
              controller.value.getMaxScaleOnAxis() * 2400,
              lessThanOrEqualTo(size.width + .001),
            );
            expect(
              controller.value.getMaxScaleOnAxis() * 800,
              lessThanOrEqualTo(size.height + .001),
            );
            await captureSpace(
              t,
              '78-${resting ? 'resting' : 'cultivation'}-${size.width.toInt()}x${size.height.toInt()}-$scale-map',
            );
            await t.tap(find.byKey(const Key('fullscreen-map-toggle')));
            await t.pumpAndSettle();
            expect(controller.value, cameraBeforeFold);
            await t.ensureVisible(
              find.byKey(const Key('fullscreen-tools-toggle')),
            );
            if (!resting)
              expect(
                find.byKey(const ValueKey('cultivation-tool-0')),
                findsNothing,
              );
            await t.tap(find.text('도구 펼치기'));
            await t.pumpAndSettle();
            if (resting) {
              expect(
                t
                    .widget<GardenWorldView>(find.byType(GardenWorldView))
                    .readOnly,
                isTrue,
              );
              expect(
                find.byKey(const ValueKey('cultivation-tool-0')),
                findsNothing,
              );
            } else {
              for (final id in [
                'fullscreen-plant',
                'fullscreen-water',
                'fullscreen-plants',
                'fullscreen-decorate',
              ]) {
                final button = find.byKey(ValueKey(id));
                await t.ensureVisible(button);
                await t.pumpAndSettle();
                expect(button.hitTestable(), findsOneWidget);
                expect(t.getSize(button).height, greaterThanOrEqualTo(48));
              }
            }
            expect(controller.value, cameraBeforeFold);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
            expect(rotations.last, ['DeviceOrientation.portraitUp']);
          },
        );
      }
    }
  }
  for (final id in ['pine', 'not-a-plant', 'cherry']) {
    testWidgets('home activity focuses only a saved plant: $id', (t) async {
      final store = MongiGardenStore.instance;
      final layouts = GardenLayoutStore.instance;
      await t.runAsync(() async {
        await (await SharedPreferences.getInstance()).setString(
          MongiGardenStore.storageKey,
          jsonEncode(
            MongiGardenData(
              seedTokens: 5,
              essence: 12,
              seeds: {'pine': 7},
              wateredOn: {'pine': MongiGardenData.dayKey(DateTime.now())},
            ).toJson(),
          ),
        );
        await store.reload();
        await layouts.update(
          (_) => GardenLayout(
            spaces: 3,
            positions: {'seed:pine': const Offset(.82, .76)},
          ),
        );
      });
      await openGarden(t, _Garden(), focusPlant: id);
      await t.pumpAndSettle();
      final view = t.widget<GardenWorldView>(find.byType(GardenWorldView));
      expect(view.focusPlantId, id == 'pine' ? 'pine' : null);
      if (id == 'pine') {
        expect(find.byKey(const Key('focused-plant-name')), findsOneWidget);
        final plantRect = t.getRect(
          find.byKey(const ValueKey('world-item-seed:pine')),
        );
        final canvasRect = t.getRect(find.byType(GardenWorldView));
        expect(canvasRect.overlaps(plantRect), isTrue);
      } else {
        expect(find.byKey(const Key('focused-plant-name')), findsNothing);
      }
      expect(store.value.seeds, {'pine': 7});
      expect(store.value.seedTokens, 5);
      expect(store.value.essence, 12);
      expect(layouts.value.positions['seed:pine'], const Offset(.82, .76));
      await t.runAsync(() async {
        await store.reload();
        await layouts.reload();
      });
      expect(store.value.seeds, {'pine': 7});
      expect(layouts.value.positions['seed:pine'], const Offset(.82, .76));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }

  for (final fullscreen in [false, true]) {
    testWidgets(
      'moving an existing plant cancels, rejects invalid land and survives reload without charging fullscreen=$fullscreen',
      (t) async {
        final store = MongiGardenStore.instance,
            layouts = GardenLayoutStore.instance;
        await t.runAsync(() async {
          await (await SharedPreferences.getInstance()).setString(
            MongiGardenStore.storageKey,
            jsonEncode(
              MongiGardenData(
                seedTokens: 5,
                seeds: {'pine': 7},
                wateredOn: {'pine': MongiGardenData.dayKey(DateTime.now())},
              ).toJson(),
            ),
          );
          await store.reload();
          await layouts.update(
            (_) => GardenLayout(
              spaces: 3,
              positions: {
                'seed:pine': const Offset(.44, .7),
                'decor:bench': const Offset(.51, .8),
              },
            ),
          );
        });
        await openGarden(
          t,
          _Garden(),
          cultivation: !fullscreen,
          fullscreen: fullscreen,
          size: fullscreen ? const Size(844, 390) : const Size(390, 844),
        );
        await t.pumpAndSettle();
        final before = jsonEncode(store.value.toJson()),
            initial = layouts.value.positions['seed:pine'];
        Future<void> startMove() async {
          final plantsButton = find.byKey(
            ValueKey(fullscreen ? 'fullscreen-plants' : 'cultivation-tool-2'),
          );
          // Only the fullscreen floating panel scrolls. ensureVisible on the
          // embedded page also scrolls its horizontal parent PageView away.
          if (fullscreen) await t.ensureVisible(plantsButton);
          expect(plantsButton.hitTestable(), findsOneWidget);
          await t.tap(plantsButton);
          await t.pumpAndSettle();
          final action = find.byKey(const ValueKey('move-button-pine'));
          await t.ensureVisible(action);
          await t.tap(action);
          await t.pumpAndSettle();
          expect(
            t
                .widget<GardenWorldView>(find.byType(GardenWorldView))
                .placementCount,
            7,
          );
        }

        await startMove();
        await t.tap(find.byKey(const Key('cancel-plant-location')));
        await t.pumpAndSettle();
        expect(layouts.value.positions['seed:pine'], initial);
        expect(jsonEncode(store.value.toJson()), before);
        await startMove();
        var world = t.widget<GardenWorldView>(find.byType(GardenWorldView));
        world.onPlacementPoint!(const Offset(.15, .4));
        await t.pumpAndSettle();
        expect(
          t
              .widget<FilledButton>(
                find.byKey(const Key('confirm-plant-location')),
              )
              .onPressed,
          isNull,
        );
        expect(layouts.value.positions['seed:pine'], initial);
        world = t.widget<GardenWorldView>(find.byType(GardenWorldView));
        world.onPlacementPoint!(const Offset(.62, .6));
        await t.pumpAndSettle();
        await captureSpace(
          t,
          fullscreen ? '78-fullscreen-moving-plant' : '24-moving-plant',
        );
        await t.runAsync(() async {
          await t.tap(find.byKey(const Key('confirm-plant-location')));
          await t.tap(find.byKey(const Key('confirm-plant-location')));
          final deadline = DateTime.now().add(const Duration(seconds: 30));
          while (layouts.value.positions['seed:pine'] !=
              const Offset(.62, .6)) {
            if (DateTime.now().isAfter(deadline))
              fail('Move did not commit its coordinate');
            await Future<void>.delayed(const Duration(milliseconds: 5));
            await t.pump();
          }
        });
        await t.pumpAndSettle();
        expect(jsonEncode(store.value.toJson()), before);
        expect(layouts.value.positions['decor:bench'], const Offset(.51, .8));
        expect(find.byKey(const Key('focused-plant-name')), findsOneWidget);
        await captureSpace(
          t,
          fullscreen ? '78-fullscreen-moved-plant' : '25-moved-plant',
        );
        await t.pumpWidget(const SizedBox());
        await t.runAsync(() async {
          // Reopen the cached user handles as a restarted process would; never
          // delete records or keep StorageService pointing at a closed Hive box.
          await StorageService.clearCurrentUser();
          await Hive.close();
          await StorageService.setCurrentUser('local_user');
          await layouts.reload();
          await store.reload();
        });
        expect(layouts.value.positions['seed:pine'], const Offset(.62, .6));
        expect(jsonEncode(store.value.toJson()), before);
        await openGarden(
          t,
          _Garden(),
          cultivation: !fullscreen,
          fullscreen: fullscreen,
          size: fullscreen ? const Size(844, 390) : const Size(390, 844),
        );
        await t.pumpAndSettle();
        expect(
          t
              .widget<GardenWorldView>(find.byType(GardenWorldView))
              .layout
              .position('seed:pine'),
          const Offset(.62, .6),
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'direct garden preserves old plants; placement cancels, retries and locates saved trees',
    (t) async {
      final store = MongiGardenStore.instance,
          layouts = GardenLayoutStore.instance;
      final initial = MongiGardenData(
        seedTokens: 2,
        seeds: const {'pine': 4, 'maple': 3},
        wateredOn: {'maple': MongiGardenData.dayKey(DateTime.now())},
        owned: const {'bench'},
        placed: const {'bench'},
      );
      await t.runAsync(() async {
        await (await SharedPreferences.getInstance()).setString(
          MongiGardenStore.storageKey,
          jsonEncode(initial.toJson()),
        );
        await layouts.update(
          (_) => GardenLayout(
            spaces: 3,
            positions: const {
              'seed:pine': Offset(.15, .72),
              'seed:maple': Offset(.85, .7),
              'decor:bench': Offset(.51, .8),
            },
          ),
        );
      });
      final garden = _Garden();
      await openGarden(t, garden, cultivation: true);
      await t.pumpAndSettle();
      expect(find.text('내 정원 들어가기'), findsNothing);
      for (var i = 0; i < 4; i++)
        expect(find.byKey(ValueKey('cultivation-tool-$i')), findsOneWidget);
      expect(store.value.seeds, initial.seeds);
      Future<void> capture(String name) async {
        await t.pumpAndSettle();
        final out = Platform.environment['DIRECT_GARDEN_REVIEW_DIR'];
        if (out == null) return;
        await t.runAsync(() async {
          for (final path in [
            'assets/living_garden/cultivation_day.png',
            'assets/living_garden/cultivation_night.png',
            'assets/storybook_garden/panorama.png',
            'assets/storybook_garden/foreground.png',
            'assets/living_garden/plants.webp',
          ]) {
            await precacheImage(AssetImage(path), screenshot.currentContext!);
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await t.pump();
        await t.runAsync(() async {
          final image =
              await (screenshot.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$out/$name.png').writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('01-actual-garden');
      Future<void> chooseCherry() async {
        await t.tap(find.byKey(const ValueKey('cultivation-tool-0')));
        await t.pumpAndSettle();
        await chooseMind(t, note: true);
        await t.ensureVisible(find.text('벚꽃나무 심을 자리 고르기'));
        await t.tap(find.text('벚꽃나무 심을 자리 고르기'));
        await t.pumpAndSettle();
      }

      Future<void> chooseGround() async {
        final camera = find.byKey(const Key('garden-world-camera'));
        final matrix = t
            .widget<InteractiveViewer>(camera)
            .transformationController!
            .value;
        final local = MatrixUtils.transformPoint(
          matrix,
          const Offset(.44 * 2400, .72 * 800),
        );
        await t.tapAt(t.getTopLeft(camera) + local);
        await t.pump();
      }

      await chooseCherry();
      expect(
        t
            .widget<PopupMenuButton<String>>(
              find.byKey(const Key('portrait-garden-menu')),
            )
            .enabled,
        isFalse,
      );
      await chooseGround();
      expect(find.byKey(const Key('plant-location-preview')), findsOneWidget);
      expect(store.value.seedTokens, 2);
      await capture('02-select-location');
      await t.tap(find.byKey(const Key('cancel-plant-location')));
      await t.pumpAndSettle();
      expect(store.value.seedTokens, 2);
      expect(layouts.value.positions.containsKey('seed:cherry'), isFalse);
      expect(PlantMemoryStore.instance.value.containsKey('cherry'), isFalse);
      await chooseCherry();
      await chooseGround();
      var injected = false;
      Completer<void>? saveGate;
      SessionTransaction.fault = (stage) async {
        if (stage == 'before_journal') {
          await saveGate?.future;
          if (!injected) {
            injected = true;
            throw StateError('injected failure');
          }
        }
      };
      Future<void> confirm() async {
        saveGate = Completer<void>();
        await t.runAsync(() async {
          await t.tap(find.byKey(const Key('confirm-plant-location')));
          final before = t
              .widget<GardenWorldView>(find.byType(GardenWorldView))
              .placementPoint;
          t
              .widget<GardenWorldView>(find.byType(GardenWorldView))
              .onPlacementPoint
              ?.call(const Offset(.6, .8));
          await t.pump();
          expect(
            t
                .widget<GardenWorldView>(find.byType(GardenWorldView))
                .placementPoint,
            before,
          );
          await t.tap(find.byKey(const Key('confirm-plant-location')));
          saveGate!.complete();
          // Capture readback competes with real encrypted-file I/O. Wait for
          // the UI's completed commit/error state, never a 500ms budget.
          final deadline = DateTime.now().add(const Duration(seconds: 30));
          while (true) {
            await t.pump();
            final button = find.byKey(const Key('confirm-plant-location'));
            if (button.evaluate().isEmpty ||
                t.widget<FilledButton>(button).onPressed != null) {
              break;
            }
            if (DateTime.now().isAfter(deadline)) {
              fail('Plant commit did not reach a verified success/error state');
            }
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
        });
        await t.pumpAndSettle();
      }

      await confirm();
      expect(store.value.seedTokens, 2);
      expect(find.textContaining('저장하지 못했어요'), findsOneWidget);
      expect(PlantMemoryStore.instance.value.containsKey('cherry'), isFalse);
      await confirm();
      SessionTransaction.fault = null;
      expect(store.value.seedTokens, 1);
      expect(store.value.seeds['cherry'], 1);
      expect(store.value.seeds['pine'], 4);
      expect(layouts.value.positions['seed:pine'], const Offset(.15, .72));
      expect(layouts.value.positions['decor:bench'], const Offset(.51, .8));
      expect(layouts.value.positions['seed:cherry']!.dx, closeTo(.44, .00001));
      expect(find.byKey(const Key('located-plant-highlight')), findsOneWidget);
      expect(find.byKey(const Key('focused-plant-name')), findsOneWidget);
      expect(find.text('첫 물 주기'), findsOneWidget);
      expect(find.byKey(const Key('plant-focus-backdrop')), findsOneWidget);
      final tokensAfterPlant = store.value.seedTokens;
      await t.pump(const Duration(seconds: 4));
      // The selected plant stays visible after the transient locate glow expires.
      expect(find.byKey(const Key('located-plant-highlight')), findsOneWidget);
      expect(store.value.seedTokens, tokensAfterPlant);
      final focusedCamera = t
          .widget<InteractiveViewer>(
            find.byKey(const Key('garden-world-camera')),
          )
          .transformationController!
          .value;
      final savedRoot = layouts.value.position('seed:cherry');
      final rootOnScreen =
          t.getTopLeft(find.byKey(const Key('garden-world-camera'))) +
          MatrixUtils.transformPoint(
            focusedCamera,
            Offset(savedRoot.dx * 2400, savedRoot.dy * 800),
          );
      expect(
        rootOnScreen.dy,
        lessThan(
          t.getTopLeft(find.byKey(const Key('focused-plant-name'))).dy - 20,
        ),
        reason: 'Saved root and new sprout must remain above the care card',
      );
      await capture('03-after-planting');
      expect(
        PlantMemoryStore.instance.value['cherry']!.timeline.single.emotionCatId,
        'weary',
      );
      expect(
        PlantMemoryStore.instance.value['cherry']!.timeline.single.note,
        '많이 지쳤지만, 오늘도 하루를 보냈다.',
      );
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('focused-plant-water')));
        await t.tap(find.byKey(const Key('focused-plant-water')));
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (store.value.wateredOn['cherry'] !=
            MongiGardenData.dayKey(DateTime.now())) {
          await t.pump();
          if (DateTime.now().isAfter(deadline))
            fail('First watering did not finish');
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await t.pumpAndSettle();
      expect(store.value.seeds['cherry'], 2);
      expect(store.value.seedTokens, tokensAfterPlant);
      expect(
        t
            .widget<FilledButton>(find.byKey(const Key('focused-plant-water')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const ValueKey('needs-water-cherry')), findsNothing);
      await capture('05-first-watered');
      final wateringNotice = find.byType(SnackBar);
      if (wateringNotice.evaluate().isNotEmpty) {
        await t.pump(t.widget<SnackBar>(wateringNotice).duration);
        await t.pumpAndSettle();
      }
      expect(wateringNotice, findsNothing);
      await t.ensureVisible(find.byKey(const Key('focused-plant-memory')));
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('focused-plant-memory')));
        await PlantMemoryStore.instance.reload();
        await t.pump();
      });
      await t.pumpAndSettle();
      expect(find.byType(PlantMemoryEditor), findsOneWidget);
      await t.ensureVisible(find.text('많이 지쳤지만, 오늘도 하루를 보냈다.').last);
      await t.pumpAndSettle();
      await capture('07-private-mind-readback');
      await t.runAsync(() async {
        Navigator.of(t.element(find.byType(PlantMemoryEditor))).pop();
        await LocalRecordTransaction.run(() async {});
        await t.pump();
      });
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('cultivation-tool-2')));
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('my-plants-list')),
          matching: find.text('소나무'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('my-plants-list')),
          matching: find.text('단풍나무'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('my-plants-list')),
          matching: find.textContaining('오늘 물주기 완료'),
        ),
        findsNWidgets(2),
      );
      await capture('04-my-plants');
      await t.runAsync(() async {
        await t.tap(find.byKey(const ValueKey('water-pine')));
        for (var i = 0; i < 100; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          await t.pump();
          if (store.value.wateredOn['pine'] ==
              MongiGardenData.dayKey(DateTime.now()))
            break;
        }
      });
      await t.pumpAndSettle();
      expect(store.value.seeds['pine'], 5);
      expect(
        t
            .widget<TextButton>(find.byKey(const ValueKey('water-pine')))
            .onPressed,
        isNull,
      );
      await t.tap(find.byKey(const ValueKey('water-pine')));
      await t.pump();
      expect(store.value.seeds['pine'], 5);
      await t.tap(find.byKey(const ValueKey('locate-maple')));
      await t.pumpAndSettle();
      final camera = find.byKey(const Key('garden-world-camera'));
      final matrix = t
          .widget<InteractiveViewer>(camera)
          .transformationController!
          .value;
      final point = MatrixUtils.transformPoint(
        matrix,
        const Offset(.85 * 2400, .7 * 800),
      );
      expect(point.dx, inInclusiveRange(0, t.getSize(camera).width));
      await capture('06-locate-saved-maple');
      await openFullscreen(t, find.byKey(const ValueKey('cultivation-tool-3')));
      expect(
        t
            .widget<GardenWorldScreen>(find.byType(GardenWorldScreen).last)
            .initialLandscape,
        isTrue,
      );
      expect(find.text('정원 전체 지도'), findsOneWidget);
      await t.tap(find.byKey(const Key('fullscreen-exit')));
      await t.pumpAndSettle();
      expect(find.text('전체보기'), findsOneWidget);
      expect(rotations.last, ['DeviceOrientation.portraitUp']);
      expect(find.byKey(const Key('focused-plant-name')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      for (final request in garden.requests) {
        if (!request.isCompleted) request.complete(<ReceivedCheer>[]);
      }
      await flushNetworkFuture(t);
    },
  );

  testWidgets(
    'local garden stays usable through slow requests, retries, account changes and exit',
    (tester) async {
      final garden = _Garden();
      await openGarden(tester, garden);
      expect(garden.requests, hasLength(1));
      expect(find.byType(GardenWorldView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester
            .widget<GardenWorldView>(find.byType(GardenWorldView))
            .fillViewport,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('garden-exit-fullscreen')));
      await tester.pump();
      expect(
        tester
            .widget<GardenWorldView>(find.byType(GardenWorldView))
            .fillViewport,
        isFalse,
      );
      expect(find.text('빛의 정수 0개'), findsOneWidget);
      await tester.runAsync(
        () => MongiGardenStore.instance.addOriginalEssence(120),
      );
      await tester.pump();
      expect(find.text('빛의 정수 120개'), findsOneWidget);
      await tester.runAsync(
        () => MongiGardenStore.instance.spendOriginalEssence(60),
      );
      await tester.pump();
      expect(find.text('빛의 정수 60개'), findsOneWidget);
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final balance = find.byKey(const ValueKey('garden-essence-balance'));
      expect(tester.getRect(balance).right, lessThanOrEqualTo(360));

      await tester.tap(find.byKey(const Key('garden-enter-fullscreen')));
      await tester.pump();
      expect(
        tester
            .widget<GardenWorldView>(find.byType(GardenWorldView))
            .fillViewport,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('garden-exit-fullscreen')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('garden-landscape')));
      await tester.pump();
      expect(rotations.last, [
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
      tester.view.physicalSize = const Size(844, 390);
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is AspectRatio && widget.aspectRatio == 3,
        ),
        findsNothing,
      );
      expect(
        tester.getRect(find.byKey(const Key('garden-canvas'))),
        const Rect.fromLTWH(0, 0, 844, 390),
      );
      expect(
        tester.widget<GardenWorldView>(find.byType(GardenWorldView)).immersive,
        isTrue,
      );
      expect(find.byKey(const Key('garden-portrait')), findsOneWidget);
      expect(find.byKey(const Key('garden-immersive-back')), findsOneWidget);
      const screenshotPath = String.fromEnvironment('GARDEN_SCREENSHOT_PATH');
      if (screenshotPath.isNotEmpty) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 250));
        });
        await tester.pump();
        await tester.runAsync(() async {
          final image =
              await (screenshot.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(screenshotPath).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      expect(MongiGardenStore.instance.value.essence, 60);
      await tester.pump(const Duration(seconds: 50));
      expect(find.byType(GardenWorldView), findsOneWidget);
      garden.requests.single.completeError(StateError('offline'));
      await flushNetworkFuture(tester);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(offlineMessage), findsOneWidget);
      expect(find.byType(GardenWorldView), findsOneWidget);
      await tester.tap(find.text('다시 확인'));
      await flushNetworkFuture(tester);
      expect(garden.requests, hasLength(2));
      garden.requests.last.complete([]);
      await flushNetworkFuture(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());

      expect(rotations.last, ['DeviceOrientation.portraitUp']);

      // All scenarios share one fake-clock zone, matching the app lifetime of
      // the serialized local stores instead of abandoning their future queues.
      final switchedGarden = _Garden();
      await openGarden(tester, switchedGarden);
      final oldResponse = switchedGarden.requests.single;
      switchedGarden.owner = 'bob';
      oldResponse.completeError(StateError('old account offline'));
      await flushNetworkFuture(tester);
      expect(find.text(offlineMessage), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await flushNetworkFuture(tester);
      expect(switchedGarden.requests, hasLength(2));
      switchedGarden.requests.last.complete([]);
      await flushNetworkFuture(tester);
      expect(find.byType(GardenWorldView), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());

      final exitedGarden = _Garden();
      await openGarden(tester, exitedGarden);
      final response = exitedGarden.requests.single;
      // Retained decoration/tools routes also use confirmed positioned planting.
      await tester.runAsync(() async {
        final store = MongiGardenStore.instance;
        await (await SharedPreferences.getInstance()).setString(
          MongiGardenStore.storageKey,
          jsonEncode(store.value.copy(seedTokens: 1).toJson()),
        );
        await store.reload();
      });
      await tester.pump();
      await tester.tap(find.byKey(const Key('open-plant-picker')));
      await tester.pumpAndSettle();
      await chooseMind(tester);
      await tester.ensureVisible(find.text('소나무 심을 자리 고르기'));
      await tester.tap(find.text('소나무 심을 자리 고르기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirm-plant-location')), findsOneWidget);
      expect(find.byKey(const ValueKey('cultivation-tool-2')), findsOneWidget);
      expect(MongiGardenStore.instance.value.seedTokens, 1);
      await tester.tap(find.byKey(const Key('cancel-plant-location')));
      await tester.pumpAndSettle();
      expect(MongiGardenStore.instance.value.seedTokens, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      response.completeError(StateError('offline after exit'));
      await flushNetworkFuture(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(offlineMessage), findsNothing);
    },
  );

  testWidgets(
    'all-features own garden wrapper opens cultivation without a scroll viewport',
    (tester) async {
      final garden = _Garden();
      await openGarden(tester, garden, ownerRoute: true);
      expect(tester.takeException(), isNull);
      for (final title in ['씨앗 심기', '물주기', '내 식물', '전체보기']) {
        expect(find.text(title), findsWidgets);
      }
      final screen = tester.widget<GardenWorldScreen>(
        find.byType(GardenWorldScreen),
      );
      expect(screen.cultivation, isTrue);
      await tester.tap(find.byTooltip('정원 보조 메뉴'));
      await tester.pumpAndSettle();
      expect(find.text('기록·활동 보기'), findsOneWidget);
      expect(find.text('정원 도구 · 장식 이동 · 확장'), findsOneWidget);
      await tester.tapAt(const Offset(8, 350));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'incoming movement undo restores only coordinates and can move again',
    (t) async {
      final store = MongiGardenStore.instance,
          layouts = GardenLayoutStore.instance;
      await t.runAsync(() async {
        await (await SharedPreferences.getInstance()).setString(
          MongiGardenStore.storageKey,
          jsonEncode(
            MongiGardenData(
              seedTokens: 5,
              seeds: {'pine': 7},
              wateredOn: {'pine': MongiGardenData.dayKey(DateTime.now())},
            ).toJson(),
          ),
        );
        await store.reload();
        await layouts.update(
          (_) => GardenLayout(
            spaces: 3,
            positions: {
              'seed:pine': const Offset(.44, .7),
              'decor:bench': const Offset(.51, .8),
            },
          ),
        );
      });
      await openGarden(t, _Garden(), cultivation: true);
      await t.pumpAndSettle();
      final before = jsonEncode(store.value.toJson()),
          initial = layouts.value.positions['seed:pine'];
      Future<void> startMove() async {
        await t.tap(find.byKey(const ValueKey('cultivation-tool-2')));
        await t.pumpAndSettle();
        final action = find.byKey(const ValueKey('move-button-pine'));
        await t.ensureVisible(action);
        await t.tap(action);
        await t.pumpAndSettle();
        expect(
          t
              .widget<GardenWorldView>(find.byType(GardenWorldView))
              .placementCount,
          7,
        );
      }

      await startMove();
      await t.tap(find.byKey(const Key('cancel-plant-location')));
      await t.pumpAndSettle();
      expect(layouts.value.positions['seed:pine'], initial);
      expect(jsonEncode(store.value.toJson()), before);
      await startMove();
      var world = t.widget<GardenWorldView>(find.byType(GardenWorldView));
      world.onPlacementPoint!(const Offset(.15, .4));
      await t.pumpAndSettle();
      expect(
        t
            .widget<FilledButton>(
              find.byKey(const Key('confirm-plant-location')),
            )
            .onPressed,
        isNull,
      );
      expect(layouts.value.positions['seed:pine'], initial);
      world = t.widget<GardenWorldView>(find.byType(GardenWorldView));
      world.onPlacementPoint!(const Offset(.62, .6));
      await t.pumpAndSettle();
      await captureSpace(t, '24-moving-plant');
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('confirm-plant-location')));
        await t.tap(find.byKey(const Key('confirm-plant-location')));
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (layouts.value.positions['seed:pine'] != const Offset(.62, .6)) {
          if (DateTime.now().isAfter(deadline))
            fail('Move did not commit its coordinate');
          await Future<void>.delayed(const Duration(milliseconds: 5));
          await t.pump();
        }
      });
      await t.pumpAndSettle();
      expect(jsonEncode(store.value.toJson()), before);
      expect(layouts.value.positions['decor:bench'], const Offset(.51, .8));
      expect(find.byKey(const Key('focused-plant-name')), findsOneWidget);
      await captureSpace(t, '79-moved-before-undo');
      // Revert via the actual user action, then redo before the existing restart check.
      final undo = find.widgetWithText(SnackBarAction, '되돌리기');
      expect(undo, findsOneWidget);
      await t.runAsync(() async {
        await t.tap(undo);
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (layouts.value.positions['seed:pine'] != initial) {
          if (DateTime.now().isAfter(deadline)) fail('Undo did not persist');
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await t.pumpAndSettle();
      expect(jsonEncode(store.value.toJson()), before);
      await startMove();
      t.widget<GardenWorldView>(find.byType(GardenWorldView)).onPlacementPoint!(
        const Offset(.62, .6),
      );
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('confirm-plant-location')));
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (layouts.value.positions['seed:pine'] != const Offset(.62, .6)) {
          if (DateTime.now().isAfter(deadline))
            fail('Move after undo did not persist');
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await t.pumpAndSettle();
      expect(jsonEncode(store.value.toJson()), before);
      await t.pumpWidget(const SizedBox());
      await t.runAsync(() async {
        // Reopen the cached user handles as a restarted process would; never
        // delete records or keep StorageService pointing at a closed Hive box.
        await StorageService.clearCurrentUser();
        await Hive.close();
        await StorageService.setCurrentUser('local_user');
        await layouts.reload();
        await store.reload();
      });
      expect(layouts.value.positions['seed:pine'], const Offset(.62, .6));
      expect(jsonEncode(store.value.toJson()), before);
      await openGarden(t, _Garden(), cultivation: true);
      await t.pumpAndSettle();
      expect(
        t
            .widget<GardenWorldView>(find.byType(GardenWorldView))
            .layout
            .position('seed:pine'),
        const Offset(.62, .6),
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'integrated shelter, seasonal layout and sound panels use actual garden routes',
    (t) async {
      await t.runAsync(() async {
        await (await SharedPreferences.getInstance()).setString(
          MongiGardenStore.storageKey,
          jsonEncode(
            MongiGardenData(
              seedTokens: 3,
              essence: 500,
              seeds: {'pine': 6},
              owned: {'cat_cushion', 'cat_basket'},
              placed: {'cat_cushion', 'cat_basket'},
            ).toJson(),
          ),
        );
        await MongiGardenStore.instance.reload();
        await GardenLayoutStore.instance.update((_) => GardenLayout(spaces: 3));
      });
      final garden = _Garden()
        ..equippedDecorationIds = ['cat_cushion', 'cat_basket'];
      await openGarden(t, garden, cultivation: true);
      await t.pumpAndSettle();
      expect(
        t.widget<GardenWorldView>(find.byType(GardenWorldView)).decorations,
        containsAll(['cat_cushion', 'cat_basket']),
      );
      Future<void> localReady({Type? destination}) async {
        await t.runAsync(() async {
          final deadline = DateTime.now().add(const Duration(seconds: 30));
          await t.pump();
          if (destination != null) {
            for (
              var frame = 0;
              frame < 120 && find.byType(destination).evaluate().isEmpty;
              frame++
            ) {
              await t.pump(const Duration(milliseconds: 16));
            }
            expect(find.byType(destination), findsOneWidget);
          }
          final route = ModalRoute.of(
            t.element(
              destination == null
                  ? find.byType(Scaffold).last
                  : find.byType(destination),
            ),
          );
          for (
            var frame = 0;
            frame < 120 &&
                route?.animation?.status != AnimationStatus.completed &&
                (destination != null ||
                    route?.animation?.status != AnimationStatus.dismissed);
            frame++
          ) {
            await t.pump(const Duration(milliseconds: 16));
          }
          if (route?.animation != null && destination != null)
            expect(route!.animation!.status, AnimationStatus.completed);
          while (find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
              find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
            if (DateTime.now().isAfter(deadline))
              fail('Local panel did not finish loading');
            await Future<void>.delayed(const Duration(milliseconds: 5));
            await t.pump(const Duration(milliseconds: 16));
          }
        });
        await t.pumpAndSettle();
      }

      await t.tap(find.byTooltip('정원 보조 메뉴'));
      await t.pumpAndSettle();
      await t.tap(find.text('고양이 쉼터'));
      await t.pumpAndSettle();
      expect(find.text('방석에서 쉬기'), findsOneWidget);
      expect(find.text('바구니에서 쉬기'), findsOneWidget);
      expect(find.text('소나무 그늘에서 쉬기'), findsOneWidget);
      await captureSpace(t, '79-shelter-options');
      await t.tap(find.text('바구니에서 쉬기'));
      await t.pumpAndSettle();
      expect(
        t
            .widget<GardenWorldView>(find.byType(GardenWorldView))
            .requestedRestItem,
        'decor:cat_basket',
      );
      expect(
        t
            .widget<Semantics>(find.byKey(const Key('garden-companion')))
            .properties
            .label,
        contains('바구니에서 일어나기'),
      );
      await captureSpace(t, '79-cat-basket');
      await t.tap(find.byTooltip('정원 보조 메뉴'));
      await t.pumpAndSettle();
      await t.tap(find.text('계절·배치 저장'));
      await localReady();
      await t.runAsync(() async {
        await t.tap(find.text('봄'));
        await t.pump();
      });
      await localReady();
      expect(GardenStyleStore.instance.season, 'spring');
      await captureSpace(t, '79-season-layout-panel');
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      await captureSpace(t, '79-spring-garden');
      final revision = GardenPersonalGalleryStore.changes.value;
      await t.runAsync(() async {
        await t.tap(find.byTooltip('정원 사진 찍기'));
        await t.pump();
        final deadline = DateTime.now().add(const Duration(seconds: 30));
        while (GardenPersonalGalleryStore.changes.value == revision) {
          if (DateTime.now().isAfter(deadline))
            fail('Garden photo did not save');
          await Future<void>.delayed(const Duration(milliseconds: 5));
          await t.pump(const Duration(milliseconds: 16));
        }
      });
      await localReady();
      final gallery = await t.runAsync(
        () => GardenPersonalGalleryStore.read(CatCareService.localOwner),
      );
      expect(gallery!['photos'], hasLength(1));
      await t.runAsync(() async {
        final png = base64Decode(
          (gallery['photos'] as List).single['png'] as String,
        );
        await precacheImage(MemoryImage(png), screenshot.currentContext!);
        final out = Platform.environment['DIRECT_GARDEN_REVIEW_DIR'];
        if (out != null)
          await File('$out/79-saved-garden-photo.png').writeAsBytes(png);
      });
      await t.tap(find.byTooltip('정원 사진첩·전시 관리'));
      await localReady(destination: GardenGalleryScreen);
      expect(find.textContaining('나만 보는 사진 1/8'), findsOneWidget);
      await captureSpace(t, '79-private-garden-album');
      await t.binding.handlePopRoute();
      await localReady();
      final c = t.element(find.byType(GardenWorldScreen));
      Navigator.of(c).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SoundSettingsControls(sound: SoundService()),
                ),
              ),
            ),
          ),
        ),
      );
      await localReady(destination: SoundSettingsControls);
      expect(find.text('정원 자연음'), findsOneWidget);
      await captureSpace(t, '79-sound-settings');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'actual five pages capture $size text $scale without changing garden',
        (t) async {
          debugPrint('five-pages: prepare stores');
          await t.runAsync(() async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              MongiGardenStore.storageKey,
              jsonEncode(
                MongiGardenData(seedTokens: 2, seeds: {'pine': 6}).toJson(),
              ),
            );
            await MongiGardenStore.instance.reload();
            debugPrint('five-pages: garden loaded');
            await GardenLayoutStore.instance.update(
              (_) => GardenLayout(
                spaces: 3,
                positions: const {'seed:pine': Offset(.36, .55)},
              ),
            );
            await CompanionSpriteAtlas.load(CompanionCoat.ginger);
            debugPrint('five-pages: atlas loaded');
          });
          await openGarden(
            t,
            _Garden(),
            cultivation: true,
            size: size,
            textScale: scale,
          );
          debugPrint('five-pages: route ready');
          for (var page = 0; page < 5; page++) {
            final tab = find.byKey(ValueKey('main-tab-$page'));
            // The new route starts encrypted filesystem reads. Create those
            // futures in the real-I/O zone, as openGarden does for first entry.
            await t.runAsync(() async {
              await t.ensureVisible(tab);
              await t.tap(tab, warnIfMissed: true);
              for (var frame = 0; frame < 35; frame++) {
                await t.pump(const Duration(milliseconds: 16));
              }
            });
            final pager = t.widget<PageView>(
              find.byKey(const Key('main-pastel-pager')),
            );
            expect(pager.controller!.page, closeTo(page.toDouble(), .001));
            if (page == 0) {
              final cat = t.getRect(
                find.byKey(const Key('home-companion-presence')),
              );
              final status = t.getRect(
                find.byKey(const Key('home-greeting-status')),
              );
              expect(status.top, greaterThanOrEqualTo(cat.bottom));
            }
            if (page == 1) {
              await t.runAsync(() async {
                final deadline = DateTime.now().add(
                  const Duration(seconds: 30),
                );
                bool ready() =>
                    find.byType(GardenWorldView).evaluate().isNotEmpty &&
                    t
                            .widget<TextButton>(
                              find.byKey(const ValueKey('cultivation-tool-0')),
                            )
                            .onPressed !=
                        null;
                while (!ready()) {
                  if (DateTime.now().isAfter(deadline)) {
                    fail('Actual saved garden did not finish loading');
                  }
                  await Future<void>.delayed(const Duration(milliseconds: 5));
                  await t.pump();
                }
              });
              expect(find.byType(GardenWorldView), findsOneWidget);
              expect(
                t
                    .widget<TextButton>(
                      find.byKey(const ValueKey('cultivation-tool-0')),
                    )
                    .onPressed,
                isNotNull,
              );
              expect(
                t
                    .widget<GardenWorldView>(find.byType(GardenWorldView))
                    .seeds['pine'],
                6,
              );
              // Finish Material's disabled-to-enabled color transition after
              // the actual I/O-ready condition; this is animation time only.
              await t.pump(const Duration(milliseconds: 300));
            }
            await captureSpace(
              t,
              '80-main-page-' +
                  (page + 1).toString() +
                  '-' +
                  size.width.toInt().toString() +
                  'x' +
                  size.height.toInt().toString() +
                  '-$scale',
            );
            expect(t.takeException(), isNull);
            debugPrint('five-pages: page $page done');
          }
          expect(MongiGardenStore.instance.value.seedTokens, 2);
          expect(MongiGardenStore.instance.value.seeds['pine'], 6);
          expect(
            GardenLayoutStore.instance.value.positions['seed:pine'],
            const Offset(.36, .55),
          );
          await t.pumpWidget(const SizedBox());
          debugPrint('five-pages: widgets disposed');
          // Visiting the record page queues private reads in this widget's
          // FakeAsync zone. Finish them here, while its microtasks can still
          // be pumped, rather than stranding fixture teardown outside the zone.
          await t.runAsync(() async {
            debugPrint('five-pages: drain start');
            var complete = false;
            Object? cleanupError;
            StackTrace? cleanupStack;
            closeFixture().then(
              (_) => complete = true,
              onError: (Object error, StackTrace stack) {
                cleanupError = error;
                cleanupStack = stack;
                complete = true;
              },
            );
            final deadline = DateTime.now().add(const Duration(seconds: 30));
            while (!complete) {
              if (DateTime.now().isAfter(deadline))
                fail('Private page reads did not finish');
              await Future<void>.delayed(const Duration(milliseconds: 5));
              await t.pump();
            }
            if (cleanupError != null)
              Error.throwWithStackTrace(cleanupError!, cleanupStack!);
            debugPrint('five-pages: stores closed and owned files removed');
          });
        },
      );
    }
  }
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'reference100 garden category and overlays $size font $scale',
        (tester) async {
          await tester.runAsync(() async {
            final data = MongiGardenData(
              seedTokens: 3,
              essence: 80,
              seeds: const {'pine': 12, 'cherry': 1},
              careDays: {MongiGardenData.dayKey(DateTime.now())},
            );
            await (await SharedPreferences.getInstance()).setString(
              MongiGardenStore.storageKey,
              jsonEncode(data.toJson()),
            );
            await MongiGardenStore.instance.reload();
            await CompanionSpriteAtlas.load(CompanionCoat.ginger);
            await GardenLayoutStore.instance.update(
              (_) => GardenLayout(
                spaces: 3,
                positions: const {
                  'seed:pine': Offset(.4, .58),
                  'seed:cherry': Offset(.62, .63),
                },
              ),
            );
          });
          final garden = _Garden()..lightEssence = 80;
          await openGarden(
            tester,
            garden,
            cultivation: true,
            size: size,
            textScale: scale,
          );
          await tester.pumpAndSettle();
          final before = jsonEncode(MongiGardenStore.instance.value.toJson());
          final layoutBefore = jsonEncode(
            GardenLayoutStore.instance.value.toJson(),
          );
          final canvas = tester.getRect(
            find.byKey(const Key('cultivation-canvas')),
          );
          expect(canvas.height, greaterThan(size.height * .7));
          final camera = tester
              .widget<InteractiveViewer>(
                find.byKey(const Key('garden-world-camera')),
              )
              .transformationController!;
          final matrix = camera.value.clone();
          await tester.ensureVisible(
            find.byKey(const Key('portrait-tools-toggle')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('portrait-tools-toggle')));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.byKey(const Key('cultivation-canvas'))),
            canvas,
          );
          expect(camera.value, matrix);
          await tester.tap(find.byKey(const Key('portrait-tools-toggle')));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('정원 보조 메뉴'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('햇살 정원 보기').last);
          await tester.pumpAndSettle();
          await tester.tap(find.text('햇살 정원 보기').last);
          await tester.pumpAndSettle();
          final suffix = size.width.toInt().toString() + '-' + scale.toString();
          await captureSpace(tester, '100-garden-' + suffix);
          final entry = find.byKey(const Key('garden-daily-care-entry'));
          await tester.ensureVisible(entry);
          await tester.pumpAndSettle();
          await tester.tap(entry);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('garden-care-companion-name')),
            findsOneWidget,
          );
          expect(
            tester.getSize(find.byType(CompanionPresence)).width,
            greaterThan(200),
          );
          await captureSpace(tester, '100-care-' + suffix);
          await tester.scrollUntilVisible(
            find.byKey(const Key('garden-care-receipt')),
            160,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('garden-care-receipt')));
          await tester.pumpAndSettle();
          expect(find.text('빛의 정수 +20'), findsOneWidget);
          await captureSpace(tester, '100-reward-' + suffix);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const Key('garden-items-button')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('garden-items-button')));
          await tester.pumpAndSettle();
          await captureSpace(tester, '100-decorate-' + suffix);
          expect(
            find.byKey(const Key('decoration-confirm')).hitTestable(),
            findsOneWidget,
          );
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          expect(jsonEncode(MongiGardenStore.instance.value.toJson()), before);
          expect(
            jsonEncode(GardenLayoutStore.instance.value.toJson()),
            layoutBefore,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          for (final request in garden.requests) {
            if (!request.isCompleted) request.complete([]);
          }
          await flushNetworkFuture(tester);
        },
      );
    }
  }
  testWidgets(
    'reference100 saved letter returns to Garden receipt without changing the home tab or granting twice',
    (tester) async {
      Future<void> routeReady() async {
        await tester.pump(const Duration(milliseconds: 16));
        final route = ModalRoute.of(tester.element(find.byType(Scaffold).last));
        for (
          var frame = 0;
          frame < 120 && route?.animation?.status == AnimationStatus.forward;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(route?.animation?.status, isNot(AnimationStatus.forward));
      }

      final app = AppStateProvider();
      addTearDown(app.dispose);
      app.selectedCat = shadowCats.first;
      app.flowStage = FlowStage.letter;
      final garden = _Garden();
      await openGarden(tester, garden, cultivation: true, app: app);
      await tester.tap(find.byKey(const Key('garden-daily-care-entry')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('garden-care-record')),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await routeReady();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('garden-care-record')));
        await tester.pump();
      });
      await routeReady();
      final field = find.byType(TextField).first;
      await tester.ensureVisible(field);
      await routeReady();
      await tester.enterText(field, '정원 안에서 남긴 별도 테스트 마음');
      tester.testTextInput.hide();
      final save = find.widgetWithText(ElevatedButton, '편지 남기기');
      await tester.ensureVisible(save);
      await routeReady();
      await tester.runAsync(() async {
        await tester.tap(save);
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (app.currentLetterId == null ||
            app.gardenRewardRetrying ||
            MongiGardenStore.instance.value.essence < 20) {
          if (DateTime.now().isAfter(deadline))
            fail('Letter and daily receipt did not finish saving');
          await Future<void>.delayed(const Duration(milliseconds: 5));
          await tester.pump();
        }
      });
      await routeReady();
      expect(
        StorageService.getAllLetters().single.letterText,
        '정원 안에서 남긴 별도 테스트 마음',
      );
      final done = find.widgetWithText(FilledButton, '오늘은 여기까지').first;
      await tester.ensureVisible(done);
      await routeReady();
      await tester.runAsync(() async {
        await tester.tap(done);
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (find.byKey(const Key('garden-care-plant')).evaluate().isEmpty) {
          if (DateTime.now().isAfter(deadline))
            fail('Garden receipt did not open after confirmed save');
          await Future<void>.delayed(const Duration(milliseconds: 5));
          await tester.pump();
        }
      });
      await routeReady();
      expect(find.text('빛의 정수 +20'), findsOneWidget);
      expect(app.requestedTabIndex, isNull);
      final before = MongiGardenStore.instance.value.toJson();
      await tester.runAsync(() => app.retryGardenRewards());
      expect(MongiGardenStore.instance.value.toJson(), before);
      expect(MongiGardenStore.instance.value.seedTokens, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      for (final request in garden.requests) {
        if (!request.isCompleted) request.complete([]);
      }
      await flushNetworkFuture(tester);
    },
  );
}
