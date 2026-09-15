import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/hive_encryption.dart';

/// Durable write-ahead journal. Replay writes final values, never increments.
class SessionTransaction {
  static String newId() => List.generate(24, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  static const boxName = 'mongi_progress_local_user';
  static const pendingKey = '__mongi_pending_commit_v1';
  static const receiptsKey = '__mongi_session_receipts_v1';
  static final zoneKey = Object();
  static Box? _box;
  static Future<void>? _recovering;
  // Fault injection at real persistence boundaries, unused in production.
  static Future<void> Function(String)? fault;
  static DraftBox? get draft => Zone.current[zoneKey] as DraftBox?;

  static Future<void> initialize() async {
    _box = await HiveEncryption.openBox(boxName);
    await recover();
  }

  static Future<void> recover() {
    if (_box?.isOpen != true) return Future.value();
    return _recovering ??= _replay().whenComplete(() => _recovering = null);
  }

  static Future<void> _replay() async {
    final box = _box!;
    final raw = box.get(pendingKey);
    if (raw == null) return;
    final commit = Map<String, dynamic>.from(raw as Map);
    final writes = Map<String, dynamic>.from(commit['writes'] as Map);
    for (final entry in writes.entries) {
      await box.put(entry.key, entry.value);
      await fault?.call('hive_write');
    }
    for (final key in List<String>.from(commit['deletes'] as List)) {
      await box.delete(key);
    }
    await box.flush();
    await fault?.call('hive_flushed');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('local_user_mongi_garden_v1', commit['garden'] as String)) {
      throw StateError('정원 저장을 완료하지 못했어요. 다시 시도해 주세요.');
    }
    await fault?.call('garden_written');
    await box.delete(pendingKey);
    await box.flush();
    await fault?.call('commit_finished');
  }

  static Future<void> commit(DraftBox draft, Map<String, dynamic> garden) async {
    await fault?.call('before_journal');
    await _box!.put(pendingKey, {
      'writes': draft.writes, 'deletes': draft.deletes.toList(),
      'garden': jsonEncode(garden),
    });
    await _box!.flush();
    await fault?.call('journal_flushed');
    await recover();
  }
}

class DraftBox {
  final Map<dynamic, dynamic> values;
  final Map<String, dynamic> writes = {};
  final Set<String> deletes = {};
  DraftBox(Box box) : values = jsonDecode(jsonEncode(box.toMap())) as Map;
  dynamic get(dynamic key, {dynamic defaultValue}) => values[key] ?? defaultValue;
  Future<void> put(dynamic key, dynamic value) async {
    values[key] = value; writes[key as String] = value; deletes.remove(key);
  }
  Future<void> putAll(Map values) async {
    for (final entry in values.entries) { await put(entry.key, entry.value); }
  }
  Future<void> delete(dynamic key) async {
    values.remove(key); writes.remove(key); deletes.add(key as String);
  }
}

/// Other writes must first finish an interrupted commit, so recovery cannot
/// overwrite a later purchase, care action, or diary edit.
class RecoveringBox {
  final Box box;
  RecoveringBox(this.box);
  dynamic get(dynamic key, {dynamic defaultValue}) => box.get(key, defaultValue: defaultValue);
  Future<void> put(dynamic key, dynamic value) async {
    await SessionTransaction.recover(); await box.put(key, value);
  }
  Future<void> putAll(Map values) async {
    await SessionTransaction.recover(); await box.putAll(values);
  }
  Future<void> delete(dynamic key) async {
    await SessionTransaction.recover(); await box.delete(key);
  }
}
