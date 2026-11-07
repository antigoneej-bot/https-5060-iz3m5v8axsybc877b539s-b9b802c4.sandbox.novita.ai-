// Manual screenshot review: flutter test test/manual/statistics_visual_review.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/screens/emotion_statistics_screen.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'visual_review_fonts.dart';

class _ReviewGarden extends GardenProvider {
  @override
  bool get isInitialized => true;
}

void main() {
  tearDown(() => SubscriptionService.debugIsPremiumOverride = null);
  testWidgets('statistics layouts and calendar navigation', (tester) async {
    Future<void> finishImages() async {
      await tester.runAsync(() async {
        for (final element in find.byType(Image).evaluate().toList()) {
          Object? failure;
          await precacheImage(
            (element.widget as Image).image,
            element,
            onError: (error, _) => failure = error,
          );
          if (failure != null)
            throw StateError('Review image failed: $failure');
        }
      });
      await tester.pump();
    }

    SharedPreferences.setMockInitialValues({});
    SubscriptionService.debugIsPremiumOverride = true;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      // This layout review does not edit private reflection drafts. Avoid real
      // disk I/O in the widget test's fake clock, as in the navigation tests.
      (call) async => throw PlatformException(
        code: 'keystore-unavailable-in-layout-review',
      ),
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      ),
    );
    await tester.runAsync(() async {
      await loadReviewEmojiFont();
      for (final font in {
        'GowunDodum': 'GowunDodum-Regular.ttf',
        'GamjaFlower': 'GamjaFlower-Regular.ttf',
      }.entries) {
        await (FontLoader(
          font.key,
        )..addFont(rootBundle.load('assets/fonts/${font.value}'))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final now = DateTime.now();
    final app = AppStateProvider();
    final garden = _ReviewGarden();
    addTearDown(app.dispose);
    addTearDown(garden.dispose);
    final key = GlobalKey();
    for (final scenario in [
      'weekly',
      'monthly',
      'narrow',
      'large-text',
      'empty',
    ]) {
      app.history = scenario == 'empty'
          ? []
          : [
              for (var i = 0; i < 12; i++)
                LetterEntry(
                  id: '$i',
                  catId: ['sad', 'joyful', 'angry'][i % 3],
                  date: DateTime(
                    now.year,
                    now.month,
                    now.day - i ~/ 2,
                    12 + i % 2,
                  ),
                  letterText: '오늘의 마음을 기록했어요.',
                ),
            ];
      tester.view.physicalSize = Size(scenario == 'narrow' ? 320 : 390, 844);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: app),
            ChangeNotifierProvider<GardenProvider>.value(value: garden),
          ],
          child: MaterialApp(
            theme: appTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  scenario == 'large-text' ? 1.5 : 1,
                ),
              ),
              child: child!,
            ),
            home: RepaintBoundary(
              key: key,
              child: TickerMode(
                enabled: false,
                child: EmotionStatisticsScreen(
                  key: ValueKey(scenario),
                  initialMonthly: scenario != 'weekly',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await finishImages();
      expect(tester.takeException(), isNull, reason: scenario);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await boundary.toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory(
          'verification/statistics-screens',
        ).create(recursive: true);
        await File(
          'verification/statistics-screens/$scenario.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.drag(find.byType(ListView).first, const Offset(0, -650));
      await tester.pumpAndSettle();
      await finishImages();
      expect(tester.takeException(), isNull, reason: '$scenario scrolled');
      await tester.runAsync(() async {
        final img =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'verification/statistics-screens/$scenario-lower.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
