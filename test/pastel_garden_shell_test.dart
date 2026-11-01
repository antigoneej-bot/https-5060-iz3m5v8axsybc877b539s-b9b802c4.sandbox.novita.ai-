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
    for (final e in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(320, 640),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('approved four pages remain interactive $size $scale', (
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
            await File(
              '$dir/page-${page + 1}-${size.width.toInt()}-$scale.png',
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
          find.text('좋아요'),
          120,
          scrollable: find
              .descendant(
                of: find.byKey(const PageStorageKey('pastel-page-0')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await t.pumpAndSettle();
        await t.tap(find.text('좋아요'));
        expect(moods, [0]);
        await tap('마음 기록하기', 0, PastelAction.write);
        await t.tap(find.text('정원').last);
        await t.pumpAndSettle();
        await capture(1);
        for (final e in [
          ('정원 꾸미기', PastelAction.garden),
          ('기억의 나무', PastelAction.memories),
          ('열매 정원', PastelAction.orchard),
          ('둘러보기', PastelAction.discover),
          ('즐겨찾기', PastelAction.favorites),
          ('받은 응원·선물', PastelAction.inbox),
        ]) {
          await tap(e.$1, 1, e.$2);
        }
        await t.tap(find.text('마음돌보기').last);
        await t.pumpAndSettle();
        await capture(2);
        for (final e in [
          ('고양이 선택', PastelAction.coats),
          ('밥 주기', PastelAction.feed),
          ('물 주기', PastelAction.water),
          ('목욕', PastelAction.bath),
          ('청소', PastelAction.clean),
          ('호흡·명상', PastelAction.meditation),
          ('색칠 힐링', PastelAction.coloring),
          ('돌봄 기록', PastelAction.care),
        ]) {
          await tap(e.$1, 2, e.$2);
        }
        await t.tap(find.text('모든 기능').last);
        await t.pumpAndSettle();
        await capture(3);
        for (final e in [
          ('편지 기록', PastelAction.records),
          ('감정 통계', PastelAction.comic),
          ('감정 캘린더', PastelAction.calendar),
          ('정원 기록집', PastelAction.memoryBook),
          ('추억 카드', PastelAction.cards),
          ('계정·백업·잠금', PastelAction.dataSafety),
          ('소리·알림', PastelAction.sound),
          ('구독·혜택', PastelAction.premium),
          ('전체 기능 둘러보기', PastelAction.all),
        ]) {
          await tap(e.$1, 3, e.$2);
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
      await t.tap(find.text('마음돌보기').last);
      await t.pump(const Duration(milliseconds: 300));
      final scroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('pastel-page-2')),
            matching: find.byType(Scrollable),
          )
          .first;
      await t.scrollUntilVisible(find.text('밥 주기'), 120, scrollable: scroll);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('밥 주기'));
      await t.tap(find.text('물 주기'));
      expect(actions, isEmpty);
      await t.tap(find.text('모든 기능').last);
      await t.pump(const Duration(milliseconds: 300));
      await t.enterText(find.byType(TextField), '백업');
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('계정·백업·잠금'), findsOneWidget);
      expect(find.text('편지 기록'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
}
