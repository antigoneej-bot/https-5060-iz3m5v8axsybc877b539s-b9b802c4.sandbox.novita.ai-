import 'dart:async';
import 'dart:math';
import 'analytics_service.dart';
import '../mongi/models/shared_tree.dart';
import 'cloud_service.dart';

typedef SharedTreeTransport =
    Future<Map<String, dynamic>> Function(
      String action,
      Map<String, dynamic> body,
      String owner,
    );

class SharedTreeService {
  final SharedTreeTransport _transport;
  final String? Function() _currentOwner;
  final Future<void> Function(Duration)? _wait;
  String? _owner;
  SharedTreeService({
    SharedTreeTransport? transport,
    String? Function()? currentOwner,
    Future<void> Function(Duration)? retryDelay,
  }) : _transport =
           transport ??
           ((action, body, owner) => CloudService.call(action, body, owner)),
       _currentOwner = currentOwner ?? _cloudOwner,
       _wait = retryDelay;
  static String? _cloudOwner() {
    final user = CloudService.currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  String? get currentOwner => _currentOwner();
  static String newRequestId() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<Map<String, dynamic>> _call(
    String action, [
    Map<String, dynamic> body = const {},
  ]) async {
    final uid = _currentOwner();
    if (uid == null) throw const CloudException('authentication-required');
    if (_owner != null && _owner != uid)
      throw const CloudException('account-changed');
    _owner ??= uid;
    return CloudService.retryAccountBusy(
      owner: uid,
      currentOwner: _currentOwner,
      wait: _wait,
      action: () => _transport(action, body, uid),
    );
  }

  SharedTree _tree(Map<String, dynamic> result) {
    if (result['tree'] is! Map) throw const FormatException('나무를 다시 불러와 주세요.');
    return SharedTree.fromJson(
      Map<String, dynamic>.from(result['tree'] as Map),
    );
  }

  Future<SharedTreePage> list({String? cursor}) async =>
      SharedTreePage.fromJson(
        await _call('listSharedTrees', {if (cursor != null) 'cursor': cursor}),
      );
  Future<SharedTree> get(String id) async =>
      _tree(await _call('getSharedTree', {'id': id}));
  void _track(String event) {
    // Analytics must never turn a completed server write into a failed action.
    unawaited(AnalyticsService().logEvent(event).catchError((Object _) {}));
  }

  Future<SharedTree> create({
    required String gardenId,
    required String name,
    required String anniversaryOn,
    required String requestId,
  }) async {
    final tree = _tree(
      await _call('createSharedTree', {
        'gardenId': gardenId,
        'name': name.trim(),
        'anniversaryOn': anniversaryOn,
        'requestId': requestId,
      }),
    );
    _track(AnalyticsEvents.sharedTreeCreated);
    return tree;
  }

  Future<void> respond(String id, {required bool accept}) async {
    await _call('respondSharedTree', {'id': id, 'accept': accept});
    if (accept) _track(AnalyticsEvents.sharedTreeJoined);
  }

  Future<void> reportNote(String id, String noteId) async {
    await _call('reportSharedTreeNote', {'id':id, 'noteId':noteId});
  }

  Future<SharedTree> water(String id) async {
    final tree = _tree(await _call('waterSharedTree', {'id': id}));
    _track(AnalyticsEvents.sharedTreeWatered);
    return tree;
  }

  Future<SharedTree> addNote(
    String id, {
    required String text,
    required String requestId,
  }) async {
    final tree = _tree(
      await _call('addSharedTreeNote', {
        'id': id,
        'text': text.trim(),
        'requestId': requestId,
      }),
    );
    _track(AnalyticsEvents.sharedTreeNoteSaved);
    return tree;
  }

  Future<void> deleteNote(String id, String noteId) async {
    await _call('deleteSharedTreeNote', {'id': id, 'noteId': noteId});
  }

  Future<MySharedTreeNotePage> myNotes({String? cursor}) async =>
      MySharedTreeNotePage.fromJson(
        await _call('listMySharedTreeNotes', {
          if (cursor != null) 'cursor': cursor,
        }),
      );
  Future<void> markSeen(String id, int version) async {
    await _call('markSharedTreeSeen', {'id': id, 'version': version});
  }

  Future<bool> hasUnreadActivity() async {
    String? cursor;
    final visited = <String>{};
    do {
      final page = await list(cursor: cursor);
      if (page.trees.any((tree) => tree.hasUnread)) return true;
      cursor = page.nextCursor;
      if (cursor != null && !visited.add(cursor)) break;
    } while (cursor != null);
    return false;
  }

  Future<void> leave(String id) async {
    await _call('leaveSharedTree', {'id': id});
  }

  Future<SharedTree> setStyle(String id, String style) async =>
      _tree(await _call('setSharedTreeStyle', {'id': id, 'style': style}));

  static String message(Object error) {
    if (error is CloudException) {
      return switch (error.code) {
        'unknown-action' => '함께 가꾸는 나무의 서버 업데이트가 필요해요. 운영자에게 알려 주세요.',
        'shared-tree-not-found' => '이 나무에 접근할 수 없어요. 초대나 이웃 연결이 바뀌었을 수 있어요.',
        'shared-tree-invitation-required' => '이웃이 초대를 수락한 뒤 함께 가꿀 수 있어요.',
        'shared-tree-note-limit' => '메모 100개가 모였어요. 내 메모를 정리한 뒤 다시 남겨 주세요.',
        'invalid-shared-tree' ||
        'invalid-shared-tree-note' => '나무 이름, 기념일과 메모를 다시 확인해 주세요.',
        'subscription-required' =>
          '새 공동 나무와 분위기 꾸미기는 구독으로 이용할 수 있어요. 기존 나무 돌보기와 초대 참여는 무료예요.',
        _ => error.toString(),
      };
    }
    return '나무를 불러오지 못했어요. 연결을 확인한 뒤 다시 시도해 주세요.';
  }
}
