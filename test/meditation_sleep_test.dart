import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/meditation_sleep_service.dart';

void main() {
  test('sleep deadline fades and stops exactly once', () async {
    final s = MeditationSleepService(), owner = Object();
    final volumes = <double>[];
    var stops = 0;
    s.attach(
      owner,
      volume: (v) async {
        volumes.add(v);
      },
      stop: () async {
        stops++;
      },
    );
    await s.setTimer(15);
    final end = s.deadline!;
    await s.tick(now: end.subtract(const Duration(seconds: 5)));
    expect(s.factor, .5);
    expect(volumes.last, .5);
    await s.tick(now: end);
    expect(stops, 1);
    expect(s.owner, isNull);
    expect(volumes.last, 0);
    await s.tick(now: end.add(const Duration(minutes: 1)));
    expect(stops, 1);
  });
  test('timer cancelled and repeat reset on player handoff', () async {
    final s = MeditationSleepService(), a = Object(), b = Object();
    var stops = 0;
    s.attach(
      a,
      volume: (v) async {},
      stop: () async {
        stops++;
      },
    );
    await s.setTimer(30);
    final end = s.deadline!;
    s.setRepeat(true);
    s.attach(
      b,
      volume: (v) async {},
      stop: () async {
        stops++;
      },
    );
    await s.tick(now: end);
    expect(stops, 0);
    expect(s.deadline, isNull);
    expect(s.repeat, false);
    s.detach(b);
  });
  test(
    'old in-flight tick cannot stop a new session on the same owner',
    () async {
      final s = MeditationSleepService(), owner = Object();
      final gate = Completer<void>();
      var stops = 0;
      s.attach(
        owner,
        volume: (v) async {
          if (v == 0) await gate.future;
        },
        stop: () async {
          stops++;
        },
      );
      await s.setTimer(15);
      final tick = s.tick(now: s.deadline!);
      s.detach(owner);
      s.attach(
        owner,
        volume: (v) async {},
        stop: () async {
          stops++;
        },
      );
      gate.complete();
      await tick;
      expect(stops, 0);
      expect(s.owner, owner);
      s.detach(owner);
    },
  );
}
