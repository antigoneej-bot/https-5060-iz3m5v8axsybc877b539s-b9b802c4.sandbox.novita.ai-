import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/garden_personal_gallery_store.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/backup_service.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/mongi/models/garden_life.dart';

Uint8List png() => base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aK1sAAAAASUVORK5CYII=');
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CatCareService.setCurrentUser('gallery-test');
    directory = await Directory.systemTemp.createTemp('private-gallery-');
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel, (call) async => call.method == 'read' ? base64Encode(List<int>.filled(32, 7)) : null);
  });
  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    CatCareService.clearCurrentUser();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  test('concurrent favorites and photo writes retain all changes', () async {
    await Future.wait([
      GardenPersonalGalleryStore.favorite('gallery-test', 'letter:saved:a', true),
      GardenPersonalGalleryStore.favorite('gallery-test', 'garden:saved:b', true),
      GardenPersonalGalleryStore.addPhoto('gallery-test', png()),
    ]);
    final data = await GardenPersonalGalleryStore.read('gallery-test');
    expect(data['favorites'], containsAll(['letter:saved:a', 'garden:saved:b']));
    expect(data['photos'], hasLength(1));
    final box = await HiveEncryption.openBox(GardenPersonalGalleryStore.boxName);
    expect(box.name, endsWith('__enc'));
  });
  test('full album fails without evicting photos; deleting releases a slot', () async {
    for (var i = 0; i < GardenPersonalGalleryStore.maxPhotos; i++) {
      await GardenPersonalGalleryStore.addPhoto('gallery-test', png());
    }
    final before = await GardenPersonalGalleryStore.read('gallery-test');
    await expectLater(GardenPersonalGalleryStore.addPhoto('gallery-test', png()), throwsStateError);
    expect(await GardenPersonalGalleryStore.read('gallery-test'), before);
    final id = (before['photos'] as List).first['id'] as String;
    await GardenPersonalGalleryStore.deletePhoto('gallery-test', id);
    await GardenPersonalGalleryStore.addPhoto('gallery-test', png());
    expect((await GardenPersonalGalleryStore.read('gallery-test'))['photos'], hasLength(8));
  });
  test('removing exhibit preserves photos and favorites; wrong owner cannot read or write', () async {
    await GardenPersonalGalleryStore.exhibit('gallery-test', png());
    await GardenPersonalGalleryStore.addPhoto('gallery-test', png());
    await GardenPersonalGalleryStore.favorite('gallery-test', 'letter:saved:a', true);
    await GardenPersonalGalleryStore.exhibit('gallery-test', null);
    final data = await GardenPersonalGalleryStore.read('gallery-test');
    expect(data['artwork'], isNull);
    expect(data['photos'], hasLength(1));
    expect(data['favorites'], ['letter:saved:a']);
    CatCareService.setCurrentUser('different-owner');
    await expectLater(GardenPersonalGalleryStore.read('gallery-test'), throwsStateError);
    await expectLater(GardenPersonalGalleryStore.exhibit('gallery-test', png()), throwsStateError);
    expect((await GardenPersonalGalleryStore.read('different-owner'))['photos'], isEmpty);
  });
  test('backup captures private images and validates owner and image dimensions', () async {
    await GardenPersonalGalleryStore.exhibit('gallery-test', png());
    final snapshot = await BackupService.snapshot();
    BackupService.validate(snapshot);
    final rows = (snapshot['boxes'] as Map)['garden_personal_gallery'] as List;
    expect(rows, hasLength(1));
    final original = Map<String, dynamic>.from(rows.single['value'] as Map);
    expect(original['artwork'], base64Encode(png()));
    final box = await HiveEncryption.openBox(GardenPersonalGalleryStore.boxName);
    await box.clear();
    await BackupService.restore(snapshot);
    expect(await GardenPersonalGalleryStore.read('gallery-test'), original);
    expect(() => GardenPersonalGalleryStore.validate('wrong-key', original), throwsFormatException);
    final oversized = png();
    ByteData.sublistView(oversized).setUint32(16, 999999);
    expect(() => GardenPersonalGalleryStore.validateImage(base64Encode(oversized)), throwsFormatException);
    expect(() => GardenPersonalGalleryStore.validateImage(base64Encode(Uint8List(200000))), throwsFormatException);
  });
  test('unstable legacy record IDs are rejected without storing a favorite', () async {
    await expectLater(GardenPersonalGalleryStore.favorite('gallery-test', 'letter:legacy:0', true), throwsFormatException);
    expect((await GardenPersonalGalleryStore.read('gallery-test'))['favorites'], isEmpty);
  });
  test('cushion walk avoids obstacle and settles at exact seat', () {
    const from = Offset(1000, 600), seat = Offset(1400, 600), obstacle = Offset(1200, 600);
    final moving = GardenCatMoment.cushion(from, seat, .5, [obstacle]);
    expect(moving.walking, isTrue);
    expect((moving.feet - obstacle).distance, greaterThan(40));
    final resting = GardenCatMoment.cushion(from, seat, 1, [obstacle]);
    expect(resting.feet, seat);
    expect(resting.resting, isTrue);
    expect(resting.walking, isFalse);
  });
}
