import 'dart:math';
import '../data/shadow_cats_data.dart';

/// "묘연(猫緣) 코드" — 내가 만난 그림자 고양이를 짧은 코드로 바꿔 친구에게
/// 보내고, 친구가 그 코드를 입력하면 자기 고양이와 나란히 놓고 관찰할 수
/// 있게 해주는 완전 로컬(서버 불필요) 인코딩/디코딩 서비스입니다.
///
/// 설계 원칙:
/// - 서버 없이 기기 안에서만 인코딩/디코딩되므로 개인정보가 외부로 전송되지
///   않습니다(고양이 id 하나만 담깁니다).
/// - "좋은 궁합/나쁜 궁합" 같은 점수·판단 언어는 쓰지 않고, 앱 전체 원칙과
///   동일하게 "이런 조합이 보여요"라는 관찰형 문장만 제공합니다.
class CompatibilityService {
  CompatibilityService._();

  // 혼동되기 쉬운 O/0, I/1, L 등을 제외한 31자 알파벳 (사람이 직접 타이핑하기
  // 편하도록 구성).
  static const String _alphabet =
      'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const String _prefix = 'M';

  /// 고양이 id로부터 4자리 묘연 코드를 생성합니다(항상 같은 id는 같은 코드).
  /// 예: 'dreamy' -> 'M7K9'
  static String codeForCat(String catId) {
    final index = shadowCats.indexWhere((c) => c.id == catId);
    if (index < 0) return '';
    final d1 = index ~/ _alphabet.length;
    final d2 = index % _alphabet.length;
    final checksum = (d1 * 7 + d2 * 3 + 5) % _alphabet.length;
    return '$_prefix${_alphabet[d1]}${_alphabet[d2]}${_alphabet[checksum]}';
  }

  /// 코드를 고양이 id로 되돌립니다. 형식이 잘못됐거나 체크섬이 맞지 않으면
  /// null을 반환합니다(친구가 코드를 잘못 입력한 경우를 조용히 걸러냄).
  static String? catIdForCode(String rawCode) {
    final cleaned = rawCode
        .trim()
        .toUpperCase()
        .replaceAll('-', '')
        .replaceAll(' ', '');
    final body = cleaned.startsWith(_prefix)
        ? cleaned.substring(1)
        : cleaned;
    if (body.length != 3) return null;

    final i1 = _alphabet.indexOf(body[0]);
    final i2 = _alphabet.indexOf(body[1]);
    final i3 = _alphabet.indexOf(body[2]);
    if (i1 < 0 || i2 < 0 || i3 < 0) return null;

    final expectedChecksum = (i1 * 7 + i2 * 3 + 5) % _alphabet.length;
    if (i3 != expectedChecksum) return null;

    final index = i1 * _alphabet.length + i2;
    if (index < 0 || index >= shadowCats.length) return null;
    return shadowCats[index].id;
  }

  /// 두 고양이(나 / 친구)를 나란히 놓고 관찰하는 문장을 만듭니다.
  /// 점수나 우열을 매기지 않고, 두 그림자가 함께 있을 때의 풍경을 담담하게
  /// 서술합니다. 같은 문구가 매번 반복되지 않도록 조합별로 몇 가지 표현 중
  /// 하나를 무작위로 고릅니다.
  static String compatibilitySentence({
    required String myCatId,
    required String friendCatId,
  }) {
    final my = shadowCatById(myCatId);
    final friend = shadowCatById(friendCatId);
    final rng = Random();

    if (myCatId == friendCatId) {
      const templates = [
        '두 사람 모두 지금 \'{name}\'의 그림자를 품고 있어요.\n같은 결을 가진 두 마음이 나란히 서 있는 하루예요.',
        '\'{name}\'이 두 사람에게 동시에 찾아왔어요.\n서로의 마음을 설명하지 않아도 알아볼 수 있는 순간일지도 몰라요.',
      ];
      final t = templates[rng.nextInt(templates.length)];
      return t.replaceAll('{name}', my.nameKr);
    }

    final templates = [
      '당신의 그림자는 \'{a}({ka})\', 친구의 그림자는 \'{b}({kb})\'예요.\n서로 다른 결의 두 마음이 오늘 나란히 놓여 있어요.',
      '\'{a}\'와 \'{b}\'가 오늘 만났어요.\n{ka}과 {kb}, 이 둘이 함께 있을 때 어떤 풍경이 될까요?',
      '당신은 {ka}의 마음을, 친구는 {kb}의 마음을 지나고 있어요.\n각자의 속도로 흘러가는 두 결을 그대로 지켜봐 주세요.',
    ];
    final t = templates[rng.nextInt(templates.length)];
    return t
        .replaceAll('{a}', my.nameKr)
        .replaceAll('{b}', friend.nameKr)
        .replaceAll('{ka}', my.keyword)
        .replaceAll('{kb}', friend.keyword);
  }
}
