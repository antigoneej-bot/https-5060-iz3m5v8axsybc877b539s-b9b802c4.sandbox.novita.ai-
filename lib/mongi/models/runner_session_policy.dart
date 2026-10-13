/// Short stage sessions; endless and practice modes keep their own rules.
class RunnerSessionPolicy {
  static int targetForStage(int stage) => stage <= 1
      ? 20
      : stage == 2
      ? 25
      : 30;

  static int secondsForTarget(int target) =>
      (60 + (target - 20) * 3).clamp(20, 90);
}
