import 'package:flutter/material.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/screens/garden_village_screen.dart';
import 'package:flutter_app/mongi/widgets/garden_return_sheet.dart';
import 'package:flutter_app/services/garden_return_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Garden extends GardenProvider {
  String? owner = 'alice';
  @override
  String? get publicGardenAccount => owner;
  void switchOwner(String? next) {
    owner = next;
    notifyListeners();
  }

  @override
  bool? get hasUnpublishedGardenChanges => false;
  @override
  bool? get gardenPublication => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  final recap = GardenReturnSummary(
    previousVisit: DateTime(2026, 10, 10),
    currentVisit: DateTime(2026, 10, 16),
    newPlants: 2,
    grownPlants: 3,
    newRecordDays: 4,
  );

  Future<_Garden> open(WidgetTester tester) async {
    final garden = _Garden();
    addTearDown(garden.dispose);
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<GardenProvider>.value(
        value: garden,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showGardenReturnSheet(context, recap),
                  child: const Text('정원 소식 열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('정원 소식 열기'));
    await tester.pumpAndSettle();
    return garden;
  }

  testWidgets(
    'open recap hides prior account details immediately after account switch or logout',
    (tester) async {
      final garden = await open(tester);
      expect(find.text(recap.description), findsOneWidget);
      expect(find.text('다시 만나 반가워요'), findsOneWidget);
      expect(tester.takeException(), isNull);
      garden.switchOwner('bob');
      await tester.pump();
      expect(find.text(recap.description), findsNothing);
      expect(find.text('다시 만나 반가워요'), findsNothing);
      expect(find.text('지금의 정원에서 잠깐 쉬어가도 괜찮아요.'), findsOneWidget);
      garden.switchOwner(null);
      await tester.pump();
      expect(find.text(recap.description), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'inbox navigation closes the sheet and opens the received tab from page context',
    (tester) async {
      await open(tester);
      await tester.ensureVisible(find.text('받은 마음 살펴보기'));
      await tester.tap(find.text('받은 마음 살펴보기'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text(recap.description), findsNothing);
      expect(find.byType(GardenVillageScreen), findsOneWidget);
      expect(
        tester
            .widget<GardenVillageScreen>(find.byType(GardenVillageScreen))
            .initialTab,
        2,
      );
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('정원 소식 열기'), findsOneWidget);
      expect(find.text(recap.description), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
