/// Presentation only. This never grants access or changes purchase ownership.
class SubscriptionStatusSummary {
  const SubscriptionStatusSummary(this.title, this.detail);
  final String title;
  final String detail;

  factory SubscriptionStatusSummary.fromRecord(
    Map? record, {
    required DateTime now,
  }) {
    const unknown = SubscriptionStatusSummary(
      '구독 상태 확인 필요',
      '상태 새로고침 또는 구독 관리에서 확인해 주세요.',
    );
    if (record == null) return unknown;
    final checked = DateTime.tryParse('${record['checkedAt'] ?? ''}');
    if (checked == null ||
        checked.isAfter(now) ||
        now.difference(checked) > const Duration(hours: 48)) {
      return const SubscriptionStatusSummary(
        '최신 구독 상태 확인 필요',
        '구독 관리에서 다시 확인해 주세요. 기록은 그대로 보관돼요.',
      );
    }
    final expiry = DateTime.tryParse('${record['expiresAt'] ?? ''}');
    final state = record['state'];
    if (state == 'expired' || (expiry != null && !expiry.isAfter(now))) {
      return const SubscriptionStatusSummary(
        '구독 이용 기간 종료',
        '기존 기록과 받은 장식은 남아 있어요.',
      );
    }
    if (record['active'] == false) {
      return const SubscriptionStatusSummary(
        '무료 이용 중',
        '기본 기록과 정원을 계속 이용할 수 있어요.',
      );
    }
    if (record['active'] != true || expiry == null) return unknown;
    final plan = switch (record['productId']) {
      'garden_plus_yearly' => '연간 구독',
      'garden_plus_monthly' => '월간 구독',
      _ => '구독',
    };
    final date = accountStatusDate(expiry);
    if (state == 'cancelScheduled' || record['autoRenewEnabled'] == false) {
      return SubscriptionStatusSummary(
        '$plan · 해지 예약',
        '$date까지 이용 가능해요. 자동 갱신은 꺼져 있어요.',
      );
    }
    final title = state == 'trial' ? '$plan · 무료체험 중' : '$plan 이용 중';
    return SubscriptionStatusSummary(
      title,
      record['autoRenewEnabled'] == true
          ? '다음 갱신 예정: $date · 결제 내역은 Google Play에서 확인해요.'
          : '현재 이용 기간: $date까지 · 갱신 여부는 구독 관리에서 확인해요.',
    );
  }
}

String accountStatusDate(DateTime value) {
  final date = value.toLocal();
  return '${date.year}.${date.month}.${date.day} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class BackupStatusSummary {
  const BackupStatusSummary({
    required this.enabled,
    this.lastConfirmedAt,
    this.pendingChanges,
  });
  final bool enabled;
  final DateTime? lastConfirmedAt;
  final bool? pendingChanges;
  String get title => enabled ? '자동 백업 켜짐' : '자동 백업 꺼짐';
  String get detail => lastConfirmedAt == null
      ? '이 기기에서 확인한 서버 백업이 없어요. 파일 백업도 이용할 수 있어요.'
      : '마지막 서버 백업: ${accountStatusDate(lastConfirmedAt!)}\n${pendingChanges == true
            ? '아직 백업하지 않은 변경이 있어요. 백업·복원에서 지금 백업할 수 있어요.'
            : pendingChanges == false
            ? '최근 확인한 기록까지 백업했어요. 새 기록은 앱 사용 중 다시 확인해요.'
            : '그 뒤 남긴 기록은 아직 백업되지 않았을 수 있어요.'}';
}
