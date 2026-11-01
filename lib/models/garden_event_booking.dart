import 'notice.dart';

/// An authenticated server receipt, never a locally reserved seat.
class GardenEventBooking {
  final String newsId;
  final String? sessionId;
  final DateTime? sessionStartsAt;
  final DateTime? createdAt;
  final Notice? news;
  final bool eventUnavailable;

  const GardenEventBooking({
    required this.newsId,
    this.sessionId,
    this.sessionStartsAt,
    this.createdAt,
    this.news,
    this.eventUnavailable = false,
  });

  factory GardenEventBooking.fromJson(Map<String, dynamic> json) {
    final newsId = json['newsId'];
    if (newsId is! String || newsId.isEmpty) {
      throw const FormatException('신청 내역을 다시 확인해 주세요.');
    }
    return GardenEventBooking(
      newsId: newsId,
      sessionId: json['sessionId']?.toString(),
      sessionStartsAt: DateTime.tryParse(
        json['sessionStartsAt']?.toString() ?? '',
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      news: json['news'] is Map
          ? Notice.fromJson(Map<String, dynamic>.from(json['news'] as Map))
          : null,
      eventUnavailable: json['eventUnavailable'] == true,
    );
  }

  GardenEventSession? get session {
    for (final slot in news?.sessions ?? const <GardenEventSession>[]) {
      if (slot.id == sessionId) return slot;
    }
    return null;
  }
}

class GardenEventConfirmation {
  final GardenEventBooking reservation;
  final Notice? news;
  const GardenEventConfirmation({required this.reservation, this.news});
}
