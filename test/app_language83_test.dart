import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/screens/meditation_library_screen.dart';
import 'package:flutter_app/screens/meditation_category_screen.dart';
import 'package:flutter_app/widgets/guide_steps.dart';
import 'package:flutter_app/data/solutions_data.dart';
import 'package:flutter_app/models/companion_coat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('ko');
  });
  test('locale choice persists and unsupported choices cannot overwrite it', () async {
    await AppLanguage.instance.select('en');
    expect((await SharedPreferences.getInstance()).getString(AppLanguage.preferenceKey), 'en');
    await AppLanguage.instance.load();
    expect(AppLanguage.instance.code, 'en');
    await expectLater(AppLanguage.instance.select('xx'), throwsArgumentError);
    expect(AppLanguage.instance.code, 'en');
    await AppLanguage.instance.select(null);
    expect((await SharedPreferences.getInstance()).containsKey(AppLanguage.preferenceKey), false);
  });
  test('formatting preserves names literally, including Korean and placeholder-like text', () {
    expect(formatCopy('{0}에게\n{1} {2}개', 'en', ['봄이 {1}', 'Daisy', 2]),
      'To 봄이 {1}\nDaisy × 2');
    expect(formatCopy('user diary text', 'en'), 'user diary text');
    expect(formatCopy('취소', 'ko'), '취소');
  });
  test('localized coat labels do not change serialized identifiers', () async {
    await AppLanguage.instance.select('en');
    expect(CompanionCoat.ginger.label, 'Orange tabby');
    expect(CompanionCoat.ginger.name, 'ginger');
    expect(CompanionCoat.parse('ginger'), CompanionCoat.ginger);
    await AppLanguage.instance.select('ko');
    expect(CompanionCoat.ginger.label, '치즈태비');
  });
  testWidgets('language change rebuilds live UI without discarding an open draft', (t) async {
    final controller = TextEditingController(text: '내 이름과 My draft {0}');
    await t.pumpWidget(AnimatedBuilder(animation: AppLanguage.instance,
      builder: (_, __) => MaterialApp(locale: AppLanguage.instance.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: Column(children: [const LanguageSetting(), TextField(controller: controller)])))));
    await t.pumpAndSettle();
    await t.runAsync(() => AppLanguage.instance.select('en'));
    await t.pumpAndSettle();
    expect(find.text('Language / 언어'), findsOneWidget);
    expect(controller.text, '내 이름과 My draft {0}');
    await t.runAsync(() => AppLanguage.instance.select('ko'));
    await t.pumpAndSettle();
    expect(find.text('언어 / Language'), findsOneWidget);
    expect(controller.text, '내 이름과 My draft {0}');
    await t.pumpWidget(const SizedBox()); controller.dispose();
  });
  testWidgets('English meditation is unavailable through library category and shared player gate', (t) async {
    await AppLanguage.instance.select('en');
    for (final child in <Widget>[
      const MeditationLibraryScreen(),
      const MeditationCategoryScreen(categoryKey: 'breathing'),
      GuideSteps(guide: breathingGuide.values.first, guideKey: breathingGuide.keys.first),
    ]) {
      await t.pumpWidget(MaterialApp(home: child is MeditationCategoryScreen ? child : Scaffold(body: SingleChildScrollView(child: child))));
      await t.pump();
      expect(find.text("English meditation is on the way"), findsOneWidget);
      expect(find.textContaining("not ready to play or buy yet"), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    }
  });
}
