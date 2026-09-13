import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

/// Password-derived authenticated encryption. Password is never stored in file.
class BackupCodec {
  static const maxBytes = 8 * 1024 * 1024;
  static const iterations = 600000;
  static Future<Uint8List> encrypt(Map<String, dynamic> snapshot, String password) =>
      compute(_seal, {'snapshot': snapshot, 'password': password});
  static Future<Map<String, dynamic>> decrypt(Uint8List bytes, String password) =>
      compute(_open, {'bytes': bytes, 'password': password});
}
Future<SecretKey> _derive(String password, List<int> salt) => Pbkdf2(
  macAlgorithm: Hmac.sha256(), iterations: BackupCodec.iterations, bits: 256,
).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
Future<Uint8List> _seal(Map<String, dynamic> input) async {
  final password = input['password'] as String;
  if (password.length < 12) throw const FormatException('백업 암호는 12자 이상으로 정해 주세요.');
  final plaintext = utf8.encode(jsonEncode(input['snapshot']));
  if (plaintext.length > 4 * 1024 * 1024) throw const FormatException('백업 용량이 현재 한도를 넘었어요.');
  final rng = Random.secure();
  final salt = List<int>.generate(16, (_) => rng.nextInt(256));
  final secret = await _derive(password, salt);
  final box = await AesGcm.with256bits().encrypt(plaintext, secretKey: secret,
      aad: utf8.encode('maeumnyang-backup-v1'));
  return Uint8List.fromList(utf8.encode(jsonEncode({
    'format': 'maeumnyang-backup', 'version': 1,
    'salt': base64Encode(salt), 'nonce': base64Encode(box.nonce),
    'ciphertext': base64Encode(box.cipherText), 'mac': base64Encode(box.mac.bytes),
  })));
}
Future<Map<String, dynamic>> _open(Map<String, dynamic> input) async {
  final bytes = input['bytes'] as Uint8List;
  if (bytes.length > BackupCodec.maxBytes) throw const FormatException('파일이 너무 커요.');
  final raw = jsonDecode(utf8.decode(bytes));
  if (raw is! Map || raw['format'] != 'maeumnyang-backup' || raw['version'] != 1) {
    throw const FormatException('지원하지 않는 백업 형식이에요.');
  }
  final salt = base64Decode(raw['salt'] as String);
  final nonce = base64Decode(raw['nonce'] as String);
  final mac = base64Decode(raw['mac'] as String);
  if (salt.length != 16 || nonce.length != 12 || mac.length != 16) throw const FormatException('손상된 백업이에요.');
  final key = await _derive(input['password'] as String, salt);
  final plaintext = await AesGcm.with256bits().decrypt(
    SecretBox(base64Decode(raw['ciphertext'] as String), nonce: nonce, mac: Mac(mac)),
    secretKey: key, aad: utf8.encode('maeumnyang-backup-v1'));
  if (plaintext.length > 4 * 1024 * 1024) throw const FormatException('파일이 너무 커요.');
  return Map<String, dynamic>.from(jsonDecode(utf8.decode(plaintext)) as Map);
}
