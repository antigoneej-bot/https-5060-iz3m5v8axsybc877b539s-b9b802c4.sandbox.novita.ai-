import 'cloud_service.dart';
import 'draft_service.dart';
import 'garden_event_service.dart';

/// Keeps every publish bound to the operator who opened the editor.
/// Only explicit account-busy rejections are retried; uncertain writes are not.
class GardenNewsEditorService {
  GardenNewsEditorService({
    GardenEventTransport? transport,
    String? Function()? currentOwner,
    bool Function()? backendEnabled,
    Future<void> Function(Duration)? wait,
  }) : _transport = transport ?? CloudService.call,
       _currentOwner = currentOwner ?? _cloudOwner,
       _backendEnabled = backendEnabled ?? (() => CloudService.enabled),
       _wait = wait;

  final GardenEventTransport _transport;
  final String? Function() _currentOwner;
  final bool Function() _backendEnabled;
  final Future<void> Function(Duration)? _wait;

  static String? _cloudOwner() {
    final user = CloudService.currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  String? get currentOwner => _currentOwner();

  Future<String> save(
    String owner,
    Map<String, dynamic> news, {
    String? id,
    String? requestId,
  }) async {
    if (!_backendEnabled()) {
      throw const CloudException('backend-not-configured');
    }
    final result = await CloudService.retryAccountBusy(
      owner: owner,
      currentOwner: _currentOwner,
      wait: _wait,
      action: () => _transport(
        id == null ? 'adminCreateGardenNews' : 'adminUpdateGardenNews',
        {
          'news': news,
          if (id != null) 'id': id,
          if (id == null && requestId != null) 'requestId': requestId,
        },
        owner,
      ),
    );
    final savedId = result['id'];
    if (savedId is! String ||
        savedId.isEmpty ||
        (id != null && savedId != id)) {
      throw const CloudException('news-confirmation-missing');
    }
    return savedId;
  }
}

/// Drafts share the existing encrypted local store, isolated by account + news.
/// Serial writes ensure an older autosave cannot resurrect a published draft.
class GardenNewsDraftStore {
  Future<void> _tail = Future.value();

  Future<Map<String, dynamic>?> load(String key) async {
    await _tail;
    final box = await DraftService.box();
    final value = box.get(key);
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> save(String key, Map<String, dynamic> value) =>
      _enqueue(() async {
        final box = await DraftService.box();
        await box.put(key, value);
        await box.flush();
      });

  Future<void> clear(String key) => _enqueue(() async {
    final box = await DraftService.box();
    await box.delete(key);
    await box.flush();
  });

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _tail.catchError((Object _) {}).then((_) => operation());
    _tail = next;
    return next;
  }
}
