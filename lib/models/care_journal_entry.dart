import '../l10n/app_language.dart';

enum AfterWritingFeeling { lighter, same, complex, unknown }

enum CareActionKind { rest, walk, meditation, custom }

enum CareHelpfulness { helped, same, harder, unknown }

extension AfterWritingFeelingLabel on AfterWritingFeeling {
  String get label => switch (this) {
    AfterWritingFeeling.lighter => tr("조금 가벼워졌어요"),
    AfterWritingFeeling.same => tr("비슷해요"),
    AfterWritingFeeling.complex => tr("더 복잡해졌어요"),
    AfterWritingFeeling.unknown => tr("아직 잘 모르겠어요"),
  };
}

extension CareActionKindLabel on CareActionKind {
  String get label => switch (this) {
    CareActionKind.rest => tr("잠깐 쉬기"),
    CareActionKind.walk => tr("가볍게 걷기"),
    CareActionKind.meditation => tr("명상하기"),
    CareActionKind.custom => tr("내가 정한 돌봄"),
  };
}

extension CareHelpfulnessLabel on CareHelpfulness {
  String get label => switch (this) {
    CareHelpfulness.helped => tr("도움이 됐어요"),
    CareHelpfulness.same => tr("비슷했어요"),
    CareHelpfulness.harder => tr("더 힘들었어요"),
    CareHelpfulness.unknown => tr("잘 모르겠어요"),
  };
}

/// A private, explicitly self-reported experience. It never infers a diagnosis,
/// completion, or helpfulness from writing, navigation, or an elapsed timer.
class CareJournalEntry {
  const CareJournalEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.sourceLetterId,
    this.afterWritingFeeling,
    this.actionKind,
    this.actionLabel,
    this.contextLabel,
    this.completedAt,
    this.helpfulness,
    this.ownQuote,
    this.selfChosenClosing,
    this.encouragementText,
    this.encouragementSourceId,
    this.encouragementAuthor,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sourceLetterId;
  final AfterWritingFeeling? afterWritingFeeling;
  final CareActionKind? actionKind;
  final String? actionLabel;
  final String? contextLabel;
  final DateTime? completedAt;
  final CareHelpfulness? helpfulness;
  final String? ownQuote;
  final String? selfChosenClosing;
  final String? encouragementText;
  final String? encouragementSourceId;
  final String? encouragementAuthor;

  bool get isPlanned => actionKind != null && completedAt == null;
  bool get wasHelpful =>
      completedAt != null && helpfulness == CareHelpfulness.helped;

  CareJournalEntry copyWith({
    DateTime? updatedAt,
    AfterWritingFeeling? afterWritingFeeling,
    DateTime? completedAt,
    CareHelpfulness? helpfulness,
    String? ownQuote,
    String? selfChosenClosing,
  }) => CareJournalEntry(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sourceLetterId: sourceLetterId,
    afterWritingFeeling: afterWritingFeeling ?? this.afterWritingFeeling,
    actionKind: actionKind,
    actionLabel: actionLabel,
    contextLabel: contextLabel,
    completedAt: completedAt ?? this.completedAt,
    helpfulness: helpfulness ?? this.helpfulness,
    ownQuote: ownQuote ?? this.ownQuote,
    selfChosenClosing: selfChosenClosing ?? this.selfChosenClosing,
    encouragementText: encouragementText,
    encouragementSourceId: encouragementSourceId,
    encouragementAuthor: encouragementAuthor,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sourceLetterId': sourceLetterId,
    'afterWritingFeeling': afterWritingFeeling?.name,
    'actionKind': actionKind?.name,
    'actionLabel': actionLabel,
    'contextLabel': contextLabel,
    'completedAt': completedAt?.toIso8601String(),
    'helpfulness': helpfulness?.name,
    'ownQuote': ownQuote,
    'selfChosenClosing': selfChosenClosing,
    'encouragementText': encouragementText,
    'encouragementSourceId': encouragementSourceId,
    'encouragementAuthor': encouragementAuthor,
  };

  /// Shared by normal reads and backup validation. Invalid entries must not be
  /// silently converted into reassuring or apparently completed experiences.
  factory CareJournalEntry.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported care journal version');
    }
    String? string(String key, {int max = 256, bool required = false}) {
      final value = json[key];
      if (value == null && !required) return null;
      if (value is! String || value.trim().isEmpty || value.length > max) {
        throw FormatException('Invalid care journal field: $key');
      }
      return value;
    }

    DateTime? date(String key, {bool required = false}) {
      final text = string(key, max: 64, required: required);
      if (text == null) return null;
      final value = DateTime.tryParse(text);
      if (value == null || value.toIso8601String() != text)
        throw FormatException('Invalid care date: $key');
      return value;
    }

    T? choice<T extends Enum>(String key, List<T> values) {
      final value = string(key, max: 40);
      if (value == null) return null;
      for (final item in values) {
        if (item.name == value) return item;
      }
      throw FormatException('Invalid care choice: $key');
    }

    final entry = CareJournalEntry(
      id: string('id', required: true)!,
      createdAt: date('createdAt', required: true)!,
      updatedAt: date('updatedAt', required: true)!,
      sourceLetterId: string('sourceLetterId'),
      afterWritingFeeling: choice(
        'afterWritingFeeling',
        AfterWritingFeeling.values,
      ),
      actionKind: choice('actionKind', CareActionKind.values),
      actionLabel: string('actionLabel', max: 500),
      contextLabel: string('contextLabel', max: 80),
      completedAt: date('completedAt'),
      helpfulness: choice('helpfulness', CareHelpfulness.values),
      ownQuote: string('ownQuote', max: 600),
      selfChosenClosing: string('selfChosenClosing', max: 120),
      encouragementText: string('encouragementText', max: 1200),
      encouragementSourceId: string('encouragementSourceId'),
      encouragementAuthor: string('encouragementAuthor', max: 80),
    );
    if (entry.updatedAt.isBefore(entry.createdAt) ||
        (entry.completedAt?.isBefore(entry.createdAt) ?? false) ||
        (entry.completedAt?.isAfter(entry.updatedAt) ?? false) ||
        (entry.actionKind == null) != (entry.actionLabel == null) ||
        (entry.completedAt != null && entry.actionKind == null) ||
        (entry.helpfulness != null && entry.completedAt == null) ||
        ((entry.ownQuote != null ||
                entry.selfChosenClosing != null ||
                entry.afterWritingFeeling != null) &&
            entry.sourceLetterId == null) ||
        (entry.encouragementText == null) !=
            (entry.encouragementSourceId == null) ||
        (entry.encouragementAuthor != null &&
            entry.encouragementText == null) ||
        (entry.afterWritingFeeling == null &&
            entry.actionKind == null &&
            entry.ownQuote == null &&
            entry.selfChosenClosing == null &&
            entry.encouragementText == null)) {
      throw const FormatException('Inconsistent care journal entry');
    }
    return entry;
  }
}
