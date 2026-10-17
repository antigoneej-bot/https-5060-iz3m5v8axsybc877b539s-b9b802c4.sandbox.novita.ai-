import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/public_garden_browse_screen.dart';
import 'package:flutter_app/mongi/screens/public_garden_inbox_screen.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

PublicGarden garden(String id) => PublicGarden(
  gardenId: id,
  nickname: '정원 $id',
  seedCounts: const {},
  equippedDecorationIds: const [],
  treeStageIndex: -1,
);
ReceivedCheer cheer(String id, {String? name}) => ReceivedCheer(
  id: id,
  messageIndex: 0,
  giftLightEssence: 0,
  createdAt: DateTime.utc(2026, 10, 16),
  claimed: true,
  senderNickname: name ?? id,
  deliveryKind: 'cheer',
  hasFlower: false,
);

class _Pages extends GardenVillageService {
  final pages = <String?, Future<PublicGardenPage> Function()>{};
  final cursors = <String?>[];
  @override
  String? get accountOwner => null;
  @override
  Future<PublicGardenPage> listPublicGardensPage({
    String? cursor,
    int pageSize = 12,
  }) {
    cursors.add(cursor);
    return pages[cursor]!();
  }
}

class _InboxPages extends GardenProvider {
  final pages = <String?, Future<ReceivedCheerBatch> Function()>{};
  final cursors = <String?>[];
  @override
  Future<ReceivedCheerBatch> loadMyPublicCheersPage({
    String? cursor,
    int pageSize = 30,
  }) {
    cursors.add(cursor);
    return pages[cursor]!();
  }
}

