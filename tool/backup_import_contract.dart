// Run with Dart alone: dart run tool/backup_import_contract.dart
import 'dart:io';
import 'dart:typed_data';
import '../lib/services/backup_file_reader.dart';

int passed = 0;
void check(bool condition, String label) {
  if (!condition) throw StateError(label);
  passed++;
}

Future<void> rejects(Future<void> Function() action, String label) async {
  try {
    await action();
  } on FormatException {
    passed++;
    return;
  }
  throw StateError(label);
}

Future<void> main() async {
  var pathReads = 0;
  final browserBytes = Uint8List.fromList([1, 2, 3]);
  final imported = await readBackupFileBytes(
    bytes: browserBytes,
    declaredSize: 3,
    maxBytes: 8,
    readPath: (_, __) async {
      pathReads++;
      throw StateError('no path on web');
    },
  );
  check(
    imported.length == 3 && pathReads == 0,
    'browser bytes must restore without a native path',
  );
  await rejects(() async {
    await readBackupFileBytes(
      declaredSize: 9,
      maxBytes: 8,
      path: 'too-large',
      readPath: (_, __) async {
        pathReads++;
        return browserBytes;
      },
    );
  }, 'advertised oversized file must be rejected');
  check(pathReads == 0, 'reject oversized metadata before reading');
  await rejects(() async {
    await readBackupFileBytes(
      declaredSize: 2,
      maxBytes: 8,
      bytes: Uint8List(9),
    );
  }, 'actual bytes must also be bounded');
  await rejects(() async {
    await readBackupFileBytes(
      declaredSize: 0,
      maxBytes: 8,
      bytes: Uint8List(0),
    );
  }, 'empty file must fail instead of showing password dialog');
  await rejects(() async {
    await readBackupFileBytes(declaredSize: 3, maxBytes: 8);
  }, 'missing bytes and path must report a readable failure');
  final temp = await Directory.systemTemp.createTemp(
    'mindnyang-backup-import-',
  );
  try {
    final file = File('${temp.path}/sample.mng');
    await file.writeAsBytes(browserBytes);
    final native = await readBackupFileBytes(
      declaredSize: 3,
      maxBytes: 8,
      path: file.path,
    );
    check(native.join(',') == '1,2,3', 'native file path still imports');
    await file.writeAsBytes(Uint8List(9));
    await rejects(() async {
      await readBackupFileBytes(declaredSize: 3, maxBytes: 8, path: file.path);
    }, 'native file that grew after selection must be rejected');
  } finally {
    await temp.delete(recursive: true);
  }
  print('backup import contract: $passed checks passed');
}
