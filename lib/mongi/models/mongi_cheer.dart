import 'dart:math';

/// "몽이의 응원 우편함" - Finch "Good Vibes"를 벤치마킹한 경량 소셜 기능
/// (벤치마킹 제안 #3)의 로컬 경량판.
///
/// 이 앱은 처음부터 Firebase/서버가 전혀 없는 완전 로컬 우선 구조다. 실제
/// 타인과 익명으로 실시간 메시지를 주고받는 "진짜 소셜"은 이 구조와 근본적으로
/// 충돌하므로, 대신 정직하게 재해석한 로컬 경량판으로 구현한다:
/// - "보내기": 미리 큐레이션된 응원 문구 중 하나를 골라 몽이에게 맡기면,
///   몽이가 그 마음을 대신 세상에 전해준다는 제스처. 실제 수신자는 없다는
///   사실을 화면에 항상 정직하게 안내한다.
/// - "받기": 하루 한 번, 큐레이션된 응원 풀에서 무작위로 하나를 "누군가의
///   마음"처럼 받는다.
///
/// 실제 문구는 화면에서 [AppLocalizations]를 통해 인덱스 기반으로 완성한다
/// (easterEgg/[MongiMoodService]와 동일한 다국어 지원 패턴) - 서버/AI 없이
/// 로컬 데이터 + 큐레이션된 목록만으로 동작한다는 원칙을 그대로 따른다.
class MongiCheer {
  MongiCheer._();

  /// 보낼 수 있는 응원 문구 개수. 실제 문구는 `cheerSendOption0` ~
  /// `cheerSendOption{sendOptionCount - 1}` 키로 ARB 파일에 번역되어 있다.
  static const int sendOptionCount = 6;

  /// 받을 수 있는 응원 문구 풀 크기. 실제 문구는 `cheerReceiveMessage0` ~
  /// `cheerReceiveMessage{receiveMessageCount - 1}` 키로 ARB 파일에 번역되어 있다.
  static const int receiveMessageCount = 16;

  /// "보내기"를 완료했을 때 지급되는 소량의 빛의 정수 보상(작은 친절도
  /// 인정해주는 차원 - 마음 챌린지의 하루 보상보다는 낮게 설정).
  static const int sendRewardLightEssence = 2;

  /// "받기"를 눌러 오늘의 응원을 확인할 때 함께 지급되는 소량의 빛의 정수 보상.
  static const int receiveRewardLightEssence = 3;

  /// 오늘 받을 응원 문구의 인덱스를 무작위로 고른다.
  static int randomReceiveIndex() => Random().nextInt(receiveMessageCount);
}
