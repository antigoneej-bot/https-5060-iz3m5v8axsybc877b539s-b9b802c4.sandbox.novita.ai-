import '../lib/mongi/models/runner_session_policy.dart';

void require(bool ok, String message) {
  if (!ok) throw StateError(message);
}

void main() {
  for (final stage in [-1, 0, 1, 2, 3, 10, 20, 100, 1000000]) {
    final target = RunnerSessionPolicy.targetForStage(stage);
    final seconds = RunnerSessionPolicy.secondsForTarget(target);
    require(target >= 20 && target <= 30, 'unbounded target at $stage');
    require(seconds >= 60 && seconds <= 90, 'unbounded time at $stage');
  }
  require(RunnerSessionPolicy.secondsForTarget(20) == 60, 'first run');
  require(RunnerSessionPolicy.secondsForTarget(25) == 75, 'second run');
  require(RunnerSessionPolicy.secondsForTarget(30) == 90, 'later run');
  require(
    RunnerSessionPolicy.secondsForTarget(2) == 20,
    'short fixture remains safe',
  );
  require(
    RunnerSessionPolicy.secondsForTarget(10000) == 90,
    'old targets capped',
  );
  print(
    'PASS: ordinary stages have bounded targets/time; short fixtures remain valid.',
  );
}
