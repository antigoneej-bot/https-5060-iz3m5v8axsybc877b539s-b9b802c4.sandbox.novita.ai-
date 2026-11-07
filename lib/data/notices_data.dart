import '../models/notice.dart';

/// 정원소식 로컬 정적 목록 - 서버 미연결 시의 폴백(fallback)용.
///
/// 정원소식은 이제 서버(Firestore `gardenNews` 컬렉션)에서 관리합니다.
/// 관리자 계정으로 로그인하면 앱 안에서 직접 작성/수정/삭제할 수 있고,
/// `lib/screens/notice_list_screen.dart`가 [NoticeService]를 통해 서버 목록을
/// 가져와 보여줍니다.
///
/// 이 파일은 서버가 아직 연결되지 않은 환경([CloudService.enabled]==false)
/// 또는 네트워크 오류 시에만 참고용으로 쓰이는 "최초 캐시" 역할만 합니다.
/// 운영 중인 서비스에 새 소식을 올리려면 더 이상 이 파일을 수정하지
/// 마세요 - 관리자 계정으로 로그인해 정원소식 화면에서 직접 작성하세요.
///
/// [설계 원칙] 운영자가 실제로 올린 내용만 보여준다 - 가짜 참여자 수,
/// 가짜 신청 현황 같은 "운영 중인 것처럼 꾸민" 데이터는 절대 만들지 않는다.
final List<Notice> noticesData = [
  Notice(
    id: 'notice_2026_07_12_meditation_update',
    title: '명상 · 움직임 콘텐츠가 늘어났어요',
    body:
        '4-7-8 호흡법, 허밍 호흡, 소리 명상, 안전한 장소 떠올리기 등 다양한 명상·이완 가이드가 새로 추가되었습니다. '
        '"명상 · 움직임" 탭에서 새로워진 콘텐츠를 만나보세요.',
    emoji: '🧘',
    type: NoticeType.update,
    date: '2026-07-12',
  ),
  Notice(
    id: 'notice_2026_07_12_welcome',
    title: '마음냥 정원에 오신 걸 환영해요',
    body:
        '42마리 그림자 고양이와 함께 매일의 감정을 알아차리고, 마음 돌보기로 나만의 고양이를 키워보세요. '
        '궁금한 점이나 의견이 있다면 마이페이지에서 언제든 알려주세요.',
    emoji: '🌸',
    type: NoticeType.info,
    date: '2026-07-12',
  ),
];
