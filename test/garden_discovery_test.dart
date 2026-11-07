import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/screens/garden_discovery_screen.dart';
import 'package:flutter_app/mongi/screens/garden_visit_screen.dart';
import 'package:flutter_app/mongi/screens/public_garden_settings_screen.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_test/flutter_test.dart';

PublicGarden garden(String id, {bool favorite = false}) => PublicGarden(
  gardenId: id,
  nickname: '$id 정원',
  seedCounts: const {'pine': 3},
  equippedDecorationIds: const ['bench'],
  treeStageIndex: 1,
  layout: GardenLayout(),
  isFavorite: favorite,
  neighborStatus: 'none',
);

class DiscoveryService extends GardenVillageService {
  bool supported = true;
  final queue = <PublicGarden?>[garden('bob'), garden('carol'), null];
  int randomCalls = 0, neighborCalls = 0, favoriteWrites = 0;
  bool favorite = false, unavailable = false;
  Object? error;
  Completer<PublicGarden?>? delayed;
  @override
  String? get accountOwner => 'alice';
  @override
  Future<GardenVillageProfile> getProfile() async => GardenVillageProfile(
    inviteCode: 'ABCD12345678',
    visibility: GardenVisibility.public,
    discoveryOptIn: true,
    randomVisitOptIn: false,
    supportsRandomVisits: supported,
    receiveGifts: true,
  );
  @override
  Future<PublicGarden?> randomGarden() async {
    randomCalls++;
    if (error != null) throw error!;
    return delayed?.future ?? (queue.isEmpty ? null : queue.removeAt(0));
  }

  @override
  Future<PublicGarden> getPublicVisitGarden(String id) async {
    if (unavailable) throw const CloudException('garden-not-found');
    return garden(id, favorite: favorite);
  }

  @override
  Future<GardenNeighborLists> listNeighbors() async {
    neighborCalls++;
    return const GardenNeighborLists();
  }

  @override
  Future<void> setFavorite(String id, bool value) async {
    favoriteWrites++;
    favorite = value;
  }

  @override
  Future<PublicGardenPage> favoriteGardens({String? cursor}) async =>
      unavailable
      ? const PublicGardenPage(unavailableIds: ['bob'])
      : PublicGardenPage(gardens: [garden('bob', favorite: true)]);
}

class Publication extends GardenProvider {
  int saves = 0;
  bool? randomChoice;
  Map<String, dynamic>? cat;
  @override
  Future<void> refreshPublicGardenAppearance() async {}
  @override
  Future<bool> publishGarden({
    String? nickname,
    GardenVisibility? visibility,
    bool? discoveryOptIn,
    bool? receiveGifts,
    bool? randomVisitOptIn,
    Map<String, dynamic>? publicCat,
  }) async {
    saves++;
    randomChoice = randomVisitOptIn;
    cat = publicCat;
    return true;
  }
}

