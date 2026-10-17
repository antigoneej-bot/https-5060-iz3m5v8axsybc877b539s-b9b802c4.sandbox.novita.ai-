import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/mongi/integration/cheer_flower_store.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/screens/garden_visit_screen.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

class _Gifts extends GardenVillageService {
  final calls = <String?>[];
  bool failOld = true;
  @override
  String? get accountOwner => 'alice';
  @override
  Future<PublicGarden> getGarden(String id) async => PublicGarden(
    gardenId: id,
    nickname: '이웃',
    receiveGifts: true,
    seedCounts: const {},
    equippedDecorationIds: const [],
    treeStageIndex: -1,
  );
  @override
  Future<GardenNeighborLists> listNeighbors() async =>
      const GardenNeighborLists(neighbors: [GardenNeighbor(gardenId: 'bob')]);
  @override
  Future<ReceivedCheerBatch> listReceivedCheers({
    String? cursor,
    int pageSize = 80,
  }) async {
    calls.add(cursor);
    if (cursor == null) {
      return ReceivedCheerBatch(
        cheers: [
          ReceivedCheer.fromJson({
            'id': 'planted',
            'messageIndex': 0,
            'flowerKind': 'daisy',
            'bloomConfirmed': true,
            'senderNickname': '이미 심은 꽃',
          }),
        ],
        nextCursor: 'old',
      );
    }
    if (failOld) throw StateError('이전 꽃 연결 실패');
    return ReceivedCheerBatch(
      cheers: [
        ReceivedCheer.fromJson({
          'id': 'ancient',
          'messageIndex': 0,
          'flowerKind': 'tulip',
          'senderNickname': '오래전 이웃',
        }),
        ReceivedCheer.fromJson({
          'id': 'currency',
          'messageIndex': 0,
          'flowerKind': 'daisy',
          'giftLightEssence': 5,
          'senderNickname': '옛 정수 선물',
        }),
        ReceivedCheer.fromJson({
          'id': 'transferred',
          'messageIndex': 0,
          'flowerKind': 'daisy',
          'senderNickname': '다른 곳에 보낸 꽃',
        }),
      ],
      retiredIds: ['transferred'],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('gift-pages-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 19))
              : null,
        );
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'stored gift picker loads old flowers and excludes planted, currency and transferred items',
    (tester) async {
      final service = _Gifts();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GardenVisitScreen(
            gardenId: 'bob',
            service: service,
            accountReady: () async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('village-send-gift')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('보관한 꽃 선물하기'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        Future<void> finishStorage() async {
          for (var i = 0; i < 100; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            await tester.pump();
            final sheet = find.ancestor(
              of: find.text('보관한 꽃 선물하기'),
              matching: find.byType(BottomSheet),
            );
            if (find
                .descendant(
                  of: sheet,
                  matching: find.byType(LinearProgressIndicator),
                )
                .evaluate()
                .isEmpty)
              return;
          }
          fail('Gift picker storage did not finish');
        }

        await finishStorage();
        expect(find.text('이미 심은 꽃님에게 받은 꽃'), findsNothing);
        await tester.tap(find.byKey(const Key('stored-gifts-more')));
        await tester.pump();
        await finishStorage();
        expect(find.textContaining('이전 꽃 연결 실패'), findsOneWidget);
        service.failOld = false;
        await tester.tap(find.byKey(const Key('stored-gifts-more')));
        await tester.pump();
        await finishStorage();
        expect(find.text('오래전 이웃님에게 받은 꽃'), findsOneWidget);
        expect(find.text('옛 정수 선물님에게 받은 꽃'), findsNothing);
        expect(find.text('다른 곳에 보낸 꽃님에게 받은 꽃'), findsNothing);
        expect(find.byKey(const Key('stored-gifts-more')), findsNothing);
        expect(service.calls, [null, 'old', 'old']);
        expect(
          CheerFlowerStore.instance
              .forOwner('alice')
              .any((f) => f.id == 'ancient'),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    },
  );
}
