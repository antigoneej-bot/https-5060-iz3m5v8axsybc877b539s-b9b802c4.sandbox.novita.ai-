import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/backup_fingerprint.dart';

void main() {
  Map<String, dynamic> snapshot(String text) => {
    'schema': 1,
    'createdAt': 'first',
    'boxes': {
      'letters': [
        {'key': 'b', 'value': text},
        {'key': 'a', 'value': 'kept'},
      ],
    },
    'settings': {
      'companion': {'type': 'string', 'value': '냥이'},
    },
  };
  test(
    'timestamps, map order and Hive insertion order do not upload duplicates',
    () async {
      final first = snapshot('hello');
      final second = {
        'settings': first['settings'],
        'boxes': {
          'letters': (first['boxes'] as Map)['letters'].reversed.toList(),
        },
        'createdAt': 'later',
        'schema': 1,
      };
      expect(await backupFingerprint(first), await backupFingerprint(second));
    },
  );
  test(
    'new edits and deletions remain distinguishable from last uploaded snapshot',
    () async {
      final first = await backupFingerprint(snapshot('original'));
      expect(
        await backupFingerprint(snapshot('changed during upload')),
        isNot(first),
      );
      final removed = snapshot('original');
      removed['boxes'] = {'letters': <Map<String, String>>[]};
      expect(await backupFingerprint(removed), isNot(first));
    },
  );
  test('preferences and ordered memory timelines count as changes', () async {
    final first = snapshot('first');
    final second = snapshot('first');
    (second['settings'] as Map)['companion']['value'] = '새 이름';
    expect(
      await backupFingerprint(first),
      isNot(await backupFingerprint(second)),
    );
  });
}
