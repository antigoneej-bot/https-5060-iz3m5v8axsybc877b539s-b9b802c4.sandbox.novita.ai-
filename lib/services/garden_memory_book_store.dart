import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/garden_memory_book.dart';
import '../models/letter_entry.dart';
import '../mongi/integration/plant_memory_store.dart';
import '../mongi/integration/mongi_garden_store.dart';
import '../mongi/models/seed.dart';
import 'access_policy.dart';
import 'care_journal_store.dart';
import 'hive_encryption.dart';
import 'self_care_store.dart';
import 'local_record_transaction.dart';
import 'private_letter_memory_source.dart';
import 'subscription_service.dart';

export '../models/garden_memory_book.dart';

/// Personal books stay in encrypted local storage. Remote social snapshots do
/// not read this box. Entitlements never decide whether old books can be read.
class GardenMemoryBookStore extends ValueNotifier<List<GardenMemoryBook>> {
  static const boxName = 'garden_memory_books_local_user';
  static final instance = GardenMemoryBookStore();
  static const policyKey = '__creation_policy';
  static const creationPolicy = {'version': 1, 'firstBookCreated': true};
  static void validatePolicy(Object? raw) {
    if (raw is! Map ||
        raw.length != 2 ||
        raw['version'] != 1 ||
        raw['firstBookCreated'] != true) {
      throw const FormatException('기록집 생성 이력을 확인해 주세요.');
    }
  }

  bool _firstBookCreated = false;
  final Future<Box> Function() _open;
  final Future<bool> Function() _premium;
  final FutureOr<List<LetterEntry>> Function() _letters;
  final Future<List<GardenBookCare>> Function() _helpfulCare;
  final Future<List<GardenBookPlant>> Function() _plants;
  final DateTime Function() _now;
  final _queue = LocalRecordQueue();

  GardenMemoryBookStore({
    Future<Box> Function()? open,
    Future<bool> Function()? premium,
    FutureOr<List<LetterEntry>> Function()? letters,
    Future<List<GardenBookCare>> Function()? helpfulCare,
    Future<List<GardenBookPlant>> Function()? plants,
    DateTime Function()? now,
  }) : _open = open ?? (() => HiveEncryption.openBox(boxName)),
       _premium = premium ?? (() => SubscriptionService().isPremium()),
       _letters = letters ?? PrivateLetterMemorySource.bookLetters,
       _helpfulCare = helpfulCare ?? _readHelpfulCare,
       _plants = plants ?? _readPlants,
       _now = now ?? DateTime.now,
       super(const []);

  static Future<List<GardenBookCare>> _readHelpfulCare() async {
    // Do not enter the care-hub queue while holding the book queue. Deleting a
    // care entry scrubs book copies first, and otherwise the two queues cycle.
    final actions = await SelfCareStore.instance.load();
    return [
      for (final entry
          in actions
              .where((entry) => entry.action != null)
              .map(CareJournalStore.projectAction))
        if (entry.wasHelpful && entry.actionLabel != null)
          GardenBookCare(
            entryId: entry.id,
            actionLabel: entry.actionLabel!,
            completedAt: entry.completedAt!.toLocal(),
            sourceLetterId: entry.sourceLetterId,
          ),
    ];
  }

  static Future<List<GardenBookPlant>> _readPlants() async {
    // No plant queue is held here. Private plant deletion holds the book queue
    // until its source write completes, preventing a stale editor restoring it.
    final box = await HiveEncryption.openBox(PlantMemoryStore.boxName);
    await MongiGardenStore.instance.reload();
    return [
      for (final seed in SeedType.all)
        if (box.get(seed.id) case final Map raw)
          GardenBookPlant(
            plantId: seed.id,
            name: PlantMemory.fromJson(raw).name.trim().isEmpty
                ? seed.label
                : PlantMemory.fromJson(raw).name,
            anniversaryOn: PlantMemory.fromJson(raw).anniversaryOn,
          )
        else if ((MongiGardenStore.instance.value.seeds[seed.id] ?? 0) > 0)
          GardenBookPlant(plantId: seed.id, name: seed.label),
    ];
  }

  Future<void> _serial(Future<void> Function() action) =>
      LocalRecordTransaction.atomic(() => _queued(action));

  Future<void> _queued(Future<void> Function() action) => _queue.run(action);

