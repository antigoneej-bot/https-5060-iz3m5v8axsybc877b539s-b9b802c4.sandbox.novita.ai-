import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/screens/cat_walk_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  test(
    'native walk profile carries language and preserves selected coat, emotion IDs and names',
    () {
      for (final language in ['en', 'ko']) {
        for (final coat in [-1, 0, 1, 2, 3, 4, 5]) {
          final profile = createWalkProfile(
            name: "소하 O'Neil {0} <script>",
            coat: coat,
            emotions: ['sad', 'joyful', 'sad'],
            language: language,
          );
          final decoded = jsonDecode(jsonEncode(profile));
          expect(decoded['name'], "소하 O'Neil {0} <script>");
          expect(decoded['coat'], coat);
          expect(decoded['emotions'], ['sad', 'joyful']);
          expect(decoded['language'], language);
        }
      }
    },
  );
  test('default name is localized only when no saved name exists', () {
    Map<String, Object> make(String name, String lang) =>
        createWalkProfile(name: name, coat: 0, emotions: [], language: lang);
    expect(make('', 'en')['name'], 'Nabi');
    expect(make('', 'ko')['name'], '나비');
    expect(make('나비', 'en')['name'], '나비');
    expect(make('', 'unsupported')['language'], 'ko');
  });
  testWidgets(
    'English native fallback and reload accessibility labels are translated',
    (t) async {
      await AppLanguage.instance.select('en');
      await t.pumpWidget(const MaterialApp(home: CatWalkScreen()));
      await t.pump();
      expect(find.text('Cat walk'), findsOneWidget);
      expect(
        find.text('Cat walks are available in the Android and iPhone apps.'),
        findsOneWidget,
      );
      expect(find.byTooltip('Reload walk'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await AppLanguage.instance.select('ko');
    },
    variant: TargetPlatformVariant({TargetPlatform.linux}),
  );
}