Future<void> app(
  WidgetTester tester,
  Widget child, {
  GardenProvider? provider,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final shell = MaterialApp(
    locale: const Locale('ko'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  await tester.pumpWidget(
    provider == null
        ? shell
        : ChangeNotifierProvider<GardenProvider>.value(
            value: provider,
            child: shell,
          ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> more(WidgetTester tester, String key) async {
  final button = find.byKey(Key(key));
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'page contracts preserve old responses and forward opaque cursors',
    () async {
      expect(PublicGardenPage.fromJson({'gardens': []}).nextCursor, isNull);
      expect(ReceivedCheerBatch.fromJson({'cheers': []}).nextCursor, isNull);
      expect(
        () => PublicGardenPage.fromJson({'gardens': [], 'nextCursor': ''}),
        throwsFormatException,
      );
      expect(
        () => ReceivedCheerBatch.fromJson({'cheers': [], 'nextCursor': 8}),
        throwsFormatException,
      );
      final calls = <Map<String, dynamic>>[];
      final service = GardenVillageService(
        currentOwner: () => 'alice',
        transport: (action, params, owner) async {
          calls.add({'action': action, ...params});
          return action == 'listPublicGardens'
              ? {'gardens': [], 'nextCursor': 'public-cursor'}
              : {
                  'cheers': [],
                  'retiredIds': ['old'],
                  'nextCursor': 'cheer-cursor',
                };
        },
      );
      expect(
        (await service.listPublicGardensPage(
          cursor: 'opaque',
          pageSize: 8,
        )).nextCursor,
        'public-cursor',
      );
      expect(
        (await service.listReceivedCheers(
          cursor: 'older',
          pageSize: 30,
        )).retiredIds,
        ['old'],
      );
      expect(calls, [
        {'action': 'listPublicGardens', 'cursor': 'opaque', 'pageSize': 8},
        {'action': 'listMyCheers', 'cursor': 'older', 'pageSize': 30},
      ]);
    },
  );

  test('page completion from a previous account is rejected', () async {
    String? owner = 'alice';
    final pending = Completer<Map<String, dynamic>>();
    final service = GardenVillageService(
      currentOwner: () => owner,
      transport: (_, __, ___) => pending.future,
    );
    final response = service.listReceivedCheers(cursor: 'old-cursor');
    owner = 'bob';
    pending.complete({'cheers': [], 'nextCursor': null});
    await expectLater(
      response,
      throwsA(
        isA<CloudException>().having(
          (error) => error.code,
          'code',
          'account-changed',
        ),
      ),
    );
  });

  testWidgets(
    'empty filtered public page still advances; errors retain visible gardens',
    (tester) async {
      final pages = _Pages()
        ..pages[null] = (() async =>
            const PublicGardenPage(nextCursor: 'scan-80'))
        ..pages['scan-80'] = (() async =>
            PublicGardenPage(gardens: [garden('a')], nextCursor: 'scan-160'))
        ..pages['scan-160'] = (() async => throw StateError('잠시 연결 실패'));
      await app(
        tester,
        PublicGardenBrowseScreen(
          service: pages,
          accountReady: () async => true,
        ),
      );
      expect(find.textContaining('지금 둘러볼 수 있는 정원이 없어요.'), findsNothing);
      await more(tester, 'public-gardens-more');
      expect(find.text('정원 a'), findsOneWidget);
      await more(tester, 'public-gardens-more');
      expect(find.text('정원 a'), findsOneWidget);
      expect(find.textContaining('잠시 연결 실패'), findsOneWidget);
      pages.pages['scan-160'] = () async =>
          PublicGardenPage(gardens: [garden('a'), garden('b')]);
      await more(tester, 'public-gardens-more');
      expect(find.text('정원 a'), findsOneWidget);
      expect(find.text('정원 b'), findsOneWidget);
      expect(find.byKey(const Key('public-gardens-more')), findsNothing);
      expect(pages.cursors, [null, 'scan-80', 'scan-160', 'scan-160']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'old inbox pages deduplicate and remove transferred gifts without clearing on failure',
    (tester) async {
      final pages = _InboxPages()
        ..pages[null] = (() async =>
            ReceivedCheerBatch(cheers: [cheer('first')], nextCursor: 'older'))
        ..pages['older'] = (() async => throw StateError('이전 목록 연결 실패'));
      await app(
        tester,
        PublicGardenInboxScreen(accountReady: () async => true),
        provider: pages,
      );
      expect(find.text('first님이 응원을 보냈어요'), findsOneWidget);
      await more(tester, 'received-cheers-more');
      expect(find.text('first님이 응원을 보냈어요'), findsOneWidget);
      expect(find.textContaining('이전 목록 연결 실패'), findsOneWidget);
      pages.pages['older'] = () async => ReceivedCheerBatch(
        cheers: [cheer('first'), cheer('ancient')],
        retiredIds: ['first'],
      );
      await more(tester, 'received-cheers-more');
      expect(find.text('first님이 응원을 보냈어요'), findsNothing);
      expect(find.text('ancient님이 응원을 보냈어요'), findsOneWidget);
      expect(find.byKey(const Key('received-cheers-more')), findsNothing);
      expect(pages.cursors, [null, 'older', 'older']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inbox account switch hides old pages and ignores the late old response',
    (tester) async {
      String? owner = 'alice';
      final changes = StreamController<String?>();
      addTearDown(changes.close);
      final old = Completer<ReceivedCheerBatch>();
      final pages = _InboxPages()
        ..pages[null] = (() async =>
            ReceivedCheerBatch(cheers: [cheer('alice')], nextCursor: 'old'))
        ..pages['old'] = (() => old.future);
      await app(
        tester,
        PublicGardenInboxScreen(
          accountReady: () async => true,
          currentAccount: () => owner,
          accountChanges: changes.stream,
        ),
        provider: pages,
      );
      await more(tester, 'received-cheers-more');
      pages.pages[null] = () async =>
          ReceivedCheerBatch(cheers: [cheer('bob')]);
      owner = 'bob';
      changes.add(owner);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      old.complete(ReceivedCheerBatch(cheers: [cheer('secret-alice')]));
      await tester.pump();
      expect(find.text('bob님이 응원을 보냈어요'), findsOneWidget);
      expect(find.text('alice님이 응원을 보냈어요'), findsNothing);
      expect(find.text('secret-alice님이 응원을 보냈어요'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
