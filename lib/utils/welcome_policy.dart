/// Test builds replay the welcome tour once per root session, without deleting
/// completion flags, companion names, letters or subscription state.
bool shouldShowWelcome({
  required bool completed,
  required bool testReplay,
  required bool shownThisSession,
}) => !completed || (testReplay && !shownThisSession);
