import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = MongiGardenStore.instance;
  setUp(() async {SharedPreferences.setMockInitialValues({}); await store.reload();});
  test('old garden loads empty food, new food survives copy and roundtrip', () {
    final old = MongiGardenData().toJson()..remove('walkStock');
    expect(MongiGardenData.fromJson(old).walkStock, isEmpty);
    final data=MongiGardenData(walkStock:{'churu_tuna':2},essence:20).copy(stage:2);
    expect(MongiGardenData.fromJson(data.toJson()).walkStock['churu_tuna'],2);
  });
  test('retry and concurrent reward calls credit one receipt with food and essence', () async {
    final id=List.filled(48,'a').join();
    await Future.wait(List.generate(3, (_) => store.receiveWalkReward(id,
      {'churu':2,'snack':1,'light':25},isCurrentOwner:()=>true)));
    await store.reload();
    expect(store.value.essence,25);
    expect(store.value.walkStock,{'churu_tuna':2,'food_dry':1});
    expect(await store.consumeWalkFood('food_dry',isCurrentOwner:()=>true),true);
    expect(await store.consumeWalkFood('food_dry',isCurrentOwner:()=>true),false);
    expect(store.value.essence,25);
  });
  test('account change and malformed reward never mint currency', () async {
    final id=List.filled(48,'b').join();
    await expectLater(store.receiveWalkReward(id,{'light':25},isCurrentOwner:()=>false),throwsStateError);
    await expectLater(store.receiveWalkReward(id,{'light':999},isCurrentOwner:()=>true),throwsArgumentError);
    expect(store.value.essence,0);
  });
}
