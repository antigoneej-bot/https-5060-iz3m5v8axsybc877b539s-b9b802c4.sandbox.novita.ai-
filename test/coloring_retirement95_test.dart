import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/coloring_stroke.dart';
import 'package:flutter_app/services/brush_coloring_store.dart';
import 'package:flutter_app/widgets/premium_test_access.dart';
import 'package:flutter_app/l10n/app_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'retired template is preserved in source but excluded from app assets',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      expect(
        manifest.listAssets(),
        isNot(contains('assets/coloring/love_cat.png')),
      );
      expect(File('assets/coloring/love_cat.png').lengthSync(), 1977660);
    },
  );

  test(
    'no application import/export path reaches the retired coloring screens',
    () {
      final pending = <Uri>[File('lib/main.dart').absolute.uri];
      final visited = <Uri>{};
      final imports = RegExp(
        r'''^(?:import|export|part)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      );
      while (pending.isNotEmpty) {
        final uri = pending.removeLast();
        if (!visited.add(uri)) continue;
        for (final match in imports.allMatches(
          File.fromUri(uri).readAsStringSync(),
        )) {
          final value = match[1]!;
          final dependency = value.startsWith('package:flutter_app/')
              ? File(
                  'lib/${value.substring('package:flutter_app/'.length)}',
                ).absolute.uri
              : value.contains(':')
              ? null
              : uri.resolve(value);
          if (dependency != null) pending.add(dependency);
        }
      }
      expect(visited.length, greaterThan(100));
      expect(
        visited.any(
          (uri) => uri.path.endsWith('/coloring_healing_screen.dart'),
        ),
        isFalse,
      );
      expect(
        visited.any((uri) => uri.path.endsWith('/legacy_coloring_screen.dart')),
        isFalse,
      );
    },
  );

  test(
    'retiring navigation preserves previously saved strokes and finished art byte for byte',
    () async {
      final old = jsonEncode([
        ColoringStroke(0xff123456, 16, false, [
          const Offset(20, 30),
          const Offset(90, 40),
        ]).toJson(),
      ]);
      const key = 'coloring_brush_v1_local_user_love';
      SharedPreferences.setMockInitialValues({
        key: old,
        '${key}_finished': old,
        'another_user_record': 'untouched',
      });
      for (final lang in ['ko', 'en']) {
        await AppLanguage.instance.select(lang);
        expect(MembershipFeatures.free.join(' '), isNot(contains('색칠')));
        expect(
          MembershipFeatures.free.join(' ').toLowerCase(),
          isNot(contains('coloring')),
        );
        final store = BrushColoringStore('local_user');
        expect((await store.load()).single.points, [
          const Offset(20, 30),
          const Offset(90, 40),
        ]);
        expect((await store.load(finished: true)).single.color, 0xff123456);
      }
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), old);
      expect(prefs.getString('${key}_finished'), old);
      expect(prefs.getString('another_user_record'), 'untouched');
    },
  );
}
