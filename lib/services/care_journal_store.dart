import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/care_journal_entry.dart';
import '../models/letter_entry.dart';
import '../models/self_care_entry.dart';
import 'hive_encryption.dart';
import 'local_record_transaction.dart';
import 'analytics_service.dart';
import 'self_care_store.dart';
import 'storage_service.dart';
import 'special_letter_service.dart';

/// A single care hub. Actions stay in the existing SelfCareStore; this box only
/// adds private letter responses and explicitly saved words/encouragement.
class CareJournalStore extends ChangeNotifier {
  CareJournalStore._()
    : _openBox = (() => HiveEncryption.openBox(boxName)),
      _selfCare = SelfCareStore.instance,
      _sourceText = _storedLetterText,
      _clock = DateTime.now;

  @visibleForTesting
  CareJournalStore.forTesting({
    required Future<Box> Function() openBox,
    required SelfCareStore selfCare,
    DateTime Function()? clock,
    String? Function(String)? sourceText,
  }) : _openBox = openBox,
       _selfCare = selfCare,
       _sourceText = sourceText ?? _storedLetterText,
       _clock = clock ?? DateTime.now;

  static final instance = CareJournalStore._();
  static const boxName = 'care_journal_local_user';
  final Future<Box> Function() _openBox;
  final SelfCareStore _selfCare;
  final String? Function(String) _sourceText;
  final DateTime Function() _clock;
  final _queue = LocalRecordQueue();
  List<CareJournalEntry> _entries = const [];
  bool _loaded = false;
  List<CareJournalEntry> get entries => List.unmodifiable(_entries);
  bool get isLoaded => _loaded;

  /// Only the latest explicitly reviewed experience of an action is offered.
  /// A later uncomfortable/unchanged experience must not be hidden by an older
  /// helpful one. All experiences remain visible in the full history.
  List<CareJournalEntry> get helpfulActions {
    final reviewed = _entries.where((e) => e.helpfulness != null).toList()
      ..sort((a, b) {
        final order = b.updatedAt.compareTo(a.updatedAt);
        if (order != 0) return order;
        if (a.helpfulness == CareHelpfulness.harder &&
            b.helpfulness != CareHelpfulness.harder)
          return -1;
        if (b.helpfulness == CareHelpfulness.harder &&
            a.helpfulness != CareHelpfulness.harder)
          return 1;
        return b.id.compareTo(a.id);
      });
    final seen = <String>{};
    return List.unmodifiable(
      reviewed.where((e) {
        final key = '${e.actionKind?.name}:${e.actionLabel}';
        return seen.add(key) && e.wasHelpful;
      }),
    );
  }

  void _track(String event) {
    unawaited(AnalyticsService().logEvent(event).catchError((Object _) {}));
  }

  static String? _storedLetterText(String sourceId) {
    if (sourceId.startsWith('heart:')) {
      final id = sourceId.substring(6);
      for (final letter in SpecialLetterService.getAllEntries()) {
        if (letter.id == id) return letter.letterText;
      }
    } else {
      for (final letter in StorageService.getAllLetters()) {
        if (letter.id == sourceId) return letter.letterText;
      }
    }
    return null;
  }

  void _requireLetter(String sourceId, {String? originalText, String? quote}) {
    final actual = _sourceText(sourceId);
    if (actual == null ||
        (originalText != null && originalText != actual) ||
        (quote != null && !actual.contains(quote))) {
      throw StateError('원래 편지를 다시 확인해 주세요. 삭제된 편지에는 기록을 덧붙일 수 없어요.');
    }
  }

  Future<T> _serialized<T>(Future<T> Function() action) =>
      LocalRecordTransaction.atomic(() => _queued(action));

  Future<T> _queued<T>(Future<T> Function() action) => _queue.run(action);

  static CareJournalEntry projectAction(SelfCareEntry entry) {
    final kind = switch (entry.action!) {
      CareAction.rest => CareActionKind.rest,
      CareAction.walk => CareActionKind.walk,
      CareAction.meditation => CareActionKind.meditation,
      _ => CareActionKind.custom,
    };
    final helpfulness = switch (entry.feedback) {
      CareFeedback.helped => CareHelpfulness.helped,
      CareFeedback.unchanged => CareHelpfulness.same,
      CareFeedback.uncomfortable => CareHelpfulness.harder,
      CareFeedback.unsure => CareHelpfulness.unknown,
      null => null,
    };
    return CareJournalEntry(
      id: 'action:${entry.id}',
      createdAt: entry.createdAt,
      updatedAt: entry.reviewedAt ?? entry.completedAt ?? entry.createdAt,
      sourceLetterId: entry.sourceLetterId,
      contextLabel: entry.contextLabel,
      actionKind: kind,
      actionLabel: kind == CareActionKind.custom && entry.plan.trim().isNotEmpty
          ? entry.plan
          : entry.action!.label,
      completedAt: entry.completedAt ?? entry.reviewedAt,
      helpfulness: helpfulness,
    );
  }

