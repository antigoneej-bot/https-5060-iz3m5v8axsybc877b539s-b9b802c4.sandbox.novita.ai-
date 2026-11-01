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
import 'package:flutter_app/models/cat_visit.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/screens/cat_visit_inbox_screen.dart';
import 'package:flutter_app/mongi/screens/garden_visit_screen.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/theme.dart';

final invitation = <String, dynamic>{
  'id': 'invitation1',
  'hostId': 'host',
  'guestId': 'guest',
  'hostNickname': '초롱',
  'hostCat': {'coat': 'ginger', 'stage': 3, 'name': '초롱냥'},
};
final visited = <String, dynamic>{
  ...invitation,
  'guestCat': {'coat': 'ginger', 'stage': 0, 'name': '아기냥'},
  'visitedAt': DateTime.now().millisecondsSinceEpoch,
};
Map<String, dynamic> garden() => {
  'garden': {
    'gardenId': 'host',
    'nickname': '초롱',
    'seedCounts': {'love': 3, 'peace': 8},
    'equippedDecorationIds': ['bench'],
    'layout': GardenLayout(spaces: 3).toJson(),
  },
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'transport snapshots are account-bound and carry only appearance',
    () async {
      String? owner = 'guest';
      final response = Completer<Map<String, dynamic>>();
      final service = GardenVillageService(
        currentOwner: () => owner,
        transport: (action, params, uid) {
          expect(action, 'respondCatVisit');
          expect(params['cat'], {'coat': 'white', 'stage': 0, 'name': '아기'});
          expect(params.containsKey('careDays'), false);
          return response.future;
        },
      );
      final pending = service.respondCat(
        CatVisit.fromJson(invitation),
        cat: const VisitingCat(coat: CompanionCoat.white, stage: 0, name: '아기'),
      );
      final expectation = expectLater(pending, throwsA(isA<CloudException>()));
      owner = 'other';
      response.complete({'visit': visited});
      await expectation;
    },
  );
  test('malformed appearance cannot become an image path or invalid stage', () {
    for (final cat in [
      {'coat': '../secret', 'stage': 0, 'name': 'x'},
      {'coat': 'ginger', 'stage': 9, 'name': 'x'},
    ]) {
      expect(() => VisitingCat.fromJson(cat), throwsFormatException);
    }
  });
  testWidgets(
    'accept opens two independent cats; scene ends when access is revoked',
    (tester) async {
      CatCareService.setCurrentUser('local_user');
      SharedPreferences.setMockInitialValues({
        'local_user_companion_journey_v1': const CompanionJourney(
          coat: CompanionCoat.ginger,
        ).encode(),
      });
      var blocked = false, accepted = 0;
      Map<String, dynamic>? chosen;
      final service = GardenVillageService(
        currentOwner: () => 'guest',
        transport: (action, params, owner) async {
          switch (action) {
            case 'listCatVisits':
              return {
                'invitations': accepted == 0 ? [invitation] : [],
                'memories': accepted > 0 ? [visited] : [],
              };
            case 'listNeighbors':
              return {
                'neighbors': [
                  {'gardenId': 'host', 'nickname': '초롱'},
                ],
                'incoming': [],
                'outgoing': [],
                'blocked': [],
              };
            case 'respondCatVisit':
              accepted++;
              chosen = Map<String, dynamic>.from(params['cat']);
              return {
                'visit': {...visited, 'guestCat': chosen},
              };
            case 'getCatVisit':
              if (blocked) throw const CloudException('cat-visit-unavailable');
              return {
                'visit': {
                  ...visited,
                  'guestCat': chosen ?? visited['guestCat'],
                },
              };
            case 'getNeighborGarden':
              return garden();
            default:
              throw StateError(action);
          }
        },
      );
      final care = CatCareProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: care,
          child: MaterialApp(
            theme: appTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: CatVisitInboxScreen(
              service: service,
              accountReady: () async => true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('accept-visit-invitation1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds:500));
      await tester.tap(find.byKey(const ValueKey('visit-cat-ginger')));
      await tester.pumpAndSettle();
      expect(accepted, 1);
      expect(find.byKey(const Key('garden-visiting-guest')), findsOneWidget);
      final world = tester.widget<GardenWorldView>(
        find.byType(GardenWorldView),
      );
      expect(world.visitingHost!.coat, CompanionCoat.ginger);
      expect(world.visitingGuest!.coat, CompanionCoat.ginger);
      expect(world.visitingHost!.stage, 3);
      expect(world.visitingGuest!.stage, 0);
      expect(care.journey.residents.length, 1);
      expect(care.journey.growthDays, 0);
      await tester.tap(find.text('함께 쉬기'));
      await tester.pump();
      expect(
        tester
            .widget<GardenWorldView>(find.byType(GardenWorldView))
            .visitActivity,
        'rest',
      );
      blocked = true;
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('garden-visiting-guest')), findsNothing);
      expect(find.text('방문이 끝났어요. 우리 고양이와 돌아가요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      care.dispose();
    },
  );
  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    testWidgets('invited scene fits phone $size and exports a real preview', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = GardenVillageService(
        currentOwner: () => 'guest',
        transport: (action, params, owner) async {
          if (action == 'getCatVisit')
            return {
              'visit': {
                ...visited,
                'guestCat': {'coat': 'tuxedo', 'stage': 1, 'name': '보리'},
              },
            };
          if (action == 'getNeighborGarden') return garden();
          if (action == 'listNeighbors')
            return { 'neighbors': [{'gardenId':'host'}], 'incoming':[], 'outgoing':[], 'blocked':[] };
          throw StateError(action);
        },
      );
      const dest = String.fromEnvironment('CAT_VISIT_CAPTURE_DIR');
      if (dest.isNotEmpty) {
        for (final font in ['GowunDodum', 'GamjaFlower']) {
          final loader = FontLoader(font)
            ..addFont(rootBundle.load('assets/fonts/$font-Regular.ttf'));
          await tester.runAsync(loader.load);
        }
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await tester.runAsync(icons.load);
      }
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: RepaintBoundary(
            key: boundary,
            child: GardenVisitScreen(
              gardenId: 'host',
              visitId: 'invitation1',
              service: service,
              accountReady: () async => true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('garden-visiting-guest')), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (dest.isNotEmpty && size.width == 390) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(seconds: 2));
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final img =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          await Directory(dest).create(recursive: true);
          await File(
            '$dest/Mindnyang-Neighbor-Cats-v48.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          img.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
