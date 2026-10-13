import '../lib/mongi/models/runner_resume_gate.dart';
import '../lib/mongi/models/runner_session_policy.dart';
import '../lib/services/meditation_timer_policy.dart';

int checked = 0;
void check(bool value, String message) {
  if (!value) throw StateError(message);
  checked++;
}

void main() {
  final gate = RunnerResumeGate();
  check(gate.blocked && !gate.begin(), 'cannot start before assets are ready');
  gate.ready = true;
  check(gate.blocked && gate.begin(), 'explicit start required after loading');
  check(
    !gate.begin() && gate.countdown == 3,
    'double tap cannot restart countdown',
  );
  check(
    !gate.tick() && gate.blocked && gate.countdown == 2,
    'first second remains paused',
  );
  gate.setForeground(false);
  check(
    !gate.tick() && gate.countdown == null,
    'background interrupts countdown',
  );
  gate.setForeground(true);
  check(gate.blocked && !gate.tick(), 'return never resumes automatically');
  check(gate.begin(), 'can explicitly try again');
  gate.tick();
  check(!gate.tick() && gate.blocked, 'full three seconds are required');
  check(
    gate.tick() && !gate.blocked && gate.started,
    'release exactly on third tick',
  );
  check(!gate.tick() && !gate.begin(), 'extra ticks do not release twice');
  gate.interrupt();
  check(
    gate.blocked && gate.started && gate.countdown == null,
    'pause preserves run identity',
  );
  gate.setForeground(false);
  check(!gate.begin(), 'cannot resume while backgrounded');
  gate.setForeground(true);
  gate.begin();
  gate.interrupt();
  check(!gate.tick() && gate.blocked, 'cancel countdown safely');
  check(MeditationTimerPolicy.allows(null), 'timer optional by default');
  for (final minutes in [3, 5, 10, 15, 30, 60]) {
    check(
      MeditationTimerPolicy.allows(minutes),
      'supported optional timer $minutes',
    );
  }
  check(
    !MeditationTimerPolicy.allows(0) && !MeditationTimerPolicy.allows(-1),
    'reject invalid timer',
  );
  check(
    MeditationTimerPolicy.fadeFactor(const Duration(seconds: 30)) == 1,
    'no early fade',
  );
  check(
    MeditationTimerPolicy.fadeFactor(const Duration(seconds: 5)) == .5,
    'last ten seconds fade',
  );
  check(
    MeditationTimerPolicy.fadeFactor(const Duration(seconds: -1)) == 0,
    'deadline cannot produce negative volume',
  );
  check(
    [1, 2, 18].map(RunnerSessionPolicy.targetForStage).join(',') == '20,25,30',
    'existing stage goals preserved',
  );
  check(
    [20, 25, 30].map(RunnerSessionPolicy.secondsForTarget).join(',') ==
        '60,75,90',
    'existing run durations preserved',
  );
  print(
    'PASS: $checked readiness, lifecycle, timer and unchanged duration contracts.',
  );
}
