import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/reply_style_picker.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/theme.dart';

void main() {
  testWidgets('reply style controls wrap and retain the selected mode', (
    tester,
  ) async {
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
      await (FontLoader('NotoColorEmoji')..addFont(
            File(
              '/tmp/NotoColorEmoji.ttf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final scenario in ['normal', 'narrow', 'large-text']) {
      final key = GlobalKey();
      var selected = ReplyStyle.listen;
      tester.view.physicalSize = Size(scenario == 'narrow' ? 320 : 390, 844);
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scenario == 'large-text' ? 1.5 : 1),
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16),
              child: StatefulBuilder(builder: (context, setState) => ReplyStylePicker(value: selected,
                onChanged: (value) => setState(() => selected = value))))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scenario);

      await tester.runAsync(() async {
        final img =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory('verification/reply-styles').create(recursive: true);
        await File(
          'verification/reply-styles/$scenario.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
      await tester.tap(find.text(ReplyStyle.reflect.label));
      await tester.pumpAndSettle();
      expect(selected, ReplyStyle.reflect);
      await tester.tap(find.text(ReplyStyle.suggest.label));
      await tester.pumpAndSettle();
      expect(selected, ReplyStyle.suggest);
      expect(tester.takeException(), isNull);

    }
    await tester.pumpWidget(const SizedBox());
  });
}
