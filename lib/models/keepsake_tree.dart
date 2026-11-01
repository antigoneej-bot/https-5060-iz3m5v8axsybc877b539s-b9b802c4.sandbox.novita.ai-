enum KeepsakeKind {
  love('사랑', '소중한 사랑을 오래 간직해요'),
  forgiveness('용서', '내 마음의 속도로 놓아주어요'),
  peace('평화', '고요했던 순간을 심어요'),
  gratitude('감사', '고마웠던 마음을 기억해요'),
  hope('희망', '새로운 시작을 응원해요'),
  memory('추억', '잊고 싶지 않은 하루를 담아요');

  const KeepsakeKind(this.label, this.description);
  final String label, description;
}

enum KeepsakeMetal {
  gold('황금빛', 0xFFD4A448),
  silver('은빛', 0xFF9DADB9),
  rose('장밋빛', 0xFFD294A0);

  const KeepsakeMetal(this.label, this.color);
  final String label;
  final int color;
}

String keepsakeDay(DateTime now) {
  final k = now.toUtc().add(const Duration(hours: 9));
  return '${k.year.toString().padLeft(4, '0')}-${k.month.toString().padLeft(2, '0')}-${k.day.toString().padLeft(2, '0')}';
}

bool validKeepsakeDay(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value))
    return false;
  final d = DateTime.tryParse(value);
  return d != null &&
      d.year >= 1900 &&
      d.year <= 2200 &&
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
          value;
}

class KeepsakeNote {
  final String id, day, text;
  const KeepsakeNote({required this.id, required this.day, required this.text});
  Map<String, dynamic> toJson() => {'id': id, 'day': day, 'text': text};
  factory KeepsakeNote.fromJson(Map raw) {
    if (raw['id'] is! String ||
        raw['id'].isEmpty ||
        !validKeepsakeDay(raw['day']) ||
        raw['text'] is! String ||
        raw['text'].trim().isEmpty ||
        raw['text'].length > 3000)
      throw const FormatException('추억의 날짜와 내용을 확인해주세요.');
    return KeepsakeNote(id: raw['id'], day: raw['day'], text: raw['text']);
  }
}

class KeepsakeTree {
  final String id, name, plantedDay;
  final KeepsakeKind kind;
  final KeepsakeMetal metal;
  final List<KeepsakeNote> notes;
  final List<String> careDays;
  final int revision;
  const KeepsakeTree({
    required this.id,
    required this.name,
    required this.plantedDay,
    required this.kind,
    required this.metal,
    required this.notes,
    this.careDays = const [],
    this.revision = 0,
  });
  int get stage => careDays.length >= 30
      ? 4
      : careDays.length >= 14
      ? 3
      : careDays.length >= 7
      ? 2
      : careDays.length >= 3
      ? 1
      : 0;
  String get stageLabel =>
      ['기억의 씨앗', '작은 새싹', '어린 나무', '빛나는 나무', '추억의 보석나무'][stage];
  int? get nextCare =>
      stage == 4 ? null : [3, 7, 14, 30][stage] - careDays.length;
  bool canCare(DateTime now) =>
      !careDays.contains(keepsakeDay(now)) &&
      (careDays.isEmpty || keepsakeDay(now).compareTo(careDays.last) > 0) &&
      keepsakeDay(now).compareTo(plantedDay) >= 0;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'name': name,
    'plantedDay': plantedDay,
    'kind': kind.name,
    'metal': metal.name,
    'notes': notes.map((n) => n.toJson()).toList(),
    'careDays': careDays,
    'revision': revision,
  };
  factory KeepsakeTree.fromJson(Map raw) {
    if (raw['version'] != 1 ||
        raw['id'] is! String ||
        raw['id'].isEmpty ||
        raw['name'] is! String ||
        raw['name'].trim().isEmpty ||
        raw['name'].length > 60 ||
        !validKeepsakeDay(raw['plantedDay']) ||
        raw['revision'] is! int ||
        raw['revision'] < 0 ||
        raw['notes'] is! List ||
        raw['notes'].isEmpty ||
        raw['notes'].length > 500 ||
        raw['careDays'] is! List ||
        raw['careDays'].length > 10000)
      throw const FormatException('기억의 나무 기록을 확인해주세요.');
    final kind = KeepsakeKind.values
            .where((v) => v.name == raw['kind'])
            .firstOrNull,
        metal = KeepsakeMetal.values
            .where((v) => v.name == raw['metal'])
            .firstOrNull;
    final days = raw['careDays'] as List;
    if (kind == null ||
        metal == null ||
        days.any(
          (d) => !validKeepsakeDay(d) || d.compareTo(raw['plantedDay']) < 0,
        ) ||
        days.toSet().length != days.length)
      throw const FormatException('씨앗과 성장 기록을 확인해주세요.');
    for (var i = 1; i < days.length; i++) {
      if ((days[i] as String).compareTo(days[i - 1]) <= 0)
        throw const FormatException('성장 날짜 순서가 달라요.');
    }
    final notes = (raw['notes'] as List)
        .map((v) => KeepsakeNote.fromJson(Map.from(v)))
        .toList();
    if (notes.map((n) => n.id).toSet().length != notes.length)
      throw const FormatException('추억이 중복돼요.');
    return KeepsakeTree(
      id: raw['id'],
      name: raw['name'],
      plantedDay: raw['plantedDay'],
      kind: kind,
      metal: metal,
      notes: notes,
      careDays: List<String>.from(days),
      revision: raw['revision'],
    );
  }
}
