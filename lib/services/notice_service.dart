import 'package:shared_preferences/shared_preferences.dart';
import '../data/notices_data.dart';
import '../models/notice.dart';

/// 공지사항 읽음 상태를 관리합니다.
///
/// 지금은 공지 목록 자체가 [noticesData](로컬 정적 리스트)에서 오지만,
/// 나중에 서버(B-2 단계)로 공지 발행을 옮기게 되더라도 이 서비스의
/// 인터페이스(unreadCount, markAllAsRead 등)는 그대로 유지하고
/// [_fetchNotices] 내부 구현만 API 호출로 바꾸면 됩니다.
class NoticeService {
  static const String _readIdsKey = 'notice_read_ids';

  /// 현재 노출 대상 공지 목록 (최신순)
  static List<Notice> fetchNotices() {
    // TODO(B-2 서버 단계): 여기를 Firestore 등 원격 조회로 교체
    return noticesData;
  }

  static Future<Set<String>> _readIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_readIdsKey) ?? const [];
    return list.toSet();
  }

  /// 아직 읽지 않은 공지 개수 (배지 표시용)
  static Future<int> unreadCount() async {
    final read = await _readIds();
    final all = fetchNotices();
    return all.where((n) => !read.contains(n.id)).length;
  }

  static Future<bool> isRead(String id) async {
    final read = await _readIds();
    return read.contains(id);
  }

  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_readIdsKey) ?? const [];
    if (list.contains(id)) return;
    await prefs.setStringList(_readIdsKey, [...list, id]);
  }

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = fetchNotices().map((n) => n.id).toList();
    await prefs.setStringList(_readIdsKey, ids);
  }
}
