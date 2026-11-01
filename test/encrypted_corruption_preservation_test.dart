import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/services/hive_encryption.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async =>
              call.method == 'read' ? base64Encode(List.filled(32, 7)) : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  for (final wrongKey in [false, true]) {
    test(
      wrongKey
          ? 'wrong key preserves bytes and releases failed-open handles'
          : 'corrupt tail preserves bytes and releases failed-open handles',
      () async {
        final dir = await Directory.systemTemp.createTemp('garden-preserve-');
        Hive.init(dir.path);
        final cipher = HiveAesCipher(List.filled(32, wrongKey ? 8 : 7));
        try {
          final box = await Hive.openBox(
            'private__enc',
            encryptionCipher: cipher,
          );
          await box.put('letter', '지켜야 할 기록');
          await box.flush();
          final file = File(box.path!);
          await box.close();
          if (!wrongKey) {
            await file.writeAsBytes(
              [1, 2, 3],
              mode: FileMode.append,
              flush: true,
            );
          }
          final before = await file.readAsBytes();
          // Both the first open and concurrent waiter must fail only after close.
          // Immediate retry must not race a previous box unregister/lock deletion.
          for (var attempt = 0; attempt < 3; attempt++) {
            final first = HiveEncryption.openPreservingFile(
              'private__enc',
              cipher: HiveAesCipher(List.filled(32, 7)),
            );
            final second = HiveEncryption.openPreservingFile(
              'private__enc',
              cipher: HiveAesCipher(List.filled(32, 7)),
            );
            await Future.wait([
              expectLater(first, throwsA(anything)),
              expectLater(second, throwsA(anything)),
            ]);
            expect(
              await File(dir.path + '/private__enc.lock').exists(),
              isFalse,
            );
            expect(Hive.isBoxOpen('private__enc'), isFalse);
            expect(await file.readAsBytes(), before);
          }
          await expectLater(
            HiveEncryption.openBox('private'),
            throwsA(anything),
          );
          expect(await file.readAsBytes(), before);
        } finally {
          await Hive.close();
          // This fixture owns exactly this newly created directory. No exists()
          // guard or retry masks a cleanup race or a missing directory failure.
          await dir.delete(recursive: true);
        }
      },
    );
  }
}
