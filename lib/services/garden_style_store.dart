import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../mongi/models/garden_layout.dart';
import '../mongi/integration/garden_layout_store.dart';
import '../mongi/integration/mongi_garden_store.dart';
import 'cat_care_service.dart';
import 'hive_encryption.dart';
import 'local_record_transaction.dart';

class GardenStyleStore extends ValueNotifier<Map<String, dynamic>> {
  GardenStyleStore._() : super(const {'season': 'original', 'layouts': {}});
  static final instance = GardenStyleStore._();
  static const boxName = 'garden_styles_local_user';
  static const seasons = {'original': '기본', 'spring': '봄', 'summer': '여름', 'autumn': '가을', 'winter': '겨울'};
  String? loadedOwner;
  Map get layouts => loadedOwner == CatCareService.localOwner ? value['layouts'] as Map : const {};
  String get season => loadedOwner == CatCareService.localOwner ? value['season'] as String : 'original';
  static String key(String owner) => base64Url.encode(utf8.encode(owner));
  static void validate(Object? keyValue, Object? raw) {
    if (raw is! Map || raw.length != 3 || raw['owner'] is! String || (raw['owner'] as String).isEmpty || (raw['owner'] as String).length > 256 ||
        keyValue != key(raw['owner'] as String) || !seasons.containsKey(raw['season']) || raw['layouts'] is! Map ||
        (raw['layouts'] as Map).length > 8) throw const FormatException('정원 꾸미기 기록을 확인해 주세요.');
    for (final e in (raw['layouts'] as Map).entries) {
      if (e.key is! String || (e.key as String).trim().isEmpty || (e.key as String).length > 30 || e.value is! Map) {
        throw const FormatException('배치 이름을 확인해 주세요.');
      }
      GardenLayout.fromJson(e.value as Map);
    }
  }
  Future<void> reload() => LocalRecordTransaction.run(() async {
    final owner = CatCareService.localOwner;
    final box = await HiveEncryption.openBox(boxName);
    final raw = box.get(key(owner)) ?? {'owner': owner, 'season': 'original', 'layouts': {}};
    validate(key(owner), raw);
    if (owner != CatCareService.localOwner) return;
    loadedOwner = owner;
    value = Map<String, dynamic>.from(jsonDecode(jsonEncode(raw)) as Map);
  });
  Future<void> _edit(void Function(Map<String, dynamic>) change) => LocalRecordTransaction.atomic(() async {
    final owner = CatCareService.localOwner;
    await reload();
    if (loadedOwner != owner || owner != CatCareService.localOwner) throw StateError('계정이 바뀌었어요.');
    final next = Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
    change(next); validate(key(owner), next);
    final box = await HiveEncryption.openBox(boxName);
    if (owner != CatCareService.localOwner) throw StateError('계정이 바뀌었어요.');
    LocalRecordTransaction.capture(box, afterRollback: reload);
    await box.put(key(owner), next); await box.flush(); value = next;
  });
  Future<void> setSeason(String season) => _edit((v) => v['season'] = season);
  Future<void> save(String name) => LocalRecordTransaction.run(() async {
    final owner = CatCareService.localOwner;
    await GardenLayoutStore.instance.reload();
    final current = GardenLayoutStore.instance.value;
    await MongiGardenStore.instance.reload();
    final data = MongiGardenStore.instance.value;
    final visible = [...data.seeds.entries.where((e) => e.value > 0).map((e) => 'seed:${e.key}'), ...data.placed.map((id) => 'decor:$id')];
    // Include default positions too, otherwise a freshly arranged garden saves an empty map.
    final layout = GardenLayout(spaces: current.spaces, positions: {for (final id in visible) id: current.position(id)});
    if (owner != CatCareService.localOwner) throw StateError('계정이 바뀌었어요.');
    await _edit((v) {
      if (owner != CatCareService.localOwner) throw StateError('계정이 바뀌었어요.');
      (v['layouts'] as Map)[name.trim()] = layout.toJson();
    });
  });
  Future<void> delete(String name) => _edit((v) { (v['layouts'] as Map).remove(name); });
  Future<void> apply(String name) => LocalRecordTransaction.run(() async {
    final owner = CatCareService.localOwner;
    await reload();
    if (loadedOwner != owner || owner != CatCareService.localOwner) throw StateError('계정이 바뀌었어요.');
    final raw = (value['layouts'] as Map)[name];
    if (raw == null) throw StateError('저장한 배치를 찾지 못했어요.');
    final saved = GardenLayout.fromJson(raw as Map);
    await MongiGardenStore.instance.reload();
    final data = MongiGardenStore.instance.value;
    final visible = [...data.seeds.entries.where((e) => e.value > 0).map((e) => 'seed:${e.key}'),
      ...data.placed.map((id) => 'decor:$id')];
    await GardenLayoutStore.instance.update((current) {
      if (owner != CatCareService.localOwner) throw StateError('계정이 바뀌었어요.');
      final next = GardenLayout(spaces: current.spaces, positions: {
        ...current.positions, for (final id in visible) if (saved.positions.containsKey(id)) id: saved.positions[id]!,
      });
      for (final id in visible) {
        if (!saved.positions.containsKey(id)) continue;
        final error = next.placementError(id, next.position(id), visible);
        if (error != null) throw StateError('배치를 적용할 수 없어요: $error');
      }
      return next;
    });
  });
}
