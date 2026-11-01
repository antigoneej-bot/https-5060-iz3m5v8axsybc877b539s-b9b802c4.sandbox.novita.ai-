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
  if (days == 0) return '한 줄이나 감정 하나로 오늘의 기록을 시작해요.';
  if (days >= 6) return '함께한 기록이 쌓였어요. 앞으로의 기록도 차곡차곡 간직해요.';
  return '$days일의 마음을 기록했어요. 소중한 장면은 기억의 씨앗에 따로 담아 키울 수 있어요.';
}
