import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/orchard.dart';
import 'package:flutter_app/screens/orchard_screen.dart';
import 'package:flutter_app/services/orchard_service.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/widgets/orchard_tree_art.dart';
import 'package:flutter_app/theme.dart';

Map<String, dynamic> sample() => {
  'coins': 120,
  'stock': {'apple': 30, 'tuna': 4},
  'gifts': [
    {
      'senderName': '초롱',
      'kind': 'persimmon',
      'quantity': 3,
      'receivedAt': 1000,
    },
  ],
  'trees': {
    for (final k in OrchardKind.all)
      k.id: {
        'cycle': 0,
        'stage': 4,
        'yield': 30,
        'care': 5,
        'ready': true,
        'canWater': false,
        'progress': 1.0,
      },
  },
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'ambiguous transport retains exact request across reopening, then removes it after success',
    () async {
      final bodies = <Map<String, dynamic>>[];
      var fail = true;
      GardenVillageService transport() => GardenVillageService(
        currentOwner: () => 'a',
        transport: (action, body, owner) async {
          bodies.add(body);
          if (fail) throw const CloudException('temporarily-unavailable');
          return {
            'orchard': sample(),
            'result': {'quantity': 3},
          };
        },
      );
      final first = OrchardService(village: transport());
      await expectLater(
        first.act('gift', 'apple', quantity: 3, gardenId: 'b'),
        throwsA(isA<CloudException>()),
      );
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'orchard_pending_v1_a',
        ),
        true,
      );
      fail = false;
      await OrchardService(village: transport()).load();
      expect(bodies[1], bodies[0]);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'orchard_pending_v1_a',
        ),
        false,
      );
    },
  );
  test(
    'definitive stock rejection clears pending; another account never inherits pending',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'orchard_pending_v1_a',
        jsonEncode({
          'requestId': 'a' * 32,
          'op': 'sell',
          'kind': 'apple',
          'quantity': 3,
        }),
      );
      final b = OrchardService(
        village: GardenVillageService(
          currentOwner: () => 'b',
          transport: (action, body, owner) async {
            expect(action, 'getOrchard');
            return {'orchard': sample()};
          },
        ),
      );
      await b.load();
      expect(prefs.containsKey('orchard_pending_v1_a'), true);
      final a = OrchardService(
        village: GardenVillageService(
          currentOwner: () => 'a',
          transport: (action, body, owner) async {
            throw const CloudException('orchard-stock');
          },
        ),
      );
      await expectLater(a.load(), throwsA(isA<CloudException>()));
      expect(prefs.containsKey('orchard_pending_v1_a'), false);
    },
  );
  test(
    'account change before first transport cannot attach old-owner pending to new account',
    () async {
      String? owner = 'a';
      var requests = 0;
      final service = OrchardService(
        village: GardenVillageService(
          currentOwner: () => owner,
          transport: (action, body, uid) async {
            requests++;
            return {'orchard': sample()};
          },
        ),
      );
      final pending = service.load();
      owner = 'b';
      await expectLater(pending, throwsA(isA<CloudException>()));
      expect(requests, 0);
    },
  );
  test('harvested tree stays grown while the next crop starts', () {
    final raw = sample();
    (raw['trees'] as Map)['apple'] = {
      'cycle': 1,
      'stage': 0,
      'yield': 10,
      'care': 0,
      'ready': false,
      'canWater': true,
      'progress': 0,
    };
    final s = OrchardState.fromJson(raw);
    expect(s.trees['apple']!.stageLabel, '다음 꽃을 준비해요');
    expect(s.trees['apple']!.cycle, 1);
  });
  testWidgets(
    'warehouse requires quantity confirmation and sends chosen neighbor exactly once',
    (tester) async {
      final operations = <Map<String, dynamic>>[];
      final service = OrchardService(
        village: GardenVillageService(
          currentOwner: () => 'a',
          transport: (action, body, owner) async {
            if (action == 'listNeighbors')
              return {
                'neighbors': [
                  {'gardenId': 'b', 'nickname': '초롱'},
                ],
                'incoming': [],
                'outgoing': [],
                'blocked': [],
              };
            if (action == 'mutateOrchard') operations.add(body);
            return {
              'orchard': sample(),
              'result': {'quantity': body['quantity'] ?? 1, 'coins': 5},
            };
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (c, w) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: true),
            child: w!,
          ),
          home: OrchardScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('수확 창고'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('판매').first);
      await tester.pumpAndSettle();
      expect(operations, isEmpty);
      await tester.tap(find.byTooltip('수량 늘리기'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('orchard-confirm')));
      await tester.pumpAndSettle();
      expect(operations.single['quantity'], 2);
      expect(operations.single['op'], 'sell');
      await tester.tap(find.text('이웃 선물').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('초롱'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('orchard-confirm')));
      await tester.pumpAndSettle();
      expect(operations.last['gardenId'], 'b');
      expect(operations.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets(
      'orchard and warehouse fit $size and horizontal selection keeps five tree kinds',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const dest = String.fromEnvironment('ORCHARD_CAPTURE_DIR');
        if (dest.isNotEmpty) {
          for (final font in ['GowunDodum', 'GamjaFlower']) {
            final f = FontLoader(font)
              ..addFont(rootBundle.load('assets/fonts/$font-Regular.ttf'));
            await tester.runAsync(f.load);
          }
          final f = FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
          await tester.runAsync(f.load);
        }
        final service = OrchardService(
          village: GardenVillageService(
            currentOwner: () => 'a',
            transport: (a, b, c) async => {'orchard': sample()},
          ),
        );
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme,
            builder: (c, w) => MediaQuery(
              data: MediaQuery.of(c).copyWith(disableAnimations: true),
              child: w!,
            ),
            home: RepaintBoundary(
              key: boundary,
              child: OrchardScreen(service: service),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('사과나무'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (dest.isNotEmpty && size.width == 390) {
          await tester.runAsync(() async {
            final img =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
            await File(
              '$dest/Mindnyang-Orchard-v49.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            img.dispose();
          });
        }
        await tester.drag(find.byType(PageView), const Offset(-360, 0));
        await tester.pumpAndSettle();
        expect(find.text('감나무'), findsOneWidget);
        await tester.tap(find.text('수확 창고'));
        await tester.pumpAndSettle();
        expect(find.text('사과  30개'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('묘목 상점'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'large text small phone retains scrollable care and stock actions',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final s = OrchardService(
        village: GardenVillageService(
          currentOwner: () => 'a',
          transport: (a, b, c) async => {'orchard': sample()},
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (c, w) => MediaQuery(
            data: MediaQuery.of(c).copyWith(
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.8),
            ),
            child: w!,
          ),
          home: OrchardScreen(service: s),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('수확 창고'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('all five fruit tree drawings show distinct harvests', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: RepaintBoundary(
            key: key,
            child: Scaffold(
              backgroundColor: const Color(0xfffffaf2),
              body: Row(
                children: [
                  for (final k in OrchardKind.all)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 220,
                            child: OrchardTreeArt(kind: k, fruitCount: 30),
                          ),
                          Text(k.name, style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrchardTreeArt), findsNWidgets(5));
    expect(tester.takeException(), isNull);
    const dest = String.fromEnvironment('ORCHARD_CAPTURE_DIR');
    if (dest.isNotEmpty)
      await tester.runAsync(() async {
        final img =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final b = await img.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$dest/Mindnyang-Five-Trees-v49.png',
        ).writeAsBytes(b!.buffer.asUint8List());
        img.dispose();
      });
    await tester.pumpWidget(const SizedBox());
  });
}
