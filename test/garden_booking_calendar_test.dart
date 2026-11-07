import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_app/models/notice.dart';
import 'package:flutter_app/screens/garden_event_schedule_screen.dart';
import 'package:flutter_app/screens/notice_detail_screen.dart';
import 'package:flutter_app/services/garden_event_service.dart';
import 'package:flutter_app/widgets/garden_booking_calendar.dart';

GardenEventSession slot(String id, int day, {int hour = 14, int count = 0}) =>
    GardenEventSession(
      id: id,
      startsAt: DateTime(2050, 1, day, hour),
      endsAt: DateTime(2050, 1, day, hour + 1),
      bookingClosesAt: DateTime(2050, 1, day, hour),
      capacity: 4,
      reservedCount: count,
    );

Future<void> enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(ValueKey(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> saveSchedule(WidgetTester tester) async {
  final button = find.text('날짜와 시간 저장');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> openEditor(
  WidgetTester tester,
  GardenEventSession existing,
  ValueChanged<GardenEventSession?> result, {
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result(
              await Navigator.push<GardenEventSession>(
                context,
                MaterialPageRoute(
                  builder: (_) => GardenEventScheduleScreen(existing: existing),
                ),
              ),
            ),
            child: const Text('일정 열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('일정 열기'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  testWidgets(
    'calendar groups server times, rejects full slots and clears time on date change',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? selected;
      final sessions = [
        slot('first', 14),
        slot('full', 14, hour: 16, count: 4),
        slot('next', 15),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: GardenBookingCalendar(
                  sessions: sessions,
                  selectedId: selected,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      );
      final calendar = tester.widget<CalendarDatePicker>(
        find.byType(CalendarDatePicker),
      );
      expect(calendar.selectableDayPredicate!(DateTime(2050, 1, 13)), isFalse);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('booking-time-full')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('booking-time-first')));
      await tester.pumpAndSettle();
      expect(selected, 'first');
      await tester.tap(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text('15'),
        ),
      );
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.byKey(const ValueKey('booking-time-first')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('booking-time-next')));
      await tester.pump();
      expect(selected, 'next');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('busy booking calendar cannot change the selected day or time', (
    tester,
  ) async {
    String? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GardenBookingCalendar(
            sessions: [slot('first', 14), slot('next', 15)],
            selectedId: 'first',
            enabled: false,
            onChanged: (value) => changed = value ?? 'cleared',
          ),
        ),
      ),
    );
    // Touch the blocked day as a user would; no callback is forced.
    await tester.tapAt(
      tester.getCenter(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text('15'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(changed, isNull);
    expect(find.byKey(const ValueKey('booking-time-first')), findsOneWidget);
    expect(find.byKey(const ValueKey('booking-time-next')), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('booking-time-first')),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'calendar and numeric fields save exact selected date with simple defaults at 360px',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      GardenEventSession? saved;
      await openEditor(
        tester,
        slot('edit-me', 14),
        (value) => saved = value,
        scale: 1.3,
      );
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(find.byType(TimePickerDialog), findsNothing);
      await tester.tap(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text('15'),
        ),
      );
      await tester.pump();
      await enter(tester, 'schedule-시작-시', '14');
      await enter(tester, 'schedule-시작-분', '30');
      await enter(tester, 'schedule-종료-시', '15');
      await enter(tester, 'schedule-종료-분', '45');
      await enter(tester, 'schedule-capacity', '8');
      await saveSchedule(tester);
      expect(saved?.id, 'edit-me');
      expect(saved?.startsAt, DateTime(2050, 1, 15, 14, 30));
      expect(saved?.endsAt, DateTime(2050, 1, 15, 15, 45));
      expect(saved?.bookingClosesAt, saved?.startsAt);
      expect(saved?.bookingOpensAt, isNull);
      expect(saved?.capacity, 8);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('invalid numeric times and reversed end time cannot be saved', (
    tester,
  ) async {
    GardenEventSession? saved;
    await openEditor(tester, slot('edit-me', 14), (value) => saved = value);
    await enter(tester, 'schedule-시작-시', '25');
    await saveSchedule(tester);
    expect(saved, isNull);
    expect(find.text('시간은 0~23시, 분은 0~59분으로 입력해 주세요.'), findsWidgets);
    await enter(tester, 'schedule-시작-시', '16');
    await saveSchedule(tester);
    expect(saved, isNull);
    expect(find.text('종료 시간을 시작 시간보다 늦게 입력해 주세요.'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'booked schedule locks date/time, retains exact instants and protects reserved seats',
    (tester) async {
      final start = DateTime.utc(2050, 1, 14, 4, 30, 37);
      final existing = GardenEventSession(
        id: 'booked',
        startsAt: start,
        endsAt: start.add(const Duration(hours: 1)),
        bookingClosesAt: start,
        capacity: 4,
        reservedCount: 3,
      );
      GardenEventSession? saved;
      await openEditor(tester, existing, (value) => saved = value);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('schedule-시작-시')))
            .enabled,
        isFalse,
      );
      await enter(tester, 'schedule-capacity', '2');
      await saveSchedule(tester);
      expect(saved, isNull);
      expect(find.text('이미 신청한 인원보다 줄일 수 없어요.'), findsOneWidget);
      await enter(tester, 'schedule-capacity', '5');
      await saveSchedule(tester);
      expect(saved?.startsAt, existing.startsAt);
      expect(saved?.endsAt, existing.endsAt);
      expect(saved?.id, existing.id);
      expect(saved?.reservedCount, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid extra time remains validated after extra settings collapse',
    (tester) async {
      final first = slot('with-deadline', 14);
      final existing = GardenEventSession(
        id: first.id,
        startsAt: first.startsAt,
        endsAt: first.endsAt,
        bookingOpensAt: DateTime(2050, 1, 1),
        bookingClosesAt: first.startsAt,
        capacity: 4,
      );
      GardenEventSession? saved;
      await openEditor(tester, existing, (value) => saved = value);
      await enter(tester, 'schedule-신청 시작-시', '');
      final advanced = find.text('추가 설정 · 신청 기간과 일정 이름');
      await tester.ensureVisible(advanced);
      await tester.tap(advanced);
      await tester.pump();
      await saveSchedule(tester);
      expect(saved, isNull);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('schedule-신청 시작-시')), findsOneWidget);
    },
  );

  testWidgets(
    'reservation confirmation sends only the time chosen on the new calendar day',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final news = {
        'id': 'class',
        'title': '정원 클래스',
        'type': 'event',
        'sessions': [slot('first', 14).toInput(), slot('second', 15).toInput()],
      };
      String? reserved;
      final service = GardenEventService(
        currentOwner: () => 'alice',
        backendEnabled: () => true,
        transport: (action, body, owner) async {
          if (action == 'getGardenNews') return {'news': news};
          if (action == 'myGardenNewsReservations') return {'reservations': []};
          if (action == 'reserveGardenNews') {
            reserved = body['sessionId'] as String?;
            return {
              'reserved': true,
              'reservation': {'newsId': 'class', 'sessionId': reserved},
              'news': news,
            };
          }
          throw StateError(action);
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: NoticeDetailScreen(
            notice: Notice.fromJson(news),
            eventService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(CalendarDatePicker));
      await tester.tap(
        find.descendant(
          of: find.byType(CalendarDatePicker),
          matching: find.text('15'),
        ),
      );
      await tester.pumpAndSettle();
      final time = find.byKey(const ValueKey('booking-time-second'));
      await tester.ensureVisible(time);
      await tester.tap(time);
      await tester.pump();
      final book = find.text('선택한 모임 신청하기');
      await Scrollable.ensureVisible(tester.element(book), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(book);
      await tester.pumpAndSettle();
      expect(find.text('예약 확인'), findsOneWidget);
      expect(find.textContaining('2050.01.15'), findsWidgets);
      await tester.tap(find.text('신청 확인'));
      await tester.pumpAndSettle();
      expect(reserved, 'second');
      expect(find.text('신청이 완료됐어요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
