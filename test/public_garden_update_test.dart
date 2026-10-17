import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/mongi/models/public_garden_appearance.dart';
import 'package:flutter_app/mongi/models/public_garden_status.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/public_garden_settings_screen.dart';
import 'package:flutter_app/mongi/widgets/public_garden_update_card.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> _appearance() => {
  'seedCounts': {'rose': 2, 'cherry': 1},
  'equippedDecorationIds': ['bench', 'waterwheel'],
  'treeStageIndex': 1,
  'memoryTreeStage': 2,
  'hasCheerFlowers': true,
  'flowerKinds': ['daisy', 'tulip'],
  'layout': {
    'version': 1,
    'spaces': 2,
    'positions': {
      'seed:rose': [0.4, 0.7],
    },
  },
};

class _Garden extends GardenProvider {
  bool? changes = true;
  bool? published = true;
  Object? refreshError;
  bool updateSupported = true;
  int appearanceWrites = 0, settingsWrites = 0;
  @override
  bool? get hasUnpublishedGardenChanges => changes;
  @override
  bool? get gardenPublication => published;
  @override
  DateTime? get gardenPublishedAt => DateTime(2026, 10, 16, 9, 30);
  @override
  bool get canUpdatePublishedGardenAppearance => updateSupported;
  @override
  Future<void> refreshPublicGardenAppearance() async {
    if (refreshError != null) throw refreshError!;
  }

  @override
  Future<bool> updatePublishedGardenAppearance() async {
    appearanceWrites++;
    changes = false;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> publishGarden({
    String? nickname,
    GardenVisibility? visibility,
    bool? discoveryOptIn,
    bool? receiveGifts,
  }) async {
    settingsWrites++;
    return true;
  }
}

class _Village extends GardenVillageService {
  @override
  String get accountOwner => 'alice';
  @override
  Future<GardenVillageProfile> getProfile() async => const GardenVillageProfile(
    inviteCode: 'ABCD12345678',
    visibility: GardenVisibility.neighbors,
    discoveryOptIn: false,
    receiveGifts: false,
    nickname: '나무',
  );
}

Future<void> _screen(WidgetTester tester, _Garden garden) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(garden.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider<GardenProvider>.value(
      value: garden,
      child: MaterialApp(
        home: PublicGardenSettingsScreen(
          service: _Village(),
          accountReady: () async => true,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test(
    'appearance comparison ignores ordering, numeric representation and private data',
    () {
      final left = _appearance();
      final right = _appearance()
        ..['seedCounts'] = {'cherry': 1.0, 'rose': 2.0}
        ..['equippedDecorationIds'] = ['waterwheel', 'bench']
        ..['flowerKinds'] = ['tulip', 'daisy', 'daisy']
        ..['letter'] = 'this remains private'
        ..['plantMemories'] = {'name': 'our anniversary'};
      expect(
        PublicGardenAppearance.fingerprint(left),
        PublicGardenAppearance.fingerprint(right),
      );
      for (final update in <Map<String, dynamic>>[
        {
          'seedCounts': {'cherry': 1, 'rose': 3},
        },
        {'memoryTreeStage': 3},
        {
          'flowerKinds': ['daisy'],
        },
        {
          'layout': {
            'version': 1,
            'spaces': 2,
            'positions': {
              'seed:rose': [0.5, 0.7],
            },
          },
        },
      ]) {
        expect(
          PublicGardenAppearance.fingerprint({...left, ...update}),
          isNot(PublicGardenAppearance.fingerprint(left)),
        );
      }
    },
  );

  test(
    'publication appearance and timestamp cannot leak across account or stale request',
    () {
      final status = PublicGardenStatus();
      final first = status.begin('alice');
      final snapshot = PublicGardenStatusSnapshot.fromJson({
        'published': true,
        'visibility': 'neighbors',
        'snapshot': _appearance(),
        'updatedAt': '2026-10-16T00:30:00.000Z',
      });
      expect(status.apply(first, 'alice', snapshot), isTrue);
      expect(status.snapshot, isNotNull);
      expect(status.updatedAt, DateTime.utc(2026, 10, 16, 0, 30));
      status.selectOwner('bob');
      expect(status.snapshot, isNull);
      expect(status.updatedAt, isNull);
      expect(status.apply(first, 'alice', snapshot), isFalse);
      final failed = status.begin('bob');
      status.fail(failed, 'bob');
      expect(status.snapshot, isNull);
      expect(status.published, isNull);
    },
  );

  testWidgets(
    'appearance update has its own action and preserves settings at 360px',
    (tester) async {
      final garden = _Garden();
      await _screen(tester, garden);
      expect(find.text('새로 가꾼 모습이 아직 이웃에게 보이지 않아요.'), findsOneWidget);
      expect(
        find.textContaining('마지막 모습 저장 · 2026.10.16 09:30'),
        findsOneWidget,
      );
      final button = find.byKey(const Key('public-garden-update-now'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(garden.appearanceWrites, 1);
      expect(garden.settingsWrites, 0);
      expect(find.text('지금 정원 모습이 이웃에게도 보이고 있어요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unsaved settings are not silently discarded by appearance-only update',
    (tester) async {
      final garden = _Garden();
      await _screen(tester, garden);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '새 이름');
      await tester.pump();
      tester.testTextInput.hide();
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const Key('public-garden-update-now')),
            )
            .onPressed,
        isNull,
      );
      expect(garden.appearanceWrites, 0);
      expect(find.text('바꾼 설정도 적용하려면 아래의 저장 버튼을 눌러 주세요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'status read failure is shown without claiming a private or updated garden',
    (tester) async {
      final garden = _Garden()..refreshError = StateError('offline');
      await _screen(tester, garden);
      expect(find.text('마지막으로 저장한 정원 모습을 확인하지 못했어요.'), findsOneWidget);
      expect(find.text('지금 정원 모습이 이웃에게도 보이고 있어요.'), findsNothing);
      expect(find.text('지금은 나만 보는 정원이에요.'), findsNothing);
      expect(find.byKey(const Key('public-garden-update-now')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'garden entry offers explicit update without background publishing',
    (tester) async {
      final garden = _Garden();
      addTearDown(garden.dispose);
      var opened = 0;
      await tester.pumpWidget(
        ChangeNotifierProvider<GardenProvider>.value(
          value: garden,
          child: MaterialApp(
            home: Scaffold(
              body: PublicGardenUpdateCard(onOpen: () => opened++),
            ),
          ),
        ),
      );
      expect(find.text('이웃에게 보여줄 새 모습이 있어요'), findsOneWidget);
      expect(garden.appearanceWrites, 0);
      await tester.tap(find.byKey(const Key('public-garden-update-entry')));
      expect(opened, 1);
      expect(garden.appearanceWrites, 0);
    },
  );
}
