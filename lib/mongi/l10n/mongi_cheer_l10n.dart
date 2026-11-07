import 'gen/app_localizations.dart';

/// [MongiCheer]의 인덱스 기반 응원 문구를 언어별 문자열로 변환한다.
/// [MongiMoodService.easterEggCount]와 동일한 인덱스+switch 패턴 -
/// 실제 문구는 저장하지 않고 인덱스만 저장한 뒤, 화면에서 이 헬퍼로
/// AppLocalizations 문자열로 바꿔 다국어를 지원한다.

/// "보내기" 문구 목록 중 [index]번째를 반환한다.
String cheerSendOptionText(AppLocalizations l10n, int index) {
  switch (index) {
    case 0:
      return l10n.cheerSendOption0;
    case 1:
      return l10n.cheerSendOption1;
    case 2:
      return l10n.cheerSendOption2;
    case 3:
      return l10n.cheerSendOption3;
    case 4:
      return l10n.cheerSendOption4;
    case 5:
      return l10n.cheerSendOption5;
    default:
      return l10n.cheerSendOption0;
  }
}

/// "받기" 문구 풀 중 [index]번째를 반환한다.
String cheerReceiveMessageText(AppLocalizations l10n, int index) {
  switch (index) {
    case 0:
      return l10n.cheerReceiveMessage0;
    case 1:
      return l10n.cheerReceiveMessage1;
    case 2:
      return l10n.cheerReceiveMessage2;
    case 3:
      return l10n.cheerReceiveMessage3;
    case 4:
      return l10n.cheerReceiveMessage4;
    case 5:
      return l10n.cheerReceiveMessage5;
    case 6:
      return l10n.cheerReceiveMessage6;
    case 7:
      return l10n.cheerReceiveMessage7;
    case 8:
      return l10n.cheerReceiveMessage8;
    case 9:
      return l10n.cheerReceiveMessage9;
    case 10:
      return l10n.cheerReceiveMessage10;
    case 11:
      return l10n.cheerReceiveMessage11;
    case 12:
      return l10n.cheerReceiveMessage12;
    case 13:
      return l10n.cheerReceiveMessage13;
    case 14:
      return l10n.cheerReceiveMessage14;
    case 15:
      return l10n.cheerReceiveMessage15;
    default:
      return l10n.cheerReceiveMessage0;
  }
}
