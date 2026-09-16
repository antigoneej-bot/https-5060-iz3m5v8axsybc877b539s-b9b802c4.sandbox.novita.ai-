import '../lib/services/access_policy.dart';

void require(bool value, String label) {
  if (!value) throw StateError(label);
}

void main() {
  require(AccessPolicy.adsAllowed(false), 'free ads allowed');
  require(!AccessPolicy.adsAllowed(true), 'premium and trial ads blocked');
  require(!AccessPolicy.adsAllowed(null), 'unknown entitlement ads blocked');
  require(AccessPolicy.freeMeditations.length == 2, 'exactly two free guides');
  require(AccessPolicy.meditationAllowed('forestRest', false), 'free forest');
  require(
    AccessPolicy.meditationAllowed('rainThunderRest', false),
    'free rain',
  );
  require(
    !AccessPolicy.meditationAllowed('singingBowlRest', false),
    'locked singing bowls',
  );
  require(
    AccessPolicy.meditationAllowed('singingBowlRest', true),
    'subscriber meditation',
  );
  require(!AccessPolicy.itemAllowed(false), 'free items locked');
  require(AccessPolicy.itemAllowed(true), 'subscriber items allowed');
  require(
    AccessPolicy.newReplyAllowed(premium: false, used: 0),
    'first free reply',
  );
  require(
    !AccessPolicy.newReplyAllowed(premium: false, used: 1),
    'second reply locked',
  );
  require(
    AccessPolicy.newReplyAllowed(premium: true, used: 99),
    'premium replies',
  );
  require(
    AccessPolicy.dayKey(DateTime(2026, 9, 16, 23, 59)) == '2026-09-16',
    'day before reset',
  );
  require(
    AccessPolicy.dayKey(DateTime(2026, 9, 17)) == '2026-09-17',
    'day after reset',
  );
  const month = StorePhase('P1M', 'KRW', 4900000000, 0);
  const year = StorePhase('P1Y', 'KRW', 29000000000, 0);
  const trial = StorePhase('P15D', 'KRW', 0, 1);
  require(
    SubscriptionOfferPolicy.accepts([month], yearly: false),
    'monthly 4900',
  );
  require(
    SubscriptionOfferPolicy.accepts([year], yearly: true),
    'yearly 29000',
  );
  require(
    SubscriptionOfferPolicy.accepts([trial, month], yearly: false),
    '15-day eligible offer',
  );
  require(
    !SubscriptionOfferPolicy.accepts([
      const StorePhase('P1M', 'KRW', 3900000000, 0),
    ], yearly: false),
    'reject old 3900',
  );
  require(
    !SubscriptionOfferPolicy.accepts([
      const StorePhase('P7D', 'KRW', 0, 1),
      month,
    ], yearly: false),
    'reject 7-day offer',
  );
  require(
    !SubscriptionOfferPolicy.accepts([month], yearly: true),
    'reject incorrect renewal period',
  );
  require(
    !SubscriptionOfferPolicy.accepts([
      const StorePhase('P1M', 'KRW', 4900000000, 1),
    ], yearly: false),
    'reject non-recurring offer',
  );
  require(
    !SubscriptionOfferPolicy.accepts([], yearly: false),
    'no product no purchase',
  );
  require(!SubscriptionOfferPolicy.hasTrial([month]), 'no false trial promise');
  print('PASS: 24 subscription policy checks');
}
