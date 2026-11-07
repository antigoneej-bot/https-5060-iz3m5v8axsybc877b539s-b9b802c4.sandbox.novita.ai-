import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/services/hive_encryption.dart';
import 'package:flutter_app/services/meditation_checkin_store.dart';
import 'package:flutter_app/services/meditation_completion_journal.dart';
import 'package:flutter_app/services/meditation_library_store.dart';

void useEncryptedMeditationStorage() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('meditation-encrypted-');
    Hive.init(dir.path);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => call.method == 'read'
              ? base64Encode(List<int>.filled(32, 7))
              : null,
        );
    await HiveEncryption.openBox(MeditationCompletionJournal.boxName);
    await MeditationCheckInStore.read();
    await MeditationLibraryStore.instance.reload();
  });
  tearDown(() async {
    // Flush async disk callbacks before leaving a widget test's fake clock.
    await Hive.close();
    await dir.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
