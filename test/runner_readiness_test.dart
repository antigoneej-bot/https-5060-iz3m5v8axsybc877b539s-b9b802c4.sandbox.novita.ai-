import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/widgets/runner_ready_overlay.dart';
import 'package:flutter_app/mongi/models/runner_resume_gate.dart';

void main() {
  testWidgets(
    'readiness blocks underlying controls at narrow width and larger text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var underlying = 0, starts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.6),
            ),
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: TextButton(
                      onPressed: () => underlying++,
                      child: const Text('game input'),
                    ),
                  ),
                  Positioned.fill(
                    child: RunnerReadyOverlay(
                      ready: true,
                      started: false,
                      practice: false,
                      countdown: null,
                      target: 20,
                      seconds: 60,
                      onStart: () => starts++,
                      onPause: () {},
                      onExit: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tapAt(const Offset(4, 4));
      expect(underlying, 0);
      await tester.ensureVisible(
        find.byKey(const ValueKey('runner-ready-start')),
      );
      await tester.tap(find.byKey(const ValueKey('runner-ready-start')));
      expect(starts, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'focus return and interrupted countdown require another explicit start',
    () {
      final gate = RunnerResumeGate()..ready = true;
      expect(gate.begin(), true);
      gate.tick();
      gate.setForeground(false);
      gate.setForeground(true);
      expect(gate.blocked, true);
      expect(gate.tick(), false);
      expect(gate.begin(), true);
      expect(gate.tick(), false);
      expect(gate.tick(), false);
      expect(gate.tick(), true);
    },
  );
}
