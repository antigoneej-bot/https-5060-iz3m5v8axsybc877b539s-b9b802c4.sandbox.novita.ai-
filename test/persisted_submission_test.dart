import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/persisted_submission.dart';

void main() {
  test('concurrent sends persist once; delayed rewards do not block success', () async {
    final disk = Completer<void>();
    final reward = Completer<void>();
    var writes = 0;
    var saved = 0;
    var bonuses = 0;
    final operation = PersistedSubmission<String>(
      payload: 'stable-id',
      persist: (_) async { writes++; await disk.future; },
      onSaved: (_) { saved++; },
      afterSaved: (_) async { bonuses++; await reward.future; },
    );
    final first = operation.submit();
    final second = operation.submit();
    expect(writes, 1);
    expect(saved, 0);
    disk.complete();
    await Future.wait([first, second]).timeout(const Duration(seconds: 1));
    expect(saved, 1);
    expect(bonuses, 1);
    await operation.submit();
    expect(writes, 1);
    expect(bonuses, 1);
    reward.complete();
  });

  test('failed flush retries the same key without creating another record', () async {
    final records = <String, String>{};
    var attempts = 0;
    var saved = 0;
    var bonuses = 0;
    final operation = PersistedSubmission<String>(
      payload: 'stable-id',
      persist: (id) async {
        records.putIfAbsent(id, () => 'letter');
        if (++attempts == 1) throw StateError('simulated flush failure');
      },
      onSaved: (_) { saved++; },
      afterSaved: (_) async { bonuses++; },
    );
    await expectLater(operation.submit(), throwsStateError);
    expect(saved, 0);
    expect(bonuses, 0);
    await operation.submit();
    expect(records.keys, ['stable-id']);
    expect(attempts, 2);
    expect(saved, 1);
    expect(bonuses, 1);
  });

  test('failed reward does not turn a committed letter into a failed send', () async {
    var writes = 0;
    var bonuses = 0;
    final operation = PersistedSubmission<int>(
      payload: 1,
      persist: (_) async { writes++; },
      onSaved: (_) {},
      afterSaved: (_) async { bonuses++; throw StateError('reward unavailable'); },
    );
    await operation.submit();
    await Future<void>.delayed(Duration.zero);
    await operation.submit();
    expect(writes, 1);
    expect(bonuses, 1);
  });

  test('post-commit UI callback failure does not cause another write', () async {
    var writes = 0;
    var bonuses = 0;
    final operation = PersistedSubmission<int>(
      payload: 1,
      persist: (_) async { writes++; },
      onSaved: (_) { throw StateError('listener failure'); },
      afterSaved: (_) async { bonuses++; },
    );
    await operation.submit();
    await operation.submit();
    expect(writes, 1);
    expect(bonuses, 1);
  });
}
