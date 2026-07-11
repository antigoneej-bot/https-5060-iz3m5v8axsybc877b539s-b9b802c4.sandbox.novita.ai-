import 'package:hive_flutter/hive_flutter.dart';
import '../models/promise_entry.dart';

/// "오늘의 약속" 데이터를 계정별로 관리하는 서비스.
/// 하루 최대 3개까지 등록할 수 있고, 자정이 지나면 그날의 약속은
/// (지켰든 못 지켰든) 조용히 정리되어 새 하루를 부담 없이 시작할 수 있게 합니다.
/// '실패' 개념이 없으므로 못 지킨 약속도 그냥 사라질 뿐, 별도 표시를 남기지 않습니다.
class PromiseService {
  static String _uid = 'guest';
  static Box? _box;
  static const int maxPerDay = 3;

  static Future<void> setCurrentUser(String userId) async {
    if (_uid == userId && _box != null && _box!.isOpen) return;
    _uid = userId;
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = await Hive.openBox('promise_entries_$_uid');
  }

  static Future<void> clearCurrentUser() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
    _box = null;
    _uid = 'guest';
  }

  static Box get _b {
    if (_box == null || !_box!.isOpen) {
      throw Exception('PromiseService: 사용자가 설정되지 않았습니다 (setCurrentUser 먼저 호출)');
    }
    return _box!;
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// 오늘 등록된 약속만 반환합니다. 자정이 지난 지난 날짜의 약속은 화면에
  /// 노출되지 않으며(누적 압박감 방지), [purgeStaleEntries]를 통해 실제로도
  /// 정리됩니다.
  static List<PromiseEntry> getTodayEntries() {
    final all = _b.values
        .map((e) => PromiseEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((e) => _isToday(e.createdAt))
        .toList();
    all.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return all;
  }

  /// 오늘 날짜가 아닌(=지나간) 약속을 조용히 정리합니다.
  /// 앱 진입 시(또는 화면 로드 시) 한 번씩 호출해 자정이 지난 뒤 남은
  /// 지난 약속이 계속 쌓이지 않도록 합니다.
  static Future<void> purgeStaleEntries() async {
    final keysToRemove = <dynamic>[];
    for (final key in _b.keys) {
      final raw = _b.get(key);
      if (raw == null) continue;
      final entry = PromiseEntry.fromMap(
        Map<dynamic, dynamic>.from(raw as Map),
      );
      if (!_isToday(entry.createdAt)) {
        keysToRemove.add(key);
      }
    }
    if (keysToRemove.isNotEmpty) {
      await _b.deleteAll(keysToRemove);
    }
  }

  /// 오늘 하루 새 약속을 추가합니다. 이미 3개라면 추가하지 않고 false를 반환합니다.
  static Future<bool> addPromise(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    final today = getTodayEntries();
    if (today.length >= maxPerDay) return false;
    final entry = PromiseEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      createdAt: DateTime.now(),
    );
    await _b.put(entry.id, entry.toMap());
    return true;
  }

  /// 약속을 지켰다고 표시합니다 (다시 되돌리는 것도 허용 - 실수로 눌렀을 때 대비).
  static Future<void> setKept(String id, bool kept) async {
    final raw = _b.get(id);
    if (raw == null) return;
    final entry = PromiseEntry.fromMap(Map<dynamic, dynamic>.from(raw as Map));
    final updated = entry.withKept(kept);
    await _b.put(id, updated.toMap());
  }

  static Future<void> deletePromise(String id) async {
    await _b.delete(id);
  }
}
