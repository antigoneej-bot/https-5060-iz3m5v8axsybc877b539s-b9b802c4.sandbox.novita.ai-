import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/notice.dart';
import 'package:flutter_app/screens/garden_news_editor_screen.dart';
import 'package:flutter_app/widgets/garden_booking_calendar.dart';
import 'package:flutter_app/screens/notice_detail_screen.dart';
import 'package:flutter_app/screens/my_garden_reservations_screen.dart';
import 'package:flutter_app/services/garden_event_service.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:intl/date_symbol_data_local.dart';

Map<String, dynamic> sessionJson() => {
  'id': 'evening',
  'label': '저녁 모임',
  'startsAt': '2026-11-02T20:00:00+09:00',
  'endsAt': '2026-11-02T20:20:00+09:00',
  'bookingOpensAt': '2026-11-01T09:00:00+09:00',
  'bookingClosesAt': '2026-11-02T19:00:00+09:00',
  'capacity': 5,
  'reservedCount': 2,
  'state': 'open',
};

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));
  test('legacy undated notices keep reservation behavior', () {
    final legacy = Notice.fromJson({
      'id': 'old',
      'title': '원데이 클래스',
      'capacity': 2,
      'reservedCount': 2,
    });
    expect(legacy.isReservable, isTrue);
    expect(legacy.isReservationFull, isTrue);
    expect(legacy.sessions, isEmpty);
    expect(Notice.fromJson({'id': 'announcement'}).isReservable, isFalse);
  });

  test(
    'session times retain the same instant and counters are not admin input',
    () {
      final session = GardenEventSession.tryFromJson(sessionJson())!;
      expect(session.startsAt, DateTime.utc(2026, 11, 2, 11));
      expect(session.reservedCount, 2);
      expect(session.toInput()['startsAt'], '2026-11-02T11:00:00.000Z');
      expect(session.toInput().containsKey('reservedCount'), isFalse);
      final notice = Notice.fromJson({
        'id': 'event',
        'type': 'event',
        'sessions': [sessionJson()],
        'eventMode': 'online',
        'reservedCount': 2,
      });
      expect(notice.isReservable, isTrue);
      expect(notice.toAdminInput().containsKey('reservedCount'), isFalse);
      expect(notice.sessions.single.label, '저녁 모임');
    },
  );

  test(
    'booking opens inclusively and closes at the deadline; full/canceled slots deny booking',
    () {
      final session = GardenEventSession.tryFromJson(sessionJson())!;
      final open = session.bookingOpensAt!;
      final close = session.bookingClosesAt;
      expect(
        session.canBookAt(open.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        session.availabilityAt(open.subtract(const Duration(seconds: 1))),
        '신청 시작 전',
      );
      expect(session.canBookAt(open), isTrue);
      expect(
        session.canBookAt(close.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(session.canBookAt(close), isFalse);
      expect(session.availabilityAt(close), '신청 마감');
      final full = GardenEventSession.tryFromJson({
        ...sessionJson(),
        'reservedCount': 5,
      })!;
      expect(full.canBookAt(open), isFalse);
      expect(full.availabilityAt(open), '정원 마감');
      final canceled = GardenEventSession.tryFromJson({
        ...sessionJson(),
        'state': 'canceled',
      })!;
      expect(canceled.canBookAt(open), isFalse);
      expect(canceled.availabilityAt(open), '취소된 일정');
    },
  );

  test('malformed session data does not become an actionable slot', () {
    final notice = Notice.fromJson({
      'sessions': [
        {'id': 'missing-dates'},
        {...sessionJson(), 'endsAt': 'invalid'},
        null,
        sessionJson(),
      ],
    });
    expect(notice.sessions.length, 1);
  });

  testWidgets(
    'evening template stays an editable local draft and fits a 360px screen',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: GardenNewsEditorScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('함께 편지 쓰는 저녁 · 초안 불러오기'));
      await tester.pump();
      expect(find.text('함께 편지 쓰는 저녁'), findsOneWidget);
      await tester.tap(find.text('추가 정보 (선택)'));
      await tester.pumpAndSettle();
      final type = tester.widget<DropdownButtonFormField<NoticeType>>(
        find.byType(DropdownButtonFormField<NoticeType>),
      );
      expect(type.initialValue, NoticeType.event);
      final status = tester.widget<DropdownButtonFormField<NoticeStatus?>>(
        find.byType(DropdownButtonFormField<NoticeStatus?>),
      );
      expect(status.initialValue, NoticeStatus.recruiting);
      expect(find.byType(GardenNewsEditorScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('예약 받기 (선택)'));
      await tester.tap(find.text('예약 받기 (선택)'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('예약 날짜 추가'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('예약 날짜 추가'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dated notice remains readable on 360px at larger text and does not fake offline confirmation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final notice = Notice.fromJson({
        'id': 'offline-test',
        'title': '함께 편지 쓰는 저녁',
        'body': '각자의 편지를 쓰고 조용히 쉬는 모임이에요.',
        'type': 'event',
        'eventMode': 'online',
        'sessions': [sessionJson()],
      });
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: NoticeDetailScreen(notice: notice),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(GardenBookingCalendar),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(find.text('신청이 완료됐어요.'), findsNothing);
      expect(find.text('연결 다시 확인'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('successful booking stays confirmed if all later reads fail', (
    tester,
  ) async {
    var reads = 0;
    final noticeJson = {
      'id': 'legacy',
      'title': '편지 모임',
      'capacity': 4,
      'reservedCount': 0,
    };
    final service = GardenEventService(
      currentOwner: () => 'alice',
      backendEnabled: () => true,
      transport: (action, body, owner) async {
        if (action == 'getGardenNews') return {'news': noticeJson};
        if (action == 'myGardenNewsReservations') {
          if (++reads > 1) {
            throw const CloudException('temporarily-unavailable');
          }
          return {'reservations': []};
        }
        if (action == 'reserveGardenNews') {
          return {
            'reserved': true,
            'reservation': {'newsId': 'legacy'},
            'news': {...noticeJson, 'reservedCount': 1},
          };
        }
        throw StateError('unexpected action');
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NoticeDetailScreen(
          notice: Notice.fromJson(noticeJson),
          eventService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('선택한 모임 신청하기'));
    await tester.tap(find.text('선택한 모임 신청하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('신청 확인'));
    await tester.pumpAndSettle();
    expect(find.text('신청이 완료됐어요.'), findsOneWidget);
    expect(find.text('신청 취소하기'), findsOneWidget);
    expect(reads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy removed capacity never hides an existing cancellation', (
    tester,
  ) async {
    final noticeJson = {
      'id': 'legacy',
      'title': '기존 모임',
      'capacity': null,
      'reservedCount': 1,
    };
    final service = GardenEventService(
      currentOwner: () => 'alice',
      transport: (action, body, owner) async => action == 'getGardenNews'
          ? {'news': noticeJson}
          : {
              'reservations': [
                {'newsId': 'legacy'},
              ],
            },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NoticeDetailScreen(
          notice: Notice.fromJson(noticeJson),
          eventService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('신청이 완료됐어요.'), findsOneWidget);
    expect(find.text('신청 취소하기'), findsOneWidget);
    expect(find.text('선택한 모임 신청하기'), findsNothing);
  });

  testWidgets(
    'my bookings display real dates and cancel without another fetch at 360px',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var reads = 0;
      final service = GardenEventService(
        currentOwner: () => 'alice',
        transport: (action, body, owner) async {
          if (action == 'cancelGardenNewsReservation') {
            return {'canceled': true};
          }
          reads++;
          return {
            'reservations': [
              {
                'newsId': 'evening',
                'sessionId': 'evening',
                'sessionStartsAt': sessionJson()['startsAt'],
                'news': {
                  'id': 'evening',
                  'title': '함께 편지 쓰는 저녁',
                  'sessions': [sessionJson()],
                },
              },
            ],
          };
        },
      );
      await tester.pumpWidget(
        MaterialApp(home: MyGardenReservationsScreen(service: service)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('2026.11.02'), findsOneWidget);
      expect(find.text('함께 편지 쓰는 저녁'), findsOneWidget);
      await tester.tap(find.text('신청 취소하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('신청 취소'));
      await tester.pumpAndSettle();
      expect(find.text('아직 신청한 모임이 없어요.'), findsOneWidget);
      expect(reads, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
