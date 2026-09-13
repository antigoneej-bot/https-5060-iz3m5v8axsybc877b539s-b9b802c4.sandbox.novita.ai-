/// Authored finite content, not an automatic monthly-content promise.
class JourneyWeek {
  final String story;
  final String question;
  final String action;
  const JourneyWeek(this.story,this.question,this.action);
}
class SubscriberJourney {
  final String id;
  final String title;
  final List<JourneyWeek> weeks;
  const SubscriberJourney(this.id,this.title,this.weeks);
}
const subscriberJourneys = [
  SubscriberJourney('kindness','나에게 조금 다정해지기',[
    JourneyWeek('고양이가 작은 방석을 창가에 놓았어요. 아무것도 해내지 않아도 앉을 수 있는 자리래요.','오늘 나에게 조금 덜 엄격해져도 되는 일은 무엇인가요?','원한다면 쉬어 갈 자리에서 잠깐 앉아보세요.'),
    JourneyWeek('정원에는 빨리 자라는 풀도, 아직 흙 아래 있는 씨앗도 있어요. 고양이는 두 곳에 똑같이 물을 주었어요.','남과 비교하지 않고 인정하고 싶은 내 속도가 있나요?','작아도 내가 해낸 일 하나를 적어보세요.'),
    JourneyWeek('고양이가 울퉁불퉁한 돌을 벤치 옆에 놓았어요. 반듯하지 않아도 마음에 드는 모양이래요.','고치려 애쓰기 전에 받아들여도 되는 내 모습이 있나요?','오늘 나에게 해주고 싶은 말을 한 줄 남겨보세요.'),
    JourneyWeek('한 달의 편지를 상자에 모았어요. 고양이는 가장 긴 편지 대신 다시 읽고 싶은 편지부터 골랐어요.','이번 여정에서 다시 읽고 싶은 내 문장은 무엇인가요?','기록에서 편지 한 통을 다시 읽어보세요.'),
  ]),
  SubscriberJourney('boundaries','내 마음의 문 돌보기',[
    JourneyWeek('정원 문에 작은 손잡이가 생겼어요. 열어 둘 때와 닫아 둘 때를 정하는 건 정원의 주인이래요.','지금 나에게 필요한 거리는 어느 정도인가요?','오늘 선택할 수 있는 작은 거절이나 요청을 떠올려보세요.'),
    JourneyWeek('고양이는 방문객을 위해 의자를 놓고 자기 방석도 남겨뒀어요. 둘 다 놓을 자리가 있었어요.','다른 사람을 배려하면서 놓치고 있던 내 필요가 있나요?','원하는 것을 짧은 문장으로 적어보세요.'),
    JourneyWeek('바람이 강한 날에는 정원 문을 조금 닫았어요. 고양이는 바람이 잦아든 뒤 다시 열기로 했어요.','바로 답하지 않고 시간을 가져도 되는 일이 있나요?','가능하다면 답하기 전에 잠깐 쉬어보세요.'),
    JourneyWeek('문 옆에 작은 꽃이 피었어요. 고양이는 닫았던 날도 열었던 날도 정원을 돌본 날이라고 했어요.','이번 여정에서 나를 존중했던 순간을 하나 고른다면요?','내 선택을 평가하지 않고 한 줄 기록해보세요.'),
  ]),
  SubscriberJourney('small_joy','작은 기쁨 발견하기',[
    JourneyWeek('고양이가 창틀의 햇빛을 따라 움직였어요. 멀리 가지 않아도 밝은 자리가 있었어요.','오늘 잠깐 눈길이 머문 장면은 무엇인가요?','주변에서 마음에 드는 색 하나를 찾아보세요.'),
    JourneyWeek('정원 한쪽에서 이름 모를 풀을 발견했어요. 고양이는 이름을 알아내기 전에 모양부터 구경했어요.','잘하지 않아도 궁금한 일이 있나요?','가능하면 궁금했던 것을 잠깐 살펴보세요.'),
    JourneyWeek('고양이가 아끼던 리본을 우체통에 달았어요. 작은 장식 하나로 익숙한 길이 달라 보였어요.','내 하루에 더하고 싶은 작은 즐거움이 있나요?','부담 없이 할 수 있는 즐거운 일 하나를 골라보세요.'),
    JourneyWeek('고양이는 모아둔 잎과 돌을 늘어놓았어요. 대단한 것은 없어도 정원에서 보낸 시간이 담겨 있었어요.','다음 달에도 함께 가져가고 싶은 작은 기쁨은 무엇인가요?','기억하고 싶은 장면을 편지에 남겨보세요.'),
  ]),
];
