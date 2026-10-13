import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readPath(String path, int maxBytes) async {
  final file = File(path);
  if (await file.length() > maxBytes) {
    throw const FormatException('파일이 너무 커요.');
  }
  return file.readAsBytes();
}
