import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/screens/shared_trees_screen.dart';
import 'package:flutter_app/services/shared_tree_service.dart';
import 'package:flutter_app/mongi/screens/my_shared_tree_notes_screen.dart';
import 'package:flutter_app/services/cloud_service.dart';

Map<String, dynamic> _tree({bool accepted = false}) => {
  'id': 'tree-1',
  'name': '함께 남기는 가을',
  'anniversaryOn': '2026-10-21',
  'myRole': 'guest',
  'status': accepted ? 'active' : 'invited',
  'guestStatus': accepted ? 'accepted' : 'invited',
  'activeDays': 0,
  'wateredToday': false,
  'notes': [],
  'hostName': '친구',
};
void main() {
  testWidgets(
    '360px invited free member accepts without a paywall and sees working care controls',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var accepted = false;
      final calls = <String>[];
      final service = SharedTreeService(
        currentOwner: () => 'guest',
        transport: (action, body, _) async {
          calls.add(action);
          if (action == 'respondSharedTree') accepted = true;
          return {'tree': _tree(accepted: accepted)};
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SharedTreeScreen(id: 'tree-1', service: service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('함께 가꾸기'), findsOneWidget);
      expect(find.textContaining('참여는 무료예요'), findsOneWidget);
      await tester.ensureVisible(find.text('함께 가꾸기'));
      await tester.tap(find.text('함께 가꾸기'));
      await tester.pumpAndSettle();
      expect(calls, contains('respondSharedTree'));
      expect(find.text('물 주고 다녀가기'), findsOneWidget);
      expect(find.text('구독 알아보기'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('read failure removes previous shared content and shows retry', (
    tester,
  ) async {
    var available = true;
    final service = SharedTreeService(
      currentOwner: () => 'guest',
      transport: (_, __, ___) async {
        if (!available) throw StateError('network');
        return {'tree': _tree(accepted: true)};
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SharedTreeScreen(id: 'tree-1', service: service),
      ),
    );
    await tester.pumpAndSettle();
    available = false;
    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refresh.onRefresh();
    await tester.pumpAndSettle();
    expect(find.text('함께 남기는 가을'), findsNothing);
    expect(find.text('다시 확인하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'real recent activity is shown and the displayed version is marked read',
    (tester) async {
      final seen = <Map<String, dynamic>>[];
      final service = SharedTreeService(
        currentOwner: () => 'guest',
        transport: (action, body, _) async {
          if (action == 'markSharedTreeSeen') {
            seen.add(body);
            return {'seen': true};
          }
          return {
            'tree': {
              ..._tree(accepted: true),
              'activityVersion': 5,
              'unreadCount': 1,
              'activities': [
                {
                  'type': 'note',
                  'mine': false,
                  'version': 5,
                  'unread': true,
                  'createdAt': '2026-10-21T08:00:00Z',
                },
              ],
            },
          };
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SharedTreeScreen(id: 'tree-1', service: service),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('새 마음 한 줄이 도착했어요'), findsOneWidget);
      expect(seen, [
        {'id': 'tree-1', 'version': 5},
      ]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'former member can delete own note without reloading inaccessible tree',
    (tester) async {
      var deleted = false;
      final service = SharedTreeService(
        currentOwner: () => 'guest',
        transport: (action, body, _) async {
          if (action == 'listMySharedTreeNotes')
            return {
              'notes': [
                {
                  'treeId': 'retired-tree',
                  'id': 'note-1',
                  'text': '내가 남긴 소중한 말',
                },
              ],
              'nextCursor': null,
            };
          if (action == 'deleteSharedTreeNote') {
            deleted = true;
            return {'deleted': true};
          }
          throw const CloudException('shared-tree-not-found');
        },
      );
      await tester.pumpWidget(
        MaterialApp(home: MySharedTreeNotesScreen(service: service)),
      );
      await tester.pumpAndSettle();
      expect(find.text('내가 남긴 소중한 말'), findsOneWidget);
      await tester.tap(find.text('이 메모 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(find.text('내가 남긴 소중한 말'), findsNothing);
      expect(find.text('내가 남긴 공동 메모가 없어요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
