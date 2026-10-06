import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/coalescing_refresh.dart';

void main() {
  test(
    'a record saved during reconciliation is included before callers finish',
    () async {
      final firstRead = Completer<void>();
      final secondRead = Completer<void>();
      final savedDays = <String>{'2026-10-05'};
      final creditedDays = <String>{};
      var reads = 0;
      var rewards = 0;
      final refresh = CoalescingRefresh(() async {
        final snapshot = savedDays.toSet();
        reads++;
        await (reads == 1 ? firstRead.future : secondRead.future);
        for (final day in snapshot) {
          if (creditedDays.add(day)) rewards++;
        }
      });
      final initial = refresh.request();
      savedDays.add('2026-10-06');
      final afterSave = refresh.request();
      expect(identical(initial, afterSave), isTrue);
      var finished = false;
      afterSave.then((_) {
        finished = true;
      });
      firstRead.complete();
      await Future<void>.delayed(Duration.zero);
      expect(reads, 2);
      expect(finished, isFalse);
      expect(refresh.isRunning, isTrue);
      secondRead.complete();
      await Future.wait([initial, afterSave]);
      expect(creditedDays, savedDays);
      expect(rewards, 2);
      expect(refresh.isRunning, isFalse);
      await refresh.request();
      expect(rewards, 2);
    },
  );

  test(
    'a failed refresh can be retried without leaving the queue locked',
    () async {
      var attempts = 0;
      final refresh = CoalescingRefresh(() async {
        if (++attempts == 1) throw StateError('storage unavailable');
      });
      await expectLater(refresh.request(), throwsStateError);
      expect(refresh.isRunning, isFalse);
      await refresh.request();
      expect(attempts, 2);
      expect(refresh.isRunning, isFalse);
    },
  );
}
