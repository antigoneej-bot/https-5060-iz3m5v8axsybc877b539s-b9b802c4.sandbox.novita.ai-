import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/widgets/garden_ambient.dart';

void main() {
  testWidgets('eye overlay closes briefly and opens when motion is disabled', (
    tester,
  ) async {
    Future<void> show(double time, {bool enabled = true}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: const Key('blink-preview'),
              child: SizedBox(
                width: 360,
                height: 360,
                child: GardenCatArt(
                  animation: AlwaysStoppedAnimation(time / 24),
                  blinking: enabled,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(2);
    await tester.runAsync(() async {
      final context = tester.element(find.byType(GardenCatArt));
      await Future.wait([
        precacheImage(
          const AssetImage('assets/living_garden/cat.webp'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/living_garden/cat_blink.webp'),
          context,
        ),
      ]);
    });
    await tester.pump();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    await show(3.2);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    if (const bool.fromEnvironment('GARDEN_GOLDENS')) {
      await expectLater(
        find.byKey(const Key('blink-preview')),
        matchesGoldenFile('../docs/mongi-blink.png'),
      );
    }
    await show(3.5);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    await show(3.2, enabled: false);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    expect(tester.takeException(), isNull);
  });
}
