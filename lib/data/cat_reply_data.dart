import 'dart:math';
import '../models/letter_entry.dart';
import '../models/shadow_cat.dart';

/// "고양이의 답장" 문구를 오프라인에서 즉석으로 만들어내는 헬퍼.
///
/// 서버나 AI 호출 없이, 사용자가 그날 쓴 편지에 대해 그림자 고양이가
/// 다음날 아침 보내주는 짧은 답장을 그 자리에서 생성합니다. 같은 편지에는
/// 항상 같은 답장이 나오도록 [LetterEntry.id]를 시드로 사용해 고정합니다
/// (앱을 다시 열어도, 다른 기기에서 봐도 같은 내용이 보이도록).
///
/// 내용은 그 고양이 고유의 위로 문구([ShadowCat.comfortMessage])와 실천
/// 지침([ShadowCat.guidance])을 그대로 살려, "그 고양이가 나에게 답장을
/// 쓴다면 이런 말을 할 것 같다"는 톤으로 앞뒤에 인사말을 덧붙입니다.

const List<String> _catReplyOpeners = [
  '어젯밤, 네가 보낸 편지를 몇 번이나 다시 읽었어.',
  '아직 해가 다 뜨지도 않았는데, 네 편지 생각에 눈이 먼저 떠졌어.',
  '편지 고마워. 네 마음이 고스란히 느껴졌어.',
  '너의 편지를 받고, 나도 밤새 네 생각을 했어.',
  '조용한 새벽, 네가 남긴 말들을 가만히 들여다봤어.',
  '네가 잠든 사이에, 나는 네 편지를 품고 있었어.',
];

const List<String> _catReplyClosers = [
  '오늘 하루도, 내가 네 곁에 있을게.',
  '무리하지 않아도 괜찮아. 나는 여기서 기다릴게.',
  '오늘은 너 자신에게 조금 더 다정해지기를 바라.',
  '또 편지 써줘. 나는 언제든 여기서 기다리고 있어.',
  '네가 어떤 모습이든, 나는 네 편이야.',
  '오늘도 애쓰지 않아도 돼. 그냥 너답게, 하루를 보내줘.',
];

/// [entry]에 대한 [cat]의 답장 전문을 만들어 반환합니다.
String generateCatReply(LetterEntry entry, ShadowCat cat) {
  final rng = Random(entry.id.hashCode);
  final opener = _catReplyOpeners[rng.nextInt(_catReplyOpeners.length)];
  final closer = _catReplyClosers[rng.nextInt(_catReplyClosers.length)];
  return '$opener\n\n'
      '${cat.comfortMessage}\n\n'
      '${cat.guidance}\n\n'
      '$closer\n\n'
      '- ${cat.nameKr} ${cat.emoji}';
}
