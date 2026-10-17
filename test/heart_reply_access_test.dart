import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/heart_letter_history_screen.dart';
import 'package:flutter_app/screens/heart_letters_screen.dart';
import 'package:flutter_app/mongi/screens/mental_health_support_screen.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/widgets/garden_path_card.dart';

import 'package:flutter_app/models/special_letter_entry.dart';
import 'package:flutter_app/services/access_policy.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/personal_reply_service.dart';
import 'package:flutter_app/services/special_letter_service.dart';
import 'package:flutter_app/widgets/saved_heart_reply.dart';

const _oldReply = '예전에 받은 답장입니다. 오늘은 산책을 나가 보는 게 좋겠어요.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Box letters;
  late Box replies;
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
    await HiveEncryption.openBox('reply_feedback_local_user');
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

  Widget screen(Widget child, AppStateProvider app) =>
      ChangeNotifierProvider<AppStateProvider>.value(
        value: app,
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [Locale('ko')],
          home: child,
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

  Future<void> checkAccess(WidgetTester tester) async {
    final app = AppStateProvider();
    addTearDown(app.dispose);
    final older = SpecialLetterEntry(
      id: 'older',
      type: SpecialLetterType.gratitude,
      letterText: '예전 편지. 친구가 도와줘서 고마워.',
      replyText: '',
      createdAt: DateTime(2026, 10, 10),
    );
    final newer = SpecialLetterEntry(
      id: 'newer',
      type: SpecialLetterType.gratitude,
      letterText: '최근 편지. 가족에게 정말 고마워.',
      replyText: '',
      createdAt: DateTime(2026, 10, 12),
    );
    try {
      await io(tester, () async {
        await letters.put(older.id, older.toMap());
        await letters.put(newer.id, newer.toMap());
        await replies.put(quota, 0);
      });
      await tester.pumpWidget(
        screen(
          const HeartLetterHistoryScreen(type: SpecialLetterType.gratitude),
          app,
        ),
      );
      await until(tester, find.text('답장 열기'));
      await drainIo(tester);
      expect(find.text('답장 열기'), findsNWidgets(2));
      expect(replies.get(quota), 0);
      expect(
        SpecialLetterEntry.fromMap(letters.get(newer.id) as Map).replyText,
        isEmpty,
      );
      await tester.tap(find.text(newer.letterText));
      await drainIo(tester);
      expect(
        SpecialLetterEntry.fromMap(letters.get(newer.id) as Map).replySeen,
        isFalse,
        reason: 'Expanding the original letter does not read a reply.',
      );
      final olderCard = find.ancestor(
        of: find.text(older.letterText),
        matching: find.byType(GlassBlob),
      );
      final openOlder = find.descendant(
        of: olderCard,
        matching: find.text('답장 열기'),
      );
      await tester.ensureVisible(openOlder);
      await tester.tap(openOlder);
      await until(tester, find.text('이번 답장은 어땠나요? (선택)'));
      await drainIo(tester);
      expect(replies.get(quota), 1);
      expect(
        SpecialLetterEntry.fromMap(letters.get(older.id) as Map).replyText,
        isNotEmpty,
      );
      expect(
        SpecialLetterEntry.fromMap(letters.get(newer.id) as Map).replyText,
        isEmpty,
      );
      expect(
        SpecialLetterEntry.fromMap(letters.get(older.id) as Map).replySeen,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await drainIo(tester);

      final cached = entry('below-fold');
      await io(tester, () => seed(cached));
      await tester.pumpWidget(
        screen(
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 1000),
                  SavedHeartReply(entry: cached),
                ],
              ),
            ),
          ),
          app,
        ),
      );
      await until(tester, find.text(_oldReply));
      await drainIo(tester);
      expect(
        SpecialLetterEntry.fromMap(letters.get(cached.id) as Map).replySeen,
        isFalse,
      );
      await tester.ensureVisible(find.text(_oldReply));
      await tester.pump();
      await drainIo(tester);
      expect(
        SpecialLetterEntry.fromMap(letters.get(cached.id) as Map).replySeen,
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      await drainIo(tester);

      final count = letters.length;
      await tester.pumpWidget(
        screen(
          const Scaffold(
            body: SingleChildScrollView(child: HeartLettersScreen()),
          ),
          app,
        ),
      );
      await tester.tap(find.text('지난 마음편지'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.widgetWithText(ListTile, '감사 편지'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(HeartLetterHistoryScreen), findsOneWidget);
      expect(
        letters.length,
        count,
        reason: 'Reading history never requires a new letter.',
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      await drainIo(tester);
    }
  }

  Future<void> checkSupport(WidgetTester tester) async {
    final app = AppStateProvider();
    addTearDown(app.dispose);
    final risk = SpecialLetterEntry(
      id: 'need-help',
      type: SpecialLetterType.gratitude,
      letterText: '나는 지금 죽고 싶어.',
      replyText: '기쁜 하루였겠어요. 축하해요!',
      createdAt: DateTime.now(),
    );
    try {
      await io(tester, () => seed(risk));
      await tester.pumpWidget(
        screen(
          const HeartLetterHistoryScreen(type: SpecialLetterType.gratitude),
          app,
        ),
      );
      await tester.pump();
      expect(find.text('지금 도움받을 곳 보기'), findsOneWidget);
      expect(find.text(risk.replyText), findsNothing);
      expect(replies.get(quota), 1);
      expect(
        SpecialLetterEntry.fromMap(letters.get(risk.id) as Map).replyText,
        risk.replyText,
      );
      await tester.ensureVisible(find.text('지금 도움받을 곳 보기'));
      await tester.tap(find.text('지금 도움받을 곳 보기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(MentalHealthSupportScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await drainIo(tester);
      // Already-arrived legacy answers follow the same independent support path.
      final arrivedRisk = SpecialLetterEntry(
        id: risk.id,
        type: risk.type,
        letterText: risk.letterText,
        replyText: risk.replyText,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      await io(tester, () => letters.put(arrivedRisk.id, arrivedRisk.toMap()));
      await tester.pumpWidget(
        screen(
          Scaffold(
            body: SingleChildScrollView(
              child: SavedHeartReply(entry: arrivedRisk),
            ),
          ),
          app,
        ),
      );
      await tester.pump();
      expect(find.text('지금 도움받을 곳 보기'), findsOneWidget);
      expect(find.text(risk.replyText), findsNothing);
      expect(replies.get(quota), 1);
      await drainIo(tester);
      expect(
        SpecialLetterEntry.fromMap(letters.get(risk.id) as Map).replySeen,
        isTrue,
      );
    } finally {
      await tester.pumpWidget(const SizedBox());
      await drainIo(tester);
    }
  }

  Future<void> checkResume(WidgetTester tester) async {
    final app = AppStateProvider();
    addTearDown(app.dispose);
    final pending = SpecialLetterEntry(
      id: 'arrival',
      type: SpecialLetterType.gratitude,
      letterText: '오늘 고마웠던 일을 적었어.',
      replyText: '',
      createdAt: DateTime.now(),
    );
    try {
      await io(tester, () => letters.put(pending.id, pending.toMap()));
      await tester.pumpWidget(
        screen(
          const HeartLetterHistoryScreen(type: SpecialLetterType.gratitude),
          app,
        ),
      );
      expect(find.text('답장은 내일 아침에 도착해요'), findsOneWidget);
      final ready = SpecialLetterEntry(
        id: pending.id,
        type: pending.type,
        letterText: pending.letterText,
        replyText: '',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await io(tester, () => letters.put(ready.id, ready.toMap()));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await drainIo(tester);
      await until(tester, find.text('답장 열기'));
      expect(find.text('답장은 내일 아침에 도착해요'), findsNothing);
      expect(replies.get(quota), 1);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await drainIo(tester);
    }
  }

  // Keep real Hive IO and its static serialized service queue in one fake zone.
  // Each scenario still resets persisted records and independently asserts behavior.
  testWidgets(
    'heart history access, quota, visible read state, immediate support and resume',
    (tester) async {
      Future<void> reset() => io(tester, () async {
        await letters.clear();
        await replies.clear();
        await replies.put(quota, 1);
      });
      try {
        await reset();
        await checkAccess(tester);
        await reset();
        await checkSupport(tester);
        await reset();
        await checkResume(tester);
      } finally {
        await finish(tester);
      }
    },
  );
}
