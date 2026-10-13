import '../lib/mongi/models/public_garden_status.dart';

void main() {
  var count = 0;
  void check(bool value, String reason) {
    if (!value) throw StateError(reason);
    count++;
  }

  final status = PublicGardenStatus();
  status.selectOwner('a', cachedNickname: '정원');
  check(
    status.published == null,
    'An editing hint cannot declare private status.',
  );
  final first = status.begin('a');
  status.apply(first, 'a', const PublicGardenStatusSnapshot(true, '정원'));
  check(
    status.published == true,
    'A new device must discover existing publication.',
  );

  final refresh = status.begin('a');
  status.fail(refresh, 'a');
  check(
    status.published == null,
    'Failed reads must not claim private status.',
  );
  final unpublish = status.begin('a');
  status.fail(unpublish, 'a');
  check(status.published == null, 'A lost unpublish response is unknown.');

  final old = status.begin('a');
  status.selectOwner('b');
  check(
    status.nickname == null && status.published == null,
    'Account B cannot inherit A hints/status.',
  );
  check(
    !status.apply(old, 'a', const PublicGardenStatusSnapshot(true, 'A')),
    'Ignore late previous-account response.',
  );
  final b = status.begin('b');
  status.apply(b, 'b', const PublicGardenStatusSnapshot(false, null));
  check(
    status.published == false,
    'An explicit server acknowledgement can declare private.',
  );

  final beforeChange = status.begin('b');
  final afterChange = status.begin('b');
  status.apply(afterChange, 'b', const PublicGardenStatusSnapshot(false, null));
  check(
    !status.apply(
      beforeChange,
      'b',
      const PublicGardenStatusSnapshot(true, 'B'),
    ),
    'An older read cannot replace an acknowledged publication change.',
  );
  check(
    !status.fail(beforeChange, 'b') && status.published == false,
    'An older failure cannot replace a newer decision.',
  );

  status.selectOwner(null);
  check(
    status.published == null && status.nickname == null,
    'Logout removes account state.',
  );
  var rejected = false;
  try {
    PublicGardenStatusSnapshot.fromJson({'error': 'temporarily-unavailable'});
  } on FormatException {
    rejected = true;
  }
  check(rejected, 'Malformed server replies are never false/private.');
  print('Public garden status: $count checks passed.');
}
