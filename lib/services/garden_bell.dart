import 'dart:convert';
import 'local_record_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-level choice. Notification sound is played by Android, never media audio.
class GardenBell {
  static const soundChannel = 'garden_updates_bell_v1';
  static const silentChannel = 'garden_updates_silent_v1';
  static Future<bool> enabled() async =>
      (await SharedPreferences.getInstance()).getBool('garden_bell_enabled') ??
      true;
  static Future<void> setEnabled(bool value) async {
    if (!await (await SharedPreferences.getInstance()).setBool(
      'garden_bell_enabled',
      value,
    ))
      throw StateError('소리 설정을 저장하지 못했어요.');
  }

  static DateTime? _last;
  static bool takeSound(DateTime now) {
    if (_last != null && now.difference(_last!) < const Duration(seconds: 3))
      return false;
    _last = now;
    return true;
  }

  static final _queue = LocalRecordQueue();
  static Future<bool> newNotices(String owner, List<String> ids) =>
      _queue.run(() async {
        final prefs = await SharedPreferences.getInstance();
        final key = 'garden_notice_seen_$owner';
        final raw = prefs.getString(key);
        final old = raw == null
            ? null
            : (jsonDecode(raw) as List).cast<String>().toSet();
        final fresh = old != null && ids.any((id) => !old.contains(id));
        // Keep known IDs when an older entry returns to the paginated list.
        final all = {...?old, ...ids}.toList();
        if (all.length > 2000) all.removeRange(0, all.length - 2000);
        if (!await prefs.setString(key, jsonEncode(all))) return false;
        return fresh;
      });
}
