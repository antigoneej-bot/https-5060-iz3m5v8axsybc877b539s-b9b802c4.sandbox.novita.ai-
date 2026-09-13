import '../models/letter_tags.dart';

/// 선택한 감정을 돌아보는 질문. 전문 상담이나 진단이 아닙니다.
class LetterReplyInsight {
  final String stateDescription;
  final String solution;
  final String comfort;
  final String meditation;

  const LetterReplyInsight({
    required this.stateDescription,
    required this.solution,
    required this.comfort,
    required this.meditation,
  });
}

class LetterReplyInsightService {
  LetterReplyInsightService._();
  static const _questions = <EmotionTag, String>{
    EmotionTag.anxious: '지금 걱정하는 일 중 오늘 내가 할 수 있는 작은 일은 무엇일까요?',
    EmotionTag.lonely: '오늘 어떤 방식의 연결이나 혼자만의 시간이 필요했나요?',
    EmotionTag.angry: '오늘 내가 지키고 싶었던 경계나 소중한 것은 무엇이었나요?',
    EmotionTag.grateful: '오늘 고마웠던 장면을 하나 남겨볼까요?',
    EmotionTag.joyful: '오늘의 기쁨을 어떤 장면으로 기억하고 싶나요?',
    EmotionTag.sad: '지금 나에게 필요한 것은 휴식일까요, 말할 상대일까요, 다른 무엇일까요?',
    EmotionTag.regretful: '그때의 나에게 지금 건네고 싶은 말이 있나요?',
    EmotionTag.excited: '기다리는 일에서 가장 기대되는 부분은 무엇인가요?',
    EmotionTag.calm: '이 편안함 곁에 잠시 더 머물 수 있는 방법이 있을까요?',
    EmotionTag.weary: '오늘 덜어낼 수 있는 일 하나가 있나요?',
    EmotionTag.hopeful: '바라는 방향으로 아주 작게 해볼 수 있는 일이 있나요?',
  };
  static LetterReplyInsight build(EmotionTag emotion) {
    return LetterReplyInsight(
      stateDescription: _questions[emotion] ?? '오늘 내 마음에 남은 장면은 무엇인가요?',
      solution: '답이 떠오르면 한 줄 적어보세요. 떠오르지 않으면 지금은 쉬어도 좋아요.',
      comfort: '이 질문은 내 경험을 돌아보는 초대예요. 맞지 않는 설명에 나를 맞출 필요는 없어요.',
      meditation: '원한다면 편안한 자세로 주변을 둘러보거나 자연스럽게 숨을 쉬어보세요. 불편하면 멈춰도 괜찮아요.',
    );
  }
}
