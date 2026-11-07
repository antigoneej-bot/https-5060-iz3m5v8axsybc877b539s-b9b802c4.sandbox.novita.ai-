import 'package:flutter_app/services/care_journal_store.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/data/subscriber_journeys.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_app/services/social_auth_service.dart';
import 'package:flutter_app/services/subscription_service.dart';
import 'package:flutter_app/screens/orchard_screen.dart';
import 'package:flutter_app/services/orchard_service.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'orchard_test.dart' as orchard_fixture;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_app/screens/self_care_entry_screen.dart';
import 'package:flutter_app/screens/care_journal_screen.dart';
import 'package:flutter_app/screens/about_app_screen.dart';
import 'package:flutter_app/screens/privacy_policy_screen.dart';
import 'package:flutter_app/screens/terms_of_service_screen.dart';
import 'package:flutter_app/models/self_care_entry.dart';
import 'package:flutter_app/models/keepsake_tree.dart';
import 'package:flutter_app/models/orchard.dart';
import 'package:flutter_app/models/cat_accessory.dart';
import 'package:flutter_app/models/cat_achievement.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/widgets/premium_test_access.dart';
import 'package:flutter_app/widgets/memory_card_art.dart';
import 'package:flutter_app/widgets/emotion_comic_book.dart';
import 'package:flutter_app/services/unified_emotion_summary_service.dart';
import 'package:flutter_app/services/draft_service.dart';
import 'package:flutter_app/services/reflection_service.dart';
import 'package:flutter_app/l10n/english_catalog.dart';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/providers/app_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('english87');
    Hive.init(temp.path);
    await DraftService.box();
    final emojiPath = Platform.environment['REVIEW_EMOJI_FONT'];
    if (emojiPath != null) {
      await (FontLoader('NotoColorEmoji')..addFont(
            Future.value(
              ByteData.sublistView(await File(emojiPath).readAsBytes()),
            ),
          ))
          .load();
    }
    for (final font in {
      'GowunDodum': 'assets/fonts/GowunDodum-Regular.ttf',
      'GamjaFlower': 'assets/fonts/GamjaFlower-Regular.ttf',
      'Poppins': 'assets/fonts/Poppins-ExtraBold.ttf',
      'NanumPenScript': 'assets/fonts/NanumPenScript-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  tearDownAll(() async {
    final ownedFiles = await temp.list(followLinks: false).toList();
    for (final entry in ownedFiles) {
      if (entry is! File || !entry.path.endsWith('.hive')) continue;
      final name = entry.uri.pathSegments.last.replaceFirst(
        RegExp(r'\.hive$'),
        '',
      );
      if (Hive.isBoxOpen(name)) {
        print('Closing fixture box: $name');
        await Hive.box<dynamic>(
          name,
        ).close().timeout(const Duration(seconds: 10));
        expect(Hive.isBoxOpen(name), isFalse);
        print('Closed fixture box: $name');
      }
    }
    await Hive.close().timeout(const Duration(seconds: 10));
    for (final entry in await temp.list(followLinks: false).toList()) {
      expect(entry, isA<File>());
      await entry.delete();
    }
    await temp.delete();
    expect(await temp.exists(), isFalse);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('en');
  });
  Future<void> waitForStorage(
    WidgetTester t,
    Future<void> Function() work,
  ) async {
    await t.runAsync(() async {
      bool done = false;
      Object? error;
      StackTrace? stack;
      Future<void>(work).then(
        (_) => done = true,
        onError: (Object e, StackTrace s) {
          error = e;
          stack = s;
          done = true;
        },
      );
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (!done) {
        if (DateTime.now().isAfter(deadline))
          fail('Screen storage work did not finish in its owning widget test');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await t.pump();
      }
      if (error != null) Error.throwWithStackTrace(error!, stack!);
    });
  }

  Future<void> mount(WidgetTester t, Widget page, double scale) async {
    t.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: ThemeData(
          fontFamily: 'GowunDodum',
          fontFamilyFallback: const ['NotoColorEmoji'],
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        debugShowCheckedModeBanner: false,
        home: ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: RepaintBoundary(key: const Key('capture87'), child: page),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    if (page is CareJournalScreen) {
      await waitForStorage(t, CareJournalStore.instance.reload);
      await t.pump();
      expect(CareJournalStore.instance.isLoaded, isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }
  }

  Future<void> finishDrafts(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() async {
      bool done = false;
      Object? error;
      StackTrace? stack;
      Future<void>(() async {
        await DraftTextController.flushAll();
        final draftBox = await DraftService.box();
        await draftBox.flush();
        // Screen-created boxes must finish closing in the fake-clock zone
        // that opened them. The shared draft box was opened in setUpAll.
        for (final entry in await temp.list(followLinks: false).toList()) {
          if (entry is! File || !entry.path.endsWith('.hive')) continue;
          final name = entry.uri.pathSegments.last.replaceFirst(
            RegExp(r'\.hive$'),
            '',
          );
          if (name != draftBox.name && Hive.isBoxOpen(name)) {
            await Hive.box<dynamic>(name).close();
            expect(Hive.isBoxOpen(name), isFalse);
          }
        }
      }).then(
        (_) => done = true,
        onError: (Object e, StackTrace s) {
          error = e;
          stack = s;
          done = true;
        },
      );
      final deadline = DateTime.now().add(const Duration(seconds: 30));
      while (!done) {
        if (DateTime.now().isAfter(deadline))
          fail('Draft writes did not finish in their owning widget test');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await t.pump();
      }
      if (error != null) Error.throwWithStackTrace(error!, stack!);
    });
    await t.pump();
  }

  Future<void> capture(WidgetTester t, String name) async {
    final dir = Platform.environment['REVIEW87'];
    if (dir == null) return;
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('capture87')),
      );
      final im = await boundary.toImage(pixelRatio: 2);
      final data = await im.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(data!.buffer.asUint8List());
      im.dispose();
    });
  }

  void testEnglishWidget(
    String name,
    Future<void> Function(WidgetTester) body,
  ) {
    testWidgets(name, (t) async {
      try {
        await body(t);
      } finally {
        await finishDrafts(t);
      }
    });
  }

  testEnglishWidget(
    'disposed draft writes finish before their widget zone ends',
    (t) async {
      final controller = DraftTextController('english87-fixture-regression');
      controller.text = '사용자가 작성한 원문 · fixture';
      controller.dispose();
      await finishDrafts(t);
      Object? saved;
      await t.runAsync(() async {
        saved = (await DraftService.box()).get('english87-fixture-regression');
      });
      expect(saved, '사용자가 작성한 원문 · fixture');
    },
  );

  void englishText(WidgetTester t) {
    for (final text in t.widgetList<Text>(find.byType(Text))) {
      expect(
        RegExp('[가-힣]').hasMatch((text.data ?? '').replaceAll('박은정', '')),
        isFalse,
        reason: text.data,
      );
    }
  }

  for (final scale in [1.0, 2.0]) {
    for (final item in <String, Widget>{
      'self-care': const SelfCareEntryScreen(),
      'care-journal': const CareJournalScreen(),
      'about': const AboutAppScreen(),
      'privacy': const PrivacyPolicyScreen(),
      'terms': const TermsOfServiceScreen(),
    }.entries) {
      testEnglishWidget('English ${item.key} at text scale $scale', (t) async {
        await mount(t, item.value, scale);
        for (var i = 0; i < 5; i++) {
          await t.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          });
          await t.pump();
        }
        expect(t.takeException(), isNull);
        englishText(t);
        await capture(t, '${item.key}-en-${scale.toInt()}');
        final scroll = find.byType(Scrollable);
        if (scroll.evaluate().isNotEmpty) {
          await t.drag(scroll.first, const Offset(0, -550));
          await t.pump(const Duration(milliseconds: 300));
          expect(t.takeException(), isNull);
          englishText(t);
        }
        await finishDrafts(t);
        await t.pump(const Duration(seconds: 1));
      });
    }
  }

  for (final scale in [1.0, 2.0]) {
    testEnglishWidget('English orchard tabs at text scale $scale', (t) async {
      final service = OrchardService(
        village: GardenVillageService(
          currentOwner: () => 'english87',
          transport: (a, b, c) async => {
            'orchard': {...orchard_fixture.sample(), 'gifts': []},
          },
        ),
      );
      await mount(t, OrchardScreen(service: service), scale);
      await t.pumpAndSettle();
      for (final tab in ['Tend trees', 'Harvest storehouse', 'Sapling shop']) {
        await t.tap(find.text(tab));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        englishText(t);
      }
      await capture(t, 'orchard-en-${scale.toInt()}');
      await finishDrafts(t);
      await t.pump();
    });
  }
  testEnglishWidget(
    'English comic can turn every page and keeps original notes',
    (t) async {
      final records = UnifiedEmotionSummaryService.read(
        letters: [],
        gardenDiary: [
          for (var i = 1; i <= 12; i++)
            {
              'id': '$i',
              'date': '2026-11-${i.toString().padLeft(2, '0')}',
              'emotionType': 'calm',
              'note': 'User’s original words $i',
            },
        ],
      );
      await mount(
        t,
        Scaffold(
          body: SingleChildScrollView(
            child: EmotionComicBook(
              summary: UnifiedEmotionPeriod(records),
              start: DateTime(2026, 11),
              end: DateTime(2026, 11, 30),
              monthly: true,
              detailed: true,
            ),
          ),
        ),
        1,
      );
      await t.pumpAndSettle();
      englishText(t);
      expect(t.takeException(), isNull);
      await capture(t, 'comic-en-1');
      for (var i = 0; i < 3; i++) {
        await t.tap(find.byTooltip('Next page'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        englishText(t);
      }
      await finishDrafts(t);
      await t.pump();
    },
  );

  test(
    'presentation updates on each language switch while IDs and user records stay intact',
    () async {
      final entry = SelfCareEntry(
        id: 'stable',
        createdAt: DateTime(2026, 11, 4),
        promptIndex: 0,
        reflection: '내가 쓴 말 그대로',
        plan: '사용자 계획',
        action: CareAction.rest,
      );
      final saved = entry.toMap();
      for (final code in ['en', 'ko', 'en']) {
        await AppLanguage.instance.select(code);
        expect(entry.toMap(), saved);
        expect(
          CareAction.rest.label,
          code == 'en' ? 'Take a short rest' : '잠깐 쉬기',
        );
        expect(
          OrchardKind.byId('apple').name,
          code == 'en' ? 'Apple tree' : '사과나무',
        );
        expect(KeepsakeKind.love.label, code == 'en' ? 'Love' : '사랑');
        expect(
          catAccessories.first.label,
          code == 'en' ? 'Everyday cat food' : '일반 사료',
        );
        expect(
          catAchievements.first.title,
          code == 'en' ? 'First hello' : '첫 만남',
        );
        expect(
          RegExp('[가-힣]').hasMatch(MembershipFeatures.free.join()),
          code == 'ko',
        );
        expect(
          memoryThemes['rain'],
          code == 'en' ? 'A rainy-day nap' : '비 오는 날의 낮잠',
        );
      }
    },
  );
  test('generated statistics use English without rewriting journal text', () {
    final records = UnifiedEmotionSummaryService.read(
      letters: [
        LetterEntry(
          id: 'a',
          catId: 'sad',
          date: DateTime(2026, 11, 1),
          letterText: '내 기록',
        ),
      ],
      gardenDiary: [
        {
          'id': 'b',
          'date': '2026-11-02',
          'emotionType': 'calm',
          'note': '원문 유지',
        },
      ],
    );
    for (final r in records) {
      expect(RegExp('[가-힣]').hasMatch(r.label), false);
    }
    expect(records.first.note, '내 기록');
    final summary = ReflectionService.buildMonthlySummarySentence(
      firstHalfCatId: 'sad',
      secondHalfCatId: 'joyful',
    );
    expect(RegExp('[가-힣]').hasMatch(summary), false);
  });
  test(
    'translated templates preserve all numeric placeholders except Korean particles',
    () {
      for (final entry in englishCatalog.entries) {
        final ko = RegExp(
          r'\{(\d+)\}',
        ).allMatches(entry.key).map((m) => m[1]).toSet();
        final en = RegExp(
          r'\{(\d+)\}',
        ).allMatches(entry.value).map((m) => m[1]).toSet();
        expect(en.difference(ko), isEmpty, reason: entry.key);
      }
    },
  );
  test('all 37 cat stories and 12 journey chapters have English copy', () {
    expect(shadowCats.length, 37);
    for (final cat in shadowCats) {
      for (final value in [
        cat.displayName,
        cat.displayKeyword,
        cat.story,
        cat.comfortMessage,
        cat.guidance,
        cat.letterPrompt,
      ]) {
        expect(
          RegExp('[가-힣]').hasMatch(value),
          false,
          reason: '${cat.id}: $value',
        );
      }
    }
    expect(subscriberJourneys.expand((j) => j.weeks).length, 12);
    for (final journey in subscriberJourneys) {
      for (final value in [
        journey.title,
        ...journey.weeks.expand((w) => [w.story, w.question, w.action]),
      ]) {
        expect(RegExp('[가-힣]').hasMatch(tr(value)), false, reason: value);
      }
    }
  });
  test(
    'authentication and store copy keep codes and original billing configuration',
    () {
      const e = SocialAuthException('auth-server-unreachable');
      expect(e.code, 'auth-server-unreachable');
      expect(e.message, contains('AUTH-06'));
      expect(RegExp('[가-힣]').hasMatch(e.message), false);
      expect(SubscriptionService.monthlyProductId, 'garden_plus_monthly');
      expect(SubscriptionService.yearlyProductId, 'garden_plus_yearly');
      for (final plan in SubscriptionPlan.values) {
        expect(
          RegExp('[가-힣]').hasMatch(SubscriptionService().priceLabelFor(plan)),
          false,
        );
        expect(
          RegExp(
            '[가-힣]',
          ).hasMatch(SubscriptionService().productAvailabilityLabel(plan)),
          false,
        );
      }
    },
  );
}
