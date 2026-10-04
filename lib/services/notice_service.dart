import 'package:shared_preferences/shared_preferences.dart';
import '../data/notices_data.dart';
import '../models/notice.dart';
import 'cloud_service.dart';

/// 정원소식(구 "공지사항")을 가져오고 읽음 상태를 관리합니다.
///
/// 목록은 서버(Firestore `gardenNews` 컬렉션, Cloud Functions `gardenApi`를
/// 통해서만 접근)에서 가져옵니다. 서버가 아직 연결되지 않은 경우
/// ([CloudService.enabled]==false) 또는 네트워크 오류가 있을 때는 마지막으로
/// 성공한 목록을 그대로 보여주고(빈 화면보다 낫다), 처음 실행이라 캐시조차
/// 없으면 빈 목록을 반환합니다 - 가짜 소식을 지어내지 않습니다.
class NoticeService {
  static const String _readIdsKey = 'notice_read_ids';

  /// 마지막으로 성공적으로 가져온 목록(메모리 캐시). [fetchNotices]를 아직
  /// 호출하지 않았거나 매번 네트워크를 기다리기 어려운 화면(홈 미리보기
  /// 카드 등)에서 동기적으로 쓸 수 있도록 둡니다. 서버가 아직 연결되지
  /// 않은 환경([CloudService.enabled]==false)에서는 [noticesData](과거
  /// 로컬 정적 목록)를 초기값으로 사용해 완전히 빈 화면이 되지 않게 합니다.
  static List<Notice> _cache = CloudService.enabled
      ? const []
      : noticesData
            .map(
              (n) => Notice(
                id: n.id,
                title: n.title,
                body: n.body,
                emoji: n.emoji,
                type: n.type,
                date: n.date,
                status: n.status,
                period: n.period,
                location: n.location,
                cost: n.cost,
                applyUrl: n.applyUrl,
              ),
            )
            .toList();

  /// 서버에서 정원소식 목록(최신순)을 가져온다. 실패하면 마지막 캐시를
  /// 그대로 돌려준다.
  static Future<List<Notice>> fetchNotices() async {
    if (!CloudService.enabled) return _cache;
    try {
      final raw = await CloudService.listGardenNews();
      _cache = raw.map(Notice.fromJson).toList();
      return _cache;
    } catch (_) {
      return _cache;
    }
  }

  /// 마지막으로 가져온 목록을 네트워크 호출 없이 즉시 돌려준다(홈 화면
  /// 미리보기 카드처럼 동기적으로 그려야 하는 자리에서 사용).
  static List<Notice> cachedNotices() => _cache;

  static Future<Set<String>> _readIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_readIdsKey) ?? const [];
    return list.toSet();
  }

  /// 아직 읽지 않은 소식 개수 (배지 표시용)
  static Future<int> unreadCount() async {
    final read = await _readIds();
    final all = await fetchNotices();
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
    final ids = _cache.map((n) => n.id).toList();
    await prefs.setStringList(_readIdsKey, ids);
  }
}
