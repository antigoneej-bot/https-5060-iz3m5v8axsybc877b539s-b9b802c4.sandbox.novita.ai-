import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_app/widgets/neighbor_news_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

class _News extends GardenVillageService {
  final people = Completer<GardenNeighborLists>();
  final cheers = Completer<ReceivedCheerBatch>();
  int peopleCalls = 0, cheerCalls = 0, orchardCalls = 0;
  @override
  Future<GardenNeighborLists> listNeighbors() {
    peopleCalls++;
    return people.future;
  }

  @override
  Future<ReceivedCheerBatch> listReceivedCheers({
    String? cursor,
    int pageSize = 30,
  }) {
    cheerCalls++;
    return cheers.future;
  }

  @override
  Future<Map<String, dynamic>> orchardState() async {
    orchardCalls++;
    return {
      'orchard': {'gifts': <dynamic>[]},
    };
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('compact news uses one delivery chain and no friend-list read', (
    t,
  ) async {
    final service = _News();
    await t.pumpWidget(
      MaterialApp(
        home: NeighborNewsBubble(
          service: service,
          currentAccount: () => 'compact_poll',
        ),
      ),
    );
    await t.pump();
    expect(service.peopleCalls, 0);
    expect(service.cheerCalls, 1);
    await t.pump(const Duration(seconds: 90));
    expect(
      service.cheerCalls,
      1,
      reason: 'An unfinished request must not be duplicated',
    );
    service.cheers.complete(const ReceivedCheerBatch());
    await t.pumpAndSettle();
    expect(service.orchardCalls, 1);
    await t.pump(const Duration(seconds: 45));
    await t.pumpAndSettle();
    expect(service.cheerCalls, 2);
    expect(service.orchardCalls, 2);
    expect(service.peopleCalls, 0);
    await t.pumpWidget(const SizedBox());
  });
  for (final stopped in ['hidden', 'background', 'covered', 'account']) {
    testWidgets('in-flight compact news stops follow-up reads when $stopped', (
      t,
    ) async {
      final service = _News();
      final nav = GlobalKey<NavigatorState>();
      var visible = true;
      String? account = 'stopped_$stopped';
      late StateSetter rebuild;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: StatefulBuilder(
            builder: (_, setState) {
              rebuild = setState;
              return TickerMode(
                enabled: visible,
                child: NeighborNewsBubble(
                  service: service,
                  currentAccount: () => account,
                ),
              );
            },
          ),
        ),
      );
      await t.pump();
      expect(service.cheerCalls, 1);
      if (stopped == 'hidden') {
        rebuild(() => visible = false);
        await t.pump();
      }
      if (stopped == 'background')
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      if (stopped == 'covered') {
        nav.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        );
        await t.pumpAndSettle();
      }
      if (stopped == 'account') account = 'other';
      service.cheers.complete(const ReceivedCheerBatch());
      await t.pumpAndSettle();
      expect(service.orchardCalls, 0);
      if (stopped != 'account') {
        await t.pump(const Duration(seconds: 90));
        expect(service.cheerCalls, 1);
      }
      await t.pumpWidget(const SizedBox());
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('expanded village reuses parent-owned neighbor snapshot', (
    t,
  ) async {
    final service = _News();
    service.cheers.complete(const ReceivedCheerBatch());
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeighborNewsBubble(
            expanded: true,
            neighbors: const GardenNeighborLists(),
            service: service,
            currentAccount: () => 'expanded_snapshot',
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(service.peopleCalls, 0);
    expect(service.cheerCalls, 1);
    expect(service.orchardCalls, 1);
    expect(find.text('받은 신청 0'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });

  for (final afterPeople in [false, true]) {
    testWidgets(
      'account switch stops notification chain after people=$afterPeople',
      (t) async {
        String? owner = 'account_a';
        final service = _News();
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NeighborNewsBubble(
                expanded: true,
                service: service,
                currentAccount: () => owner,
              ),
            ),
          ),
        );
        await t.pump();
        expect(service.peopleCalls, 1);
        if (afterPeople) {
          service.people.complete(const GardenNeighborLists());
          await t.pump();
          expect(service.cheerCalls, 1);
        }
        owner = 'account_b';
        if (afterPeople) {
          service.cheers.complete(const ReceivedCheerBatch());
        } else {
          service.people.complete(const GardenNeighborLists());
        }
        await t.pump();
        expect(service.cheerCalls, afterPeople ? 1 : 0);
        expect(service.orchardCalls, 0);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('signed out or hidden notification never requests account data', (
    t,
  ) async {
    final service = _News();
    await t.pumpWidget(
      MaterialApp(
        home: NeighborNewsBubble(service: service, currentAccount: () => null),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 46));
    expect(service.peopleCalls, 0);
    expect(service.cheerCalls, 0);
    expect(service.orchardCalls, 0);
    await t.pumpWidget(
      MaterialApp(
        home: TickerMode(
          enabled: false,
          child: NeighborNewsBubble(
            service: service,
            currentAccount: () => 'account_a',
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 46));
    expect(service.peopleCalls, 0);
    expect(service.cheerCalls, 0);
    expect(service.orchardCalls, 0);
    await t.pumpWidget(const SizedBox());
  });
}
