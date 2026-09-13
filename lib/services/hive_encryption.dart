import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// B-1: Hive 박스 AES 암호화 + 키 안전 보관.
///
/// - 키는 [FlutterSecureStorage]에 보관 (기기 키스토어/키체인 기반)
/// - 디스크상 박스명은 `{원본}__enc` 로 분리해, 기존 평문 박스가 있으면
///   최초 1회 마이그레이션 후 평문 박스를 삭제합니다.
/// - 마이그레이션 실패 시에는 빈 암호화 박스로 갈아타지 않고,
///   원본을 보존하고 오류를 알립니다. 평문 쓰기로 전환하지 않습니다.
class HiveEncryption {
  HiveEncryption._();

  static const _secureKeyName = 'hive_aes_key_v1';
  static const _encSuffix = '__enc';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static HiveAesCipher? _cipher;
  static Future<HiveAesCipher>? _cipherOpening;

  /// AES 암호화를 위한 [HiveAesCipher]를 준비합니다.
  static Future<HiveAesCipher> cipher() {
    if (_cipher != null) return Future.value(_cipher!);
    return _cipherOpening ??= _loadCipher().catchError((Object error) {
      _cipherOpening = null;
      throw error;
    });
  }

  static Future<HiveAesCipher> _loadCipher() async {

    String? encoded = await _secureStorage.read(key: _secureKeyName);
    if (encoded == null || encoded.isEmpty) {
      final key = Hive.generateSecureKey();
      encoded = base64Encode(key);
      await _secureStorage.write(key: _secureKeyName, value: encoded);
    }

    _cipher = HiveAesCipher(base64Decode(encoded));
    return _cipher!;
  }

  static final Map<String, Future<Box>> _opening = {};

  /// Keep both files on failure. Never silently continue writing plaintext.
  static Future<Box> openBox(String name) {
    return _opening.putIfAbsent(name, () => _openEncrypted(name).whenComplete(() {
      _opening.remove(name);
    }));
  }

  static Future<Box> _openEncrypted(String name) async {
    final encName = '$name$_encSuffix';
    final cipher = await HiveEncryption.cipher();
    final plainExists = await Hive.boxExists(name);
    if (Hive.isBoxOpen(encName) && !plainExists) return Hive.box(encName);
    final enc = Hive.isBoxOpen(encName) ? Hive.box(encName)
      : await Hive.openBox(encName, encryptionCipher: cipher);
    if (!plainExists) return enc;
    Box? plain;
    try {
      plain = Hive.isBoxOpen(name) ? Hive.box(name) : await Hive.openBox(name);
      await mergeLegacyRecords(plain, enc);
      await plain.close();
      plain = null;
      await Hive.deleteBoxFromDisk(name);
      return enc;
    } catch (_) {
      if (plain != null && plain.isOpen) await plain.close();
      if (enc.isOpen) await enc.close();
      rethrow;
    }
  }

  @visibleForTesting
  static Future<void> mergeLegacyRecords(Box plain, Box encrypted) async {
    // Counts alone cannot establish that all original keys were copied.
    for (final key in plain.keys.toList()) {
      if (!encrypted.containsKey(key)) await encrypted.put(key, plain.get(key));
    }
    await encrypted.flush();
    if (plain.keys.any((key) => !encrypted.containsKey(key))) {
      throw StateError('암호화 이전 기록의 복사를 마치지 못했어요.');
    }
  }
}
