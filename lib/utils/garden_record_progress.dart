/// Private growth receipts survive letter deletion. No text or emotion is copied.
Set<String> gardenRecordDays(
  Iterable<String> receipts,
  Iterable<DateTime> letters, {
  required DateTime now,
}) {
  String key(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final today = key(now.toLocal());
  return {
    ...receipts,
    ...letters
        .map((date) => key(date.toLocal()))
        .where((day) => day.compareTo(today) <= 0),
  };
}

String gardenRecordMessage(int days) {
  if (days == 0) return '한 줄이나 감정 하나를 남기면 기억의 나무가 자라기 시작해요.';
  if (days >= 6) return '기억의 나무가 꽃을 피웠어요. 앞으로의 기록도 나무에서 돌아볼 수 있어요.';
  final next = days < 3 ? 3 : 6;
  return '$days일의 시간이 나무에 남았어요. 다른 날의 기록이 ${next - days}일 더 쌓이면 모습이 달라져요.';
}
