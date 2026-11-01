import 'package:flutter_app/screens/my_garden_screen.dart';
import 'package:flutter_app/widgets/feature_scaffold.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/widgets/pastel_garden_shell.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';
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

void main() {
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
  });
  late Directory directory;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final rotations = <List<dynamic>>[];
  final screenshot = GlobalKey();
  const offlineMessage = '내 정원은 사용할 수 있어요. 새로 받은 마음은 연결 후 다시 확인해 주세요.';

  setUp(() async {
    rotations.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations')
            rotations.add(List<dynamic>.from(call.arguments as List));
          return null;
        });
    SharedPreferences.setMockInitialValues({});
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
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    await StorageService.clearCurrentUser();
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> openGarden(
    WidgetTester tester,
    _Garden garden, {
    bool cultivation = false,
    bool ownerRoute = false,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    final cat = CatCareProvider();
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
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
            ChangeNotifierProvider<CatCareProvider>.value(value: cat),
          ],
          child: RepaintBoundary(
            key: screenshot,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              theme: appTheme,
              home: cultivation
                  ? PastelGardenShell(
                      actualGarden: const GardenWorldScreen.owned(
                        embedded: true,
                      ),
                      onAction: (_) {},
                      onCoat: (_) {},
                      coat: CompanionCoat.ginger,
                      gardenPreview: const SizedBox(),
                      motionEnabled: false,
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
        await tester.tap(find.text('정원'));
        await tester.pump();
      }
      // The real encrypted local stores use filesystem I/O, so let them finish
      // outside the widget test's fake clock. The server promise stays pending.
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tester.pump();
        if (garden.requests.isNotEmpty) break;
      }
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

  Future<void> captureSpace(WidgetTester t, String name) async {
    final out = Platform.environment['DIRECT_GARDEN_REVIEW_DIR'];
    if (out == null) return;
    await t.runAsync(() async {
      for (final asset in [
        'assets/living_garden/world_day.webp',
        'assets/living_garden/world_night.webp',
        'assets/storybook_garden/panorama.png',
        'assets/storybook_garden/foreground.png',
        'assets/living_garden/plants.webp',
      ]) {
        await precacheImage(AssetImage(asset), screenshot.currentContext!);
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
          final choose = find.text('소나무 심을 자리 고르기');
          await t.ensureVisible(choose);
          await t.pumpAndSettle();
          await t.tap(choose);
          await t.pumpAndSettle();
          if (size.height < 500) {
            expect(
              t
                  .widget<PopupMenuButton<bool>>(
                    find.byKey(const Key('compact-garden-switch')),
                  )
                  .enabled,
              false,
            );
          } else {
            expect(
              t
                  .widget<ChoiceChip>(
                    find.byKey(const ValueKey('rest-garden-tab')),
                  )
                  .onSelected,
              isNull,
            );
          }
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
            if (size.height < 500) {
              await t.tap(find.byKey(const Key('compact-garden-switch')));
              await t.pumpAndSettle();
              await t.tap(find.text(rest ? '쉬어가는 정원' : '내가 가꾸는 정원').last);
            } else {
              final tab = find.byKey(
                ValueKey(rest ? 'rest-garden-tab' : 'cultivate-garden-tab'),
              );
              await Scrollable.of(
                t.element(tab),
              ).position.ensureVisible(t.renderObject(tab));
              await t.pump();
              await t.tap(tab);
            }
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
      await t.ensureVisible(find.byKey(const ValueKey('rest-garden-tab')));
      await t.tap(find.byKey(const ValueKey('rest-garden-tab')));
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
      await t.tap(find.byKey(const Key('rest-garden-overview')));
      await t.pumpAndSettle();
      expect(jsonEncode(store.value.toJson()), beforeData);
      expect(jsonEncode(layouts.value.toJson()), beforeLayout);
      await t.ensureVisible(find.byKey(const ValueKey('cultivate-garden-tab')));
      await t.tap(find.byKey(const ValueKey('cultivate-garden-tab')));
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
        final out = Platform.environment['DIRECT_GARDEN_REVIEW_DIR'];
        if (out == null) return;
        await t.runAsync(() async {
          for (final path in [
            'assets/living_garden/world_day.webp',
            'assets/living_garden/world_night.webp',
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
            .widget<ChoiceChip>(find.byKey(const ValueKey('rest-garden-tab')))
            .onSelected,
        isNull,
      );
      await chooseGround();
      expect(find.byKey(const Key('plant-location-preview')), findsOneWidget);
      expect(store.value.seedTokens, 2);
      await capture('02-select-location');
      await t.tap(find.byKey(const Key('cancel-plant-location')));
      await t.pumpAndSettle();
      expect(store.value.seedTokens, 2);
      expect(layouts.value.positions.containsKey('seed:cherry'), isFalse);
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
      await capture('03-after-planting');
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
      await t.tap(find.byKey(const ValueKey('cultivation-tool-3')));
      await t.pumpAndSettle();
      expect(find.text('원래 보기'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('cultivation-tool-3')));
      await t.pumpAndSettle();
      expect(find.text('전체보기'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      if (garden.requests.isNotEmpty)
        garden.requests.single.complete(<ReceivedCheer>[]);
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

      expect(rotations.last, isEmpty);

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
}
