import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/providers/cat_care_provider.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/widgets/resting_garden_view.dart';
import 'package:flutter_app/mongi/widgets/garden_world_view.dart';

void main() {
  testWidgets('resting space follows all six saved companion choices without creating garden data', (t) async {
    SharedPreferences.setMockInitialValues({}); CatCareService.setCurrentUser('local_user');
    final care = CatCareProvider(); final garden = GardenProvider()..gardenMotionEnabled=false;
    await care.loadJourney(); await care.setAutomaticBehavior(false); await care.renameCompanion('내 동반묘');
    await t.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<CatCareProvider>.value(value:care),
      ChangeNotifierProvider<GardenProvider>.value(value:garden),
    ], child: const MaterialApp(home: Scaffold(body: RestingGardenView()))));
    for (final coat in CompanionCoat.values) {
      await care.selectCoat(coat); await t.pumpAndSettle();
      final prefs=await SharedPreferences.getInstance();
      final before={for(final k in prefs.getKeys()) k:prefs.get(k)};
      final view=t.widget<GardenWorldView>(find.byType(GardenWorldView));
      expect(view.visitingHost!.coat,coat); expect(view.visitingHost!.name,'내 동반묘');
      expect(view.readOnly,true); expect(view.seeds,isEmpty); expect(view.decorations,isEmpty);
      await t.tap(find.byKey(const Key('rest-garden-overview'))); await t.pumpAndSettle();
      expect({for(final k in prefs.getKeys()) k:prefs.get(k)},before);
    }
    await t.pumpWidget(const SizedBox());care.dispose();garden.dispose();expect(t.takeException(),isNull);
  });
}
