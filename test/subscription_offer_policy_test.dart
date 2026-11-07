import 'package:flutter_app/services/access_policy.dart';
import 'package:flutter_test/flutter_test.dart';

StorePhase phase(
  String period,
  int price, {
  int cycles = 0,
  StoreRecurrence recurrence = StoreRecurrence.infinite,
  String currency = 'KRW',
}) => StorePhase(period, currency, price, cycles, recurrence: recurrence);

void main() {
  test('annual store price and 12-month notation are supported', () {
    for (final period in ['P1Y', 'P12M']) {
      for (final price in [29000000000, 55000000000, 59000000000]) {
        expect(
          SubscriptionOfferPolicy.accepts([phase(period, price)], yearly: true),
          isTrue,
        );
      }
    }
    expect(
      SubscriptionOfferPolicy.accepts([phase('P1M', 4900000000)], yearly: true),
      isFalse,
    );
    expect(
      SubscriptionOfferPolicy.accepts([
        phase('P1Y', 29000000000),
      ], yearly: false),
      isFalse,
    );
  });
  test(
    'eligible trials and introductory prices retain their real duration',
    () {
      for (final trial in ['P7D', 'P15D', 'P1M']) {
        final phases = [
          phase(trial, 0, cycles: 1, recurrence: StoreRecurrence.finite),
          phase('P1Y', 55000000000),
        ];
        expect(SubscriptionOfferPolicy.accepts(phases, yearly: true), isTrue);
        expect(SubscriptionOfferPolicy.hasTrial(phases), isTrue);
      }
      expect(
        SubscriptionOfferPolicy.accepts([
          phase(
            'P1M',
            1000000000,
            cycles: 3,
            recurrence: StoreRecurrence.finite,
          ),
          phase('P1Y', 55000000000),
        ], yearly: true),
        isTrue,
      );
    },
  );
  test(
    'prepaid, free recurring, malformed and mixed currency offers are blocked',
    () {
      for (final phases in <List<StorePhase>>[
        [],
        [phase('P1Y', 0)],
        [phase('P1Y', 55000000000, recurrence: StoreRecurrence.none)],
        [
          phase(
            'P1Y',
            55000000000,
            cycles: 1,
            recurrence: StoreRecurrence.finite,
          ),
        ],
        [
          phase('invalid', 0, cycles: 1, recurrence: StoreRecurrence.finite),
          phase('P1Y', 55000000000),
        ],
        [
          phase(
            'P7D',
            0,
            cycles: 1,
            currency: 'USD',
            recurrence: StoreRecurrence.finite,
          ),
          phase('P1Y', 55000000000),
        ],
      ]) {
        expect(SubscriptionOfferPolicy.accepts(phases, yearly: true), isFalse);
      }
    },
  );
}
