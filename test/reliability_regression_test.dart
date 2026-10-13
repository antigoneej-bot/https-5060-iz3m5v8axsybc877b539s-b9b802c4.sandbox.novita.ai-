import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/meditation_check_in_record.dart';
import 'package:flutter_app/services/meditation_check_in_store.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/quiet_mode_screen.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/models/self_care_entry.dart';
import 'package:flutter_app/screens/self_care_entry_screen.dart';
import '../tool/reliability_contract.dart' as contract;

class QuietGarden extends GardenProvider {
  final ids = <String?>[];
  final intensities = <int?>[];
  final notes = <String?>[];
  bool failOnce = false;
  Completer<void>? pending;
  @override
  Future<void> recordQuietSession(
    List<EmotionType> emotionTypes, {
    String? targetName,
    String? note,
    int? intensity,
    String? sessionId,
  }) async {
    ids.add(sessionId);
    intensities.add(intensity);
    notes.add(note);
    if (failOnce) {
      failOnce = false;
      throw StateError('disk');
    }
    await pending?.future;
  }
}

Widget quietApp(QuietGarden garden) =>
    ChangeNotifierProvider<GardenProvider>.value(
      value: garden,
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              child: const Text('open quiet'),
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) =>
                      QuietModeScreen(emotions: [Emotion.all.first]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
Future<void> reflect(WidgetTester tester, QuietGarden garden) async {
  await tester.pumpWidget(quietApp(garden));
  await tester.tap(find.text('open quiet'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('다음'));
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('건너뛰기'));
  await tester.tap(find.text('건너뛰기'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('reliability-');
    Hive.init(directory.path);
    GoogleFonts.config.allowRuntimeFetching = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await (await HiveEncryption.openBox(
      MeditationCheckInStore.boxName,
    )).clear();
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test(
    'reminder errors, rapid actions and private feedback contract',
    contract.main,
  );
  test(
    'legacy feelings migrate encrypted; repeated session never overwrites; backup roundtrip',
    () async {
      final p = await SharedPreferences.getInstance();
      final raw = {
        'session': 'legacy',
        'guide': 'forestRest',
        'feeling': 'worse',
        'at': '2026-10-13T00:00:00.000',
      };
      await p.setString(MeditationCheckInStore.legacyKey, jsonEncode([raw]));
      final store = MeditationCheckInStore.instance;
      expect((await store.load()).single['feeling'], 'worse');
      expect(p.containsKey(MeditationCheckInStore.legacyKey), isFalse);
      expect(
        await Hive.boxExists('${MeditationCheckInStore.boxName}__enc'),
        isTrue,
      );
      expect(await Hive.boxExists(MeditationCheckInStore.boxName), isFalse);
      await store.save(
        MeditationCheckInRecord.fromMap({...raw, 'feeling': 'better'}),
      );
      expect((await store.load()).single['feeling'], 'worse');
      final backup = await BackupService.snapshot();
      BackupService.validate(backup);
      expect(
        (backup['boxes']['meditation_checkins'] as List).single['key'],
        'legacy',
      );
      await (await HiveEncryption.openBox(
        MeditationCheckInStore.boxName,
      )).clear();
      await BackupService.restore(backup);
      expect((await store.load()).single['feeling'], 'worse');
    },
  );
  test(
    'damaged migration leaves plaintext intact and does not partially import',
    () async {
      final p = await SharedPreferences.getInstance();
      final raw = jsonEncode([
        {
          'session': 'ok',
          'guide': 'forestRest',
          'feeling': 'same',
          'at': '2026-10-13T00:00:00.000',
        },
        null,
      ]);
      await p.setString(MeditationCheckInStore.legacyKey, raw);
      await expectLater(
        MeditationCheckInStore.instance.load(),
        throwsFormatException,
      );
      expect(p.getString(MeditationCheckInStore.legacyKey), raw);
      expect(
        (await HiveEncryption.openBox(MeditationCheckInStore.boxName)).isEmpty,
        isTrue,
      );
      await p.remove(MeditationCheckInStore.legacyKey);
      expect(await MeditationCheckInStore.instance.load(), isEmpty);
    },
  );
  testWidgets(
    'quiet session leaves intensity empty and blocks back during save',
    (tester) async {
      final garden = QuietGarden()..pending = Completer<void>();
      await reflect(tester, garden);
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .every((c) => !c.selected),
        isTrue,
      );
      await tester.ensureVisible(find.text('마음에 심기'));
      await tester.tap(find.text('마음에 심기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2400));
      expect(garden.intensities, [null]);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(QuietModeScreen), findsOneWidget);
      garden.pending!.complete();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('open quiet'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      garden.dispose();
    },
  );
  testWidgets(
    'quiet save retries same session and retains note; back requires confirmation',
    (tester) async {
      final garden = QuietGarden()..failOnce = true;
      await reflect(tester, garden);
      await tester.enterText(find.byType(TextField), '오늘은 천천히');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('작성 중인 마음을 닫을까요?'), findsOneWidget);
      await tester.tap(find.text('계속 쓰기'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('마음에 심기'));
      await tester.tap(find.text('마음에 심기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다시 저장하기'));
      await tester.pumpAndSettle();
      expect(garden.ids.length, 2);
      expect(garden.ids.toSet().length, 1);
      expect(garden.notes, ['오늘은 천천히', '오늘은 천천히']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      garden.dispose();
    },
  );
  testWidgets('care feedback protects changed answer on system back', (
    tester,
  ) async {
    final entry = SelfCareEntry(
      id: 'review',
      createdAt: DateTime(2026, 10, 13),
      action: CareAction.rest,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              child: const Text('open feedback'),
              onPressed: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => CareFeedbackScreen(entry: entry),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open feedback'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(CareFeedback.helped.label));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('작성 중인 후기를 닫을까요?'), findsOneWidget);
    await tester.tap(find.text('계속 쓰기'));
    await tester.pumpAndSettle();
    expect(find.byType(CareFeedbackScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
