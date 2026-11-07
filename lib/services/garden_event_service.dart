import '../models/garden_event_booking.dart';
import '../models/notice.dart';
import 'cloud_service.dart';

typedef GardenEventTransport =
    Future<Map<String, dynamic>> Function(
      String action,
      Map<String, dynamic> body,
      String owner,
    );

/// Booking uses the existing authenticated/App-Check protected API. The server
/// owns seats and deadlines; a local optimistic count is never a confirmation.
class GardenEventService {
  final GardenEventTransport _transport;
  final String? Function() _currentOwner;
  final bool Function() _backendEnabled;

  GardenEventService({
    GardenEventTransport? transport,
    String? Function()? currentOwner,
    bool Function()? backendEnabled,
  }) : _transport =
           transport ??
           ((action, body, owner) => CloudService.call(action, body, owner)),
       _currentOwner = currentOwner ?? _cloudOwner,
       _backendEnabled = backendEnabled ?? (() => CloudService.enabled);

  static String? _cloudOwner() {
    final user = CloudService.currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  String? get currentOwner => _currentOwner();
  bool get backendEnabled => _backendEnabled();

  Future<Notice> refresh(String newsId) async {
    final result = await _call('getGardenNews', {'newsId': newsId});
    return Notice.fromJson(Map<String, dynamic>.from(result['news'] as Map));
  }

  Future<List<GardenEventBooking>> myReservations() async {
    final result = await _call('myGardenNewsReservations');
    final raw = result['reservations'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map(
            (value) =>
                GardenEventBooking.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList(growable: false);
    }
    // Older servers confirm undated reservations with IDs only.
    return (result['newsIds'] as List? ?? const [])
        .whereType<String>()
        .map((id) => GardenEventBooking(newsId: id))
        .toList(growable: false);
  }

  Future<GardenEventBooking?> reservation(String newsId) async {
    for (final row in await myReservations()) {
      if (row.newsId == newsId) return row;
    }
    return null;
  }

  Future<GardenEventConfirmation> reserve(
    String newsId, {
    String? sessionId,
    String? displayName,
    String? note,
  }) async {
    final result = await _call('reserveGardenNews', {
      'newsId': newsId,
      if (sessionId != null) 'sessionId': sessionId,
      if (displayName != null) 'displayName': displayName,
      if (note != null) 'note': note,
    });
    if (result['reserved'] != true) {
      throw const GardenEventException('reservation-confirmation-missing');
    }
    final raw = result['news'];
    final receipt = result['reservation'];
    final booking = receipt is Map
        ? GardenEventBooking.fromJson(Map<String, dynamic>.from(receipt))
        : GardenEventBooking(newsId: newsId, sessionId: sessionId);
    if (booking.newsId != newsId || booking.sessionId != sessionId) {
      throw const GardenEventException('reservation-confirmation-missing');
    }
    // The successful write is sufficient. A follow-up read must never undo or
    // mislabel confirmation when connectivity drops immediately afterwards.
    return GardenEventConfirmation(
      reservation: booking,
      news: raw is Map ? Notice.fromJson(Map<String, dynamic>.from(raw)) : null,
    );
  }

  Future<Notice?> cancel(String newsId) async {
    final result = await _call('cancelGardenNewsReservation', {
      'newsId': newsId,
    });
    if (result['canceled'] != true) {
      throw const GardenEventException('reservation-confirmation-missing');
    }
    final raw = result['news'];
    return raw is Map ? Notice.fromJson(Map<String, dynamic>.from(raw)) : null;
  }

  Future<String?> meetingUrl(String newsId) async {
    final result = await _call('getGardenEventAccess', {'newsId': newsId});
    return result['meetingUrl']?.toString();
  }

  Future<Map<String, dynamic>> _call(
    String action, [
    Map<String, dynamic> body = const {},
  ]) async {
    final owner = _currentOwner();
    if (owner == null) {
      throw const GardenEventException('authentication-required');
    }
    try {
      return await CloudService.retryAccountBusy(
        owner: owner,
        currentOwner: _currentOwner,
        action: () => _transport(action, body, owner),
      );
    } on CloudException catch (error) {
      throw GardenEventException(error.code);
    }
  }
}

class GardenEventException implements Exception {
  final String code;
  const GardenEventException(this.code);
  @override
  String toString() => switch (code) {
    'invalid-event-sessions' => '날짜·시작·종료 시간과 모집 인원을 확인해 주세요.',
    'invalid-event-mode' => '온라인 또는 오프라인을 선택해 주세요.',
    'invalid-event-link' => '모임 접속 링크는 올바른 HTTPS 주소로 입력해 주세요.',
    'event-has-reservations' =>
      '신청자가 있어 예약 기능을 없애거나 신청 인원보다 정원을 줄일 수 없어요. 일정의 시간 변경·삭제 대신 마감하거나 취소해 주세요.',
    'event-session-required' ||
    'invalid-event-session' => '참여할 날짜와 시간을 선택해 주세요.',
    'reservation-not-open' => '아직 신청 시작 시간이 아니에요.',
    'reservation-required' => '신청을 완료한 뒤 모임에 입장할 수 있어요.',
    'event-canceled' => '운영자가 이 일정을 취소했어요. 정원소식을 확인해 주세요.',
    'reservation-confirmation-missing' =>
      '신청 결과를 확인하지 못했어요. 다시 신청하기 전에 내 신청 내역을 확인해 주세요.',
    _ => CloudException(code).toString(),
  };
}
