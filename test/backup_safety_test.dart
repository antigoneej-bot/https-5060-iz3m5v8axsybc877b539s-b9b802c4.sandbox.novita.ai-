import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/backup_codec.dart';
import 'package:flutter_app/services/backup_service.dart';

Map<String,dynamic> sample() => {
  'schema':1, 'createdAt':'2026-09-13T00:00:00Z',
  'boxes':<String,dynamic>{'drafts':[{'key':'letter_test','value':'오늘의 마음 기록'}]},
  'settings':<String,dynamic>{'companion_name':{'type':'string','value':'마음냥'}},
};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('encrypted backup roundtrip preserves Korean records', () async {
    final data = sample();
    final bytes = await BackupCodec.encrypt(data,'test-only-password-123');
    expect(utf8.decode(bytes), isNot(contains('오늘의 마음 기록')));
    expect(await BackupCodec.decrypt(bytes,'test-only-password-123'), data);
  }, timeout: const Timeout(Duration(minutes:2)));
  test('wrong password and changed authentication tag cannot restore', () async {
    final bytes = await BackupCodec.encrypt(sample(),'test-only-password-123');
    await expectLater(BackupCodec.decrypt(bytes,'wrong-password-123'),throwsA(anything));
    final envelope = jsonDecode(utf8.decode(bytes)) as Map;
    final tag = base64Decode(envelope['mac'] as String); tag[0] ^= 1;
    envelope['mac'] = base64Encode(tag);
    await expectLater(BackupCodec.decrypt(Uint8List.fromList(utf8.encode(jsonEncode(envelope))),
      'test-only-password-123'),throwsA(anything));
  }, timeout: const Timeout(Duration(minutes:2)));
  test('backup validates an ordinary snapshot', () { BackupService.validate(sample()); });
  test('import cannot restore premium rights', () {
    final data = sample();
    (data['settings'] as Map)['local_user_premium'] = {'type':'bool','value':true};
    expect(()=>BackupService.validate(data),throwsFormatException);
  });
  test('known preference cannot be restored with an incompatible type', () {
    final data = sample();
    (data['settings'] as Map)['local_user_care_temperature'] = {'type':'string','value':'oops'};
    expect(()=>BackupService.validate(data),throwsFormatException);
  });
  test('duplicate IDs and unknown record boxes fail before any write', () {
    final data = sample();
    (data['boxes']['drafts'] as List).add({'key':'letter_test','value':'duplicate'});
    expect(()=>BackupService.validate(data),throwsFormatException);
    final other = sample(); (other['boxes'] as Map)['purchase_tokens'] = [];
    expect(()=>BackupService.validate(other),throwsFormatException);
  });
  test('unknown preferences are excluded from export', () {
    expect(BackupService.allowedPref('local_user_new_secret'),isFalse);
    expect(BackupService.allowedPref('last_cloud_backup_some_uid'),isFalse);
    expect(BackupService.allowedPref('local_user_journey_done'),isTrue);
  });
}
