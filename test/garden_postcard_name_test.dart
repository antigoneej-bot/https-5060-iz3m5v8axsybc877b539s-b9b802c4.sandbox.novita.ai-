import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/mongi/integration/garden_postcard_screen.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';

void main() {
  testWidgets(
    'postcard uses chosen companion name without rewriting a caption',
    (tester) async {
      final care = CatCareProvider()..companionName = '밤';
      addTearDown(care.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<CatCareProvider>.value(
          value: care,
          child: MaterialApp(
            home: GardenPostcardScreen(data: MongiGardenData(), cats: const []),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('밤과 함께, 오늘도 조금씩'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '몽이에게 처음 편지를 쓴 날');
      await tester.pump();
      final preview = find.descendant(
        of: find.byType(RepaintBoundary),
        matching: find.text('몽이에게 처음 편지를 쓴 날'),
      );
      expect(preview, findsWidgets);
      expect(find.text('밤에게 처음 편지를 쓴 날'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
