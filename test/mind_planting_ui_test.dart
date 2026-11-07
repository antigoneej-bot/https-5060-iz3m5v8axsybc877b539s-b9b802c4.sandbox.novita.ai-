import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/models/companion_journey.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
import 'package:flutter_app/mongi/integration/plant_memory_store.dart';
import 'package:flutter_app/mongi/screens/mind_planting_screen.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/widgets/companion_motion_art.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/cat_flow_tab_screen.dart';
import 'package:flutter_app/screens/mind_care_hub.dart';
import 'package:flutter_app/widgets/feature_scaffold.dart';
import 'package:flutter_app/services/meditation_completion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late CatCareProvider cat;
  late AppStateProvider app;
  MindPlantingChoice? result;
  final shot = GlobalKey();
  setUpAll(() async {
    for (final font in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mind-ui-97-');
    Hive.init(directory.path);
    CatCareService.setCurrentUser('local_user');
    PlantMemoryStore.mindSaveFault = null;
    SharedPreferences.setMockInitialValues({
      MongiGardenStore.storageKey: jsonEncode(
        MongiGardenData(seedTokens: 2, seeds: {'maple': 5}).toJson(),
      ),
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async =>
              call.method == 'read' ? base64Encode(List.filled(32, 37)) : null,
        );
    await AppLanguage.instance.select('ko');
    await MongiGardenStore.instance.reload();
    await PlantMemoryStore.instance.reload();
    cat = CatCareProvider()
      ..journey = const CompanionJourney(
        coat: CompanionCoat.calico,
        automaticBehavior: false,
      )
      ..companionName = '우리 이름';
    result = null;
    app = AppStateProvider();
  });
  tearDown(() async {
    PlantMemoryStore.mindSaveFault = null;
    cat.dispose();
    app.dispose();
    await Hive.close();
    final files = await directory.list(followLinks: false).toList();
    for (final file in files) {
      expect(file, isA<File>());
      await file.delete();
    }
    await directory.delete();
  });
  Future<void> open(
    WidgetTester t, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CatCareProvider>.value(value: cat),
          ChangeNotifierProvider<AppStateProvider>.value(value: app),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          builder: (context, child) => RepaintBoundary(
            key: shot,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<MindPlantingChoice>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MindPlantingScreen(),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.runAsync(() => CompanionSpriteAtlas.load(cat.journey.coat!));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  Future<void> capture(WidgetTester t, String name) async {
    final path = Platform.environment['MIND98_SHOTS'];
    if (path == null) return;
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final image =
          await (shot.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(path).create(recursive: true);
      await File('$path/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Future<void> choose(WidgetTester t) async {
    await t.ensureVisible(find.byKey(const Key('mind-emotion-weary')));
    await t.tap(find.byKey(const Key('mind-emotion-weary')));
    await t.pump();
    await t.ensureVisible(find.byKey(const Key('mind-continue')));
    await t.tap(find.byKey(const Key('mind-continue')));
    await t.pumpAndSettle();
  }

  testWidgets(
    'all 37 real emotions remain accessible and do not change companion',
    (t) async {
      await open(t);
      expect(find.text('우리 이름'), findsOneWidget);
      final catPaint = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is CompanionMotionPainter,
      );
      expect(catPaint, findsOneWidget);
      expect(t.getSize(catPaint).width, greaterThan(150));
      expect(t.getSize(catPaint).height, greaterThan(100));
      await t.ensureVisible(find.byKey(const Key('mind-all-emotions')));
      await t.tap(find.byKey(const Key('mind-all-emotions')));
      await t.pumpAndSettle();
      for (final emotion in shadowCats.where((c) => c.selectable)) {
        await t.enterText(
          find.byKey(const Key('mind-emotion-search')),
          emotion.keyword,
        );
        await t.pump();
        expect(find.byKey(ValueKey('mind-all-${emotion.id}')), findsOneWidget);
      }
      await t.tap(find.byKey(const Key('mind-all-guilty')));
      await t.pumpAndSettle();
      expect(cat.journey.coat, CompanionCoat.calico);
      expect(cat.companionName, '우리 이름');
      expect(MongiGardenStore.instance.value.seedTokens, 2);
      expect(PlantMemoryStore.instance.value, isEmpty);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
  for (final lang in ['ko', 'en']) {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(844, 390),
    ]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          '$lang ${size.width}x${size.height} text $scale: mind, optional note, cancellation and draft only',
          (t) async {
            await AppLanguage.instance.select(lang);
            await open(t, size: size, scale: scale);
            expect(t.takeException(), isNull);
            await capture(t, 'mind-$lang-${size.width.toInt()}-$scale');
            await choose(t);
            await t.ensureVisible(find.byKey(const Key('mind-note')));
            await t.enterText(find.byKey(const Key('mind-note')), '나만 보는 한마디');
            await t.testTextInput.receiveAction(TextInputAction.done);
            await t.pumpAndSettle();
            await capture(t, 'plant-$lang-${size.width.toInt()}-$scale');
            expect(t.takeException(), isNull);
            await t.ensureVisible(find.byKey(const Key('plant-selected')));
            await t.tap(find.byKey(const Key('plant-selected')));
            await t.pumpAndSettle();
            expect(result?.seed.id, 'pine');
            expect(result?.mind?.note, '나만 보는 한마디');
            expect(result?.mind?.emotionCatId, 'weary');
            expect(MongiGardenStore.instance.value.seedTokens, 2);
            expect(MongiGardenStore.instance.value.seeds, {'maple': 5});
            expect(PlantMemoryStore.instance.value, isEmpty);
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
            await t.pumpAndSettle();
          },
        );
      }
    }
  }
  testWidgets('keyboard inset and cancelling discard only the unsaved draft', (
    t,
  ) async {
    await open(t, size: const Size(320, 640), scale: 2);
    await choose(t);
    t.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(t.view.resetViewInsets);
    await t.pump();
    await t.ensureVisible(find.byKey(const Key('mind-note')));
    await t.enterText(find.byKey(const Key('mind-note')), '저장하지 않을 마음');
    await t.ensureVisible(find.byKey(const Key('plant-selected')));
    expect(
      find.byKey(const Key('plant-selected')).hitTestable(),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    t.view.resetViewInsets();
    await t.pageBack();
    await t.pumpAndSettle();
    await t.pageBack();
    await t.pumpAndSettle();
    expect(result, isNull);
    expect(MongiGardenStore.instance.value.seedTokens, 2);
    expect(PlantMemoryStore.instance.value, isEmpty);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets(
    'back preserves draft until cancel; optional writing can stay empty; planted species is never replanted',
    (t) async {
      await open(t);
      await choose(t);
      await t.ensureVisible(find.byKey(const Key('mind-note')));
      await t.enterText(find.byKey(const Key('mind-note')), '잠시 간직할 말');
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('mind-continue')), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('mind-continue')));
      await t.tap(find.byKey(const Key('mind-continue')));
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextField>(find.byKey(const Key('mind-note')))
            .controller!
            .text,
        '잠시 간직할 말',
      );
      await t.ensureVisible(find.byKey(const Key('mind-note')));
      await t.enterText(find.byKey(const Key('mind-note')), '');
      await t.ensureVisible(find.byKey(const Key('plant-selected')));
      await t.tap(find.byKey(const Key('plant-selected')));
      await t.pumpAndSettle();
      expect(result!.mind!.note, isEmpty);
      expect(PlantMemoryStore.instance.value, isEmpty);
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await choose(t);
      await t.ensureVisible(find.text('이미 심은 식물'));
      await t.tap(find.text('이미 심은 식물'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('plant-selected')), findsNothing);
      await t.ensureVisible(find.byKey(const Key('locate-plant')));
      await t.tap(find.byKey(const Key('locate-plant')));
      await t.pumpAndSettle();
      expect(result!.seed.id, 'maple');
      expect(result!.mind, isNull);
      expect(MongiGardenStore.instance.value.seeds['maple'], 5);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );

  testWidgets(
    'accessible emotion activation selects a feeling and enables continue',
    (t) async {
      final semantics = t.ensureSemantics();
      await open(t);
      final node = t.getSemantics(find.bySemanticsLabel('무기력'));
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, ui.SemanticsAction.tap);
      await t.pump();
      expect(
        t
            .getSemantics(find.bySemanticsLabel('무기력'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        isTrue,
      );
      expect(
        t
            .widget<FilledButton>(find.byKey(const Key('mind-continue')))
            .onPressed,
        isNotNull,
      );
      semantics.dispose();
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
  Future<void> existing(WidgetTester t) async {
    await choose(t);
    await t.ensureVisible(find.text('이미 심은 식물'));
    await t.tap(find.text('이미 심은 식물'));
    await t.pumpAndSettle();
  }

  Future<void> waitForUi(WidgetTester t, bool Function() complete) async {
    final deadline = Stopwatch()..start();
    while (!complete() && deadline.elapsed < const Duration(seconds: 10)) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(complete(), isTrue, reason: 'The requested operation must complete');
    await t.pump();
  }

  testWidgets('viewing existing memories keeps the feeling and unsaved note', (
    t,
  ) async {
    await open(t);
    await existing(t);
    await t.ensureVisible(find.byKey(const Key('mind-note')));
    await t.enterText(find.byKey(const Key('mind-note')), '그대로 간직할 말');
    await t.ensureVisible(find.text('추억 보기'));
    await t.tap(find.text('추억 보기'));
    await t.pump();
    await waitForUi(t, () => find.byType(AlertDialog).evaluate().isNotEmpty);
    expect(find.byType(AlertDialog), findsOneWidget);
    await t.tap(find.text('취소').last);
    await t.pumpAndSettle();
    expect(
      t.widget<TextField>(find.byKey(const Key('mind-note'))).controller!.text,
      '그대로 간직할 말',
    );
    expect(find.text('담아둘 마음 · 무기력'), findsOneWidget);
    expect(PlantMemoryStore.instance.value, isEmpty);
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  testWidgets(
    'all six plants with zero seeds accept one feeling after double tap',
    (t) async {
      await t.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          MongiGardenStore.storageKey,
          jsonEncode(
            MongiGardenData(
              seedTokens: 0,
              essence: 80,
              seeds: {for (final seed in SeedType.all) seed.id: 4},
            ).toJson(),
          ),
        );
        await MongiGardenStore.instance.reload();
      });
      final before = MongiGardenStore.instance.value.toJson();
      await open(t);
      await choose(t);
      expect(find.byKey(const Key('save-plant-mind')), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('mind-note')));
      await t.enterText(find.byKey(const Key('mind-note')), '오늘은 조금 쉬어도 괜찮아');
      await t.ensureVisible(find.byKey(const Key('save-plant-mind')));
      await capture(t, 'existing-six-plants-zero-seeds');
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('save-plant-mind')));
        await t.tap(find.byKey(const Key('save-plant-mind')));
        await PlantMemoryStore.instance.reload();
      });
      await t.pumpAndSettle();
      expect(result!.savedMind, isTrue);
      expect(result!.seed.id, 'pine');
      expect(
        PlantMemoryStore.instance.value['pine']!.timeline.single.note,
        '오늘은 조금 쉬어도 괜찮아',
      );
      expect(
        PlantMemoryStore.instance.value['pine']!.timeline.single.emotionCatId,
        'weary',
      );
      expect(MongiGardenStore.instance.value.toJson(), before);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'failed existing-plant save preserves draft and retries exactly once',
    (t) async {
      await open(t);
      await existing(t);
      await t.ensureVisible(find.byKey(const Key('mind-note')));
      await t.enterText(find.byKey(const Key('mind-note')), '실패해도 남아 있는 말');
      PlantMemoryStore.mindSaveFault = (at) {
        if (at == 'after_write') throw StateError('test failure');
      };
      await t.ensureVisible(find.byKey(const Key('save-plant-mind')));
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('save-plant-mind')));
        await PlantMemoryStore.instance.reload();
      });
      await t.pumpAndSettle();
      expect(find.byKey(const Key('mind-save-error')), findsOneWidget);
      expect(
        t
            .widget<TextField>(find.byKey(const Key('mind-note')))
            .controller!
            .text,
        '실패해도 남아 있는 말',
      );
      expect(PlantMemoryStore.instance.value, isEmpty);
      PlantMemoryStore.mindSaveFault = null;
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('save-plant-mind')));
        await PlantMemoryStore.instance.reload();
      });
      await t.pumpAndSettle();
      expect(PlantMemoryStore.instance.value['maple']!.timeline.length, 1);
      expect(MongiGardenStore.instance.value.seeds['maple'], 5);
      expect(MongiGardenStore.instance.value.seedTokens, 2);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
    },
  );

  for (final record in [true, false]) {
    testWidgets(
      'zero seeds opens the existing activity and returns to the same draft record=$record',
      (t) async {
        await t.runAsync(() async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            MongiGardenStore.storageKey,
            jsonEncode(
              MongiGardenData(
                seedTokens: 0,
                seeds: const {'maple': 5},
              ).toJson(),
            ),
          );
          await MongiGardenStore.instance.reload();
        });
        await open(t);
        await choose(t);
        await t.ensureVisible(find.byKey(const Key('mind-note')));
        await t.enterText(find.byKey(const Key('mind-note')), '돌아와서 남길 한마디');
        await t.testTextInput.receiveAction(TextInputAction.done);
        await t.pump();
        final target = find.byKey(
          Key(record ? 'mind-get-seed-record' : 'mind-get-seed-meditate'),
        );
        await t.ensureVisible(target);
        await t.tap(target);
        await t.pump();
        // These real destinations contain continuous decorative animations.
        // Wait for the route transition, not for every animation to stop.
        await waitForUi(t, () {
          final feature = find.byType(FeatureScaffold);
          if (feature.evaluate().isEmpty) return false;
          return ModalRoute.of(t.element(feature))!.animation!.isCompleted;
        });
        expect(find.byType(FeatureScaffold), findsOneWidget);
        expect(
          record ? find.byType(CatFlowTabScreen) : find.byType(MindCareHub),
          findsOneWidget,
        );
        expect(t.takeException(), isNull);
        Navigator.of(t.element(find.byType(FeatureScaffold))).pop();
        await t.pump();
        await waitForUi(
          t,
          () => !t
              .widget<AbsorbPointer>(find.byKey(const Key('mind-form-body')))
              .absorbing,
        );
        expect(
          t
              .widget<TextField>(find.byKey(const Key('mind-note')))
              .controller!
              .text,
          '돌아와서 남길 한마디',
        );
        expect(MongiGardenStore.instance.value.seedTokens, 0);
        expect(PlantMemoryStore.instance.value, isEmpty);
        if (!record) {
          var drained = false;
          final pending = MeditationCompletionService.instance.retry().then(
            (_) => drained = true,
          );
          await waitForUi(t, () => drained);
          await pending;
          expect(
            MeditationCompletionService.instance.saveProblem.value,
            isNull,
          );
        }
        await t.pumpWidget(const SizedBox());
        // Real destination widgets may open Hive inside the fake-clock zone.
        // Finish disk-close callbacks before that zone ends in outer tearDown.
        var closed = false;
        final closing = Hive.close().then((_) => closed = true);
        await waitForUi(t, () => closed);
        await closing;
        await t.pumpAndSettle();
      },
    );
  }
}