  Future<void> _read(Box box) async {
    final next = <CareJournalEntry>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map)
        throw const FormatException('Invalid care journal record');
      final entry = CareJournalEntry.fromJson(Map<String, dynamic>.from(raw));
      if (key != entry.id)
        throw const FormatException('Care record ID mismatch');
      next.add(entry);
    }
    final actions = await _selfCare.load();
    next.addAll(actions.where((e) => e.action != null).map(projectAction));
    next.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _entries = next;
    _loaded = true;
    notifyListeners();
  }

  Future<void> reload() => _serialized(() async => _read(await _openBox()));

  CareJournalEntry? entryForLetter(String letterId) {
    for (final entry in _entries) {
      if (entry.id == 'letter:$letterId') return entry;
    }
    return null;
  }

  DateTime _updated(CareJournalEntry entry) {
    final now = _clock().toUtc();
    return now.isBefore(entry.updatedAt) ? entry.updatedAt : now;
  }

  Future<void> _write(Box box, CareJournalEntry entry) async {
    final checked = CareJournalEntry.fromJson(entry.toJson());
    LocalRecordTransaction.capture(box, afterRollback: () => _read(box));
    await box.put(checked.id, checked.toJson());
    await box.flush();
    await _read(box);
  }

  Future<void> setAfterWritingFeeling(
    LetterEntry letter,
    AfterWritingFeeling feeling,
  ) => saveLetterFeeling(letter.id, feeling);

  Future<void> saveLetterFeeling(
    String sourceLetterId,
    AfterWritingFeeling feeling,
  ) => _serialized(() async {
    final box = await _openBox();
    await _read(box);
    _requireLetter(sourceLetterId);
    final existing = entryForLetter(sourceLetterId);
    final now = _clock().toUtc();
    await _write(
      box,
      existing?.copyWith(
            updatedAt: _updated(existing),
            afterWritingFeeling: feeling,
          ) ??
          CareJournalEntry(
            id: 'letter:$sourceLetterId',
            createdAt: now,
            updatedAt: now,
            sourceLetterId: sourceLetterId,
            afterWritingFeeling: feeling,
          ),
    );
    _track(AnalyticsEvents.letterClosingSaved);
  });

  Future<void> saveOwnQuote(LetterEntry letter, String exactQuote) =>
      saveLetterQuote(
        sourceLetterId: letter.id,
        originalText: letter.letterText,
        exactQuote: exactQuote,
      );

  Future<void> saveLetterQuote({
    required String sourceLetterId,
    required String originalText,
    required String exactQuote,
  }) => _serialized(() async {
    if (exactQuote.trim().isEmpty ||
        exactQuote.length > 600 ||
        !originalText.contains(exactQuote)) {
      throw const FormatException('Choose an exact sentence from your letter');
    }
    final box = await _openBox();
    await _read(box);
    _requireLetter(
      sourceLetterId,
      originalText: originalText,
      quote: exactQuote,
    );
    final existing = entryForLetter(sourceLetterId);
    final now = _clock().toUtc();
    await _write(
      box,
      existing?.copyWith(updatedAt: _updated(existing), ownQuote: exactQuote) ??
          CareJournalEntry(
            id: 'letter:$sourceLetterId',
            createdAt: now,
            updatedAt: now,
            sourceLetterId: sourceLetterId,
            ownQuote: exactQuote,
          ),
    );
    _track(AnalyticsEvents.letterClosingSaved);
  });

  Future<void> saveClosingWords(String sourceLetterId, String words) =>
      _serialized(() async {
        final box = await _openBox();
        await _read(box);
        _requireLetter(sourceLetterId);
        final existing = entryForLetter(sourceLetterId);
        final now = _clock().toUtc();
        await _write(
          box,
          existing?.copyWith(
                updatedAt: _updated(existing),
                selfChosenClosing: words,
              ) ??
              CareJournalEntry(
                id: 'letter:$sourceLetterId',
                createdAt: now,
                updatedAt: now,
                sourceLetterId: sourceLetterId,
                selfChosenClosing: words,
              ),
        );
        _track(AnalyticsEvents.letterClosingSaved);
      });

  Future<CareJournalEntry> planAction({
    required CareActionKind kind,
    String? customLabel,
    String? contextLabel,
    String? sourceLetterId,
    String? operationId,
  }) => _serialized(() async {
    final box = await _openBox();
    await _read(box);
    if (sourceLetterId != null) _requireLetter(sourceLetterId);
    final now = _clock().toUtc();
    final id = operationId == null
        ? 'care_${now.microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 30)}'
        : 'care_$operationId';
    for (final existing in _entries) {
      if (existing.id == 'action:$id') return existing;
    }
    final action = switch (kind) {
      CareActionKind.rest => CareAction.rest,
      CareActionKind.walk => CareAction.walk,
      CareActionKind.meditation => CareAction.meditation,
      CareActionKind.custom => CareAction.custom,
    };
    if (kind == CareActionKind.custom &&
        (customLabel == null ||
            customLabel.trim().isEmpty ||
            customLabel.length > 120)) {
      throw const FormatException('돌봄 이름을 120자 안으로 적어주세요.');
    }
    final entry = SelfCareEntry(
      id: id,
      createdAt: now,
      sourceLetterId: sourceLetterId,
      action: action,
      plan: kind == CareActionKind.custom ? customLabel!.trim() : '',
      contextLabel: contextLabel?.trim().isEmpty == true
          ? null
          : contextLabel?.trim(),
    );
    await _selfCare.save(entry);
    await _read(box);
    _track(AnalyticsEvents.careActionPlanned);
    return projectAction(entry);
  });

  Future<void> completeAction(String id, {CareHelpfulness? helpfulness}) =>
      _serialized(() async {
        if (!id.startsWith('action:'))
          throw StateError('This is not a care action');
        await _read(await _openBox());
        final previous = _entries.firstWhere((entry) => entry.id == id);
        final feedback = switch (helpfulness) {
          CareHelpfulness.helped => CareFeedback.helped,
          CareHelpfulness.same => CareFeedback.unchanged,
          CareHelpfulness.harder => CareFeedback.uncomfortable,
          CareHelpfulness.unknown => CareFeedback.unsure,
          null => null,
        };
        await _selfCare.complete(id.substring(7), feedback: feedback);
        await _read(await _openBox());
        if (previous.completedAt == null)
          _track(AnalyticsEvents.careActionCompleted);
        if (helpfulness != null && helpfulness != previous.helpfulness)
          _track(AnalyticsEvents.careActionReviewed);
      });

  /// Only a real received encouragement, explicitly chosen by its recipient.
  Future<void> saveReceivedEncouragement({
    required String sourceId,
    required String text,
    required String author,
    bool Function()? stillCurrent,
  }) => _serialized(() async {
    if (stillCurrent != null && !stillCurrent())
      throw StateError('Account changed');
    final box = await _openBox();
    await _read(box);
    final id = 'encouragement:$sourceId';
    if (box.containsKey(id)) return;
    final now = _clock().toUtc();
    if (stillCurrent != null && !stillCurrent())
      throw StateError('Account changed');
    await _write(
      box,
      CareJournalEntry(
        id: id,
        createdAt: now,
        updatedAt: now,
        encouragementText: text,
        encouragementSourceId: sourceId,
        encouragementAuthor: author,
      ),
    );
    if (stillCurrent != null && !stillCurrent()) {
      await box.delete(id);
      await box.flush();
      await _read(box);
      throw StateError('Account changed');
    }
  });

  Future<void> remove(String id) => _serialized(() async {
    final box = await _openBox();
    LocalRecordTransaction.capture(box, afterRollback: () => _read(box));
    if (id.startsWith('action:')) {
      await _selfCare.remove(id.substring(7));
    } else {
      await box.delete(id);
      await box.flush();
    }
    await _read(box);
  });

  Future<void> removeForLetter(String letterId) =>
      removeLetterSource(letterId, () async {});

  Future<void> removeLetterSource(
    String letterId,
    Future<void> Function() deleteSource,
  ) => _serialized(() async {
    final box = await _openBox();
    await _read(box);
    final keys = _entries
        .where(
          (e) => e.sourceLetterId == letterId && !e.id.startsWith('action:'),
        )
        .map((e) => e.id)
        .toList();
    LocalRecordTransaction.capture(box, afterRollback: () => _read(box));
    await box.deleteAll(keys);
    await box.flush();
    await _selfCare.removeForLetter(letterId);
    await deleteSource();
    await _read(box);
  });

  Future<void> clear() => _serialized(() async {
    final box = await _openBox();
    LocalRecordTransaction.capture(box, afterRollback: () => _read(box));
    await box.clear();
    await box.flush();
    await _selfCare.clear();
    await _read(box);
  });
}
