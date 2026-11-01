import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/garden_event_service.dart';

void main() {
  test(
    'server booking receipt confirms without a second network request',
    () async {
      final calls = <String>[];
      final service = GardenEventService(
        currentOwner: () => 'alice',
        transport: (action, body, owner) async {
          calls.add(action);
          expect(owner, 'alice');
          if (action != 'reserveGardenNews') {
            throw const CloudException('temporarily-unavailable');
          }
          return {
            'reserved': true,
            'reservation': {
              'newsId': 'evening',
              'sessionId': 'one',
              'sessionStartsAt': '2026-11-02T10:00:00Z',
            },
            'news': {'id': 'evening', 'title': '편지 모임', 'reservedCount': 1},
          };
        },
      );
      final confirmation = await service.reserve('evening', sessionId: 'one');
      expect(confirmation.reservation.newsId, 'evening');
      expect(
        confirmation.reservation.sessionStartsAt,
        DateTime.utc(2026, 11, 2, 10),
      );
      expect(confirmation.news!.reservedCount, 1);
      expect(calls, ['reserveGardenNews']);
    },
  );

  test(
    'legacy success is kept even when no refreshed notice was returned',
    () async {
      var calls = 0;
      final service = GardenEventService(
        currentOwner: () => 'alice',
        transport: (action, body, owner) async {
          calls++;
          if (calls > 1) throw const CloudException('temporarily-unavailable');
          return {'reserved': true};
        },
      );
      final confirmation = await service.reserve('legacy');
      expect(confirmation.reservation.newsId, 'legacy');
      expect(confirmation.news, isNull);
      expect(calls, 1);
    },
  );

  test(
    'missing or mismatched server confirmation never creates a booking',
    () async {
      for (final response in <Map<String, dynamic>>[
        {},
        {'reserved': false},
        {
          'reserved': true,
          'reservation': {'newsId': 'someone-else', 'sessionId': 'one'},
        },
      ]) {
        final service = GardenEventService(
          currentOwner: () => 'alice',
          transport: (_, __, ___) async => response,
        );
        await expectLater(
          service.reserve('evening', sessionId: 'one'),
          throwsA(isA<GardenEventException>()),
        );
      }
    },
  );

  test(
    'account change discards in-flight booking and my-booking responses',
    () async {
      for (final booking in [true, false]) {
        var owner = 'alice';
        final pending = Completer<Map<String, dynamic>>();
        final service = GardenEventService(
          currentOwner: () => owner,
          transport: (_, __, ___) => pending.future,
        );
        final future = booking
            ? service.reserve('evening')
            : service.myReservations();
        final assertion = expectLater(
          future,
          throwsA(
            isA<GardenEventException>().having(
              (e) => e.code,
              'code',
              'account-changed',
            ),
          ),
        );
        owner = 'bob';
        pending.complete({
          'reserved': true,
          'reservations': [
            {'newsId': 'evening'},
          ],
        });
        await assertion;
      }
    },
  );

  test(
    'my bookings preserve actual date and canceled-session status',
    () async {
      final service = GardenEventService(
        currentOwner: () => 'alice',
        transport: (_, __, ___) async => {
          'reservations': [
            {
              'newsId': 'evening',
              'sessionId': 'one',
              'sessionStartsAt': '2026-11-02T10:00:00Z',
              'news': {
                'id': 'evening',
                'sessions': [
                  {
                    'id': 'one',
                    'startsAt': '2026-11-02T10:00:00Z',
                    'endsAt': '2026-11-02T10:20:00Z',
                    'bookingClosesAt': '2026-11-02T09:00:00Z',
                    'capacity': 2,
                    'state': 'canceled',
                  },
                ],
              },
            },
          ],
        },
      );
      final booking = (await service.myReservations()).single;
      expect(booking.sessionStartsAt, DateTime.utc(2026, 11, 2, 10));
      expect(booking.session!.state, 'canceled');
      expect(booking.eventUnavailable, isFalse);
    },
  );
}
