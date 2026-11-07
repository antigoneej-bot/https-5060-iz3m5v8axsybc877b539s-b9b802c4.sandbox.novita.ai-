import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/reply_notification_plan.dart';

typedef Reply = ({String id, DateTime at, bool seen});

void main() {
  final now = DateTime(2026, 10, 13, 20);
  Reply reply(String id, int hours, {bool seen = false}) =>
      (id: id, at: now.add(Duration(hours: hours)), seen: seen);
  Reply? select(List<Reply> replies) => nextScheduledReply(
    replies,
    now: now,
    isSeen: (r) => r.seen,
    availableAt: (r) => r.at,
  );

  test('old unread reply does not suppress tomorrow notification', () {
    final next = select([reply('past', -24), reply('tomorrow', 10)]);
    expect(next?.id, 'tomorrow');
  });
  test('closest future unseen reply wins regardless of storage order', () {
    expect(select([reply('later', 20), reply('seen', 1, seen: true),
      reply('next', 2)])?.id, 'next');
  });
  test('seen, due-now and past replies do not create future schedules', () {
    expect(select([reply('now', 0), reply('past', -1),
      reply('seen', 2, seen: true)]), isNull);
    expect(select([]), isNull);
  });
  test('normal and heart-letter channels choose their own next reply', () {
    expect(select([reply('old-cat', -1)]), isNull);
    expect(select([reply('heart', 10)])?.id, 'heart');
  });
}
