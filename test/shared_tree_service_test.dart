import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/services/shared_tree_service.dart';

Map<String, dynamic> treeJson({
  String role = 'guest',
  String status = 'active',
}) => {
  'id': 'tree-1',
  'name': '우리의 나무',
  'anniversaryOn': '2026-10-21',
  'myRole': role,
  'status': status,
  'guestStatus': status == 'invited' ? 'invited' : 'accepted',
  'activeDays': 2,
  'wateredToday': false,
  'notes': [],
};
void main() {
  test(
    'free invitee reads, accepts, waters and sends only explicit shared content',
    () async {
      final calls = <(String, Map<String, dynamic>)>[];
      final service = SharedTreeService(
        currentOwner: () => 'free-guest',
        transport: (action, body, owner) async {
          expect(owner, 'free-guest');
          calls.add((action, body));
          return action == 'listSharedTrees'
              ? {
                  'trees': [treeJson(status: 'invited')],
                  'nextCursor': null,
                }
              : {'tree': treeJson()};
        },
      );
      final page = await service.list();
      expect(page.trees.single.isInvitation, true);
      await service.respond('tree-1', accept: true);
      await service.water('tree-1');
      await service.addNote(
        'tree-1',
        text: ' 다녀갔어 ',
        requestId: 'request-1234567890123456',
      );
      expect(calls.map((c) => c.$1), [
        'listSharedTrees',
        'respondSharedTree',
        'waterSharedTree',
        'addSharedTreeNote',
      ]);
      expect(calls.last.$2, {
        'id': 'tree-1',
        'text': '다녀갔어',
        'requestId': 'request-1234567890123456',
      });
    },
  );
  test(
    'response belongs to originating account and a bound service cannot switch accounts',
    () async {
      var owner = 'alice';
      final pending = Completer<Map<String, dynamic>>();
      final service = SharedTreeService(
        currentOwner: () => owner,
        transport: (_, __, ___) => pending.future,
      );
      final future = service.get('tree-1');
      final assertion = expectLater(
        future,
        throwsA(
          isA<CloudException>().having(
            (e) => e.code,
            'code',
            'account-changed',
          ),
        ),
      );
      owner = 'bob';
      pending.complete({'tree': treeJson()});
      await assertion;
      await expectLater(
        service.get('tree-1'),
        throwsA(
          isA<CloudException>().having(
            (e) => e.code,
            'code',
            'account-changed',
          ),
        ),
      );
    },
  );
  test(
    'only pre-action account-busy retries preserve original idempotency request',
    () async {
      var attempts = 0;
      final sent = <Map<String, dynamic>>[];
      final service = SharedTreeService(
        currentOwner: () => 'host',
        retryDelay: (_) async {},
        transport: (_, body, __) async {
          sent.add(body);
          if (attempts++ == 0) throw const CloudException('account-busy');
          return {'tree': treeJson(role: 'host')};
        },
      );
      await service.create(
        gardenId: 'guest',
        name: '우리의 나무',
        anniversaryOn: '2026-10-21',
        requestId: 'create-request-12345678',
      );
      expect(sent.length, 2);
      expect(sent.first, sent.last);
    },
  );
  test('older backend is explained without simulated tree or people', () {
    expect(
      SharedTreeService.message(const CloudException('unknown-action')),
      contains('서버 업데이트'),
    );
  });
  test(
    'unread summary checks later pages and acknowledges only displayed version',
    () async {
      final calls = <(String, Map<String, dynamic>)>[];
      final service = SharedTreeService(
        currentOwner: () => 'guest',
        transport: (action, body, owner) async {
          calls.add((action, body));
          if (action == 'markSharedTreeSeen') return {'seen': true};
          return body['cursor'] == null
              ? {
                  'trees': [
                    {...treeJson(), 'unreadCount': 0},
                  ],
                  'nextCursor': 'page-two',
                }
              : {
                  'trees': [
                    {
                      ...treeJson(),
                      'unreadCount': 1,
                      'activityVersion': 7,
                      'activities': [
                        {
                          'type': 'watered',
                          'mine': false,
                          'unread': true,
                          'version': 7,
                          'createdAt': '2026-10-21T08:00:00Z',
                        },
                      ],
                    },
                  ],
                  'nextCursor': null,
                };
        },
      );
      expect(await service.hasUnreadActivity(), isTrue);
      expect(calls.length, 2);
      expect(calls.last.$2, {'cursor': 'page-two'});
      await service.markSeen('tree-1', 7);
      expect(calls.last.$2, {'id': 'tree-1', 'version': 7});
    },
  );
  test(
    'own-note management accepts delete-only response and protects account changes',
    () async {
      var owner = 'guest';
      final service = SharedTreeService(
        currentOwner: () => owner,
        transport: (action, body, uid) async {
          if (action == 'listMySharedTreeNotes')
            return {
              'notes': [
                {'treeId': 'tree-1', 'id': 'note-1', 'text': '내 말'},
              ],
              'nextCursor': null,
            };
          return {'deleted': true};
        },
      );
      expect((await service.myNotes()).notes.single.text, '내 말');
      await service.deleteNote('tree-1', 'note-1');
      owner = 'other';
      await expectLater(
        service.myNotes(),
        throwsA(
          isA<CloudException>().having(
            (e) => e.code,
            'code',
            'account-changed',
          ),
        ),
      );
    },
  );
}
