import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/widgets/neighbor_design.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/screens/garden_village_screen.dart';
import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_app/mongi/integration/cheer_flower_store.dart';
import 'package:flutter_app/services/garden_return_store.dart';

class PreviewVillage extends GardenVillageService {
  @override
  Future<({GardenVillageProfile profile, GardenNeighborLists neighbors})>
  loadEntry() async {
    final profile = await getProfile();
    return (profile: profile, neighbors: await listNeighbors());
  }

  final claimed = <String>{};
  final responses = <String>[];
  int sentLoads = 0;
  String sentRecipient = '달이';
  Object? sentError;
  bool failClaimedReload = false;
  bool pureCheers = false;
  @override
  Future<GardenVillageProfile> getProfile() async => const GardenVillageProfile(
    inviteCode: 'ABCD12345678',
    visibility: GardenVisibility.neighbors,
    discoveryOptIn: false,
    receiveGifts: true,
  );
  @override
  Future<GardenNeighborLists> listNeighbors() async => GardenNeighborLists(
    incoming: [
      for (final name in ['봄이', '나비'])
        if (!responses.contains(name))
          GardenNeighbor(
            gardenId: name,
            nickname: name,
            publicCoat: name == '봄이'
                ? CompanionCoat.white
                : CompanionCoat.calico,
          ),
    ],
    outgoing: const [GardenNeighbor(gardenId: '달이', nickname: '달이')],
  );
  @override
  Future<void> respondNeighbor(String id, {required bool accept}) async {
    responses.add(id);
  }

  @override
  Future<ReceivedCheerBatch> listReceivedCheers({
    String? cursor,
    int pageSize = 30,
  }) async {
    if (failClaimedReload && claimed.isNotEmpty) throw StateError('rate-limit');
    return ReceivedCheerBatch(
      cheers: [
        for (var i = 0; i < 3; i++)
          ReceivedCheer(
            id: 'gift$i',
            messageIndex: 0,
            giftLightEssence: 0,
            createdAt: null,
            flowerKind: ['daisy', 'tulip', 'hydrangea'][i],
            deliveryKind: pureCheers ? 'cheer' : 'gift',
            hasFlower: !pureCheers,
            senderNickname: ['봄이', '달이', '나비'][i],
            senderCoat: [
              CompanionCoat.white,
              CompanionCoat.tabby,
              CompanionCoat.calico,
            ][i],
            claimed: claimed.contains('gift$i'),
          ),
      ],
    );
  }

  @override
  Future<Map<String, dynamic>> orchardState() async => {
    'orchard': {
      'coins': 0,
      'trees': {},
      'stock': {'apple': 3},
      'gifts': [
        {'kind': 'apple', 'quantity': 3, 'senderName': '봄이', 'receivedAt': 0},
      ],
    },
  };
  @override
  Future<List<Map<String, dynamic>>> listSentGardenGifts() async {
    sentLoads++;
    if (sentError != null) throw sentError!;
    return [
      {'kind': 'apple', 'quantity': 2, 'recipientName': sentRecipient},
    ];
  }
}

