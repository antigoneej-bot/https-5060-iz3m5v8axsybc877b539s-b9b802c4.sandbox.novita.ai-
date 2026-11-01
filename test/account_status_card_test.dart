import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/account_status_summary.dart';
import 'package:flutter_app/services/account_status_source.dart';
import 'package:flutter_app/widgets/account_status_card.dart';

class FakeSource extends AccountStatusSource {
  String? owner = 'a';
  final events = StreamController<String?>.broadcast();
  late Future<AccountStatusSnapshot> Function(bool) read;
  @override
  String? get currentUid => owner;
  @override
  Stream<String?> get accountChanges => events.stream;
  @override
  Future<AccountStatusSnapshot> load({bool refresh = false}) => read(refresh);
}

AccountStatusSnapshot snapshot(String owner, String title) =>
    AccountStatusSnapshot(
      owner: owner,
      provider: owner == 'a' ? '카카오' : '네이버',
      subscription: SubscriptionStatusSummary(title, '결제한 기간까지 이용해요.'),
      backup: BackupStatusSummary(
        enabled: true,
        lastConfirmedAt: DateTime(2026, 10, 24, 10),
      ),
    );

void main() {
  final now = DateTime.utc(2026, 10, 24, 9);
  Map<String, dynamic> record({String state = 'active'}) => {
    'active': true,
    'state': state,
    'checkedAt': now.toIso8601String(),
    'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
    'autoRenewEnabled': true,
    'productId': 'garden_plus_monthly',
  };
  test('monthly and annual renewal use verified plan and timestamp', () {
    final data = record();
    expect(
      SubscriptionStatusSummary.fromRecord(data, now: now).title,
      '월간 구독 이용 중',
    );
    expect(
      SubscriptionStatusSummary.fromRecord(data, now: now).detail,
      contains('다음 갱신 예정'),
    );
    data['productId'] = 'garden_plus_yearly';
    data['autoRenewEnabled'] = null;
    final yearly = SubscriptionStatusSummary.fromRecord(data, now: now);
    expect(yearly.title, '연간 구독 이용 중');
    expect(yearly.detail, isNot(contains('다음 갱신 예정')));
  });
  test('cancellation retains paid period; expiry does not look active', () {
    final data = record(state: 'cancelScheduled');
    final canceled = SubscriptionStatusSummary.fromRecord(data, now: now);
    expect(canceled.title, contains('해지 예약'));
    expect(canceled.detail, contains('까지 이용 가능'));
    data['expiresAt'] = now.toIso8601String();
    expect(
      SubscriptionStatusSummary.fromRecord(data, now: now).title,
      '구독 이용 기간 종료',
    );
  });
  test('unknown stale or future cache never announces free or active', () {
    for (final data in <Map?>[
      null,
      {},
      {...record(), 'checkedAt': 'invalid'},
      {
        ...record(),
        'checkedAt': now.subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        ...record(),
        'checkedAt': now.add(const Duration(days: 1)).toIso8601String(),
      },
    ]) {
      final summary = SubscriptionStatusSummary.fromRecord(data, now: now);
      expect(summary.title, contains('확인 필요'));
    }
    expect(
      SubscriptionStatusSummary.fromRecord({
        ...record(),
        'active': false,
        'state': 'free',
        'expiresAt': null,
      }, now: now).title,
      '무료 이용 중',
    );
  });
  test('backup confirms a dated copy, never all current records', () {
    final state = BackupStatusSummary(enabled: false, lastConfirmedAt: now);
    expect(state.title, '자동 백업 꺼짐');
    expect(state.detail, contains('마지막 서버 백업'));
    expect(state.detail, contains('그 뒤 남긴 기록'));
    expect(
      const BackupStatusSummary(enabled: true).detail,
      contains('확인한 서버 백업이 없어요'),
    );
  });

  Future<void> show(
    WidgetTester tester,
    FakeSource source, {
    Future<void> Function()? subscription,
    Future<void> Function()? backup,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AccountStatusCard(
              source: source,
              openSubscription: subscription,
              openBackup: backup,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('large text shows status and both real management entrances', (
    tester,
  ) async {
    final source = FakeSource()
      ..read = (_) async => snapshot('a', '연간 구독 이용 중');
    addTearDown(source.events.close);
    var subscriptions = 0, backups = 0;
    await show(
      tester,
      source,
      subscription: () async {
        subscriptions++;
      },
      backup: () async {
        backups++;
      },
    );
    expect(find.text('카카오 로그인 계정'), findsOneWidget);
    expect(find.text('연간 구독 이용 중'), findsOneWidget);
    for (final label in ['구독 관리·구매 복원', '기록 백업·복원']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(subscriptions, 1);
    expect(backups, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('old account response cannot overwrite new account status', (
    tester,
  ) async {
    final old = Completer<AccountStatusSnapshot>();
    final source = FakeSource();
    source.read = (_) => source.owner == 'a'
        ? old.future
        : Future.value(snapshot('b', '무료 이용 중'));
    addTearDown(source.events.close);
    await show(tester, source);
    source.owner = 'b';
    source.events.add('b');
    await tester.pumpAndSettle();
    old.complete(snapshot('a', '월간 구독 이용 중'));
    await tester.pumpAndSettle();
    expect(find.text('네이버 로그인 계정'), findsOneWidget);
    expect(find.text('월간 구독 이용 중'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'refresh failure preserves last status and explains uncertainty',
    (tester) async {
      final source = FakeSource();
      source.read = (refresh) async {
        if (refresh) throw StateError('offline');
        return snapshot('a', '월간 구독 이용 중');
      };
      addTearDown(source.events.close);
      await show(tester, source);
      await tester.ensureVisible(find.text('상태 새로고침'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('상태 새로고침'));
      await tester.pumpAndSettle();
      expect(find.text('월간 구독 이용 중'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-status-error')),
        findsOneWidget,
      );
      expect(find.text('무료 이용 중'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
