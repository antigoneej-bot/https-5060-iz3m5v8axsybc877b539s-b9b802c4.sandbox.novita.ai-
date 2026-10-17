import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_encryption.dart';

/// Drafts never fall back to plaintext storage.
class DraftService {
  static Future<Box>? _opening;
  static Future<Box> box() => _opening ??= _open();
  static Future<Box> _open() async {
    try {
      return await Hive.openBox('drafts_local_user__enc',
          encryptionCipher: await HiveEncryption.cipher());
    } catch (_) { _opening = null; rethrow; }
  }
}

class DraftTextController extends TextEditingController with WidgetsBindingObserver {
  static final Set<DraftTextController> _active = {};
  static final Set<Future<void>> _closing = {};
  static Future<void> flushAll() async {
    await Future.wait(_closing.toList());
    for (final controller in _active.toList()) {
      await controller.flush();
      if (controller._failed) throw StateError('임시저장을 완료하지 못했어요.');
    }
  }
  final String draftKey;
  final ValueNotifier<String> saveStatus = ValueNotifier('임시저장 확인 중');
  Timer? _timer;
  Future<void> _tail = Future.value();
  late final Future<void> _ready;
  bool _hydrated = false;
  bool _disposed = false;
  bool _discarded = false;
  bool _failed = false;
  bool _loadingText = false;
  int _revision = 0;
  String _lastText = '';
  DraftTextController(this.draftKey) {
    _active.add(this);
    addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    _ready = _hydrate();
  }
  void _status(String value) { if (!_disposed) saveStatus.value = value; }
  Future<void> _hydrate() async {
    try {
      final box = await DraftService.box();
      final saved = box.get(draftKey);
      if (_revision == 0 && !_discarded && saved is String) {
        _lastText = saved;
        if (!_disposed) {
          _loadingText = true;
          value = TextEditingValue(text: saved, selection: TextSelection.collapsed(offset: saved.length));
          _loadingText = false;
        }
      }
      _hydrated = true;
      _status('이 기기에 암호화 임시저장');
      if (_revision > 0 && !_discarded) _schedule();
    } catch (_) {
      _failed = true;
      _hydrated = true;
      _status('임시저장 실패 · 내용을 복사해 보관해 주세요');
    }
  }
  void _schedule() {
    if (_disposed) return;
    _timer?.cancel();
    _status('저장 중');
    _timer = Timer(const Duration(milliseconds: 300), () { unawaited(flush()); });
  }
  void _changed() {
    if (_loadingText || text == _lastText) return;
    _lastText = text;
    _revision++;
    _discarded = false;
    if (_hydrated) _schedule();
  }
  Future<void> flush() async {
    _timer?.cancel();
    await _ready;
    if (_discarded) { await _tail; return; }
    // A failed read must never overwrite a previously saved draft with empty text.
    if (_failed && _revision == 0) return;
    final snapshot = _lastText;
    _tail = _tail.catchError((Object _) {}).then((_) async {
      try {
        final box = await DraftService.box();
        await box.put(draftKey, snapshot);
        await box.flush();
        _failed = false;
        _status('이 기기에 암호화 임시저장');
      } catch (_) { _failed = true; _status('임시저장 실패 · 내용을 복사해 보관해 주세요'); }
    });
    await _tail;
  }
  Future<void> discard() async {
    _timer?.cancel();
    _discarded = true;
    _lastText = '';
    _loadingText = true;
    if (!_disposed) clear();
    _loadingText = false;
    await _ready;
    _tail = _tail.catchError((Object _) {}).then((_) async {
      final box = await DraftService.box();
      await box.delete(draftKey);
      await box.flush();
    });
    await _tail;
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(flush());
  }
  @override
  void dispose() {
    _disposed = true;
    final closing = flush();
    _closing.add(closing);
    unawaited(closing.whenComplete(() => _closing.remove(closing)));
    _active.remove(this);
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    removeListener(_changed);
    saveStatus.dispose();
    super.dispose();
  }
}
