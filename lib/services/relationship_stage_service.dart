import '../models/letter_tags.dart';

/// 관계 변화 시스템(친밀도 5단계, 설계서 8장).
///
/// 친밀도는 별도로 저장하지 않는 파생값입니다 - "처음 편지를 쓴 날짜"
/// (anchor)만 있으면 매번 다시 계산할 수 있습니다. anchor는 기존
/// `AppStateProvider.history`(오래된 순으로 정렬된 첫 `LetterEntry.date`)에서
/// 바로 구할 수 있어 별도 저장이 필요 없습니다.
class RelationshipStageService {
  /// 첫 편지 이후 며칠이 지났는지로부터 친밀도 단계를 계산합니다.
  static IntimacyTag calcIntimacy(int daysSinceFirstLetter) {
    if (daysSinceFirstLetter >= 100) return IntimacyTag.lifelongFriend;
    if (daysSinceFirstLetter >= 30) return IntimacyTag.family;
    if (daysSinceFirstLetter >= 7) return IntimacyTag.friend;
    if (daysSinceFirstLetter >= 1) return IntimacyTag.shy;
    return IntimacyTag.firstMeet;
  }

  /// [firstLetterDate](이 고양이에게 쓴 가장 오래된 편지 날짜)와 [now]로부터
  /// 친밀도 단계를 계산합니다. [firstLetterDate]가 없다면(아직 편지를 한
  /// 번도 쓰지 않은 경우) 첫만남으로 처리합니다.
  static IntimacyTag calcIntimacyFromDate(
    DateTime? firstLetterDate,
    DateTime now,
  ) {
    if (firstLetterDate == null) return IntimacyTag.firstMeet;
    final first = DateTime(
      firstLetterDate.year,
      firstLetterDate.month,
      firstLetterDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(first).inDays;
    return calcIntimacy(days < 0 ? 0 : days);
  }
}
