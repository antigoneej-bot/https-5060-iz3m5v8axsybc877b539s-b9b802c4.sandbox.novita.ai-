import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/mongi/models/seed.dart';
import 'package:flutter_app/utils/companion_name.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'English names follow locale; chosen personal names and IDs are unchanged',
    () async {
      SharedPreferences.setMockInitialValues({});
      await AppLanguage.instance.select('en');
      expect(companionDisplayName('우리 몽이'), '우리 몽이');
      expect(companionDisplayName(null), 'Cat');
      for (final coat in CompanionCoat.values) {
        expect(RegExp(r'[가-힣]').hasMatch(coat.label), false);
        expect(CompanionCoat.parse(coat.name), coat);
      }
      for (final cat in shadowCats) {
        expect(cat.displayName, cat.nameEn);
      }
      expect(SeedType.byId('pine').label, 'Pine');
      expect(SeedType.byId('pine').growthLabel(7), 'Flourishing');
      await AppLanguage.instance.select('ko');
      expect(SeedType.byId('pine').label, '소나무');
      expect(SeedType.byId('pine').growthLabel(7), '무성해졌어요');
      expect(companionDisplayName('우리 몽이'), '우리 몽이');
    },
  );
}
