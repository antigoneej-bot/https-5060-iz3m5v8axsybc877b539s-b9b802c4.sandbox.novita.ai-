/// 정원소식(구 "공지사항") 모델.
///
/// 서버(Firestore `gardenNews` 컬렉션, Cloud Functions `gardenApi`를 통해서만
/// 접근)에서 조회합니다. 관리자 계정으로 로그인하면 앱 안에서 직접
/// 작성/수정/삭제(CRUD)할 수 있어, 원데이 클래스 안내 같은 소식을 앱
/// 업데이트 없이 올릴 수 있습니다. 서버가 아직 연결되지 않은 경우
/// ([CloudService.enabled]==false)에는 목록이 비어있는 것으로 처리됩니다.
///
/// [설계 원칙] 운영자가 실제로 올린 내용만 보여준다 - 가짜 참여자 수,
/// 가짜 신청 현황 같은 "운영 중인 것처럼 꾸민" 데이터는 절대 만들지 않는다.
/// [reservedCount]는 실제 신청 건수 그대로이며, "마감임박" 같은 문구를
/// 앱이 자동으로 덧붙이지 않는다. 상태([NoticeStatus])는 운영자가 직접
/// 고른 값을 그대로 보여줄 뿐이다.
class Notice {
  /// 정원소식 고유 id (Firestore 문서 id).
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

  /// 외부 신청폼/예약 링크. 앱 안 선착순 예약([capacity])과 별개로, 결제나
  /// 추가 정보 수집이 필요한 경우를 위해 함께 걸어둘 수 있는 선택 필드다.
  final String? applyUrl;

  /// 앱 안에서 선착순으로 받는 예약 정원. null이면 이 소식은 예약 기능이
  /// 없는(기존 공지처럼 안내만 하는) 소식이다. 0 이상의 정수.
  final int? capacity;

  /// 지금까지 실제로 신청한 인원 수(실시간 값, 서버가 집계). 운영자가
  /// 직접 적은 숫자가 아니라 신청 내역을 그대로 센 값이다.
  final int reservedCount;

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
    this.capacity,
    this.reservedCount = 0,
  });

  /// 앱 안에서 선착순 예약을 받는 소식인지 여부.
  bool get isReservable => capacity != null;

  /// 정원이 다 찼는지 여부(예약 가능한 소식에만 의미가 있다).
  bool get isReservationFull =>
      capacity != null && reservedCount >= capacity!;

  /// 서버 응답(JSON)으로부터 [Notice]를 만든다. 날짜 문자열은 ISO8601
  /// 타임스탬프 중 앞 10글자(YYYY-MM-DD)만 사람이 읽기 좋게 잘라 쓴다.
  factory Notice.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt']?.toString();
    return Notice(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '📌',
      type: NoticeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NoticeType.info,
      ),
      date: (createdAt != null && createdAt.length >= 10)
          ? createdAt.substring(0, 10)
          : '',
      status: json['status'] == null
          ? null
          : NoticeStatus.values.firstWhereOrNull(
              (s) => s.name == json['status'],
            ),
      period: json['period']?.toString(),
      location: json['location']?.toString(),
      cost: json['cost']?.toString(),
      applyUrl: json['applyUrl']?.toString(),
      capacity: (json['capacity'] as num?)?.toInt(),
      reservedCount: (json['reservedCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// 관리자 작성/수정 화면에서 서버로 보낼 입력값(JSON)을 만든다.
  Map<String, dynamic> toAdminInput() => {
    'title': title,
    'body': body,
    'emoji': emoji,
    'type': type.name,
    if (status != null) 'status': status!.name,
    if (period != null) 'period': period,
    if (location != null) 'location': location,
    if (cost != null) 'cost': cost,
    if (applyUrl != null) 'applyUrl': applyUrl,
    if (capacity != null) 'capacity': capacity,
  };
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
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
