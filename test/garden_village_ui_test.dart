import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/garden_village_screen.dart';
import 'package:flutter_app/mongi/screens/garden_visit_screen.dart';
import 'package:flutter_app/mongi/screens/public_garden_browse_screen.dart';
import 'package:flutter_app/mongi/screens/public_garden_settings_screen.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/screens/account_screen.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const profile = GardenVillageProfile(
  inviteCode: 'ABCD12345678',
  visibility: GardenVisibility.private,
  discoveryOptIn: false,
  receiveGifts: true,
  nickname: '내 정원',
);

class _Village extends GardenVillageService {
  GardenVillageProfile value = profile;
  GardenNeighborLists people = const GardenNeighborLists();
  Object? error;
  final calls = <String>[];
  Completer<GardenVillageProfile>? pendingProfile;
  Completer<void>? pendingResponse;
  Completer<void>? pendingCheer;
  int responses = 0, cheers = 0, requests = 0;
  bool receiveGifts = true;
  String? sentKind;
  GardenLayout? layout;
  @override
  String? get accountOwner => 'alice';
  @override
  Future<GardenVillageProfile> getProfile() async {
    calls.add('profile');
    if (error != null) throw error!;
    return pendingProfile == null ? value : pendingProfile!.future;
  }

  @override
  Future<GardenNeighborLists> listNeighbors() async {
    calls.add('neighbors');
    return people;
  }

  @override
  Future<PublicGardenPage> listPublicGardensPage({
    String? cursor,
    int pageSize = 12,
  }) async {
    if (error != null) throw error!;
    return const PublicGardenPage();
  }

  @override
  Future<GardenNeighbor> lookupInvite(String code) async =>
      const GardenNeighbor(gardenId: 'bob', nickname: '초롱');
  @override
  Future<void> requestNeighbor({String? inviteCode, String? gardenId}) async {
    requests++;
    people = const GardenNeighborLists(
      outgoing: [GardenNeighbor(gardenId: 'bob', nickname: '초롱')],
    );
  }

  @override
  Future<void> respondNeighbor(String gardenId, {required bool accept}) async {
    responses++;
    if (pendingResponse != null) await pendingResponse!.future;
    people = const GardenNeighborLists(
      neighbors: [GardenNeighbor(gardenId: 'bob', nickname: '초롱')],
    );
  }

  @override
  Future<PublicGarden> getGarden(String gardenId) async {
    calls.add('garden');
    return PublicGarden(
      gardenId: gardenId,
      nickname: '초롱',
      receiveGifts: receiveGifts,
      seedCounts: const {},
      equippedDecorationIds: const [],
      treeStageIndex: -1,
      layout: layout,
    );
  }

  @override
  Future<void> sendCheer({
    required String gardenId,
    required int messageIndex,
    String flowerKind = 'daisy',
    String? reaction,
    String deliveryKind = 'cheer',
  }) async {
    cheers++;
    sentKind = deliveryKind;
    if (pendingCheer != null) await pendingCheer!.future;
  }
}

class _Garden extends GardenProvider {
  GardenVisibility? visibility;
  bool? discovery, gifts;
  int saves = 0;
  @override
  Future<bool> publishGarden({
    String? nickname,
    GardenVisibility? visibility,
    bool? discoveryOptIn,
    bool? receiveGifts,
  }) async {
    saves++;
    this.visibility = visibility;
    discovery = discoveryOptIn;
    gifts = receiveGifts;
    return true;
  }
}

