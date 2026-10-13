/// Self-reported comfort is independent of rewards and is never inferred.
enum CareAction {
  rest('잠깐 쉬기', '편한 자세로 잠시 쉬어요. 아무것도 하지 않아도 괜찮아요.'),
  smallStep('작은 일 하나 정하기', '지금 바꿀 수 있는 일 하나와 가능한 때를 정해 보세요.'),
  connect('믿을 만한 사람에게 연락하기', '괜찮다면, 잠깐 이야기할 수 있는지 먼저 물어보세요.'),
  kindness('나에게 다정한 말 남기기', '같은 일을 겪은 친구에게 해주고 싶은 말을 나에게도 적어 보세요.'),
  savor('간직하고 싶은 순간 적기', '기억하고 싶은 장면이나 감각 하나를 남겨 보세요.');

  final String label;
  final String guide;
  const CareAction(this.label, this.guide);
}

enum CareFeedback {
  helped('조금 도움이 됐어요'),
  unchanged('별다른 변화가 없어요'),
  uncomfortable('불편했어요'),
  unsure('잘 모르겠어요');

  final String label;
  const CareFeedback(this.label);
}

const reflectionPrompts = [
  '이 마음이 느껴졌던 순간은 언제였나요?',
  '그때 나에게 필요했던 것은 무엇일까요?',
  '지금 나에게 해주고 싶은 말이 있나요?',
];

class SelfCareEntry {
  final String id;
  final DateTime createdAt;
  final int? comfort;
  final String? catId;
  final int promptIndex;
  final String reflection;
  final CareAction? action;
  final String plan;
  final CareFeedback? feedback;
  final int? afterComfort;
  final DateTime? reviewedAt;

  const SelfCareEntry({
    required this.id,
    required this.createdAt,
    this.comfort,
    this.catId,
    this.promptIndex = 0,
    this.reflection = '',
    this.action,
    this.plan = '',
    this.feedback,
    this.afterComfort,
    this.reviewedAt,
  });

  SelfCareEntry withFeedback(
    CareFeedback feedback,
    int? afterComfort,
    DateTime reviewedAt,
  ) => SelfCareEntry(
    id: id,
    createdAt: createdAt,
    comfort: comfort,
    catId: catId,
    promptIndex: promptIndex,
    reflection: reflection,
    action: action,
    plan: plan,
    feedback: feedback,
    afterComfort: afterComfort,
    reviewedAt: reviewedAt,
  );

  Map<String, dynamic> toMap() => {
    'version': 1,
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'comfort': comfort,
    'catId': catId,
    'promptIndex': promptIndex,
    'reflection': reflection,
    'action': action?.name,
    'plan': plan,
    'feedback': feedback?.name,
    'afterComfort': afterComfort,
    'reviewedAt': reviewedAt?.toIso8601String(),
  };

  factory SelfCareEntry.fromMap(Map map) {
    Never invalid() => throw const FormatException('마음 돌봄 기록을 읽을 수 없어요.');
    DateTime? timestamp(Object? value) {
      if (value == null) return null;
      if (value is! String) invalid();
      final parsed = DateTime.tryParse(value);
      // App-generated ISO timestamps round-trip exactly; reject normalized
      // impossible dates (e.g. February 30) in imported backups.
      if (parsed == null || parsed.toIso8601String() != value) invalid();
      return parsed;
    }

    int? score(Object? value) {
      if (value == null) return null;
      if (value is! int || value < 1 || value > 10) invalid();
      return value;
    }

    final date = timestamp(map['createdAt']);
    if (map['version'] != 1 ||
        map['id'] is! String ||
        (map['id'] as String).isEmpty ||
        (map['id'] as String).length > 128 ||
        date == null ||
        map['reflection'] is! String ||
        (map['reflection'] as String).length > 2000 ||
        map['plan'] is! String ||
        (map['plan'] as String).length > 500 ||
        map['promptIndex'] is! int ||
        (map['promptIndex'] as int) < 0 ||
        (map['promptIndex'] as int) >= reflectionPrompts.length ||
        (map['catId'] != null && map['catId'] is! String))
      invalid();
    CareAction? action;
    CareFeedback? feedback;
    if (map['action'] != null) {
      for (final item in CareAction.values) {
        if (item.name == map['action']) action = item;
      }
      if (action == null) invalid();
    }
    if (map['feedback'] != null) {
      for (final item in CareFeedback.values) {
        if (item.name == map['feedback']) feedback = item;
      }
      if (feedback == null) invalid();
    }
    final reviewed = timestamp(map['reviewedAt']);
    if ((map['reviewedAt'] != null && reviewed == null) ||
        (feedback != null && (action == null || reviewed == null)) ||
        (feedback == null &&
            (reviewed != null || map['afterComfort'] != null)) ||
        (reviewed != null && reviewed.isBefore(date)))
      invalid();
    return SelfCareEntry(
      id: map['id'] as String,
      createdAt: date,
      comfort: score(map['comfort']),
      catId: map['catId'] as String?,
      promptIndex: map['promptIndex'] as int,
      reflection: map['reflection'] as String,
      action: action,
      plan: map['plan'] as String,
      feedback: feedback,
      afterComfort: score(map['afterComfort']),
      reviewedAt: reviewed,
    );
  }
}
