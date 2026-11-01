import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/my_garden_screen.dart';
import 'package:flutter_app/screens/all_features_screen.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/theme.dart';

class _App extends AppStateProvider {
  @override
  Set<String> get metCatIds => {'sad', 'angry'};
  @override
  int meetingCountFor(String id) => 12;
}

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['MINDNYANG_REVIEW_DIR'];
  if (directory == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File(
      '$directory/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    if (Platform.environment['MINDNYANG_REVIEW_DIR'] == null) return;
    for (final font in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'Poppins': 'assets/fonts/Poppins-ExtraBold.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  for (final size in [(320.0, 1.0), (360.0, 2.0), (390.0, 1.0)]) {
    testWidgets('collection in tool sheet ${size.$1} scale ${size.$2}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(size.$1, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final app = _App();
      final garden = GardenProvider();
      addTearDown(app.dispose);
      addTearDown(garden.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStateProvider>.value(value: app),
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
          ],
          child: MaterialApp(
            theme: appTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(size.$2)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: MyGardenScreen(
                  onGoMeetCat: () {},
                  showMongiPanel: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('함께한 고양이 도감'));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('12번째 만남'), findsWidgets);
      await capture(tester, 'collection-${size.$1}-${size.$2}');
      await tester.tap(find.text('함께한 고양이 도감'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('함께한 고양이 도감'));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('directory searches hidden features and empty results', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: appTheme, home: const AllFeaturesScreen()),
    );
    await tester.enterText(find.byType(TextField), '즐겨찾기');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('감정 고양이 만나기'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1개 기능'), findsOneWidget);
    await capture(tester, 'directory-search');
    expect(find.text('감정 고양이 만나기'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '없는기능xyz');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('0개 기능'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0개 기능'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('directory returns to requested shell tab', (tester) async {
    final app = _App();
    addTearDown(app.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppStateProvider>.value(
        value: app,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => openAllFeatures(context),
                child: const Text('메뉴 열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('메뉴 열기'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), '즐겨찾기');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(
      find.text('감정 고양이 만나기'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('감정 고양이 만나기'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(app.requestedTabIndex, 1);
    expect(find.text('메뉴 열기'), findsOneWidget);
  });
  for (final settings in [(390.0, 1.0, false), (320.0, 2.0, true)]) {
    testWidgets('pastel directory layout and motion $settings', (tester) async {
      tester.view.physicalSize = Size(settings.$1, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.$2),
              disableAnimations: settings.$3,
            ),
            child: child!,
          ),
          home: const AllFeaturesScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await capture(tester, 'pastel-top-${settings.$1}');
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField), '감정 고양이');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.scrollUntilVisible(
        find.text('감정 고양이 만나기'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 400));
      final before = tester.getCenter(find.text('감정 고양이 만나기'));
      await tester.pump(const Duration(milliseconds: 650));
      final after = tester.getCenter(find.text('감정 고양이 만나기'));
      if (settings.$3) {
        expect(after, before);
      } else {
        expect(after, isNot(before));
      }
      expect(tester.takeException(), isNull);
      await capture(tester, 'pastel-card-${settings.$1}');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
