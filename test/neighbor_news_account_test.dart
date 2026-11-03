import 'dart:async';
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
    await t.pumpWidget(const SizedBox());
  });
}
