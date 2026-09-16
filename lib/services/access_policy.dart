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
  const StorePhase(this.period, this.currency, this.micros, this.cycles);
}

class SubscriptionOfferPolicy {
  static bool hasTrial(List<StorePhase> phases) =>
      phases.length == 2 &&
      phases.first.micros == 0 &&
      phases.first.period == 'P15D' &&
      phases.first.cycles == 1;
  static bool accepts(List<StorePhase> phases, {required bool yearly}) {
    if (phases.isEmpty || (phases.length > 1 && !hasTrial(phases)))
      return false;
    final recurring = phases.last;
    if (recurring.period != (yearly ? 'P1Y' : 'P1M') ||
        recurring.micros <= 0 ||
        recurring.cycles != 0)
      return false;
    return recurring.currency != 'KRW' ||
        recurring.micros == (yearly ? 29000 : 4900) * 1000000;
  }
}
