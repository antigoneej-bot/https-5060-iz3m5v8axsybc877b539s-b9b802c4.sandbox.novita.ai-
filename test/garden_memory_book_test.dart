import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/services/access_policy.dart';
import 'package:flutter_app/services/garden_memory_book_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final captured = DateTime(2026, 10, 21, 12);
  final letter = LetterEntry(
    id: 'letter-1',
    catId: 'angry',
    date: DateTime(2026, 9, 3),
    letterText: '오늘은 답을 찾지 못했어. 그래도 내 마음을 남겨둔다.',
  );
  GardenBookSnapshot snapshot() => GardenBookSnapshot(
    capturedAt: captured,
    seeds: {'pine': 3},
    decorations: [],
    layout: GardenLayout(),
    memoryDays: 7,
    companionName: '나비',
  );
  GardenMemoryBook book({
    String month = '2026-09',
    String style = 'basic',
    bool quotes = true,
    List<GardenBookCare> care = const [],
  }) => GardenMemoryBook(
    month: month,
    style: style,
    createdAt: captured,
    updatedAt: captured,
    snapshot: snapshot(),
    quotes: quotes
        ? [
            GardenBookQuote(
              letterId: letter.id,
              writtenAt: letter.date,
              text: '그래도 내 마음을 남겨둔다.',
            ),
          ]
        : [],
    plants: const [
      GardenBookPlant(
        plantId: 'pine',
        name: '첫 나무',
        anniversaryOn: '2026-09-03',
      ),
    ],
    care: care,
  );

  test('UTC-backed dates group by the device calendar month', () {
    final local = DateTime(2026, 10, 1, 0, 30);
    expect(gardenBookMonth(local.toUtc()), '2026-10');
  });

  test('saved calendar days survive timezone changes and legacy parsing', () {
    final raw = book(month: '2026-10', quotes: false).toJson();
    raw['quotes'] = [
      {
        'letterId': letter.id,
        'text': letter.letterText,
        'writtenAt': '2026-09-30T15:30:00.000Z',
        'calendarDay': '2026-10-01',
      },
    ];
    final modern = GardenMemoryBook.fromJson(raw);
    expect(modern.quotes.single.calendarDate, DateTime(2026, 10, 1));
    final legacy = {...raw, 'month': '2026-09', 'id': 'book-2026-09'};
    legacy['quotes'] = [
      {...((raw['quotes'] as List).single as Map)}..remove('calendarDay'),
    ];
    expect(
      GardenMemoryBook.fromJson(legacy).quotes.single.calendarDate,
      DateTime(2026, 9, 30),
    );
  });

  test(
    'an old month keeps truthful capture date and selected source dates',
    () {
      final restored = GardenMemoryBook.fromJson(book().toJson());
      expect(restored.month, '2026-09');
      expect(restored.snapshot.capturedAt, captured);
      expect(restored.quotes.single.writtenAt, DateTime(2026, 9, 3));
      expect(restored.snapshot.toJson().keys, isNot(contains('letterText')));
    },
  );

  test(
    'month mismatch, invalid snapshot and extra private fields rejected',
    () {
      expect(
        () => GardenMemoryBook.fromJson(book(month: '2026-10').toJson()),
        throwsFormatException,
      );
      final invalid = book().toJson();
      (invalid['snapshot'] as Map)['authToken'] = 'must-never-import';
      expect(() => GardenMemoryBook.fromJson(invalid), throwsFormatException);
      final nested = book().toJson();
      ((nested['snapshot'] as Map)['layout'] as Map)['privateText'] = 'unknown';
      expect(() => GardenMemoryBook.fromJson(nested), throwsFormatException);
      final future = book().toJson();
      (future['snapshot'] as Map)['capturedAt'] = DateTime(
        2026,
        11,
      ).toIso8601String();
      expect(() => GardenMemoryBook.fromJson(future), throwsFormatException);
    },
  );

  test('letter removal scrubs copied sentence and related care only', () {
    final withCare = book(
      care: [
        GardenBookCare(
          entryId: 'care-1',
          actionLabel: '잠깐 쉬기',
          sourceLetterId: letter.id,
          completedAt: DateTime(2026, 9, 3),
        ),
      ],
    );
    final result = withCare.withoutLetter(letter.id);
    expect(result.quotes, isEmpty);
    expect(result.care, isEmpty);
    expect(result.plants.single.name, '첫 나무');
    expect(result.snapshot.seeds, {'pine': 3});
    GardenMemoryBook.fromJson(result.toJson());
  });

  test(
    'sharing excludes private categories and source identifiers by default',
    () {
      final original = book();
      expect(original.shareText(), '마음냥 정원 · 2026-09의 기록집');
      final selected = original.shareText(includePlants: true);
      expect(selected, contains('첫 나무'));
      expect(selected, isNot(contains(original.quotes.single.text)));
      expect(selected, isNot(contains(letter.id)));
      final quoted = original.shareText(includeQuotes: true);
      expect(quoted, contains(original.quotes.single.text));
      expect(quoted, isNot(contains('첫 나무')));
    },
  );

  group('encrypted-store contract with isolated test storage', () {
    late Directory directory;
    late Box box;
    late GardenMemoryBookStore store;
    late bool premium;
    late int entitlementReads;
    late List<LetterEntry> letters;
    late List<GardenBookCare> helpful;
    late List<GardenBookPlant> plants;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('garden-book-test-');
      Hive.init(directory.path);
      box = await Hive.openBox('memory-book-tests');
      premium = false;
      entitlementReads = 0;
      letters = [letter];
      helpful = [];
      plants = book().plants;
      store = GardenMemoryBookStore(
        open: () async => box,
        premium: () async {
          entitlementReads++;
          return premium;
        },
        letters: () => letters,
        helpfulCare: () async => helpful,
        plants: () async => plants,
        now: () => DateTime(2026, 10, 21, 13),
      );
    });
    tearDown(() async {
      store.dispose();
      await Hive.close();
      await directory.delete(recursive: true);
    });

    test(
      'first basic book is free, duplicate saves idempotent, next month gated',
      () async {
        await store.save(book());
        await store.save(book());
        expect(box.keys.toSet(), {
          'book-2026-09',
          GardenMemoryBookStore.policyKey,
        });
        expect(entitlementReads, 0);
        await expectLater(
          store.save(book(month: '2026-10', quotes: false)),
          throwsA(isA<SubscriptionRequired>()),
        );
        premium = true;
        await store.save(book(month: '2026-10', quotes: false));
        expect(store.value.length, 2);
      },
    );

    test('deleting the first book never renews the free offer', () async {
      await store.save(book());
      await store.remove('book-2026-09');
      await store.reload();
      expect(store.value, isEmpty);
      await expectLater(
        store.save(book(month: '2026-10', quotes: false)),
        throwsA(isA<SubscriptionRequired>()),
      );
      expect(
        box.get(GardenMemoryBookStore.policyKey),
        GardenMemoryBookStore.creationPolicy,
      );
      premium = true;
      await store.save(book(month: '2026-10', quotes: false));
      expect(store.value.single.month, '2026-10');
    });

    test(
      'old books migrate the consumed offer before last-book deletion',
      () async {
        await box.put(book().id, book().toJson());
        await store.remove(book().id);
        expect(store.value, isEmpty);
        await expectLater(
          store.save(book(month: '2026-10', quotes: false)),
          throwsA(isA<SubscriptionRequired>()),
        );
      },
    );

    test('restored consumed offer without books remains consumed', () async {
      await box.put(
        GardenMemoryBookStore.policyKey,
        GardenMemoryBookStore.creationPolicy,
      );
      await store.reload();
      await expectLater(
        store.save(book()),
        throwsA(isA<SubscriptionRequired>()),
      );
    });

    test(
      'lapse preserves read/edit/reflection without entitlement lookup',
      () async {
        premium = true;
        await store.save(book(style: 'seasonal'));
        premium = false;
        entitlementReads = 0;
        await store.reload();
        await store.save(store.value.single.copy(quotes: []));
        await store.appendReflection('book-2026-09', '지금은 잠시 쉬고 싶다.');
        expect(store.value.single.reflections.single.text, '지금은 잠시 쉬고 싶다.');
        expect(entitlementReads, 0);
      },
    );

    test('stale deleted letter and fabricated quote cannot be saved', () async {
      letters = [];
      await expectLater(store.save(book()), throwsFormatException);
      letters = [letter];
      final fabricated = book().copy(
        quotes: [
          GardenBookQuote(
            letterId: letter.id,
            writtenAt: letter.date,
            text: '이제 모든 문제가 해결됐어.',
          ),
        ],
      );
      await expectLater(store.save(fabricated), throwsFormatException);
      expect(box.isEmpty, isTrue);
    });

    test('care needs a current explicitly helpful completed source', () async {
      final selected = GardenBookCare(
        entryId: 'care-1',
        sourceLetterId: letter.id,
        actionLabel: '잠깐 쉬기',
        completedAt: DateTime(2026, 9, 3),
      );
      await expectLater(
        store.save(book(care: [selected])),
        throwsFormatException,
      );
      helpful = [selected];
      await store.save(book(care: [selected]));
      await store.removeForCareEntry('care-1');
      expect(store.value.single.care, isEmpty);
      expect(store.value.single.quotes.length, 1);
    });

    test('source deletion persists scrubbed copies across reload', () async {
      await store.save(book());
      await store.removeForLetter(letter.id);
      await store.reload();
      expect(store.value.single.quotes, isEmpty);
      expect(store.value.single.snapshot.seeds, {'pine': 3});
      await store.removeForPlant('pine');
      expect(store.value.single.plants, isEmpty);
      await store.clear();
      expect(box.keys.toList(), [GardenMemoryBookStore.policyKey]);
    });

    for (final source in ['letter', 'care', 'plant']) {
      test(
        '$source deletion blocks stale editor restoring private copies',
        () async {
          final selectedCare = GardenBookCare(
            entryId: 'care-private',
            sourceLetterId: letter.id,
            actionLabel: '내가 고른 개인 돌봄',
            completedAt: DateTime(2026, 9, 3),
          );
          helpful = [selectedCare];
          final oldEditor = book(care: [selectedCare]);
          await store.save(oldEditor);
          final deleting = Completer<void>();
          final continueDelete = Completer<void>();
          Future<void> deleteOriginal() async {
            deleting.complete();
            await continueDelete.future;
            switch (source) {
              case 'letter':
                letters = [];
              case 'care':
                helpful = [];
              case 'plant':
                plants = [];
            }
          }

          final deletion = switch (source) {
            'letter' => store.removeLetterSource(letter.id, deleteOriginal),
            'care' => store.removeCareSource(
              selectedCare.entryId,
              deleteOriginal,
            ),
            _ => store.removePlantSource('pine', deleteOriginal),
          };
          await deleting.future;
          var saveFinished = false;
          final staleSave = store.save(oldEditor);
          final checked = expectLater(staleSave, throwsFormatException).then((
            _,
          ) {
            saveFinished = true;
          });
          await Future<void>.delayed(Duration.zero);
          expect(
            saveFinished,
            isFalse,
            reason: 'source deletion holds book lock',
          );
          continueDelete.complete();
          await deletion;
          await checked;
          await store.reload();
          switch (source) {
            case 'letter':
              expect(store.value.single.quotes, isEmpty);
            case 'care':
              expect(store.value.single.care, isEmpty);
            case 'plant':
              expect(store.value.single.plants, isEmpty);
          }
        },
      );
    }

    test(
      'legacy stored calendar day remains editable after a timezone change',
      () async {
        final utcLetter = LetterEntry(
          id: letter.id,
          catId: letter.catId,
          date: DateTime.utc(2026, 9, 30, 15, 30),
          letterText: letter.letterText,
        );
        letters = [utcLetter];
        final legacy = book().toJson();
        legacy['quotes'] = [
          {
            'letterId': letter.id,
            'text': letter.letterText,
            'writtenAt': utcLetter.date.toIso8601String(),
          },
        ];
        await box.put('book-2026-09', legacy);
        await store.reload();
        await store.save(store.value.single);
        expect(store.value.single.month, '2026-09');
        expect(
          store.value.single.quotes.single.calendarDate,
          DateTime(2026, 9, 30),
        );
      },
    );

    test(
      'new quote cannot claim a different calendar day than its source',
      () async {
        final fabricated = book().copy(
          quotes: [
            GardenBookQuote(
              letterId: letter.id,
              text: letter.letterText,
              writtenAt: letter.date,
              calendarDay: '2026-09-04',
            ),
          ],
        );
        await expectLater(store.save(fabricated), throwsFormatException);
        expect(box.isEmpty, isTrue);
      },
    );

    test('saved snapshot cannot silently become a new garden', () async {
      await store.save(book());
      final original = book();
      final changed = GardenMemoryBook(
        month: original.month,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt,
        snapshot: GardenBookSnapshot(
          capturedAt: captured,
          seeds: {'pine': 100},
          decorations: [],
          layout: GardenLayout(),
          memoryDays: 7,
          companionName: '나비',
        ),
      );
      await expectLater(store.save(changed), throwsFormatException);
      expect(store.value.single.snapshot.seeds['pine'], 3);
    });
  });
}
