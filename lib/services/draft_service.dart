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
      return await Hive.openBox(
        'drafts_local_user__enc',
        encryptionCipher: await HiveEncryption.cipher(),
      );
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }
}

/// One shared draft and write queue per key, including while an editor closes.
/// A background screen must never save its old snapshot over a newer editor.
class _DraftEntry {
  final String key;
  final Set<DraftTextController> editors = {};
  late final Future<void> ready;
  Future<void> _tail = Future.value();
  Timer? _timer;
  String text = '';
  String status = '임시저장 확인 중';
  int _revision = 0;
  bool _dirty = false;
  bool _deleteRequested = false;
  bool _loaded = false;
  bool failed = false;

  _DraftEntry(this.key) {
    ready = _load();
  }

  Future<void> _load() async {
    try {
      final box = await DraftService.box();
      final saved = box.get(key);
      // An edit/discard made while storage was opening is newer than this read.
      if (_revision == 0) text = saved is String ? saved : '';
      failed = false;
      _loaded = true;
      _publish(_dirty ? '저장 중' : '이 기기에 암호화 임시저장');
      if (_dirty) _schedule();
    } catch (_) {
      _loaded = true;
      failed = true;
      _publish('임시저장 실패 · 내용을 복사해 보관해 주세요');
    }
  }

  void _publish(String value) {
    status = value;
    for (final editor in editors.toList()) {
      editor._receiveSharedDraft();
    }
  }

  void edit(String value) {
    if (value == text) return;
    text = value;
    _revision++;
    _dirty = true;
    _deleteRequested = false;
    _publish('저장 중');
    if (_loaded) _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), () {
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    _timer?.cancel();
    await ready;
    final work = _tail.then((_) async {
      // Retry an unread draft without writing an empty default over it.
      if (failed && !_dirty) await _load();
      while (_dirty) {
        final revision = _revision;
        final snapshot = text;
        final deleting = _deleteRequested;
        try {
          final box = await DraftService.box();
          if (deleting) {
            await box.delete(key);
          } else {
            await box.put(key, snapshot);
          }
          await box.flush();
          failed = false;
          if (revision == _revision) {
            _dirty = false;
            _publish('이 기기에 암호화 임시저장');
          }
          // If an editor changed during the write, persist its newer value too.
        } catch (_) {
          failed = true;
          _publish('임시저장 실패 · 내용을 복사해 보관해 주세요');
          break;
        }
      }
    });
    // Storage errors are surfaced through status/flushAll, never unhandled from
    // an autosave timer or dispose. Failed drafts remain available for retry.
    _tail = work;
    await work;
    _releaseIfIdle();
  }

  Future<void> discard() async {
    _timer?.cancel();
    _revision++;
    text = '';
    _dirty = true;
    _deleteRequested = true;
    _publish('저장 중');
    await flush();
    if (failed) throw StateError('임시저장을 정리하지 못했어요.');
  }

  void _releaseIfIdle() {
    if (editors.isEmpty && !_dirty && !failed) {
      _timer?.cancel();
      if (identical(DraftTextController._entries[key], this)) {
        DraftTextController._entries.remove(key);
      }
    }
  }
}

class DraftTextController extends TextEditingController
    with WidgetsBindingObserver {
  static final Map<String, _DraftEntry> _entries = {};

  static Future<void> flushAll() async {
    // Includes unsaved drafts whose last screen has already been disposed.
    for (final entry in _entries.values.toList()) {
      await entry.flush();
      if (entry.failed) throw StateError('임시저장을 완료하지 못했어요.');
    }
  }

  final String draftKey;
  final ValueNotifier<String> saveStatus = ValueNotifier('임시저장 확인 중');
  late final _DraftEntry _entry;
  bool _disposed = false;
  bool _receiving = false;

  DraftTextController(this.draftKey) {
    _entry = _entries.putIfAbsent(draftKey, () => _DraftEntry(draftKey));
    _entry.editors.add(this);
    addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    _receiveSharedDraft();
  }

  void _receiveSharedDraft() {
    if (_disposed) return;
    _receiving = true;
    try {
      if (text != _entry.text) {
        value = TextEditingValue(
          text: _entry.text,
          selection: TextSelection.collapsed(offset: _entry.text.length),
        );
      }
      saveStatus.value = _entry.status;
    } finally {
      _receiving = false;
    }
  }

  void _changed() {
    if (!_receiving && !_disposed) _entry.edit(text);
  }

  Future<void> flush() => _entry.flush();
  Future<void> discard() => _entry.discard();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(flush());
  }

  @override
  void dispose() {
    _disposed = true;
    _entry.editors.remove(this);
    unawaited(flush());
    WidgetsBinding.instance.removeObserver(this);
    removeListener(_changed);
    saveStatus.dispose();
    super.dispose();
  }
}
