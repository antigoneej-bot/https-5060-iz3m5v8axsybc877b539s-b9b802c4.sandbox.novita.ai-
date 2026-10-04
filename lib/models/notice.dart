/// 공지사항(= "정원 소식") 모델.
///
/// 현재는 [noticesData]에 정적으로 등록된 공지만 보여주는 "로컬 정적" 방식입니다.
/// 추후 서버(Firestore 등)를 붙이게 되면, [NoticeService]의 데이터 소스만
/// 로컬 리스트에서 서버 조회로 교체하면 되고, 이 모델과 화면 위젯은 그대로
/// 재사용할 수 있도록 필드를 설계해두었습니다.
///
/// [설계 원칙] 운영자가 실제로 올린 내용만 보여준다 - 가짜 참여자 수,
/// 가짜 신청 현황 같은 "운영 중인 것처럼 꾸민" 데이터는 절대 만들지 않는다.
/// 참여/신청은 초기엔 외부 신청폼(예: 구글 폼) 링크로 연결하고, 상태
/// ([NoticeStatus])는 운영자가 직접 올린 문구를 그대로 보여줄 뿐이다.
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

  /// 지금 이 소식이 어떤 상태인지 (예: 모집 중 / 진행 중 / 마감).
  /// null이면 상태 배지를 아예 보여주지 않는다(순수 안내성 공지에는 불필요).
  final NoticeStatus? status;

  /// 행사/모임이 진행되는 기간을 사람이 읽기 좋은 문자열로 그대로 보여준다
  /// (예: "2026-08-01 ~ 2026-08-15"). 날짜 계산이 필요 없는 단순 표시용이라
  /// 일부러 String으로 둔다 - 서버 연동 전까지는 운영자가 직접 적은 문구를
  /// 그대로 신뢰하는 구조다.
  final String? period;

  /// 오프라인 장소 또는 "온라인" 등. null이면 장소 줄 자체를 숨긴다.
  final String? location;

  /// 참가 비용 안내 문구(예: "무료", "1만원"). null이면 비용 줄을 숨긴다.
  final String? cost;

  /// 외부 신청폼/예약 링크. null이 아니면 상세 화면에 "신청하기" 버튼이 뜬다.
  /// 서버가 생기기 전까지는 구글 폼 등 외부 링크로 신청을 받는다.
  final String? applyUrl;

  const Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.type,
    required this.date,
    this.status,
    this.period,
    this.location,
    this.cost,
    this.applyUrl,
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

/// 소식(특히 모집형 이벤트)의 진행 상태. 운영자가 직접 고른 상태를 그대로
/// 보여줄 뿐, 앱이 자동으로 "인기/마감임박" 같은 판단을 추가하지 않는다
/// (가짜 긴급함 연출 금지).
enum NoticeStatus {
  /// 신청/참여를 받고 있는 중
  recruiting,

  /// 신청은 마감됐지만 행사 자체는 진행 중
  ongoing,

  /// 완전히 종료됨
  closed,
}

extension NoticeStatusLabel on NoticeStatus {
  String get label {
    switch (this) {
      case NoticeStatus.recruiting:
        return '모집 중';
      case NoticeStatus.ongoing:
        return '진행 중';
      case NoticeStatus.closed:
        return '마감';
    }
  }
}
