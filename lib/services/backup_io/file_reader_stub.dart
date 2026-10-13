import 'dart:typed_data';

Future<Uint8List> readPath(String path, int maxBytes) =>
    Future.error(UnsupportedError('이 환경에서는 파일 내용을 직접 선택해 주세요.'));
