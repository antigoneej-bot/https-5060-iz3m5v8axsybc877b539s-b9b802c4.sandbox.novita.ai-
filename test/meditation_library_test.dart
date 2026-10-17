import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/meditation_library_store.dart';
import 'package:flutter_app/screens/meditation_library_screen.dart';
import 'package:flutter_app/widgets/meditation_check_in.dart';
import 'package:flutter_app/services/meditation_completion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  test(
    'favorites recent ordering and check-in choices survive reload',
    () async {
      final s = MeditationLibraryStore();
      await s.load();
      await Future.wait([
        s.toggleFavorite('forestRest'),
        s.toggleFavorite('rainThunderRest'),
      ]);
      await s.played('forestRest');
      await s.played('rainThunderRest');
      await s.played('forestRest');
      for (final feeling in ['better', 'same', 'worse'])
        await s.checkIn(feeling, 'forestRest', feeling);
      await s.checkIn('worse', 'forestRest', 'worse');
      final restored = MeditationLibraryStore();
      await restored.load();
      expect(restored.favorites, {'forestRest', 'rainThunderRest'});
      expect(restored.recent, ['forestRest', 'rainThunderRest']);
      expect(restored.checkIns.length, 3);
      expect(restored.checkIns.first['feeling'], 'worse');
    },
  );
  testWidgets('duration and voice filters intersect', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MeditationLibraryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('10개의 명상'), findsOneWidget);
    await tester.ensureVisible(find.text('3분 이내'));
    await tester.tap(find.text('3분 이내'));
    await tester.pumpAndSettle();
    expect(find.text('5개의 명상'), findsOneWidget);
    await tester.ensureVisible(find.text('목소리 있음'));
    await tester.tap(find.text('목소리 있음'));
    await tester.pumpAndSettle();
    expect(find.text('1개의 명상'), findsOneWidget);
    await tester.ensureVisible(find.text('즐겨찾기').first);
    await tester.tap(find.text('즐겨찾기').first);
    await tester.pumpAndSettle();
    expect(find.text('0개의 명상'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('post meditation check-in is optional and can be skipped', (
    tester,
  ) async {
    MeditationCompletionService.instance.completed.value = (
      session: 'ui-skip',
      key: 'forestRest',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MeditationCheckIn(guideKey: 'forestRest')),
      ),
    );
    expect(find.text('조금 편안해졌어요'), findsOneWidget);
    expect(find.text('비슷해요'), findsOneWidget);
    expect(find.text('더 불편해요'), findsOneWidget);
    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    expect(find.text('잠깐 쉬고 난 지금은 어떤가요?'), findsNothing);
    expect(
      MeditationLibraryStore.instance.checkIns.where(
        (v) => v['session'] == 'ui-skip',
      ),
      isEmpty,
    );
  });
}
