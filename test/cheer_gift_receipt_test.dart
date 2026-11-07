import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retry after local credit preserves one amount and one receipt', () {
    final first = MongiGardenData(essence: 12).receiveGift('receipt-1', 5);
    final restored = MongiGardenData.fromJson(first.toJson());
    final retry = restored.receiveGift('receipt-1', 5);
    expect(retry.essence, 17);
    expect(retry.claimedGiftReceipts, {'receipt-1'});
    expect(retry.clearStage(1).claimedGiftReceipts, {'receipt-1'});
  });
  test('old snapshots remain readable without receipts', () {
    final old = MongiGardenData(essence: 9).toJson()
      ..remove('claimedGiftReceipts');
    final data = MongiGardenData.fromJson(old);
    expect(data.essence, 9);
    expect(data.claimedGiftReceipts, isEmpty);
  });
  test('legacy local claim may record receipt without issuing currency', () {
    final data = MongiGardenData(essence: 7).receiveGift('receipt-1', 0);
    expect(data.receiveGift('receipt-1', 5).essence, 7);
  });
  test('malformed receipts and amounts cannot change a snapshot', () {
    final data = MongiGardenData();
    expect(() => data.receiveGift('../bad', 5), throwsFormatException);
    expect(() => data.receiveGift('ok', 6), throwsFormatException);
    expect(() => data.receiveGift('ok', -1), throwsFormatException);
    final json = data.toJson()..['claimedGiftReceipts'] = [123];
    expect(() => MongiGardenData.fromJson(json), throwsFormatException);
  });
  test('simultaneous local retries persist amount and receipt in one snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MongiGardenStore.instance;
    final results = await Future.wait([
      store.receiveCheerGift('receipt-1', 5, isCurrentOwner: () => true),
      store.receiveCheerGift('receipt-1', 5, isCurrentOwner: () => true),
    ]);
    expect(results.reduce((a, b) => a + b), 5);
    await store.reload();
    expect(store.value.essence, 5);
    final prefs = await SharedPreferences.getInstance();
    final json = jsonDecode(prefs.getString(MongiGardenStore.storageKey)!) as Map;
    expect(json['essence'], 5);
    expect(json['claimedGiftReceipts'], ['receipt-1']);
  });
  test('account change before queued commit leaves gift retryable', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MongiGardenStore.instance;
    await expectLater(store.receiveCheerGift('receipt-1', 5,
      isCurrentOwner: () => false), throwsStateError);
    await store.reload();
    expect(store.value.essence, 0);
    expect(store.value.claimedGiftReceipts, isEmpty);
    expect(await store.receiveCheerGift('receipt-1', 5,
      isCurrentOwner: () => true), 5);
  });
}
