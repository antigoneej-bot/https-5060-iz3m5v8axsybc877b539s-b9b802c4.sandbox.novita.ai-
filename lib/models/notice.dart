/// 공지사항 모델.
///
/// 현재는 [noticesData]에 정적으로 등록된 공지만 보여주는 "로컬 정적" 방식입니다.
/// 추후 서버(Firestore 등)를 붙이게 되면, [NoticeService]의 데이터 소스만
/// 로컬 리스트에서 서버 조회로 교체하면 되고, 이 모델과 화면 위젯은 그대로
/// 재사용할 수 있도록 필드를 설계해두었습니다.
class Notice {
  /// 공지 고유 id. 새 공지를 추가할 때마다 유일한 값을 지정해주세요.
  /// (읽음 여부를 이 id로 로컬에 기록합니다)
  final String id;

  final String title;
  final String body;

  /// 공지 목록에서 보여줄 간단한 이모지 아이콘
  final String emoji;

  /// 공지 종류 - 배지 색상/우선순위 표기에 사용
  final NoticeType type;

  /// 공지 등록일 (YYYY-MM-DD 형식의 간단한 문자열로 관리)
  final String date;

  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.type,
    required this.date,
  });
}

enum NoticeType {
  /// 일반 안내
  info,

  /// 업데이트/신규 기능 소식
  update,

  /// 이벤트/캠페인
  event,
}

extension NoticeTypeLabel on NoticeType {
  String get label {
    switch (this) {
      case NoticeType.info:
        return '안내';
      case NoticeType.update:
        return '업데이트';
      case NoticeType.event:
        return '이벤트';
    }
  }
}
