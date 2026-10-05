import 'dart:convert';
import '../lib/utils/garden_record_progress.dart';

void check(bool value, String name) {
  if (!value) throw StateError(name);
  print('PASS $name');
}

void main() {
  final now = DateTime(2026, 10, 5, 15);
  final first = gardenRecordDays([], [
    DateTime(2026, 10, 4, 8),
    DateTime(2026, 10, 4, 20),
  ], now: now);
  check(first.length == 1, 'same day counts once');
  final restored = (jsonDecode(jsonEncode(first.toList())) as List)
      .cast<String>();
  final deleted = gardenRecordDays(restored, [], now: now);
  check(
    deleted.length == 1,
    'growth receipt survives reload and letter deletion',
  );
  check(
    gardenRecordDays(deleted, [DateTime(2026, 10, 4)], now: now).length == 1,
    'rewriting a deleted day cannot grow twice',
  );
  check(
    gardenRecordDays(deleted, [DateTime(2026, 10, 5)], now: now).length == 2,
    'next day continues growth after deletion',
  );
  check(
    gardenRecordDays([], [DateTime(2026, 10, 6)], now: now).isEmpty,
    'unclaimed future letters do not grow early',
  );
  check(
    gardenRecordDays(['2026-10-06'], [], now: now).length == 1,
    'clock correction does not remove previously earned growth',
  );
  check(
    gardenRecordMessage(2).contains('1일 더') &&
        gardenRecordMessage(5).contains('1일 더'),
    'progress matches visible sprite thresholds',
  );
  check(
    !gardenRecordMessage(6).contains('더 쌓이면') &&
        !gardenRecordMessage(10).contains('더 쌓이면'),
    'fully grown tree does not promise an unavailable visual stage',
  );
}
