import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/widgets/daily_care_card.dart';
import 'package:flutter_app/screens/mind_review_screen.dart';
import 'package:flutter_app/theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [(360.0, 1.0), (390.0, 1.0), (360.0, 2.0)]) {
    testWidgets(
      'three primary actions at ${size.$1}px and ${size.$2} text scale',
      (tester) async {
        tester.view.physicalSize = Size(size.$1, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        final chosen = <String>[];
        if (Platform.environment['MINDNYANG_REVIEW_DIR'] != null) {
          await tester.runAsync(() async {
            for (final font in {
              'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
              'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
              'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
            }.entries) {
              await (FontLoader(
                font.key,
              )..addFont(rootBundle.load(font.value))).load();
            }
          });
        }
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(size.$2)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: DailyCareCard(
                    onWrite: () => chosen.add('write'),
                    onRest: () => chosen.add('rest'),
                    onGarden: () => chosen.add('garden'),
                    onReview: () => chosen.add('review'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(chosen, isEmpty);
        expect(tester.takeException(), isNull);
        final directory = Platform.environment['MINDNYANG_REVIEW_DIR'];
        if (directory != null) {
          await tester.runAsync(() async {
            final render =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(directory).create(recursive: true);
            await File(
              '$directory/home-${size.$1.toInt()}-${size.$2}.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
        for (final label in ['마음 남기기', '정원 가꾸기', '지난 마음 보기', '지금은 조용히 쉬기']) {
          await tester.ensureVisible(find.text(label));
          await tester.pumpAndSettle();
          await tester.tap(find.text(label));
          await tester.pump();
        }
        expect(chosen, ['write', 'garden', 'review', 'rest']);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('review entrance returns to the actual record tab callback', (
    tester,
  ) async {
    var records = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      MindReviewScreen(onOpenRecords: () => records++),
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.byType(MindReviewScreen), findsOneWidget);
    for (final label in ['내가 쓴 편지', '도움이 됐던 돌봄', '마음의 흐름', '정원 기록집']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('내가 쓴 편지'));
    await tester.pumpAndSettle();
    expect(records, 1);
    expect(find.byType(MindReviewScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
