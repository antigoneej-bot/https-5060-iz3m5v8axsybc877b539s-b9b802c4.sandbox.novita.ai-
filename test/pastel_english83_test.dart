import 'package:flutter_app/l10n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'support/fake_audioplayers_platform.dart';
import 'support/fake_global_audioplayers_platform.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_app/widgets/pastel_garden_shell.dart';
import 'package:flutter_app/widgets/storybook_art.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('en');
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance =
        FakeGlobalAudioplayersPlatform();
    for (final e in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });

  testWidgets('all five pages swipe forward and back', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: PastelGardenShell(
          onAction: (_) {},
          onCoat: (_) {},
          coat: CompanionCoat.ginger,
          motionEnabled: false,
          companionAutomaticBehavior: false,
          gardenPreview: const SizedBox(),
          actualGarden: const SizedBox(),
        ),
      ),
    );
    for (var frame = 0; frame < 24; frame++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    final pager = find.byType(PageView).first;
    for (var page = 1; page < 5; page++) {
      final rect = t.getRect(pager);
      await t.dragFrom(
        Offset(rect.right - 30, rect.top + 170),
        Offset(-rect.width * .75, 0),
      );
      for (var frame = 0; frame < 24; frame++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(t.widget<PageView>(pager).controller!.page, closeTo(page, .01));
    }
    for (var page = 3; page >= 0; page--) {
      final rect = t.getRect(pager);
      await t.dragFrom(
        Offset(rect.left + 30, rect.top + 170),
        Offset(rect.width * .75, 0),
      );
      for (var frame = 0; frame < 24; frame++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(t.widget<PageView>(pager).controller!.page, closeTo(page, .01));
    }
    await t.pumpWidget(const SizedBox());
  });
  for (final size in [
    const Size(390, 844),
    const Size(320, 640),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('approved five pages remain interactive $size $scale', (
        t,
      ) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final actions = <PastelAction>[], moods = <int>[];
        final shot = GlobalKey();
        await t.pumpWidget(
          MaterialApp(
            theme: appTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(
                key: shot,
                child: PastelGardenShell(
                  onAction: actions.add,
                  onMoodSelected: moods.add,
                  onCoat: (_) {},
                  coat: CompanionCoat.ginger,
                  motionEnabled: false,
                  gardenPreview: const StorySprite.icon(9),
                ),
              ),
            ),
          ),
        );
        await t.runAsync(() async {
          await Future.wait([
            for (final name in [
              'home-scene',
              'garden-scene',
              'care-scene',
              'records-scene',
              'companion-atlas',
              'illustration-atlas',
            ])
              precacheImage(
                name.endsWith('atlas')
                    ? AssetImage('assets/storybook_ui_v1/$name.png')
                    : ResizeImage(
                        AssetImage('assets/storybook_ui_v1/$name.png'),
                        width: 1200,
                      ),
                shot.currentContext!,
              ),
          ]);
        });
        await t.pumpAndSettle();
        Future<void> capture(int page) async {
          final dir = Platform.environment['UI_APPROVED_REVIEW_DIR'];
          if (dir == null) return;
          await t.runAsync(() async {
            final image =
                await (shot.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(dir).create(recursive: true);
            await File(
              '$dir/en-page-${page + 1}-${size.width.toInt()}-$scale.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        Future<void> tap(String label, int page, PastelAction action) async {
          final scroll = find
              .descendant(
                of: find.byKey(PageStorageKey('pastel-page-$page')),
                matching: find.byType(Scrollable),
              )
              .first;
          await t.scrollUntilVisible(find.text(label), 120, scrollable: scroll);
          await t.pumpAndSettle();
          await Scrollable.ensureVisible(
            t.element(find.text(label)),
            alignment: .5,
          );
          await t.pumpAndSettle();
          await t.tap(find.text(label));
          await t.pumpAndSettle();
          expect(actions.last, action);
        }

        await capture(0);
        await t.scrollUntilVisible(
          find.text('Good'),
          120,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('pastel-page-0')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await t.pumpAndSettle();
        await t.tap(find.text('Good'));
        expect(moods, [0]);
        await tap('Write about today', 0, PastelAction.write);
        await t.ensureVisible(find.byKey(const ValueKey('main-tab-1')));
        await t.tap(find.byKey(const ValueKey('main-tab-1')));
        await t.pumpAndSettle();
        await capture(1);
        for (final e in [
          ('Decorate', PastelAction.garden),
          ('Memory trees', PastelAction.memories),
          ('Orchard', PastelAction.orchard),
          ('Explore', PastelAction.discover),
          ('Favorites', PastelAction.favorites),
          ('Messages & gifts', PastelAction.inbox),
        ]) {
          await tap(e.$1, 1, e.$2);
        }
        await t.ensureVisible(find.byKey(const ValueKey('main-tab-2')));
        await t.tap(find.byKey(const ValueKey('main-tab-2')));
        await t.pumpAndSettle();
        await capture(2);
        await t.ensureVisible(find.byKey(const ValueKey('main-tab-3')));
        await t.tap(find.byKey(const ValueKey('main-tab-3')));
        await t.pumpAndSettle();
        await capture(3);
        await t.scrollUntilVisible(
          find.byKey(const Key('open-meditation-library')),
          120,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('pastel-page-3')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          find.byKey(const Key('open-meditation-library')),
          findsOneWidget,
        );
        expect(find.text('Breathe & meditate'), findsNothing);
        expect(find.text('Color & unwind'), findsNothing);
        for (final e in [
          ('Choose a cat', PastelAction.coats),
          ('Feed', PastelAction.feed),
          ('Water', PastelAction.water),
          ('Bathe', PastelAction.bath),
          ('Clean', PastelAction.clean),
          (tr('명상·호흡·자연음'), PastelAction.meditation),
          ('Self-care journal', PastelAction.care),
        ]) {
          await tap(e.$1, 3, e.$2);
        }
        await t.ensureVisible(find.byKey(const ValueKey('main-tab-4')));
        await t.tap(find.byKey(const ValueKey('main-tab-4')));
        await t.pumpAndSettle();
        await capture(4);
        for (final e in [
          ('Letters', PastelAction.records),
          ('Mood insights', PastelAction.comic),
          ('Mood calendar', PastelAction.calendar),
          ('Garden scrapbook', PastelAction.memoryBook),
          ('Memory cards', PastelAction.cards),
          ('Account, backup & lock', PastelAction.dataSafety),
          ('Sounds & reminders', PastelAction.sound),
          ('Premium & benefits', PastelAction.premium),
          ('Browse all features', PastelAction.all),
        ]) {
          await tap(e.$1, 4, e.$2);
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
    'completed and saving care actions cannot be sent twice; search uses menu labels only',
    (t) async {
      final actions = <PastelAction>[];
      await t.pumpWidget(
        MaterialApp(
          home: PastelGardenShell(
            onAction: actions.add,
            onCoat: (_) {},
            coat: CompanionCoat.white,
            motionEnabled: false,
            completedCare: const {PastelAction.feed},
            careBusy: true,
            gardenPreview: const SizedBox(),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Unwind').last);
      await t.pump(const Duration(milliseconds: 300));
      final scroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('pastel-page-3')),
            matching: find.byType(Scrollable),
          )
          .first;
      await t.scrollUntilVisible(find.text('Feed'), 120, scrollable: scroll);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Feed'));
      await t.tap(find.text('Water'));
      expect(actions, isEmpty);
      await t.tap(find.text('Journal').last);
      await t.pump(const Duration(milliseconds: 300));
      await t.enterText(find.byType(TextField), 'BaCkUp');
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Account, backup & lock'), findsOneWidget);
      expect(find.text('Letters'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
