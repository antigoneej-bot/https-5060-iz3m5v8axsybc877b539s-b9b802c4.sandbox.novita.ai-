import 'dart:typed_data';
import 'backup_io/file_reader_stub.dart'
    if (dart.library.io) 'backup_io/file_reader_io.dart'
    as platform;

/// Browsers provide bytes rather than a local file path. Check the advertised
/// size before reading a native file, and check the actual length afterwards.
Future<Uint8List> readBackupFileBytes({
  required int declaredSize,
  required int maxBytes,
  Uint8List? bytes,
  String? path,
  Future<Uint8List> Function(String path, int maxBytes)? readPath,
}) async {
  if (declaredSize < 0 || declaredSize > maxBytes) {
    throw const FormatException('파일이 너무 커요.');
  }
  final Uint8List result;
  if (bytes != null) {
    result = bytes;
  } else if (path != null && path.isNotEmpty) {
    result = await (readPath ?? platform.readPath)(path, maxBytes);
  } else {
    throw const FormatException('백업 파일을 읽지 못했어요. 파일을 다시 선택해 주세요.');
  }
  if (result.isEmpty || result.length > maxBytes) {
    throw const FormatException('백업 파일의 크기가 올바르지 않아요.');
  }
  return result;
}
