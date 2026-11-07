import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/models/garden_decoration.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/widgets/garden_decoration_sheet.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';
import 'package:flutter_app/mongi/screens/garden_daily_care_screen.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';

class _CatalogGarden extends GardenProvider {
  final owned = <String>{};
  final placed = <String>{};
  int obtains = 0, toggles = 0;
  Completer<void>? save;
  bool fail = false;
  _CatalogGarden() {
    lightEssence = 120;
  }
  @override
  Future<void> refreshSubscription() async {}
  @override
  bool isDecorationUnlocked(GardenDecoration d) => owned.contains(d.id);
  @override
  bool isDecorationEquipped(GardenDecoration d) => placed.contains(d.id);
  @override
  Future<void> obtainDecoration(GardenDecoration d) async {
    obtains++;
    if (save != null) await save!.future;
    if (fail) throw StateError('저장 실패');
    lightEssence -= 60;
    owned.add(d.id);
    placed.add(d.id);
    equippedDecorationIds = placed.toList();
    notifyListeners();
  }

  @override
  Future<void> toggleDecorationEquipped(GardenDecoration d) async {
    toggles++;
    if (!placed.remove(d.id)) placed.add(d.id);
    equippedDecorationIds = placed.toList();
    notifyListeners();
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('ko');
  });

  Future<void> catalog(
    WidgetTester t,
    _CatalogGarden garden, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(garden.dispose);
    await t.pumpWidget(
      ChangeNotifierProvider<GardenProvider>.value(
        value: garden,
        child: MaterialApp(
          locale: AppLanguage.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const GardenDecorationSheet(),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'selection is a read-only preview; confirmation saves once, then owned items do not charge again',
    (t) async {
      final garden = _CatalogGarden();
      await catalog(t, garden);
      final before = MongiGardenStore.instance.value.toJson();
      await t.tap(find.byKey(const ValueKey('decoration-select-cat_cushion')));
      await t.pumpAndSettle();
      expect(garden.obtains, 0);
      expect(garden.lightEssence, 120);
      expect(MongiGardenStore.instance.value.toJson(), before);
      final preview = t.widget<GardenWorldView>(
        find.byKey(const Key('decoration-garden-preview')),
      );
      expect(preview.readOnly, isTrue);
      expect(preview.decorations, contains('cat_cushion'));
      garden.save = Completer<void>();
      await t.tap(find.byKey(const Key('decoration-confirm')));
      await t.pump();
      await t.tap(find.byKey(const Key('decoration-confirm')));
      expect(garden.obtains, 1);
      garden.save!.complete();
      await t.pumpAndSettle();
      expect(garden.lightEssence, 60);
      expect(garden.placed, {'cat_cushion'});
      await t.tap(find.byKey(const Key('decoration-confirm')));
      await t.pumpAndSettle();
      expect(garden.placed, isEmpty);
      expect(garden.lightEssence, 60);
      expect(garden.toggles, 1);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'failed confirmation preserves selection and balance and can retry',
    (t) async {
      final garden = _CatalogGarden()..fail = true;
      await catalog(t, garden);
      await t.tap(find.byKey(const Key('decoration-confirm')));
      await t.pumpAndSettle();
      expect(garden.lightEssence, 120);
      expect(garden.owned, isEmpty);
      expect(find.text('저장 실패'), findsOneWidget);
      garden.fail = false;
      await t.tap(find.byKey(const Key('decoration-confirm')));
      await t.pumpAndSettle();
      expect(garden.obtains, 2);
      expect(garden.lightEssence, 60);
      expect(garden.owned, {'daisy_pot'});
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('catalog confirmation remains accessible $size font $scale', (
        t,
      ) async {
        await catalog(t, _CatalogGarden(), size: size, scale: scale);
        expect(
          find.byKey(const Key('decoration-confirm')).hitTestable(),
          findsOneWidget,
        );
        await t.scrollUntilVisible(
          find.byKey(const ValueKey('decoration-select-bird_house')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(find.byKey(const ValueKey('decoration-select-bird_house')));
        await t.pumpAndSettle();
        expect(find.text('작은 새집 놓기 · 빛의 정수 60'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'receipt only reports a persisted daily allowance and never awards currency',
    (t) async {
      final empty = MongiGardenData(seedTokens: 3, essence: 40);
      Future<void> render(MongiGardenData data) => t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GardenDailyRewardReceipt(data: data)),
        ),
      );
      await render(empty);
      expect(find.text('빛의 정수 +20'), findsNothing);
      final saved = empty.claimCareDay(DateTime.now());
      final before = saved.toJson();
      await render(saved);
      await render(saved);
      expect(find.text('빛의 정수 +20'), findsOneWidget);
      expect(saved.toJson(), before);
      expect(saved.essence, 60);
      expect(saved.seedTokens, 4);
      expect(saved.claimCareDay(DateTime.now()).toJson(), before);
    },
  );
}