Future<void> _app(WidgetTester tester, Widget child, {_Garden? garden}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ChangeNotifierProvider<GardenProvider>.value(
      value: garden ?? _Garden(),
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('signed out village has an obvious real account entrance', (
    tester,
  ) async {
    final service = _Village();
    await _app(
      tester,
      GardenVillageScreen(
        service: service,
        accountReady: () async => false,
        currentAccount: () => null,
      ),
    );
    expect(find.text('간편 로그인'), findsOneWidget);
    expect(service.calls, isEmpty);
    await tester.tap(find.byKey(const Key('account-entry-card')));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hub waits for profile before neighbor request and cannot accept twice',
    (tester) async {
      final service = _Village()
        ..pendingProfile = Completer<GardenVillageProfile>()
        ..pendingResponse = Completer<void>()
        ..people = const GardenNeighborLists(
          incoming: [GardenNeighbor(gardenId: 'bob', nickname: '초롱')],
        );
      await _app(
        tester,
        GardenVillageScreen(
          service: service,
          accountReady: () async => true,
          currentAccount: () => 'alice',
        ),
      );
      expect(service.calls, ['profile']);
      service.pendingProfile!.complete(profile);
      service.pendingProfile = null;
      await tester.pumpAndSettle();
      expect(service.calls, ['profile', 'neighbors']);
      await tester.ensureVisible(find.text('수락'));
      await tester.tap(find.text('수락'));
      await tester.pump();
      await tester.tap(find.text('수락'));
      expect(service.responses, 1);
      expect(find.text('이웃으로 연결됐어요.'), findsNothing);
      service.pendingResponse!.complete();
      await tester.pumpAndSettle();
      expect(find.text('이웃으로 연결됐어요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'friend code shows identity confirmation before sending a request',
    (tester) async {
      final service = _Village();
      await _app(
        tester,
        GardenVillageScreen(
          service: service,
          accountReady: () async => true,
          currentAccount: () => 'alice',
        ),
      );
      await tester.tap(find.text('친구 코드로 찾기'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('village-friend-code')),
        'ABCD12345678',
      );
      await tester.tap(find.text('찾기'));
      await tester.pumpAndSettle();
      expect(find.text('초롱님에게 이웃 신청'), findsOneWidget);
      expect(service.requests, 0);
      await tester.tap(find.text('이웃 신청'));
      await tester.pumpAndSettle();
      expect(service.requests, 1);
      expect(find.text('수락을 기다리는 이웃'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('account switch clears old neighbors and ignores late response', (
    tester,
  ) async {
    final changes = StreamController<String?>();
    addTearDown(changes.close);
    var owner = 'alice';
    final service = _Village()
      ..pendingProfile = Completer<GardenVillageProfile>();
    final pending = service.pendingProfile!;
    await _app(
      tester,
      GardenVillageScreen(
        service: service,
        accountReady: () async => owner == 'alice',
        currentAccount: () => owner,
        accountChanges: changes.stream,
      ),
    );
    owner = 'signed-out';
    changes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('간편 로그인'), findsOneWidget);
    pending.complete(profile);
    await tester.pumpAndSettle();
    expect(find.text('ABCD12345678'), findsNothing);
    expect(find.text('간편 로그인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery connection failure is not an empty village', (
    tester,
  ) async {
    final service = _Village()..error = StateError('연결을 확인해 주세요');
    await _app(
      tester,
      PublicGardenBrowseScreen(
        service: service,
        accountReady: () async => true,
      ),
    );
    expect(find.textContaining('연결을 확인해 주세요'), findsOneWidget);
    expect(find.textContaining('지금 둘러볼 수 있는 정원이 없어요'), findsNothing);
    expect(find.text('다시 연결하기'), findsOneWidget);
    service.error = null;
    await tester.tap(find.text('다시 연결하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('지금 둘러볼 수 있는 정원이 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public visibility never silently opts into discovery', (
    tester,
  ) async {
    final service = _Village();
    final garden = _Garden();
    addTearDown(garden.dispose);
    await _app(
      tester,
      PublicGardenSettingsScreen(
        service: service,
        accountReady: () async => true,
      ),
      garden: garden,
    );
    await tester.ensureVisible(find.text('모두에게 공개'));
    await tester.tap(find.text('모두에게 공개'));
    await tester.pump();
    final discovery = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, '둘러보기에 내 정원 소개'),
    );
    expect(discovery.value, isFalse);
    await tester.ensureVisible(find.text('설정과 지금 정원 모습 저장'));
    await tester.tap(find.text('설정과 지금 정원 모습 저장'));
    await tester.pumpAndSettle();
    expect(garden.saves, 1);
    expect(garden.visibility, GardenVisibility.public);
    expect(garden.discovery, isFalse);
    expect(garden.gifts, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visit is read only and unaccepted visitors cannot give gifts', (
    tester,
  ) async {
    final service = _Village()..layout = GardenLayout();
    await _app(
      tester,
      GardenVisitScreen(
        gardenId: 'bob',
        service: service,
        accountReady: () async => true,
      ),
    );
    expect(service.calls, ['garden', 'neighbors']);
    final view = tester.widget<GardenWorldView>(find.byType(GardenWorldView));
    expect(view.readOnly, isTrue);
    expect(find.text('이웃 신청'), findsOneWidget);
    final gift = tester.widget<OutlinedButton>(
      find.byKey(const Key('village-send-gift')),
    );
    expect(gift.onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'recipient gift setting disables gifts even for an accepted neighbor',
    (tester) async {
      final service = _Village()
        ..receiveGifts = false
        ..people = const GardenNeighborLists(
          neighbors: [GardenNeighbor(gardenId: 'bob')],
        );
      await _app(
        tester,
        GardenVisitScreen(
          gardenId: 'bob',
          service: service,
          accountReady: () async => true,
        ),
      );
      final button = tester.widget<OutlinedButton>(
        find.byKey(const Key('village-send-gift')),
      );
      expect(button.onPressed, isNull);
      expect(find.text('이웃이 지금은 꽃 선물을 쉬고 있어요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'accepted neighbor can send a free flower only after choosing it',
    (tester) async {
      final service = _Village()
        ..people = const GardenNeighborLists(
          neighbors: [GardenNeighbor(gardenId: 'bob')],
        );
      await _app(
        tester,
        GardenVisitScreen(
          gardenId: 'bob',
          service: service,
          accountReady: () async => true,
        ),
      );
      await tester.tap(find.byKey(const Key('village-send-gift')));
      await tester.pumpAndSettle();
      expect(service.cheers, 0);
      await tester.tap(find.text('오늘의 꽃 보내기 · 무료'));
      await tester.pumpAndSettle();
      expect(find.text('선물할 꽃'), findsOneWidget);
      expect(service.cheers, 0);
      await tester.tap(find.text('꽃 선물하기'));
      await tester.pumpAndSettle();
      expect(service.cheers, 1);
      expect(service.sentKind, 'gift');
      expect(find.text('꽃 선물을 보냈어요. 이웃이 원하는 때 심을 수 있어요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('emoji cheer waits for success and does not create a flower', (
    tester,
  ) async {
    final service = _Village()..pendingCheer = Completer<void>();
    await _app(
      tester,
      GardenVisitScreen(
        gardenId: 'bob',
        service: service,
        accountReady: () async => true,
      ),
    );
    await tester.tap(find.text('응원'));
    await tester.pumpAndSettle();
    expect(find.text('선물할 꽃'), findsNothing);
    await tester.tap(find.text('응원 보내기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(service.cheers, 1);
    expect(service.sentKind, 'cheer');
    expect(find.text('응원 보냈어요'), findsNothing);
    service.pendingCheer!.complete();
    await tester.pumpAndSettle();
    expect(find.text('응원 보냈어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
