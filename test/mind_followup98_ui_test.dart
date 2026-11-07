import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/settings_screen.dart';
import 'package:flutter_app/mongi/widgets/garden_plant_picker.dart';
import 'package:flutter_app/mongi/widgets/garden_cultivation_tools.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/screens/all_features_screen.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/widgets/premium_test_access.dart';

class _Garden extends GardenProvider {
  @override
  Future<void> ensureInitialized() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('local_user');
    await AppLanguage.instance.select('ko');
  });
  testWidgets('zero seeds lead to existing record and meditation actions', (
    t,
  ) async {
    var records = 0, meditations = 0, plants = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GardenPlantPicker(
            tokens: 0,
            seeds: const {},
            chooseLocation: true,
            onPlant: (_) async {
              plants++;
            },
            onLocate: (_) {},
            onCare: (_) {},
            onRecord: () => records++,
            onMeditate: () => meditations++,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(
      t.widget<FilledButton>(find.byKey(const Key('plant-selected'))).onPressed,
      isNull,
    );
    await t.ensureVisible(find.byKey(const Key('mind-get-seed-record')));
    await t.tap(find.byKey(const Key('mind-get-seed-record')));
    await t.tap(find.byKey(const Key('mind-get-seed-meditate')));
    expect(records, 1);
    expect(meditations, 1);
    expect(plants, 0);
  });
  testWidgets(
    'English settings translate effects and movement and omit unsupported reset',
    (t) async {
      await AppLanguage.instance.select('en');
      final care = CatCareProvider();
      final garden = _Garden();
      await care.loadJourney();
      await t.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CatCareProvider>.value(value: care),
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Garden effects'), findsOneWidget);
      expect(find.text('Cat movement'), findsOneWidget);
      expect(find.text('정원 배경 효과'), findsNothing);
      expect(find.text('고양이 움직임'), findsNothing);
      final ctx = t.element(find.byType(SettingsScreen));
      expect(
        find.text(AppLocalizations.of(ctx).settingsResetButton),
        findsNothing,
      );
      final movement = find.byKey(const Key('settings-companion-motion'));
      await t.ensureVisible(movement);
      final old = t.widget<SwitchListTile>(movement).value;
      await t.tap(movement);
      await t.pumpAndSettle();
      expect(t.widget<SwitchListTile>(movement).value, !old);
      await t.pumpWidget(const SizedBox());
      care.dispose();
      garden.dispose();
    },
  );
  testWidgets('small large-text feature directory starts with usable search', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        builder: (c, w) => MediaQuery(
          data: MediaQuery.of(
            c,
          ).copyWith(textScaler: TextScaler.linear(2), disableAnimations: true),
          child: w!,
        ),
        home: const AllFeaturesScreen(),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(find.text('오늘은 어떤 마음으로\n산책해 볼까요?'), findsNothing);
    await t.enterText(find.byType(TextField), '백업');
    await t.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.text('기록 보관·백업·잠금'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('기록 보관·백업·잠금'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'garden toolbar keeps full action name for accessibility at large text',
    (t) async {
      final semantics = t.ensureSemantics();
      var full = 0;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(2),
              ),
              child: SizedBox(
                width: 320,
                child: GardenCoreTools(
                  onPlant: () {},
                  onWater: () {},
                  onPlants: () {},
                  onOverview: () => full++,
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('가로 보기'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('가로 전체화면')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('cultivation-tool-3')));
      expect(full, 1);
      expect(t.takeException(), isNull);
      semantics.dispose();
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'membership keeps internal test disclosure without promising future rewards',
    (t) async {
      await t.pumpWidget(const MaterialApp(home: MembershipTestScreen()));
      expect(find.textContaining('테스트 기간'), findsOneWidget);
      expect(find.textContaining('통합은 준비 중'), findsNothing);
      await t.scrollUntilVisible(
        find.textContaining('씨앗은 심기에'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('씨앗은 심기에'), findsOneWidget);
    },
  );
}
