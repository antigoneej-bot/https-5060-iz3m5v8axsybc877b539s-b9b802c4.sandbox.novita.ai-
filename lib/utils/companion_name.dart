/// Apply a chosen name to curated companion copy only, never user-written text.
String companionDisplayName(String? value) {
  final name = value?.trim() ?? '';
  return name.isEmpty ? '고양이' : name;
}

String companionCopy(String template, String? value) {
  final name = companionDisplayName(value);
  final last = name.runes.last;
  final consonant =
      last >= 0xAC00 && last <= 0xD7A3 && (last - 0xAC00) % 28 != 0;
  return template.replaceAllMapped(RegExp(r"몽이(에게|가|를|는|와|의|랑)?|Mongi('s)?"), (
    match,
  ) {
    if (match[0]!.startsWith('Mongi'))
      return name + (match[2] == null ? '' : "'s");
    final suffix = match[1] ?? '';
    return name +
        switch (suffix) {
          '가' => consonant ? '이' : '가',
          '를' => consonant ? '을' : '를',
          '는' => consonant ? '은' : '는',
          '와' => consonant ? '과' : '와',
          '랑' => consonant ? '이랑' : '랑',
          _ => suffix,
        };
  });
}
