import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/screens/history_screen.dart';

import 'package:flutter_app/models/special_letter_entry.dart';
import 'package:flutter_app/services/access_policy.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/personal_reply_service.dart';
import 'package:flutter_app/services/special_letter_service.dart';
import 'package:flutter_app/services/storage_service.dart';
import 'package:flutter_app/widgets/saved_heart_reply.dart';

const _refreshLabel = '새 문안으로 답장 다시 받기';
const _oldReply = '예전에 받은 답장입니다. 오늘은 산책을 나가 보는 게 좋겠어요.';
const _done = '새 문안의 답장으로 바꿨어요. 원래 편지와 정원 기록은 그대로예요.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box letters;
  late Box replies;
  late Box feedback;
  final today = DateTime(2026, 10, 16);
  final quota = 'quota:${AccessPolicy.dayKey(today)}';
  const storage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reply-refresh-ui-');
    Hive.init(directory.path);
    await initializeDateFormatting('ko_KR');
    SharedPreferences.setMockInitialValues({'is_premium_subscriber': false});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          storage,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.generate(32, (i) => i))
              : null,
        );
    PersonalReplyService.clock = () => today;
    await SpecialLetterService.setCurrentUser('reply_ui');
    letters = await HiveEncryption.openBox('special_letters_reply_ui');
    replies = await HiveEncryption.openBox('personal_replies_local_user');
    feedback = await HiveEncryption.openBox('reply_feedback_local_user');
    // An old answer can be repaired even after today's free answer was used.
    await replies.put(quota, 1);
  });

  tearDown(() async {
    PersonalReplyService.clock = DateTime.now;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, null);
  });

  SpecialLetterEntry entry(String id, {String reply = _oldReply}) =>
      SpecialLetterEntry(
        id: id,
        type: SpecialLetterType.gratitude,
        letterText: '친구가 내 이야기를 끝까지 들어 줘서 고마웠어.',
        replyText: reply,
        createdAt: DateTime(2026, 10, 10),
      );

  Future<void> seed(SpecialLetterEntry saved) async {
    await letters.put(saved.id, saved.toMap());
    await replies.put(
      'heart:${saved.id}',
      jsonEncode({
        'id': 'heart:${saved.id}',
        'reply': saved.replyText,
        'engineVersion': 0,
        'parts': [saved.replyText],
        'style': 'listen',
      }),
    );
  }

  Widget screen(SpecialLetterEntry saved) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SavedHeartReply(entry: saved),
      ),
    ),
  );

  // Hive uses real file IO. Wait for that IO rather than advancing the widget's
  // artificial clock to a timeout or waiting for unrelated animations.
  Future<void> until(WidgetTester tester, Finder finder) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (finder.evaluate().isNotEmpty) return;
    }
    expect(finder, findsWidgets);
  }

  Future<void> drainIo(WidgetTester tester) async {
    // Let widget-owned metadata / feedback reads finish in their original
    // fake zone before the test closes Hive. Awaiting those same futures from
    // runAsync would deadlock because their callbacks need the next pump.
    for (var attempt = 0; attempt < 10; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
  }

  Future<T> io<T>(WidgetTester tester, Future<T> Function() operation) async {
    var complete = false;
    T? value;
    Object? failure;
    operation().then(
      (result) {
        value = result;
        complete = true;
      },
      onError: (Object error, StackTrace stack) {
        failure = error;
        complete = true;
      },
    );
    for (var attempt = 0; attempt < 300 && !complete; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(complete, isTrue, reason: 'The fixture IO must finish.');
    if (failure != null) throw failure!;
    return value as T;
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await drainIo(tester);
    var closed = false;
    Hive.close().then((_) => closed = true);
    for (var attempt = 0; attempt < 100 && !closed; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(
      closed,
      isTrue,
      reason: 'Complete Hive IO before leaving fakeAsync.',
    );
    await tester.runAsync(() => directory.delete(recursive: true));
  }

  Future<void> checkExplicitRefresh(WidgetTester tester) async {
    final saved = entry('explicit');
    await io(tester, () async {
      await seed(saved);
      await PersonalReplyService.setFeedback('heart:${saved.id}', 'matched');
    });
    await tester.pumpWidget(screen(saved));
    await until(tester, find.text(_refreshLabel));
    await until(
      tester,
      find.byWidgetPredicate((w) => w is FilterChip && w.selected),
    );
    expect(find.text(_oldReply), findsOneWidget);
    expect(replies.get(quota), 1);

    await tester.tap(find.text(_refreshLabel));
    await tester.pump();
    expect(find.text(_oldReply), findsOneWidget);
    final action = tester.widget<TextButton>(
      find.ancestor(
        of: find.text(_refreshLabel),
        matching: find.byWidgetPredicate((widget) => widget is TextButton),
      ),
    );
    expect(action.onPressed, isNull);
    await until(tester, find.text(_done));
    expect(find.text(_oldReply), findsNothing);
    expect(find.text(_refreshLabel), findsNothing);
    expect(
      find.byWidgetPredicate((w) => w is FilterChip && w.selected),
      findsNothing,
    );
    expect(feedback.get('heart:${saved.id}'), isNull);
    expect(replies.get(quota), 1);
    final replaced = SpecialLetterEntry.fromMap(letters.get(saved.id) as Map);
    expect(replaced.letterText, saved.letterText);
    expect(replaced.replyText, isNot(_oldReply));
    expect(replaced.replyText, isNotEmpty);
    expect(tester.takeException(), isNull);

    // A reopened dialog may still receive an old object from its parent.
    // The latest stored reply must win and must not offer another replacement.
    await drainIo(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen(saved));
    await until(tester, find.text(replaced.replyText));
    expect(find.text(_oldReply), findsNothing);
    expect(find.text(_refreshLabel), findsNothing);
    await drainIo(tester);
    await tester.pumpWidget(const SizedBox());
  }

  Future<void> checkFailedRefresh(WidgetTester tester) async {
    final saved = entry('failure');
    await io(tester, () => seed(saved));
    await tester.pumpWidget(screen(saved));
    await until(tester, find.text(_refreshLabel));
    // The underlying letter disappeared while its dialog remained open.
    await io(tester, () => letters.delete(saved.id));
    await tester.tap(find.text(_refreshLabel));
    await until(tester, find.text('새 답장 다시 시도'));
    expect(find.text(_oldReply), findsOneWidget);
    expect(find.text('새 답장을 준비하지 못했어요. 기존 답장은 그대로예요.'), findsOneWidget);
    expect(find.text(_done), findsNothing);
    expect(replies.get(quota), 1);

    await io(tester, () => letters.put(saved.id, saved.toMap()));
    await tester.tap(find.text('새 답장 다시 시도'));
    await until(tester, find.text(_done));
    expect(find.text(_oldReply), findsNothing);
    expect(replies.get(quota), 1);
    expect(tester.takeException(), isNull);
    await drainIo(tester);
    await tester.pumpWidget(const SizedBox());
  }

  Future<void> checkEntryChange(WidgetTester tester) async {
    final first = entry('first', reply: '첫 번째 편지의 답장입니다.');
    final second = entry('second', reply: '두 번째 편지의 답장입니다.');
    await io(tester, () async {
      await seed(first);
      await seed(second);
    });
    await tester.pumpWidget(screen(first));
    await tester.pumpWidget(screen(second));
    await until(tester, find.text(second.replyText));
    expect(find.text(first.replyText), findsNothing);
    expect(find.text(_done), findsNothing);
    expect(tester.takeException(), isNull);
    await drainIo(tester);
    await tester.pumpWidget(const SizedBox());
  }

  Future<void> checkCatHistory(WidgetTester tester) async {
    final catLetter = LetterEntry(
      id: 'cat-repair',
      catId: shadowCats.first.id,
      date: DateTime(2026, 10, 10),
      letterText: '오늘은 별일 없이 편안하게 하루를 보냈어.',
    );
    final app = _HistoryApp()..history = [catLetter];
    final care = CatCareProvider();
    addTearDown(app.dispose);
    addTearDown(care.dispose);
    await io(tester, () async {
      await StorageService.setCurrentUser('local_user');
      await StorageService.saveLetter(catLetter);
      final cache = await HiveEncryption.openBox('reply_cache_local_user');
      await cache.put(catLetter.id, _oldReply);
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: app),
          ChangeNotifierProvider<CatCareProvider>.value(value: care),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: HistoryScreen())),
        ),
      ),
    );
    await tester.ensureVisible(find.text('💌 답장 도착'));
    await tester.tap(find.text('💌 답장 도착'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await until(tester, find.text(_refreshLabel));
    expect(find.text(_oldReply), findsOneWidget);
    await tester.ensureVisible(find.text(_refreshLabel));
    await tester.tap(find.text(_refreshLabel));
    await until(tester, find.text(_done));
    expect(find.text(_oldReply), findsNothing);
    expect(app.history.single.letterText, catLetter.letterText);
    expect(replies.get(quota), 1);
    expect(app.seen, contains(catLetter.id));
    expect(tester.takeException(), isNull);
    await drainIo(tester);
    await tester.pumpWidget(const SizedBox());
  }

  Future<void> checkImmediateCatSupport(WidgetTester tester) async {
    final saved = LetterEntry(
      id: 'cat-support',
      catId: shadowCats.first.id,
      date: DateTime.now(),
      letterText: '나는 지금 죽고 싶어.',
    );
    final app = _HistoryApp()..history = [saved];
    final care = CatCareProvider();
    addTearDown(app.dispose);
    addTearDown(care.dispose);
    await io(tester, () async {
      await StorageService.saveLetter(saved);
      final cache = await HiveEncryption.openBox('reply_cache_local_user');
      await cache.put(saved.id, '기쁜 하루였겠어요. 축하해요!');
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppStateProvider>.value(value: app),
          ChangeNotifierProvider<CatCareProvider>.value(value: care),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: HistoryScreen())),
        ),
      ),
    );
    final cat = shadowCatById(saved.catId);
    final card = find.text('${cat.emoji} ${cat.nameKr}');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('지금 도움받을 곳 보기'), findsOneWidget);
    expect(find.text('기쁜 하루였겠어요. 축하해요!'), findsNothing);
    expect(replies.get(quota), 1);
    expect(
      app.seen,
      isNot(contains(saved.id)),
      reason: 'Immediate support does not mark a future reply arrived.',
    );
    await drainIo(tester);
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets(
    'reply refresh: explicit action, quota, feedback, failure retry, entry change and cat history',
    (tester) async {
      try {
        await checkExplicitRefresh(tester);
        await checkFailedRefresh(tester);
        await checkEntryChange(tester);
        await checkCatHistory(tester);
        await checkImmediateCatSupport(tester);
      } finally {
        await finish(tester);
      }
    },
  );
}

class _HistoryApp extends AppStateProvider {
  final Set<String> seen = {};
  @override
  Future<void> markReplySeen(String id) async {
    seen.add(id);
  }
}