  Future<void> _reloadAfterRollback() => _reload(migratePolicy: false);

  Future<void> _reload({bool migratePolicy = true}) async {
    final box = await _open();
    final books = <GardenMemoryBook>[];
    final policy = box.get(policyKey);
    if (policy != null) validatePolicy(policy);
    _firstBookCreated = policy != null;
    for (final key in box.keys) {
      if (key == policyKey) continue;
      final raw = box.get(key);
      if (raw is! Map) throw const FormatException('기록집을 읽지 못했어요.');
      final book = GardenMemoryBook.fromJson(raw);
      if (book.id != key) throw const FormatException('기록집 번호를 확인해 주세요.');
      books.add(book);
    }
    // Existing books consume the original offer too. Persist before a later
    // deletion can remove the last evidence; old books remain freely readable.
    if (!_firstBookCreated && books.isNotEmpty && migratePolicy) {
      LocalRecordTransaction.capture(box, afterRollback: _reloadAfterRollback);
      await box.put(policyKey, creationPolicy);
      await box.flush();
      _firstBookCreated = true;
    }
    _firstBookCreated = _firstBookCreated || books.isNotEmpty;
    books.sort((a, b) => b.month.compareTo(a.month));
    value = List.unmodifiable(books);
  }

  Future<void> reload() => _serial(_reload);

  Future<void> save(GardenMemoryBook book) => _serial(() async {
    GardenMemoryBook.fromJson(book.toJson());
    await _reload();
    final existing = value.where((item) => item.id == book.id).firstOrNull;
    if ((existing == null && (_firstBookCreated || book.style != 'basic')) ||
        (existing != null &&
            existing.style != book.style &&
            book.style == 'seasonal')) {
      if (!await _premium()) {
        throw const SubscriptionRequired(
          '첫 기본 기록집은 무료예요. 새 달의 기록집과 계절 표지는 마음냥 구독으로 만들 수 있어요. 이미 만든 기록집은 계속 볼 수 있어요.',
        );
      }
    }
    if (existing != null &&
        (existing.createdAt != book.createdAt ||
            jsonEncode(existing.snapshot.toJson()) !=
                jsonEncode(book.snapshot.toJson()))) {
      throw const FormatException('기존 기록집에 담긴 정원 구성은 바꿀 수 없어요.');
    }
    final now = _now();
    if (parseGardenBookMonth(
          book.month,
        ).isAfter(DateTime(now.year, now.month)) ||
        book.createdAt.isAfter(now) ||
        book.updatedAt.isAfter(now) ||
        book.snapshot.capturedAt.isAfter(now)) {
      throw const FormatException('아직 오지 않은 날의 기록집은 만들 수 없어요.');
    }
    final box = await _open();
    if (book.plants.isNotEmpty) {
      final plants = {
        for (final plant in await _plants()) plant.plantId: plant,
      };
      for (final plant in book.plants) {
        final source = plants[plant.plantId];
        if (source == null ||
            source.name != plant.name ||
            source.anniversaryOn != plant.anniversaryOn) {
          throw const FormatException('식물 기록이 변경되었어요. 남길 이름과 기념일을 다시 골라 주세요.');
        }
      }
    }
    if (book.care.isNotEmpty) {
      final helpful = {
        for (final entry in await _helpfulCare()) entry.entryId: entry,
      };
      for (final entry in book.care) {
        final source = helpful[entry.entryId];
        final previous = existing?.care
            .where((saved) => saved.entryId == entry.entryId)
            .firstOrNull;
        final preservedDay =
            previous != null && previous.calendarDate == entry.calendarDate;
        if (source == null ||
            source.actionLabel != entry.actionLabel ||
            !source.completedAt.isAtSameMomentAs(entry.completedAt) ||
            source.sourceLetterId != entry.sourceLetterId ||
            (source.calendarDate != entry.calendarDate && !preservedDay)) {
          throw const FormatException('돌봄 기록이 변경되었어요. 도움이 된 경험을 다시 골라 주세요.');
        }
      }
    }
    // Read the source again after every asynchronous validation, immediately
    // before writing, so a deleted letter cannot reappear from an open editor.
    final letters = {for (final letter in await _letters()) letter.id: letter};
    for (final quote in book.quotes) {
      final source = letters[quote.letterId];
      final previous = existing?.quotes
          .where((saved) => saved.letterId == quote.letterId)
          .firstOrNull;
      final preservedDay =
          previous != null && previous.calendarDate == quote.calendarDate;
      final localSourceDay = source?.date.toLocal();
      if (source == null ||
          !source.date.isAtSameMomentAs(quote.writtenAt) ||
          !source.letterText.contains(quote.text) ||
          (!preservedDay &&
              (localSourceDay == null ||
                  DateTime(
                        localSourceDay.year,
                        localSourceDay.month,
                        localSourceDay.day,
                      ) !=
                      quote.calendarDate))) {
        throw const FormatException('편지가 변경되었어요. 담을 문장을 다시 골라 주세요.');
      }
    }
    LocalRecordTransaction.capture(box, afterRollback: _reloadAfterRollback);
    await box.put(book.id, book.toJson());
    await box.put(policyKey, creationPolicy);
    await box.flush();
    await _reload();
  });

