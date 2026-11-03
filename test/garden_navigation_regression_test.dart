import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

void main() {
  testWidgets('whole map returns to the exact detailed camera without shrinking viewport', (t) async {
    t.view.physicalSize = const Size(844, 390);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    Future<void> show(bool map) async {
      await t.pumpWidget(MaterialApp(home: Scaffold(body: GardenWorldView(
        layout: GardenLayout(spaces: 3), seeds: const {}, decorations: const [],
        motionEnabled: false, cultivationMode: true, fillViewport: true,
        overviewRequested: map,
        onMove: (_, __) async {}, onMemory: (_) {}, onPlant: () {}, onDecorate: () {},
      ))));
      await t.pumpAndSettle();
    }
    await show(false);
    final finder = find.byKey(const Key('garden-world-camera'));
    final camera = t.widget<InteractiveViewer>(finder).transformationController!;
    await t.drag(finder, const Offset(-100, 0)); await t.pumpAndSettle();
    final before = Matrix4.copy(camera.value);
    final viewport = t.getRect(finder);
    await show(true);
    expect(t.getRect(finder), viewport);
    final box = t.renderObject<RenderBox>(find.byKey(const Key('garden-world-ground')));
    final mapRect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    expect(mapRect.width, lessThanOrEqualTo(viewport.width + 1));
    expect(mapRect.height, lessThanOrEqualTo(viewport.height + 1));
    await show(false);
    expect(camera.value, before);
    expect(t.getRect(finder), viewport);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('camera drag and two fingers do not select a planting location', (t) async {
    t.view.physicalSize = const Size(844, 390);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final locations = <Offset>[];
    await t.pumpWidget(MaterialApp(home: Scaffold(body: GardenWorldView(
      layout: GardenLayout(spaces: 3), seeds: const {}, decorations: const [],
      motionEnabled: false, cultivationMode: true, fillViewport: true,
      placementSeed: SeedType.all.first, onPlacementPoint: locations.add,
      onMove: (_, __) async {}, onMemory: (_) {}, onPlant: () {}, onDecorate: () {},
    ))));
    await t.pumpAndSettle();
    final finder = find.byKey(const Key('garden-world-camera'));
    final center = t.getCenter(finder);
    await t.tapAt(center); await t.pump();
    expect(locations, hasLength(1));
    await t.dragFrom(center, const Offset(-80, 0)); await t.pumpAndSettle();
    expect(locations, hasLength(1));
    final a = await t.startGesture(center - const Offset(25, 0), pointer: 1);
    final b = await t.startGesture(center + const Offset(25, 0), pointer: 2);
    await a.moveBy(const Offset(-20, 0)); await b.moveBy(const Offset(20, 0));
    await a.up(); await b.up(); await t.pumpAndSettle();
    expect(locations, hasLength(1));
    await t.tapAt(center); await t.pump();
    expect(locations, hasLength(2));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