class PreviewGarden extends GardenProvider {
  PreviewGarden(this.service);
  final PreviewVillage service;
  final calls = <String>[];
  Completer<void>? pending;
  bool failSecond = false;
  @override
  Future<int> claimPublicCheer(String id) async {
    calls.add(id);
    if (pending != null) await pending!.future;
    if (failSecond && id == 'gift1') throw StateError('network');
    service.claimed.add(id);
    return 0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final e in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  late Directory temp;
  bool fixtureClosed = false;
  setUp(() async {
    fixtureClosed = false;
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('ko');
    temp = await Directory.systemTemp.createTemp('neighbor82-');
    Hive.init(temp.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
    }
    await t.pump();
  }

  Future<void> finishFixture(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() async {
      bool done = false;
      Object? error;
      StackTrace? stack;
      Future<void>(() async {
        await CheerFlowerStore.instance.reload();
        for (final owner in ['preview', 'alice', 'bob']) {
          await GardenReturnStore.instance.reload(owner);
        }
        await Hive.close();
        for (final file in await temp.list(followLinks: false).toList()) {
          expect(file, isA<File>());
          await file.delete();
        }
        await temp.delete();
        expect(await temp.exists(), isFalse);
        fixtureClosed = true;
      }).then(
        (_) => done = true,
        onError: (Object e, StackTrace s) {
          error = e;
          stack = s;
          done = true;
        },
      );
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (!done) {
        if (DateTime.now().isAfter(deadline))
          fail('Neighbor private writes did not finish');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await t.pump();
      }
      if (error != null) Error.throwWithStackTrace(error!, stack!);
    });
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  }

  Future<GlobalKey> mount(
    WidgetTester t,
    PreviewVillage s,
    PreviewGarden g,
    int tab, {
    Size size = const Size(390, 844),
    double scale = 1,
    String? owner = 'preview',
    String? Function()? ownerLookup,
    Stream<String?>? changes,
    int inboxFilter = 0,
  }) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
    final key = GlobalKey();
    await t.runAsync(() async {
      await t.pumpWidget(
        ChangeNotifierProvider<GardenProvider>.value(
          value: g,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'GowunDodum'),
            locale: AppLanguage.instance.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: key,
              child: GardenVillageScreen(
                initialTab: tab,
                inboxFilter: inboxFilter,
                service: s,
                currentAccount: ownerLookup ?? () => owner,
                accountChanges: changes,
                accountReady: () async => true,
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await settle(t);
    await t.runAsync(() async {
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      final label = tab == 2 ? tr('받은 선물') : tr('받은 신청 {0}', [2]);
      while (find.text(label).evaluate().isEmpty) {
        if (DateTime.now().isAfter(deadline)) {
          fail(
            'Neighbor did not finish loading: ${find.byType(Text).evaluate().map((e) => (e.widget as Text).data).join(" / ")}',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await t.pump();
      }
    });
    await t.runAsync(() async {
      for (final path in [
        'assets/neighbor_ui/approved-reference-02.png',
        'assets/living_garden/companion_coats.png',
        'assets/neighbor_ui/garden-header.png',
        'assets/neighbor_ui/gift-header.png',
        'assets/neighbor_ui/cat-portrait.png',
        'assets/neighbor_ui/gift-atlas.png',
      ]) {
        await precacheImage(AssetImage(path), key.currentContext!);
      }
    });
    await t.pump();
    return key;
  }

  Future<void> capture(WidgetTester t, GlobalKey key, String name) async {
    await t.runAsync(() async {
      final im =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory(
        Platform.environment['DIRECT_GARDEN_REVIEW_DIR'] ?? temp.path,
      );
      await dir.create(recursive: true);
      await File(
        '${dir.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      im.dispose();
    });
  }

  tearDown(() async {
    if (fixtureClosed) return;
    await Hive.close();
    await temp.delete(recursive: true);
  });
  for (final tab in [2, 3]) {
    testWidgets('English neighbor screen $tab renders without overflow', (
      t,
    ) async {
      await AppLanguage.instance.select('en');
      final s = PreviewVillage(), g = PreviewGarden(PreviewVillage());
      final key = await mount(t, s, g, tab);
      expect(t.takeException(), isNull);
      if (tab == 2) {
        expect(find.text('Gifts to collect: 3'), findsOneWidget);
        expect(find.text('Gift history'), findsOneWidget);
        expect(find.text('받은 내역'), findsNothing);
      }
      if (tab == 3) {
        final portraits = t.widgetList<NeighborPortrait>(
          find.byType(NeighborPortrait),
        );
        expect(
          portraits.map((p) => p.coat),
          containsAll([CompanionCoat.white, CompanionCoat.calico]),
        );
      }
      await capture(t, key, 'english-${tab == 2 ? 'gifts' : 'requests'}');
      await finishFixture(t);
    });
  }
  testWidgets('approved request layout renders and accepts once', (t) async {
    final s = PreviewVillage(), g = PreviewGarden(PreviewVillage());
    final key = await mount(t, s, g, 3);
    expect(find.text('받은 신청 2'), findsOneWidget);
    expect(find.text('수락'), findsNWidgets(2));
    await capture(t, key, 'requests-phone');
    await t.tap(find.text('수락').first);
    await settle(t);
    expect(s.responses, ['봄이']);
    await t.tap(find.text('보낸 신청 1'));
    await settle(t);
    expect(find.text('취소'), findsOneWidget);
    await finishFixture(t);
  });
  testWidgets(
    'gift layout, sent tab, bulk double tap and partial failure retry',
    (t) async {
      final s = PreviewVillage();
      final g = PreviewGarden(s);
      final key = await mount(t, s, g, 2);
      await capture(t, key, 'gifts-phone');
      expect(find.text('받을 선물 3개'), findsOneWidget);
      expect(find.text('받기'), findsWidgets);
      g.failSecond = true;
      g.pending = Completer<void>();
      await t.runAsync(() => t.tap(find.text('모두 받기')));
      await t.pump();
      await t.tap(find.text('받는 중…'));
      await t.pump();
      expect(g.calls, ['gift0']);
      await t.runAsync(() async {
        g.pending!.complete();
        g.pending = null;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await settle(t);
      expect(s.claimed, {'gift0'});
      expect(g.calls, ['gift0', 'gift1']);
      g.failSecond = false;
      await t.runAsync(() => t.tap(find.text('모두 받기')));
      await settle(t);
      expect(s.claimed, {'gift0', 'gift1', 'gift2'});
      expect(g.calls.where((id) => id == 'gift0').length, 1);
      await t.tap(find.text('보낸 선물'));
      await settle(t);
      expect(find.textContaining('달이에게'), findsOneWidget);
      ScaffoldMessenger.of(
        t.element(find.byType(GardenVillageScreen)),
      ).clearSnackBars();
      await t.pump(const Duration(seconds: 1));
      await capture(t, key, 'sent-phone');
      await finishFixture(t);
    },
  );
  testWidgets(
    'bulk retry skips acknowledged gifts even if list refresh fails',
    (t) async {
      final service = PreviewVillage();
      final garden = PreviewGarden(service)..failSecond = true;
      await mount(t, service, garden, 2);
      service.failClaimedReload = true;
      await t.tap(find.text('모두 받기'));
      await settle(t);
      expect(service.claimed, {'gift0'});
      expect(garden.calls, ['gift0', 'gift1']);
      expect(find.text('받을 선물 2개'), findsOneWidget);
      garden.failSecond = false;
      await t.tap(find.text('모두 받기'));
      await settle(t);
      expect(service.claimed, {'gift0', 'gift1', 'gift2'});
      expect(garden.calls, ['gift0', 'gift1', 'gift1', 'gift2']);
      expect(find.text('받을 선물 0개'), findsOneWidget);
      await finishFixture(t);
    },
  );
  testWidgets('pure encouragement confirms without offering flower planting', (
    t,
  ) async {
    final service = PreviewVillage()..pureCheers = true;
    final garden = PreviewGarden(service);
    final key = await mount(t, service, garden, 2, inboxFilter: 1);
    expect(find.text('심기'), findsNothing);
    final button = find.byKey(const ValueKey('receive-gift0'));
    await t.ensureVisible(button);
    await t.tap(button);
    await settle(t);
    expect(garden.calls, ['gift0']);
    expect(find.text('확인 완료'), findsOneWidget);
    expect(t.widget<FilledButton>(button).onPressed, isNull);
    expect(find.text('심기'), findsNothing);
    await capture(t, key, 'cheer-confirmed-phone');
    await finishFixture(t);
  });
  testWidgets('sent history refresh replaces the visible ledger', (t) async {
    final service = PreviewVillage();
    final garden = PreviewGarden(service);
    await mount(t, service, garden, 2);
    await t.tap(find.text('보낸 선물'));
    await settle(t);
    expect(service.sentLoads, 1);
    expect(find.textContaining('달이에게'), findsOneWidget);
    service.sentRecipient = '새 이웃';
    await t.runAsync(() async {
      var complete = false;
      Object? error;
      StackTrace? stack;
      t
          .widget<RefreshIndicator>(find.byType(RefreshIndicator).last)
          .onRefresh()
          .then(
            (_) => complete = true,
            onError: (Object e, StackTrace s) {
              error = e;
              stack = s;
              complete = true;
            },
          );
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (!complete) {
        if (DateTime.now().isAfter(deadline))
          fail('Inbox refresh did not finish');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await t.pump();
      }
      if (error != null) Error.throwWithStackTrace(error!, stack!);
    });
    await settle(t);
    expect(service.sentLoads, 2);
    expect(find.textContaining('새 이웃에게'), findsOneWidget);
    expect(find.textContaining('달이에게'), findsNothing);
    await finishFixture(t);
  });
  testWidgets(
    'old server sent history shows retry instead of a false empty inbox',
    (t) async {
      final service = PreviewVillage()
        ..sentError = StateError('unknown-action');
      await mount(t, service, PreviewGarden(service), 2);
      await t.tap(find.text('보낸 선물'));
      await settle(t);
      expect(find.textContaining('서버 업데이트'), findsOneWidget);
      expect(find.text('아직 보낸 선물이 없어요.'), findsNothing);
      service.sentError = null;
      await t.ensureVisible(find.text('다시 시도'));
      await t.tap(find.text('다시 시도'));
      await settle(t);
      expect(service.sentLoads, 2);
      expect(find.textContaining('달이에게'), findsOneWidget);
      await finishFixture(t);
    },
  );
  for (final mode in [
    'account change',
    'account round trip',
    'screen disposal',
  ]) {
    testWidgets('bulk claim stops after $mode', (t) async {
      final service = PreviewVillage();
      final garden = PreviewGarden(service)..pending = Completer<void>();
      final changes = StreamController<String?>.broadcast(sync: true);
      String? owner = 'alice';
      await mount(
        t,
        service,
        garden,
        2,
        ownerLookup: () => owner,
        changes: changes.stream,
      );
      await t.tap(find.text('모두 받기'));
      await t.pump();
      expect(garden.calls, ['gift0']);
      if (mode == 'screen disposal') {
        await t.pumpWidget(const SizedBox());
      } else {
        owner = 'bob';
        changes.add(owner);
        if (mode == 'account round trip') {
          owner = 'alice';
          changes.add(owner);
        }
      }
      await t.runAsync(() async {
        garden.pending!.complete();
      });
      await settle(t);
      expect(garden.calls, ['gift0']);
      expect(service.claimed, {'gift0'});
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await changes.close();
      await finishFixture(t);
    });
  }
  for (final tab in [2, 3])
    for (final size in [const Size(320, 640), const Size(844, 390)]) {
      testWidgets('neighbor layout $tab $size large text', (t) async {
        final s = PreviewVillage();
        final g = PreviewGarden(s);
        final key = await mount(
          t,
          s,
          g,
          tab,
          size: size,
          scale: 2,
          owner: null,
        );
        if (tab == 2) expect(find.text('받을 선물 3개'), findsOneWidget);
        expect(t.takeException(), isNull);
        if (tab == 2) {
          await t.scrollUntilVisible(
            find.byKey(const ValueKey('receive-gift0')),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          await t.pump();
          expect(t.takeException(), isNull);
        }
        await capture(t, key, 'large-$tab-${size.width.toInt()}');
        await finishFixture(t);
      });
    }
}
