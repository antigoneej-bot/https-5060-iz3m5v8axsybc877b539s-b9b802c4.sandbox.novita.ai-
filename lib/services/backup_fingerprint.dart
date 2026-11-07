import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// A local digest only: no plaintext or digest is uploaded as metadata.
/// Map iteration order and snapshot timestamps do not represent new records.
Future<String> backupFingerprint(Map<String, dynamic> snapshot) async {
  Object? canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: canonical(value[key])};
    }
    if (value is List) return value.map(canonical).toList();
    return value;
  }

  final content = Map<String, dynamic>.of(snapshot)..remove('createdAt');
  // Hive insertion order is not part of the backed-up record's identity.
  final boxes = content['boxes'];
  if (boxes is Map) {
    content['boxes'] = {
      for (final entry in boxes.entries)
        entry.key: (List<dynamic>.of(entry.value as List)
          ..sort(
            (a, b) => jsonEncode(a['key']).compareTo(jsonEncode(b['key'])),
          )),
    };
  }
  final hash = await Sha256().hash(utf8.encode(jsonEncode(canonical(content))));
  return base64UrlEncode(hash.bytes);
}
