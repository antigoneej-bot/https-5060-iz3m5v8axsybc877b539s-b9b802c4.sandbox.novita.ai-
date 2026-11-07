import 'app_language.dart';

String gardenCopy(String key, List<Object?> args) {
  final pair = _copy[key]!;
  final text = pair[AppLanguage.instance.isEnglish ? 1 : 0];
  return text.replaceAllMapped(
    RegExp(r'\{(\d+)\}'),
    (m) => '${args[int.parse(m[1]!)]}',
  );
}

const _copy = <String, List<String>>{
  "garden90.0": ["누적 성장 {0}회 · {1}/{0}", "Growth goal: {0} · {1}/{0}"],
  "garden90.1": ["다음 땅까지 성장 {0}회", "Growth needed to unlock the next area: {0}"],
  "garden90.2": [
    "{0}에서 쉬어요. 고양이를 누르면 일어나요.",
    "Resting at {0}. Tap your cat to wake them.",
  ],
  "garden90.3": ["{0}에서 일어났어요.", "Finished resting at {0}."],
  "garden90.4": [
    "{0}에는 오늘 이미 물을 주었어요. 내일 다시 돌봐 주세요.",
    "{0} has already been watered today. You can water it again tomorrow.",
  ],
  "garden90.5": [
    "{0}에 물을 주었어요. 오늘의 돌봄을 기억할게요.",
    "Watered {0}. Today’s care is saved.",
  ],
  "garden90.6": ["{0}의 집", "{0}’s home"],
  "garden90.7": ["{0} · 옮길 잔디를 눌러 주세요.", "{0} · Tap the grass to choose a spot"],
  "garden90.8": [
    "씨앗을 심거나 가꾼 횟수 {0}회에 열려요",
    "Unlocks after {0} planting or care actions",
  ],
  "garden90.9": ["24시간 응원 {0}", "Encouragement · Lasts 24 hours: {0}"],
  "garden90.10": ["{0} {1}에서 일어나기", "Wake {0} from {1}"],
  "garden90.11": ["{0} 돌보기", "Care for {0}"],
  "garden90.12": ["함께 방문한 {0}", "Visiting companion: {0}"],
  "garden90.13": ["{0}, 정원 가족", "{0}, part of your garden family"],
  "deletePlantTitle": ["이 {0}를 삭제할까요?", "Delete this {0}?"],
  "deletePlantButton": ["{0} 삭제", "Delete {0}"],
  "careDone": [
    "{0}를 마쳤어요. 조금 더 자랐어요.",
    "Finished {0}. Your plant grew a little.",
  ],
  "plantMemories": ["{0} · 추억 관리", "{0} · Memories"],
  "anniversary": ["기념 시작일 · {0}", "Counting from · {0}"],
  "newMemory": ["새로운 추억 · {0}/{1}개", "New memory · {0}/{1}"],
  "memoryDay": ["추억의 날짜 · {0}", "Memory date · {0}"],
  "deletePlantBody": [
    "정원에서 이 {0}가 사라지고, 이름·기념일·추억·성장 단계와 돌봄 날짜가 함께 지워져요. 월간 기록집에 담은 이 {0}의 이름과 기념일도 지워져요.\n\n원본 편지와 다른 식물은 그대로 남아요. 사용한 씨앗은 반환되지 않으며, 다시 심으면 처음부터 자라요.",
    "This {0} will be removed from the garden, along with its name, anniversary, memories, growth and care dates. Its name and anniversary in monthly books will also be removed.\n\nOriginal letters and other plants stay unchanged. Seeds are not refunded. Replanting starts growth from the beginning.",
  ],
  "letterCount": ["편지 {0}개", "{0} letters"],
  "memoryCount": ["{0} · 추억 {1}개", "{0} · {1} memories"],
  "giftFrom": ["{0}님이 전한 마음", "A gift from {0}"],
  "giftDate": ["{0}\n{1}.{2}.{3}에 받은 선물", "{0}\nReceived {1}-{2}-{3}"],
  "plantedFlower": ["{0}\n{1} · 정원에 심은 꽃", "{0}\n{1} · Planted in garden"],
  "giftFlower": ["{0}\n{1} · 눌러서 선물 보기", "{0}\n{1} · Tap to view gift"],
  "flowerPending": ["\n연결되면 심기 기록을 확인해요", "\nReconnect to confirm planting"],
  "giftTransfer": [
    "{0} 한 송이가 내 보관함에서 이웃에게 옮겨져요.",
    "You'll send one {0} from your storage to your neighbor.",
  ],
  "deliveryCheck": [
    "{0} 전송 결과를 다시 확인할 수 있어요.",
    "{0} You can check whether it was delivered.",
  ],
  "neighborGarden": ["{0}의 정원", "{0}’s garden"],
  "guestSnapshot": [
    "{0}와 함께 방문 중 · 초대 당시의 고양이 모습이에요",
    "Visiting with {0} · Cat's appearance saved with the invitation",
  ],
  "flowerFrom": ["{0}님에게 받은 꽃", "A flower from {0}"],
};
