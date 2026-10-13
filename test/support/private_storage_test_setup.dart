import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Media completion and feedback now use the same encrypted storage as the app.
void usePrivateStorageForTests(String prefix) {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final secure = <String, String>{};
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp(prefix);
    Hive.init(directory.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            final args = Map<String, dynamic>.from(call.arguments as Map);
            final key = args['key'] as String?;
            if (call.method == 'read') return secure[key];
            if (call.method == 'write') secure[key!] = args['value'] as String;
            if (call.method == 'delete') secure.remove(key);
            return null;
          },
        );
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
}
