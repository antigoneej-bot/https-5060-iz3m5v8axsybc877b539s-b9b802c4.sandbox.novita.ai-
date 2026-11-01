import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/storybook_motion.dart';

void main() {
  testWidgets('cat breathes, respects reduced motion, and pauses off screen', (
    t,
  ) async {
    Future<void> show({
      bool enabled = true,
      bool reduced = false,
      bool ticker = true,
    }) async {
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: TickerMode(
              enabled: ticker,
              child: Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: StorybookMotion(
                    enabled: enabled,
                    breathing: true,
                    child: const ColoredBox(color: Colors.orange),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pump();
    }

    double scale() => t
        .widget<Transform>(
          find.descendant(
            of: find.byType(StorybookMotion),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .entry(1, 1);
    await show();
    await t.pump(const Duration(milliseconds: 750));
    expect(scale(), greaterThan(1));
    await show(reduced: true);
    expect(scale(), 1);
    await t.pumpAndSettle();
    await show(enabled: false);
    await t.pumpAndSettle();
    expect(scale(), 1);
    await show(ticker: false);
    await t.pumpAndSettle();
    expect(scale(), 1);
    await show();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pumpAndSettle();
    expect(scale(), 1);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(milliseconds: 750));
    expect(scale(), greaterThan(1));
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });
  testWidgets('light overlay never intercepts controls', (t) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TextButton(onPressed: () => taps++, child: const Text('기록하기')),
                const StorybookMotion(enabled: true),
              ],
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('기록하기'));
    await t.pump(const Duration(seconds: 2));
    expect(taps, 1);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
