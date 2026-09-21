// 실제 사용자 버그(둘 다 안열려/여전히 똑같아)의 근본 원인 재현 및 회귀 테스트.
//
// 근본 원인: PersonalReplyService.create() 내부에서 (특히 웹 환경의
// flutter_secure_storage 를 거치는 HiveEncryption.cipher() 호출 지점 등)
// 어떤 await 하나가 응답을 받지 못하고 영원히 멈추면, 그 Future 자체가
// 완결되지 않아 static _tail 큐가 영구히 멈춥니다. 화면(history_screen.dart)
// 은 자체 30초 UI 타임아웃으로 에러만 보여줄 뿐 원본 작업을 취소하지
// 못했으므로, 그 뒤로 어떤 편지를 열어도(같은 큐를 타므로) 계속 응답이
// 오지 않았습니다.
//
// 이 테스트는 secure storage read 를 "응답 없음(영원히 pending)" 상태로
// 만들어 첫 번째 create() 호출이 실제로 멈추는 상황을 재현한 뒤,
// (1) 그 호출이 무한정 걸리지 않고 스스로 타임아웃되어 실패로 끝나는지,
// (2) 그 실패 이후에 들어온 두 번째(별개의) create() 호출이 큐에 영원히
//     막히지 않고 정상적으로 완료되는지를 검증합니다.
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/services/personal_reply_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('reply-hang-recovery-');
    Hive.init(dir.path);
    SharedPreferences.setMockInitialValues({'is_premium_subscriber': true});
    PersonalReplyService.clock = () => DateTime(2026, 9, 16);
  });

  tearDown(() async {
    PersonalReplyService.clock = DateTime.now;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          null,
        );
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test(
    '보안 저장소 read가 영원히 응답하지 않아도 첫 요청은 스스로 타임아웃되고, '
    '이후 요청은 큐에 영구히 막히지 않고 정상 완료된다',
    () async {
      // secure storage 의 read 요청을 절대 응답하지 않는 Completer 로
      // 묶어, 실제 버그에서 관찰된 "영원히 pending" 상태를 재현합니다.
      final neverResolves = Completer<String?>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (call) async {
              if (call.method == 'read') return neverResolves.future;
              return null;
            },
          );

      // 1) 첫 번째 요청: secure storage read 가 멈춰있으므로 내부적으로
      //    멈추지만, create() 전체에 걸린 방어 타임아웃(25초) 덕분에
      //    무한정 걸리지 않고 스스로 실패로 끝나야 합니다.
      final first = PersonalReplyService.create(
        id: 'hang-1',
        letterText: '오늘 너무 화가 났어.',
        style: ReplyStyle.listen,
        catName: '몽이',
      );

      await expectLater(first, throwsA(isA<TimeoutException>()));

      // 2) 첫 번째 요청이 여전히 내부적으로 secure storage 를 기다리며
      //    떠 있는 상태(neverResolves 는 아직 미완결)에서, 보안 저장소가
      //    정상 응답하도록 mock 을 교체한 뒤 완전히 별개의 두 번째 편지에
      //    대해 create() 를 호출합니다. 고쳐지기 전 버그였다면 이 두
      //    번째 호출도 (poison된) _tail 큐에 걸려 영원히 끝나지 않았을
      //    것입니다. 고친 뒤에는 25초 안에 정상적으로 완료되어야 합니다.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (call) async => call.method == 'read'
                ? null // 첫 실행이라 키가 없다고 응답 -> 새 키 생성 경로
                : null,
          );

      final second = await PersonalReplyService.create(
        id: 'hang-2',
        letterText: '오늘은 조금 나아졌어.',
        style: ReplyStyle.listen,
        catName: '몽이',
      );

      expect(second, isNotEmpty);
    },
    timeout: const Timeout(Duration(seconds: 40)),
  );
}
