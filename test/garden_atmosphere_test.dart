import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/garden_atmosphere.dart';

void main() {
  testWidgets(
    'ambient motion floats cards, allows taps and respects lifecycle and reduced motion',
    (tester) async {
      var taps = 0;
      Widget scene({bool reduced = false, bool enabled = true}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: GardenAtmosphere(
              motionEnabled: enabled,
              child: Center(
                child: FloatingGardenCard(
                  child: TextButton(
                    key: const Key('floating-action'),
                    onPressed: () => taps++,
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(scene());
      final start = tester.getTopLeft(find.byKey(const Key('floating-action')));
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.getTopLeft(find.byKey(const Key('floating-action'))),
        isNot(start),
      );
      await tester.tap(find.byKey(const Key('floating-action')));
      expect(taps, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final paused = tester.getTopLeft(
        find.byKey(const Key('floating-action')),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(
        tester.getTopLeft(find.byKey(const Key('floating-action'))),
        paused,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(scene(reduced: true));
      await tester.pumpAndSettle();
      final reduced = tester.getTopLeft(
        find.byKey(const Key('floating-action')),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        tester.getTopLeft(find.byKey(const Key('floating-action'))),
        reduced,
      );
      await tester.pumpWidget(scene(enabled: false));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