Future<void> mount(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

void main() {
  testWidgets(
    'random opt-in starts unchecked even when old discovery was allowed and sends only explicit saved choice',
    (tester) async {
      final s = DiscoveryService(), p = Publication();
      await mount(
        tester,
        ChangeNotifierProvider<GardenProvider>.value(
          value: p,
          child: PublicGardenSettingsScreen(
            service: s,
            currentAccount: () => 'alice',
            accountReady: () async => true,
          ),
        ),
      );
      final tile = find.ancestor(
        of: find.text('무작위 이웃 방문 허용'),
        matching: find.byType(SwitchListTile),
      );
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(tester.widget<SwitchListTile>(tile).value, false);
      expect(p.saves, 0);
      await tester.tap(tile);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(tile).value, true);
      final save = find.widgetWithText(FilledButton, '설정과 지금 정원 모습 저장');
      await tester.scrollUntilVisible(
        save,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(p.randomChoice, true);
      expect(p.cat?.keys.toSet(), {'coat', 'stage'});
    },
  );
  testWidgets(
    'legacy server keeps existing publication path and does not receive unsupported new fields',
    (tester) async {
      final s = DiscoveryService()..supported = false;
      final p = Publication();
      await mount(
        tester,
        ChangeNotifierProvider<GardenProvider>.value(
          value: p,
          child: PublicGardenSettingsScreen(
            service: s,
            currentAccount: () => 'alice',
            accountReady: () async => true,
          ),
        ),
      );
      expect(find.text('무작위 이웃 방문 허용'), findsNothing);
      final save = find.widgetWithText(FilledButton, '설정과 지금 정원 모습 저장');
      await tester.scrollUntilVisible(
        save,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(p.saves, 1);
      expect(p.randomChoice, isNull);
      expect(p.cat, isNull);
    },
  );
  test(
    'transport pins account, uses explicit actions and ignores a late old-account response',
    () async {
      String? owner = 'alice';
      final pending = Completer<Map<String, dynamic>>();
      final calls = <String>[];
      final service = GardenVillageService(
        currentOwner: () => owner,
        transport: (action, params, uid) {
          calls.add(action);
          return pending.future;
        },
      );
      final request = service.randomGarden();
      owner = 'bob';
      pending.complete({'garden': null});
      await expectLater(
        request,
        throwsA(
          isA<CloudException>().having(
            (e) => e.code,
            'code',
            'account-changed',
          ),
        ),
      );
      expect(calls, ['randomPublicGarden']);
    },
  );
  test(
    'legacy profile lacks random consent/capability; new explicit consent is serialized separately',
    () async {
      final old = GardenVillageProfile.fromJson({
        'inviteCode': 'ABCD12345678',
        'visibility': 'public',
        'discoveryOptIn': true,
        'receiveGifts': true,
      });
      expect(old.randomVisitOptIn, false);
      expect(old.supportsRandomVisits, false);
      Map<String, dynamic>? sent;
      final service = GardenVillageService(
        currentOwner: () => 'alice',
        transport: (a, p, u) async {
          sent = p;
          return {
            'inviteCode': 'ABCD12345678',
            'visibility': 'public',
            'discoveryOptIn': true,
            'receiveGifts': true,
            'randomVisitOptIn': true,
            'randomVisitsSupported': true,
          };
        },
      );
      await service.updateProfile(
        visibility: GardenVisibility.public,
        discoveryOptIn: true,
        randomVisitOptIn: true,
        receiveGifts: true,
      );
      expect(sent!['randomVisitOptIn'], true);
    },
  );
  testWidgets(
    'random visit then next is read-only and never enumerates neighbors or connects friends',
    (tester) async {
      final s = DiscoveryService();
      await mount(
        tester,
        GardenDiscoveryScreen(service: s, accountReady: () async => true),
      );
      expect(find.text('bob 정원의 정원'), findsOneWidget);
      expect(s.neighborCalls, 0);
      expect(
        tester.widget<GardenWorldView>(find.byType(GardenWorldView)).readOnly,
        true,
      );
      expect(find.text('이웃 신청'), findsNothing);
      await tester.tap(find.byKey(const Key('public-garden-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('carol 정원의 정원'), findsOneWidget);
      expect(s.randomCalls, 2);
      expect(s.neighborCalls, 0);
    },
  );
  testWidgets(
    'favorite toggles through server and next is safe after the garden disappears',
    (tester) async {
      final s = DiscoveryService();
      await mount(
        tester,
        GardenDiscoveryScreen(service: s, accountReady: () async => true),
      );
      await tester.tap(find.byKey(const Key('public-garden-favorite')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(s.favorite, true);
      expect(s.favoriteWrites, 1);
      s.unavailable = true;
      await tester.pump(const Duration(seconds: 16));
      await tester.pump();
      expect(find.byType(GardenWorldView), findsNothing);
      expect(find.textContaining('공개가 해제'), findsOneWidget);
      expect(find.text('다른 정원으로'), findsOneWidget);
    },
  );
  testWidgets('empty pool and network failure have retry UI', (tester) async {
    final s = DiscoveryService()..queue.clear();
    await mount(
      tester,
      GardenDiscoveryScreen(service: s, accountReady: () async => true),
    );
    expect(find.textContaining('새로 둘러볼 정원을 찾지 못했어요'), findsOneWidget);
    s.error = const CloudException('temporarily-unavailable');
    await tester.tap(find.text('다른 정원 찾기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(GardenWorldView), findsNothing);
    expect(find.text('다른 정원 찾기'), findsOneWidget);
  });
  testWidgets(
    'defensive client never displays same random garden consecutively',
    (tester) async {
      final s = DiscoveryService()..queue.insert(1, garden('bob'));
      await mount(
        tester,
        GardenDiscoveryScreen(service: s, accountReady: () async => true),
      );
      await tester.tap(find.byKey(const Key('public-garden-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GardenWorldView), findsNothing);
    },
  );
  testWidgets(
    'favorites do not show revoked nickname and can remove the private reference',
    (tester) async {
      final s = DiscoveryService()..unavailable = true;
      await mount(
        tester,
        GardenDiscoveryScreen(
          service: s,
          accountReady: () async => true,
          favorites: true,
        ),
      );
      expect(find.text('bob 정원'), findsNothing);
      expect(find.text('지금 방문할 수 없는 정원'), findsOneWidget);
      await tester.tap(find.byTooltip('방문 불가 정원 즐겨찾기 해제'));
      await tester.pump();
      expect(s.favoriteWrites, 1);
    },
  );
  for (final size in [const Size(320, 640), const Size(800, 320)]) {
    testWidgets(
      'compact controls remain on screen in $size including overview',
      (tester) async {
        final s = DiscoveryService();
        await mount(
          tester,
          GardenVisitScreen(
            gardenId: 'bob',
            service: s,
            accountReady: () async => true,
            publicDiscovery: true,
            onNextGarden: () async {},
          ),
          size: size,
        );
        for (final key in [
          'public-garden-overview',
          'public-garden-rotate',
          'public-garden-cheer',
          'public-garden-next',
        ]) {
          final rect = tester.getRect(find.byKey(Key(key)));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        }
        await tester.tap(find.byKey(const Key('public-garden-overview')));
        await tester.pump();
        expect(find.byKey(const Key('public-garden-next')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'dispose ignores a late random response without navigation or account data leakage',
    (tester) async {
      final s = DiscoveryService()..delayed = Completer<PublicGarden?>();
      await mount(
        tester,
        GardenDiscoveryScreen(service: s, accountReady: () async => true),
      );
      await tester.pumpWidget(const MaterialApp(home: Text('closed')));
      s.delayed!.complete(garden('bob'));
      await tester.pump();
      expect(find.byType(GardenVisitScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
