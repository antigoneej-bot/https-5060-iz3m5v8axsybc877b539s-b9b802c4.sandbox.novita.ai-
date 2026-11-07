import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/notice.dart';
import 'package:flutter_app/screens/garden_news_editor_screen.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/garden_news_editor_service.dart';
import 'package:intl/date_symbol_data_local.dart';

class MemoryDrafts extends GardenNewsDraftStore {
  final Map<String, Map<String, dynamic>> records = {};
  @override
  Future<Map<String, dynamic>?> load(String key) async => records[key];
  @override
  Future<void> save(String key, Map<String, dynamic> value) async {
    records[key] = value;
  }

  @override
  Future<void> clear(String key) async {
    records.remove(key);
  }
}

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);
Finder get save => find.byKey(const Key('save-garden-news'));

Future<void> openEditor(
  WidgetTester tester,
  GardenNewsEditorService service,
  MemoryDrafts drafts, {
  Notice? existing,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GardenNewsEditorScreen(
                  service: service,
                  drafts: drafts,
                  existing: existing,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  testWidgets(
    'lost create response survives reopening and edited retry updates the same notice',
    (tester) async {
      final drafts = MemoryDrafts();
      final requests = <Map<String, dynamic>>[];
      final actions = <String>[];
      var loseResponse = true;
      final service = GardenNewsEditorService(
        currentOwner: () => 'operator',
        backendEnabled: () => true,
        transport: (action, body, owner) async {
          actions.add(action);
          requests.add(body);
          if (loseResponse) {
            loseResponse = false;
            throw TimeoutException('response-lost');
          }
          return {'id': 'same-notice'};
        },
      );
      await openEditor(tester, service, drafts);
      await tester.enterText(field('제목'), '첫 제목');
      await tester.enterText(field('내용'), '원래 내용');
      await tester.tap(save);
      await tester.pumpAndSettle();
      final key = requests.first['requestId'];
      expect(key, isNotEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(field('내용'), '고친 내용');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(actions, [
        'adminCreateGardenNews',
        'adminCreateGardenNews',
        'adminUpdateGardenNews',
      ]);
      expect(requests[1]['requestId'], key);
      expect(requests[1]['news'], requests.first['news']);
      expect(requests.last['id'], 'same-notice');
      expect(requests.last['news']['body'], '고친 내용');
      expect(drafts.records, isEmpty);
    },
  );

  testWidgets(
    'title and body publish once; incomplete fields do not block basic news',
    (tester) async {
      final drafts = MemoryDrafts();
      final receipt = Completer<Map<String, dynamic>>();
      final calls = <Map<String, dynamic>>[];
      final service = GardenNewsEditorService(
        currentOwner: () => 'operator',
        backendEnabled: () => true,
        transport: (action, body, owner) {
          expect(action, 'adminCreateGardenNews');
          calls.add(body);
          return receipt.future;
        },
      );
      await openEditor(tester, service, drafts);
      await tester.enterText(field('제목'), '이번 주 정원소식');
      await tester.enterText(field('내용'), '편하게 쉬어 가세요.');
      await tester.pump(const Duration(milliseconds: 500));
      expect(drafts.records['garden_news:operator:new']?['title'], '이번 주 정원소식');
      await tester.tap(save);
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(calls, hasLength(1));
      final news = calls.single['news'] as Map;
      expect(news['type'], 'info');
      expect(news['sessions'], isEmpty);
      expect(news['capacity'], isNull);
      receipt.complete({'id': 'created'});
      await tester.pumpAndSettle();
      expect(find.byType(GardenNewsEditorScreen), findsNothing);
      expect(find.text('저장했어요. 정원소식에 공개됐어요.'), findsOneWidget);
      expect(drafts.records, isEmpty);
    },
  );

  testWidgets(
    'evening template can publish as an announcement without mandatory dates',
    (tester) async {
      Map<String, dynamic>? posted;
      final service = GardenNewsEditorService(
        currentOwner: () => 'operator',
        backendEnabled: () => true,
        transport: (a, b, o) async {
          posted = b['news'] as Map<String, dynamic>;
          return {'id': 'evening'};
        },
      );
      await openEditor(tester, service, MemoryDrafts());
      await tester.tap(find.text('함께 편지 쓰는 저녁 · 초안 불러오기'));
      await tester.pumpAndSettle();
      expect(posted, isNull);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(posted?['title'], '함께 편지 쓰는 저녁');
      expect(posted?['sessions'], isEmpty);
      expect(posted?['capacity'], isNull);
      expect(find.byType(GardenNewsEditorScreen), findsNothing);
    },
  );

  testWidgets(
    'empty required field shows a visible error near fixed save button at 360px',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var calls = 0;
      final service = GardenNewsEditorService(
        currentOwner: () => 'operator',
        backendEnabled: () => true,
        transport: (a, b, o) async {
          calls++;
          return {'id': 'saved'};
        },
      );
      await openEditor(tester, service, MemoryDrafts());
      await tester.tap(find.text('추가 정보 (선택)'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -900),
      );
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('제목을 입력해 주세요.'), findsOneWidget);
      expect(
        tester.getRect(find.text('제목을 입력해 주세요.')).bottom,
        lessThan(tester.getRect(save).top),
      );
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(800));
      expect(tester.takeException(), isNull);
      expect(calls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'failed publish keeps draft across reopening; account switch cannot publish it',
    (tester) async {
      var owner = 'operator';
      final drafts = MemoryDrafts();
      var calls = 0;
      final service = GardenNewsEditorService(
        currentOwner: () => owner,
        backendEnabled: () => true,
        transport: (a, b, o) async {
          calls++;
          throw const CloudException('admin-required');
        },
      );
      await openEditor(tester, service, drafts);
      await tester.enterText(field('제목'), '잃으면 안 되는 제목');
      await tester.enterText(field('내용'), '작성한 긴 안내문');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(GardenNewsEditorScreen), findsOneWidget);
      expect(find.text('저장했어요. 정원소식에 공개됐어요.'), findsNothing);
      expect(drafts.records['garden_news:operator:new']?['body'], '작성한 긴 안내문');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('제목')).controller!.text,
        '잃으면 안 되는 제목',
      );
      owner = 'another';
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(calls, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field('제목')).controller!.text, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'optional URL gets https prefix and clearing status is sent explicitly',
    (tester) async {
      Map<String, dynamic>? news;
      final service = GardenNewsEditorService(
        currentOwner: () => 'operator',
        backendEnabled: () => true,
        transport: (a, b, o) async {
          news = b['news'] as Map<String, dynamic>;
          return {'id': 'original'};
        },
      );
      final existing = Notice.fromJson({
        'id': 'original',
        'title': '소식',
        'body': '본문',
        'applyUrl': 'example.com/book',
      });
      await openEditor(tester, service, MemoryDrafts(), existing: existing);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(news?['applyUrl'], 'https://example.com/book');
      expect(news!.containsKey('status'), isTrue);
      expect(news!['status'], isNull);
    },
  );

  testWidgets(
    'legacy booked notice cannot drop capacity while simplifying save',
    (tester) async {
      var calls = 0;
      final service = GardenNewsEditorService(
        currentOwner: () => 'operator',
        backendEnabled: () => true,
        transport: (a, b, o) async {
          calls++;
          return {'id': 'original'};
        },
      );
      final existing = Notice.fromJson({
        'id': 'original',
        'title': '모임',
        'body': '본문',
        'capacity': 5,
        'reservedCount': 2,
      });
      await openEditor(tester, service, MemoryDrafts(), existing: existing);
      await tester.ensureVisible(field('날짜 없이 신청받을 인원 (선택)'));
      await tester.enterText(field('날짜 없이 신청받을 인원 (선택)'), '');
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.textContaining('모집 정원을 신청 인원 이상'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'save and error stay above the keyboard with large text on a small phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(() {
        tester.view.resetViewInsets();
        tester.view.resetDevicePixelRatio();
        tester.binding.setSurfaceSize(null);
      });
      final service = GardenNewsEditorService(
        currentOwner: () => 'owner',
        backendEnabled: () => true,
        transport: (a, b, o) async => {'id': 'new'},
      );
      await openEditor(tester, service, MemoryDrafts(), textScale: 1.3);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(520));
      expect(find.text('제목을 입력해 주세요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'editing a booked dated event preserves the exact schedule and private meeting link',
    (tester) async {
      final slot = GardenEventSession(
        id: 'slot',
        startsAt: DateTime.utc(2026, 11, 2, 11),
        endsAt: DateTime.utc(2026, 11, 2, 12),
        bookingClosesAt: DateTime.utc(2026, 11, 2, 10),
        capacity: 5,
        reservedCount: 2,
      );
      final existing = Notice(
        id: 'event',
        title: '모임',
        body: '안내',
        emoji: '🌿',
        type: NoticeType.event,
        date: '',
        sessions: [slot],
        eventMode: 'online',
        meetingUrl: 'https://example.com/private',
      );
      Map<String, dynamic>? sent;
      final service = GardenNewsEditorService(
        currentOwner: () => 'owner',
        backendEnabled: () => true,
        transport: (a, b, o) async {
          expect(a, 'adminUpdateGardenNews');
          sent = b;
          return {'id': 'event'};
        },
      );
      await openEditor(tester, service, MemoryDrafts(), existing: existing);
      await tester.enterText(field('내용'), '수정된 안내');
      await tester.tap(save);
      await tester.pumpAndSettle();
      final news = sent!['news'] as Map;
      expect(news['sessions'], [slot.toInput()]);
      expect(news['meetingUrl'], 'https://example.com/private');
      expect(news['eventMode'], 'online');
    },
  );

  test(
    'busy rejection retries, but authorization and uncertain results do not',
    () async {
      var attempts = 0;
      var code = 'account-busy';
      final service = GardenNewsEditorService(
        currentOwner: () => 'owner',
        backendEnabled: () => true,
        wait: (_) async {},
        transport: (a, b, o) async {
          attempts++;
          if (attempts == 1 || code != 'account-busy') {
            throw CloudException(code);
          }
          return {'id': 'new'};
        },
      );
      expect(await service.save('owner', {}), 'new');
      expect(attempts, 2);
      attempts = 0;
      code = 'admin-required';
      await expectLater(
        service.save('owner', {}),
        throwsA(isA<CloudException>()),
      );
      expect(attempts, 1);
      final missing = GardenNewsEditorService(
        currentOwner: () => 'owner',
        backendEnabled: () => true,
        transport: (a, b, o) async => {},
      );
      await expectLater(
        missing.save('owner', {}),
        throwsA(
          isA<CloudException>().having(
            (e) => e.code,
            'code',
            'news-confirmation-missing',
          ),
        ),
      );
    },
  );
}
