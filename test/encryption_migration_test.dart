import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../lib/services/hive_encryption.dart';

void main() {
  test('equal record counts do not hide missing keys during interrupted migration', () async {
    final directory = await Directory.systemTemp.createTemp('garden-migration-test');
    Hive.init(directory.path);
    try {
      final plain = await Hive.openBox('legacy-test');
      final cipher = HiveAesCipher(Hive.generateSecureKey());
      final encrypted = await Hive.openBox('encrypted-test', encryptionCipher: cipher);
      await plain.putAll({'a': 'older', 'b': 'must survive'});
      await encrypted.putAll({'a': 'newer', 'c': 'encrypted only'});
      await HiveEncryption.mergeLegacyRecords(plain, encrypted);
      await encrypted.close();
      final reopened = await Hive.openBox('encrypted-test', encryptionCipher: cipher);
      expect(reopened.get('a'), 'newer');
      expect(reopened.get('b'), 'must survive');
      expect(reopened.get('c'), 'encrypted only');
      expect(plain.length, 2); // Caller retains original until verified migration.
    } finally { await Hive.close(); await directory.delete(recursive: true); }
  });
}
