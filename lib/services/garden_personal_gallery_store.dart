import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'hive_encryption.dart';
import 'local_record_transaction.dart';
import 'cat_care_service.dart';

/// Private, owner-scoped additions. Never included in public garden snapshots.
class GardenPersonalGalleryStore {
  static final changes = ValueNotifier<int>(0);
  static const boxName = 'garden_personal_gallery_local_user';
  static const maxPhotos = 8, maxImageBytes = 180000;
  static bool stableRecord(String id) =>
      RegExp(r'^(letter|garden):saved:.+').hasMatch(id) && id.length <= 512;
  static String ownerKey(String owner) => base64Url.encode(utf8.encode(owner));
  static Map<String, dynamic> empty(String owner) => {
    'owner': owner, 'favorites': <String>[], 'photos': <dynamic>[], 'artwork': null,
  };
  static void validateImage(Object? value) {
    if (value is! String || value.length > ((maxImageBytes + 2) ~/ 3) * 4) {
      throw const FormatException('그림 용량이 너무 커요.');
    }
    final b = base64Decode(value);
    if (b.length < 33 || b.length > maxImageBytes ||
        !listEquals(b.sublist(0, 8), [137,80,78,71,13,10,26,10]) ||
        !listEquals(b.sublist(12, 16), [73,72,68,82])) {
      throw const FormatException('PNG 그림을 확인해 주세요.');
    }
    final header = ByteData.sublistView(b);
    final w = header.getUint32(16), h = header.getUint32(20);
    if (w == 0 || h == 0 || w > 1600 || h > 1600) {
      throw const FormatException('그림 크기를 확인해 주세요.');
    }
  }
  static void validate(Object? key, Object? value) {
    if (value is! Map || value.length != 4 ||
        !value.keys.every({'owner', 'favorites', 'photos', 'artwork'}.contains) || value['owner'] is! String ||
        (value['owner'] as String).isEmpty || (value['owner'] as String).length > 256 ||
        key != ownerKey(value['owner'] as String) ||
        value['favorites'] is! List || value['photos'] is! List) {
      throw const FormatException('개인 보관함 구조를 확인해 주세요.');
    }
    final favorites = value['favorites'] as List, photos = value['photos'] as List;
    if (favorites.length > 2000 || favorites.toSet().length != favorites.length ||
        favorites.any((id) => id is! String || !stableRecord(id)) || photos.length > maxPhotos) {
      throw const FormatException('보관함 한도를 확인해 주세요.');
    }
    final ids = <String>{};
    for (final p in photos) {
      if (p is! Map || p.length != 3 || !p.keys.every({'id', 'date', 'png'}.contains) || p['id'] is! String || (p['id'] as String).length > 64 ||
          !ids.add(p['id'] as String) || p['date'] is! String ||
          DateTime.tryParse(p['date'] as String) == null) {
        throw const FormatException('사진 기록을 확인해 주세요.');
      }
      validateImage(p['png']);
    }
    if (value['artwork'] != null) validateImage(value['artwork']);
  }
  static void _checkOwner(String owner) {
    if (owner != CatCareService.localOwner) throw StateError('계정이 바뀌었어요. 다시 열어 주세요.');
  }
  static Future<Map<String, dynamic>> read(String owner) => LocalRecordTransaction.run(() async {
    _checkOwner(owner);
    final box = await HiveEncryption.openBox(boxName);
    _checkOwner(owner);
    final value = box.get(ownerKey(owner)) ?? empty(owner);
    validate(ownerKey(owner), value);
    return Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
  });
  static Future<void> _edit(String owner, void Function(Map<String, dynamic>) edit) =>
      LocalRecordTransaction.atomic(() async {
    final data = await read(owner);
    edit(data);
    validate(ownerKey(owner), data);
    final box = await HiveEncryption.openBox(boxName);
    _checkOwner(owner);
    LocalRecordTransaction.capture(box);
    await box.put(ownerKey(owner), data);
    await box.flush();
    changes.value++;
  });
  static Future<void> favorite(String owner, String id, bool keep) => _edit(owner, (data) {
    if (!stableRecord(id)) throw const FormatException('이전 형식의 기록은 간직하기를 지원하지 않아요.');
    final ids = List<String>.from(data['favorites'] as List)..remove(id);
    if (keep) ids.add(id);
    data['favorites'] = ids;
  });
  static Future<void> exhibit(String owner, Uint8List? png) => _edit(owner, (data) {
    data['artwork'] = png == null ? null : base64Encode(png);
  });
  static Future<void> addPhoto(String owner, Uint8List png) => _edit(owner, (data) {
    final photos = data['photos'] as List;
    if (photos.length >= maxPhotos) throw StateError('사진첩이 가득 찼어요. 사진을 내보내거나 지워 주세요.');
    final now = DateTime.now();
    var id = now.microsecondsSinceEpoch.toString();
    var suffix = 0;
    while (photos.any((p) => p['id'] == id)) { id = '${now.microsecondsSinceEpoch}-${++suffix}'; }
    photos.add({'id': id, 'date': now.toIso8601String(), 'png': base64Encode(png)});
  });
  static Future<void> deletePhoto(String owner, String id) => _edit(owner, (data) {
    (data['photos'] as List).removeWhere((p) => p['id'] == id);
  });
}
