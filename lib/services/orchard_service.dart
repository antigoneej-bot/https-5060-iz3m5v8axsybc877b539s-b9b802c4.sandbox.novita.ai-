import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/orchard.dart';
import 'garden_village_service.dart';
import 'cloud_service.dart';

/// Persist the exact operation before transport. An interrupted request is
/// resolved with the same receipt ID before any later mutation is permitted.
class OrchardService {
  final GardenVillageService village;
  bool _busy = false;
  OrchardService({GardenVillageService? village})
    : village = village ?? GardenVillageService();
  String get _key {
    final owner = village.pinAccount();
    return 'orchard_pending_v1_$owner';
  }

  Future<Map<String, dynamic>> _send(
    SharedPreferences prefs,
    String key,
    Map<String, dynamic> body,
  ) async {
    try {
      final result = await village.orchardMutation(body);
      if (!await prefs.remove(key))
        throw StateError('요청 확인을 저장하지 못했어요. 다시 확인해 주세요.');
      return result;
    } on CloudException catch (e) {
      // Only definitive rejections can discard an operation; network failures
      // and account switches retain it for its original owner.
      if (const {
        'invalid-orchard',
        'invalid-target',
        'orchard-owned',
        'orchard-coins',
        'orchard-watered',
        'orchard-not-ready',
        'orchard-stock',
        'orchard-full',
        'gifts-disabled',
        'neighbor-required',
        'request-conflict',
      }.contains(e.code))
        await prefs.remove(key);
      rethrow;
    }
  }

  Future<OrchardState> load() async {
    if (_busy) throw StateError('처리 중이에요.');
    _busy = true;
    try {
      final key = _key, prefs = await SharedPreferences.getInstance();
      final pending = prefs.getString(key);
      final raw = pending == null
          ? await village.orchardState()
          : await _send(
              prefs,
              key,
              Map<String, dynamic>.from(jsonDecode(pending)),
            );
      return OrchardState.fromJson(Map<String, dynamic>.from(raw['orchard']));
    } finally {
      _busy = false;
    }
  }

  Future<Map<String, dynamic>> act(
    String op,
    String kind, {
    int quantity = 1,
    String? gardenId,
  }) async {
    if (_busy) throw StateError('처리 중이에요.');
    _busy = true;
    try {
      final key = _key, prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key)) throw StateError('이전 요청 결과를 먼저 새로고침해 주세요.');
      final random = Random.secure();
      final body = <String, dynamic>{
        'requestId': List.generate(
          16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join(),
        'op': op,
        'kind': kind,
        'quantity': quantity,
        if (gardenId != null) 'gardenId': gardenId,
      };
      if (!await prefs.setString(key, jsonEncode(body)))
        throw StateError('요청을 저장하지 못했어요. 다시 시도해 주세요.');
      return await _send(prefs, key, body);
    } finally {
      _busy = false;
    }
  }
}
