/// Product policy shared by all entry points. Does not store user content.
class AccessPolicy {
  static const freeMeditations = {'forestRest', 'rainThunderRest'};
  static const freeRepliesPerDay = 1;
  static const trialDays = 15;
  static bool meditationAllowed(String key, bool premium) =>
      premium || freeMeditations.contains(key);
  static bool adsAllowed(bool? premium) => premium == false;
  static bool itemAllowed(bool premium) => premium;
  static bool newReplyAllowed({required bool premium, required int used}) =>
      premium || used < freeRepliesPerDay;
  static String dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class SubscriptionRequired implements Exception {
  final String message;
  const SubscriptionRequired([this.message = '마음냥 구독으로 함께 이용할 수 있어요.']);
  @override
  String toString() => message;
}

/// Store phase data kept independent of UI and platform plugins for testing.
class StorePhase {
  final String period, currency;
  final int micros, cycles;
  final StoreRecurrence recurrence;
  const StorePhase(
    this.period,
    this.currency,
    this.micros,
    this.cycles, {
    required this.recurrence,
  });
}

enum StoreRecurrence { infinite, finite, none }

class SubscriptionOfferPolicy {
  static bool hasTrial(List<StorePhase> phases) =>
      phases.length > 1 &&
      phases.first.micros == 0 &&
      phases.first.recurrence == StoreRecurrence.finite &&
      phases.first.cycles > 0;
  static bool accepts(List<StorePhase> phases, {required bool yearly}) {
    if (phases.isEmpty) return false;
    final recurring = phases.last;
    if (!(yearly ? {'P1Y', 'P12M'} : {'P1M'}).contains(recurring.period) ||
        recurring.micros <= 0 ||
        recurring.cycles != 0 ||
        recurring.recurrence != StoreRecurrence.infinite ||
        recurring.currency.isEmpty) {
      return false;
    }
    // Play owns the price and eligible offers. A price change or a different
    // trial length must not silently remove an otherwise valid annual plan.
    return phases
        .take(phases.length - 1)
        .every(
          (phase) =>
              phase.recurrence == StoreRecurrence.finite &&
              phase.cycles > 0 &&
              phase.micros >= 0 &&
              phase.currency == recurring.currency &&
              RegExp(r'^P[1-9][0-9]*[DWMY]$').hasMatch(phase.period),
        );
  }
}