  Future<void> appendReflection(String id, String text) => _serial(() async {
    await _reload();
    final book = value.where((item) => item.id == id).firstOrNull;
    if (book == null) throw StateError('기록집을 다시 열어 주세요.');
    final now = _now();
    final next = book.copy(
      updatedAt: now,
      reflections: [
        ...book.reflections,
        GardenBookReflection(at: now, text: text.trim()),
      ],
    );
    GardenMemoryBook.fromJson(next.toJson());
    final box = await _open();
    LocalRecordTransaction.capture(box, afterRollback: _reloadAfterRollback);
    await box.put(id, next.toJson());
    await box.flush();
    await _reload();
  });

  Future<void> remove(String id) => _serial(() async {
    await _reload();
    final box = await _open();
    LocalRecordTransaction.capture(box, afterRollback: _reloadAfterRollback);
    await box.delete(id);
    await box.flush();
    await _reload();
  });

  Future<void> _scrubCopies({
    String? letterId,
    String? careEntryId,
    String? plantId,
  }) async {
    await _reload();
    final box = await _open();
    LocalRecordTransaction.capture(box, afterRollback: _reloadAfterRollback);
    for (final book in value) {
      final next = book.copy(
        updatedAt: _now(),
        quotes: book.quotes.where((q) => q.letterId != letterId).toList(),
        care: book.care
            .where(
              (entry) =>
                  (letterId == null || entry.sourceLetterId != letterId) &&
                  entry.entryId != careEntryId,
            )
            .toList(),
        plants: book.plants.where((plant) => plant.plantId != plantId).toList(),
      );
      if (next.quotes.length != book.quotes.length ||
          next.care.length != book.care.length ||
          next.plants.length != book.plants.length) {
        await box.put(book.id, next.toJson());
      }
    }
    await box.flush();
    await _reload();
  }

  Future<void> removeForLetter(String letterId) =>
      _serial(() => _scrubCopies(letterId: letterId));
  Future<void> removeForCareEntry(String entryId) =>
      _serial(() => _scrubCopies(careEntryId: entryId));
  Future<void> removeForPlant(String plantId) =>
      _serial(() => _scrubCopies(plantId: plantId));

  /// Source deletion and copied-text cleanup share the book write lock. The
  /// callback must only delete its source: never call this store recursively or
  /// enter a care-facade/notification queue that can wait for this store.
  Future<void> removeLetterSource(
    String letterId,
    Future<void> Function() deleteSource,
  ) => _serial(() async {
    await _scrubCopies(letterId: letterId);
    await deleteSource();
  });

  Future<void> removeCareSource(
    String entryId,
    Future<void> Function() deleteSource,
  ) => _serial(() async {
    await _scrubCopies(careEntryId: entryId);
    await deleteSource();
  });

  Future<void> removePlantSource(
    String plantId,
    Future<void> Function() deleteSource,
  ) => _serial(() async {
    await _scrubCopies(plantId: plantId);
    await deleteSource();
  });

  Future<void> clear({bool resetPolicy = false}) => _serial(() async {
    await _reload();
    final box = await _open();
    LocalRecordTransaction.capture(box, afterRollback: _reloadAfterRollback);
    await box.clear();
    if (_firstBookCreated && !resetPolicy) {
      await box.put(policyKey, creationPolicy);
    }
    _firstBookCreated = _firstBookCreated && !resetPolicy;
    await box.flush();
    value = const [];
  });
}
