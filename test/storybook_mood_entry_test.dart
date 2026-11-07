import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/cat_selection_screen.dart';
import 'package:flutter_app/widgets/emotion_cat_carousel.dart';
import 'package:flutter_app/data/cat_browse_groups.dart';

void main() {
  for (final group in ['편안해요', 'unknown-group']) {
    testWidgets('home mood is only a reversible filter: $group', (t) async {
      SharedPreferences.setMockInitialValues({
        'free_tier_reassurance_seen_v1': true,
      });
      final app = AppStateProvider();
      addTearDown(app.dispose);
      await t.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: CatSelectionScreen(initialGroup: group),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final carousel = t.widget<EmotionCatCarousel>(
        find.byType(EmotionCatCarousel),
      );
      if (catBrowseGroups.containsKey(group)) {
        expect(
          carousel.cats.map((c) => c.id).toSet(),
          catBrowseGroups[group]!.toSet(),
        );
        await t.ensureVisible(find.text(group));
        await t.tap(find.text(group));
        await t.pumpAndSettle();
      }
      expect(
        t
            .widget<EmotionCatCarousel>(find.byType(EmotionCatCarousel))
            .cats
            .length,
        37,
      );
      expect(app.selectedCat, isNull);
      expect(t.takeException(), isNull);
    });
  }
}
