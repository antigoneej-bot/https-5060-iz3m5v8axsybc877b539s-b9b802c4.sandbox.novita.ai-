import '../models/letter_tags.dart';

/// Fictional garden scenes, chosen by the existing relationship stage.
/// No invented claims about the user's memories or mental state.
class RelationshipStoryService {
  RelationshipStoryService._();
  static const _scenes = <IntimacyTag, List<String>>{
    IntimacyTag.firstMeet: [
      '정원 입구에 작은 방석을 놓았어. 오늘은 여기서 천천히 인사하자.',
      '우체통 옆에 작은 꽃을 심었어. 네 편지가 머물 자리가 생겼네.',
      '처음 만난 날은 말이 짧아도 괜찮아. 나는 햇볕 드는 자리에 앉아 있을게.',
    ],
    IntimacyTag.shy: [
      '오늘은 방석을 한 뼘 가까이 옮겼어. 편한 만큼만 이야기해 줘.',
      '정원 길에 떨어진 잎을 주웠어. 편지 옆에 살짝 놓아둘게.',
      '우체통에 작은 리본을 달았어. 길을 걷다가 편할 때 들러 줘.',
    ],
    IntimacyTag.friend: [
      '우리 정원에 벤치가 생겼어. 오늘은 나란히 앉아 바람을 구경하자.',
      '벤치 아래에 동그란 돌을 모았어. 모양이 달라도 함께 놓으니 예쁘네.',
      '오늘은 정원 지도를 그려봤어. 아직 빈 곳은 천천히 채워 가자.',
    ],
    IntimacyTag.family: [
      '벤치 곁에 작은 지붕을 만들었어. 비가 오는 날에도 쉬어 갈 수 있게.',
      '정원 지도에 쉬어 가는 곳을 하나 더 그렸어. 서둘러 도착할 필요는 없어.',
      '오늘은 우체통을 닦았어. 길게 쓰든 한 줄을 쓰든 편히 놓고 가도 돼.',
    ],
    IntimacyTag.lifelongFriend: [
      '정원 지도를 접어 우체통에 넣었어. 처음의 작은 방석도 여전히 그 자리에 있어.',
      '새 씨앗을 심을 자리를 남겨뒀어. 오래된 정원에도 새로운 이야기는 자라니까.',
      '오늘은 아무것도 만들지 않고 벤치에서 쉬었어. 우리 정원에는 그런 날도 있어.',
    ],
  };
  static String lineFor(IntimacyTag stage, DateTime date) {
    final scenes = _scenes[stage]!;
    final day = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2020)).inDays;
    return scenes[day % scenes.length];
  }
}
