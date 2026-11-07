import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

void main() {
  testWidgets('cushion works with reduced motion and removal clears rest state', (
    t,
  ) async {
    t.view.physicalSize = const Size(844, 390);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    Future<void> show(List<String> decorations, {bool readOnly = false}) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GardenWorldView(
              layout: GardenLayout(spaces: 3),
              seeds: const {},
              decorations: decorations,
              motionEnabled: false,
              companionAutomaticBehavior: false,
              cultivationMode: true,
              fillViewport: true,
              companionName: '보리',
              readOnly: readOnly,
              personalArtwork: base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aK1sAAAAASUVORK5CYII=',
              ),
              onMove: (_, __) async {},
              onMemory: (_) {},
              onPlant: () {},
              onDecorate: () {},
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    await show(['cat_cushion']);
    final item = find.byKey(const ValueKey('world-item-decor:cat_cushion'));
    await t.tap(item);
    await t.pumpAndSettle();
    final cat = find.byKey(const Key('garden-companion'));
    expect(t.widget<Semantics>(cat).properties.label, '보리 방석에서 일어나기');
    await t.tap(cat);
    await t.pumpAndSettle();
    expect(t.widget<Semantics>(cat).properties.label, isNot(contains('일어나기')));
    await t.tap(item);
    await t.pumpAndSettle();
    await show([]);
    expect(t.widget<Semantics>(cat).properties.label, isNot(contains('일어나기')));
    await show(['cat_cushion'], readOnly: true);
    expect(find.bySemanticsLabel('간직한 작품 액자'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
