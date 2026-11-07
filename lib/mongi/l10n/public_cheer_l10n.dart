import 'gen/app_localizations.dart';

/// 공개정원 응원(3단계, 서버 연동)의 인덱스 기반 문구를 언어별 문자열로
/// 변환한다. [mongi_cheer_l10n.dart]와 동일한 인덱스+switch 패턴 - 서버는
/// 인덱스 범위만 검증하고 실제 문구 내용은 모른다(다국어는 클라이언트에서
/// 완성).
String publicCheerOptionText(AppLocalizations l10n, int index) {
  switch (index) {
    case 0:
      return l10n.publicCheerOption0;
    case 1:
      return l10n.publicCheerOption1;
    case 2:
      return l10n.publicCheerOption2;
    case 3:
      return l10n.publicCheerOption3;
    case 4:
      return l10n.publicCheerOption4;
    case 5:
      return l10n.publicCheerOption5;
    default:
      return l10n.publicCheerOption0;
  }
}
