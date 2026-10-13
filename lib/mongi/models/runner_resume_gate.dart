/// Explicit readiness: lifecycle return never starts a run by itself.
/// The countdown uses active ticks, not wall-clock time spent outside the app.
class RunnerResumeGate {
  bool ready = false;
  bool foreground = true;
  bool waiting = true;
  bool started = false;
  int? countdown;

  bool get blocked => !ready || !foreground || waiting;

  void interrupt() {
    waiting = true;
    countdown = null;
  }

  void setForeground(bool value) {
    foreground = value;
    if (!value) interrupt();
  }

  bool begin() {
    if (!ready || !foreground || !waiting || countdown != null) return false;
    countdown = 3;
    return true;
  }

  /// True only on the tick that releases the run.
  bool tick() {
    if (!foreground || !ready || countdown == null) return false;
    if (countdown! > 1) {
      countdown = countdown! - 1;
      return false;
    }
    countdown = null;
    waiting = false;
    started = true;
    return true;
  }
}
