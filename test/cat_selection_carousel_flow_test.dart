import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/providers/app_state_provider.dart';
import 'package:flutter_app/screens/cat_selection_screen.dart';
import 'package:flutter_app/widgets/emotion_cat_carousel.dart';

void main() {
  testWidgets(
    'all emotions open horizontally; search, favorites and grid work',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'free_tier_reassurance_seen_v1': true,
      });
      final app = AppStateProvider();
      addTearDown(app.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: app,
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: const Scaffold(
                body: SingleChildScrollView(child: CatSelectionScreen()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EmotionCatCarousel), findsOneWidget);
      expect(find.text('1 / 37'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '감사');
      await tester.pumpAndSettle();
      final carousel = tester.widget<EmotionCatCarousel>(
        find.byType(EmotionCatCarousel),
      );
      expect(
        carousel.cats.every((c) => '${c.keyword} ${c.nameKr}'.contains('감사')),
        isTrue,
      );
      expect(app.selectedCat, isNull);
      await tester.enterText(find.byType(TextField), '존재하지않는감정');
      await tester.pumpAndSettle();
      expect(find.byType(EmotionCatCarousel), findsNothing);
      expect(find.textContaining('찾는 고양이가 없어요'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('전체 보기'));
      await tester.tap(find.text('전체 보기'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(EmotionCatCarousel), findsNothing);
      await tester.ensureVisible(find.text('좌우로 보기'));
      await tester.tap(find.text('좌우로 보기'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 37'), findsOneWidget);
      await tester.ensureVisible(find.text('즐겨찾기'));
      await tester.tap(find.text('즐겨찾기'));
      await tester.pumpAndSettle();
      expect(find.byType(EmotionCatCarousel), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
