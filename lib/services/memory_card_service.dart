import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'garden_village_service.dart';
import 'cloud_service.dart';

class MemoryCardService {
  final GardenVillageService village;
  MemoryCardService({GardenVillageService? village})
    : village = village ?? GardenVillageService();
  bool busy = false;
  Future<Map<String, dynamic>> load() async {
    final owner = village.pinAccount(),
        prefs = await SharedPreferences.getInstance();
    final key = 'card_offer_pending_$owner';
    final pending = prefs.getString(key);
    if (pending != null)
      await _send(prefs, key, Map<String, dynamic>.from(jsonDecode(pending)));
    return village.memoryCards('getMemoryCards');
  }

  Future<void> _send(
    SharedPreferences prefs,
    String key,
    Map<String, dynamic> body,
  ) async {
    try {
      await village.memoryCards('offerCardTrade', body);
      if (!await prefs.remove(key)) throw StateError('교환 요청 확인을 저장하지 못했어요.');
    } on CloudException catch (e) {
      if ({
        'invalid-card',
        'invalid-target',
        'neighbor-required',
        'card-stock',
        'card-trade-limit',
        'request-conflict',
      }.contains(e.code))
        await prefs.remove(key);
      rethrow;
    }
  }

  Future<void> offer(String gardenId, String give, String want) async {
    if (busy) throw StateError('처리 중이에요.');
    busy = true;
    try {
      final owner = village.pinAccount(),
          prefs = await SharedPreferences.getInstance(),
          key = 'card_offer_pending_${village.accountOwner}';
      if (prefs.containsKey(key)) throw StateError('새로고침해서 이전 교환 결과를 확인해주세요.');
      final random = Random.secure();
      final body = {
        'gardenId': gardenId,
        'give': give,
        'want': want,
        'requestId': List.generate(
          16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join(),
      };
      if (owner != village.accountOwner ||
          !await prefs.setString(key, jsonEncode(body)))
        throw StateError('교환 요청을 저장하지 못했어요.');
      await _send(prefs, key, body);
    } finally {
      busy = false;
    }
  }
}
