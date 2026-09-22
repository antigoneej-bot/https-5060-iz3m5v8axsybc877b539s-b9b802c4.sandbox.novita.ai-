// Authored acceptance-mode reply pack (mind_cat_acceptance_replies_72).
// Source: tool/acceptance_reply_content.json — 24 categories x 3 complete replies (72 total).
// Each reply is a finished, complete text. Never split into parts or recombine with
// sentences from another category/mode. 'receive' = short validation (default).
// 'reflect_optional' = gentle, optional invitation to reflect further (used sparingly).
class AcceptanceReply {
  final String id;
  final String mode;
  final String text;
  const AcceptanceReply(this.id, this.mode, this.text);
}

class AcceptanceCategory {
  final String id;
  final String category;
  final List<AcceptanceReply> replies;
  const AcceptanceCategory(this.id, this.category, this.replies);
  List<AcceptanceReply> get receive =>
      replies.where((r) => r.mode == 'receive').toList();
  List<AcceptanceReply> get reflectOptional =>
      replies.where((r) => r.mode == 'reflect_optional').toList();
}

const acceptanceReplyContent = <String, AcceptanceCategory>{
  "01": AcceptanceCategory(
    "01",
    "화남과 짜증",
    [
      AcceptanceReply("accept_01_01", "receive", "떠올릴수록 화가 나는구나. 여기 적는 동안은 말을 예쁘게 다듬지 않아도 돼. 네가 남긴 이야기를 읽고 있어."),
      AcceptanceReply("accept_01_02", "receive", "오늘은 화난 마음을 가지고 왔구나. 지금 마음을 서둘러 다른 기분으로 바꾸려 하지 않을게. 나는 네 옆에 앉아 있을게."),
      AcceptanceReply("accept_01_03", "reflect_optional", "화가 난다는 네 말을 읽었어. 어떤 말이나 장면이 특히 마음에 남았는지, 더 적고 싶을 때 이어서 들려줘."),
    ],
  ),
  "02": AcceptanceCategory(
    "02",
    "서운함",
    [
      AcceptanceReply("accept_02_01", "receive", "서운한 마음이 남았구나. 상대가 어떤 뜻이었는지와 별개로, 네가 그렇게 느꼈다는 이야기를 들었어. 나는 그 말을 가볍게 넘기지 않을게."),
      AcceptanceReply("accept_02_02", "receive", "그 순간이 서운하게 남아 있네. 지금은 상대를 이해하는 말까지 덧붙이지 않아도 돼. 네 쪽의 이야기도 여기 놓아둘 수 있어."),
      AcceptanceReply("accept_02_03", "reflect_optional", "서운했던 순간을 적어주었구나. 그때 어떤 반응을 바랐는지 궁금해진다면, 네 마음부터 천천히 살펴봐도 좋아."),
    ],
  ),
  "03": AcceptanceCategory(
    "03",
    "슬픔",
    [
      AcceptanceReply("accept_03_01", "receive", "오늘은 슬픈 마음이 있구나. 내 앞에서는 밝은 이야기를 골라서 할 필요 없어. 말이 짧아져도 듣고 있을게."),
      AcceptanceReply("accept_03_02", "receive", "슬프다는 네 말을 받았어. 이 편지를 좋은 결말로 끝내려고 애쓰지 않아도 돼. 오늘의 마음은 오늘 적은 모습으로 남겨둘게."),
      AcceptanceReply("accept_03_03", "reflect_optional", "슬픔을 글로 남겨주었네. 그 마음이 찾아온 순간을 더 적고 싶다면 이어 써도 좋아. 여기서 멈춰도 괜찮고."),
    ],
  ),
  "04": AcceptanceCategory(
    "04",
    "외로움",
    [
      AcceptanceReply("accept_04_01", "receive", "오늘은 외로웠구나. 그 마음을 여기 적어주었네. 나는 네 이야기를 읽으며 잠깐 곁에 머물게."),
      AcceptanceReply("accept_04_02", "receive", "외롭다는 말을 꺼내주었구나. 혼자서도 잘 지내야 한다는 말로 답하지 않을게. 지금 네 마음을 들었어."),
      AcceptanceReply("accept_04_03", "reflect_optional", "외로운 마음이 남아 있구나. 어떤 순간에 더 또렷해졌는지 돌아보고 싶다면, 그 장면 하나만 남겨도 좋아."),
    ],
  ),
  "05": AcceptanceCategory(
    "05",
    "걱정과 불안",
    [
      AcceptanceReply("accept_05_01", "receive", "앞으로의 일이 걱정되는구나. 내가 괜찮을 거라고 단정할 수는 없지만, 지금 불안하다는 네 말은 들었어. 이 편지에서 결론을 내릴 필요는 없어."),
      AcceptanceReply("accept_05_02", "receive", "오늘은 불안한 마음을 가지고 왔네. 불안이 금방 사라지지 않더라도 네 기록이 잘못된 건 아니야. 지금 적은 마음부터 받아둘게."),
      AcceptanceReply("accept_05_03", "reflect_optional", "걱정이 마음에 걸려 있구나. 적어보고 싶다면 지금 알고 있는 일과 아직 모르는 일을 나누어볼 수도 있어. 답을 정하는 건 그다음이어도 돼."),
    ],
  ),
  "06": AcceptanceCategory(
    "06",
    "질투와 부러움",
    [
      AcceptanceReply("accept_06_01", "receive", "부럽고 질투도 나는구나. 그런 마음을 적었다고 너라는 사람 전체가 정해지는 건 아니야. 나는 그 감정 하나로 너를 판단하지 않을게."),
      AcceptanceReply("accept_06_02", "receive", "누군가를 보며 부러운 마음이 올라왔구나. 축하하는 말만 해야 할 것 같은 날에도, 네 일기에는 다른 마음을 남길 수 있어."),
      AcceptanceReply("accept_06_03", "reflect_optional", "질투와 부러움을 알아차렸네. 무엇이 특히 부러웠는지는 네가 궁금해질 때 들여다봐도 좋아. 지금은 마음의 이름만 적어두어도 돼."),
    ],
  ),
  "07": AcceptanceCategory(
    "07",
    "미움",
    [
      AcceptanceReply("accept_07_01", "receive", "지금은 그 사람이 밉구나. 여기 적을 때 마음에 없는 좋은 말을 붙이지 않아도 돼. 그 사람과 어떻게 지낼지는 네가 정할 일이야."),
      AcceptanceReply("accept_07_02", "receive", "미운 마음이 있다는 이야기를 들었어. 억지로 용서하라는 말은 하지 않을게. 오늘은 네가 느낀 것을 적어둔 거니까."),
      AcceptanceReply("accept_07_03", "reflect_optional", "그 사람을 향한 미움이 있구나. 어떤 일이 그 마음과 함께 떠오르는지 더 적고 싶다면 들려줘. 무엇을 할지는 따로 생각해도 돼."),
    ],
  ),
  "08": AcceptanceCategory(
    "08",
    "후회와 미안함",
    [
      AcceptanceReply("accept_08_01", "receive", "아까의 일이 후회되고 미안하구나. 이 편지만으로 누가 얼마나 잘못했는지 정하지 않을게. 지금 네 마음에 남은 이야기를 들었어."),
      AcceptanceReply("accept_08_02", "receive", "돌아보니 마음에 걸리는 일이 있구나. 미안함을 느끼는 너와 그때 했던 행동을 한꺼번에 평가하지는 않을게. 네가 적어준 만큼 읽고 있어."),
      AcceptanceReply("accept_08_03", "reflect_optional", "미안한 마음이 남았네. 무엇이 아쉬웠고 어떤 부분을 바꾸고 싶은지는, 네가 준비됐을 때 나누어 살펴봐도 좋아."),
    ],
  ),
  "09": AcceptanceCategory(
    "09",
    "자책과 자기실망",
    [
      AcceptanceReply("accept_09_01", "receive", "오늘 네 모습이 마음에 들지 않았구나. 그 아쉬움은 들었어. 오늘의 한 장면으로 네 전부를 정하지는 않을게."),
      AcceptanceReply("accept_09_02", "receive", "자신에게 실망한 마음을 남겼구나. 내가 섣불리 잘했다고 덮어주지는 않을게. 그렇다고 너를 나쁜 사람이라고 부르지도 않을 거야."),
      AcceptanceReply("accept_09_03", "reflect_optional", "실수한 장면이 마음에 남았구나. 있었던 일과 그 일로 자신에게 붙인 말을 나누어보고 싶다면, 한 줄씩 적어봐도 좋아."),
    ],
  ),
  "10": AcceptanceCategory(
    "10",
    "창피함",
    [
      AcceptanceReply("accept_10_01", "receive", "그 순간이 창피하게 남았구나. 남들은 신경 쓰지 않을 거라고 대신 판단하지 않을게. 네가 민망했던 마음을 들었어."),
      AcceptanceReply("accept_10_02", "receive", "떠올리면 민망한 일이 있었구나. 지금 당장 웃어넘길 이야기가 되지 않아도 돼. 여기서는 네가 느낀 대로 적을 수 있어."),
      AcceptanceReply("accept_10_03", "reflect_optional", "민망한 장면이 떠오르는구나. 실제로 있었던 일과 다른 사람이 어떻게 봤을까 하는 생각을 구분해보고 싶다면, 천천히 적어도 좋아."),
    ],
  ),
  "11": AcceptanceCategory(
    "11",
    "지침",
    [
      AcceptanceReply("accept_11_01", "receive", "오늘은 많이 지쳤구나. 이 편지까지 잘 써내려고 힘주지 않아도 돼. 짧게 남긴 마음도 읽었어."),
      AcceptanceReply("accept_11_02", "receive", "지쳤다는 네 이야기를 들었어. 오늘 더 해내야 할 일을 내가 보태지는 않을게. 여기서는 한 줄만 남겨도 돼."),
      AcceptanceReply("accept_11_03", "reflect_optional", "지친 마음으로 왔구나. 몸이 피곤한지, 마음에 걸린 일이 많은지 살펴보고 싶다면 구분해 적을 수도 있어. 꼭 나눠야 하는 건 아니고."),
    ],
  ),
  "12": AcceptanceCategory(
    "12",
    "의욕 없음",
    [
      AcceptanceReply("accept_12_01", "receive", "오늘은 하고 싶은 마음이 잘 나지 않는구나. 내가 게으르다는 이름을 붙이지는 않을게. 지금 네 상태를 적어주었네."),
      AcceptanceReply("accept_12_02", "receive", "마음이 움직이지 않는 날이구나. 이 편지 끝에 다짐을 하나 더 세우지 않아도 돼. 오늘의 기록은 여기까지여도 충분해."),
      AcceptanceReply("accept_12_03", "reflect_optional", "의욕이 나지 않는다는 말을 읽었어. 하기 싫은 건지, 하고 싶지만 힘이 없는 건지 궁금해진다면 살펴봐도 좋아. 둘 다일 수도 있고."),
    ],
  ),
  "13": AcceptanceCategory(
    "13",
    "감정이 모호함",
    [
      AcceptanceReply("accept_13_01", "receive", "오늘은 어떤 마음인지 잘 모르겠구나. 꼭 이름을 붙여야 기록할 수 있는 건 아니야. 모르겠다는 오늘의 말도 받아둘게."),
      AcceptanceReply("accept_13_02", "receive", "마음이 선명하게 잡히지 않는 날이네. 내가 대신 감정의 이름을 정하지 않을게. 네가 적어준 만큼 곁에서 읽고 있어."),
      AcceptanceReply("accept_13_03", "reflect_optional", "어떤 기분인지 아직 모르겠구나. 오늘 기억나는 장면부터 적어보는 방법도 있어. 감정의 이름은 나중에 붙여도 되고, 그대로 두어도 돼."),
    ],
  ),
  "14": AcceptanceCategory(
    "14",
    "평범한 하루",
    [
      AcceptanceReply("accept_14_01", "receive", "오늘은 별일 없이 지나갔구나. 특별한 사건이 없어도 네 하루를 남길 수 있어. 짧은 소식 잘 받았어."),
      AcceptanceReply("accept_14_02", "receive", "평범한 하루였다는 이야기를 들었어. 여기서 굳이 감동적인 의미를 찾아내지는 않을게. 오늘은 그런 하루로 기록해두자."),
      AcceptanceReply("accept_14_03", "reflect_optional", "큰일 없이 지나간 날이네. 떠올리고 싶은 작은 장면이 있다면 하나 남겨도 좋아. 딱히 없다면 더 채우지 않아도 돼."),
    ],
  ),
  "15": AcceptanceCategory(
    "15",
    "기쁨",
    [
      AcceptanceReply("accept_15_01", "receive", "오늘은 기쁜 마음으로 왔구나. 네 이야기를 읽으며 나도 꼬리를 살짝 흔들었어. 그 기쁨을 다른 감정으로 설명하지 않고 들어줄게."),
      AcceptanceReply("accept_15_02", "receive", "기쁜 일이 있는 오늘이네. 그 마음을 작게 줄여서 말하지 않아도 돼. 더 자랑하고 싶다면 나는 귀를 기울일게."),
      AcceptanceReply("accept_15_03", "reflect_optional", "오늘 기뻤다는 말을 받았어. 마음에 남겨두고 싶은 순간이 있다면 조금 더 적어도 좋아. 지금 이만큼 전해줘도 좋고."),
    ],
  ),
  "16": AcceptanceCategory(
    "16",
    "성취와 뿌듯함",
    [
      AcceptanceReply("accept_16_01", "receive", "일을 끝내서 뿌듯하구나. 오늘 해낸 이야기를 들었어. 다음 목표를 재촉하지 않고 지금의 뿌듯함을 함께 바라볼게."),
      AcceptanceReply("accept_16_02", "receive", "해낸 일이 마음에 남았구나. 여기 적어둔 오늘의 한 장면을 나도 읽었어. 다른 사람의 결과와 비교하는 말은 붙이지 않을게."),
      AcceptanceReply("accept_16_03", "reflect_optional", "일을 마친 뒤 뿌듯했구나. 결과뿐 아니라 네가 마음에 들었던 과정도 있다면 남겨봐도 좋아. 무엇을 기억할지는 네가 골라줘."),
    ],
  ),
  "17": AcceptanceCategory(
    "17",
    "감사",
    [
      AcceptanceReply("accept_17_01", "receive", "오늘은 고마운 마음이 드는구나. 그 마음을 편지에 담아주었네. 나도 가만히 읽으며 곁에 있을게."),
      AcceptanceReply("accept_17_02", "receive", "네가 느낀 고마움을 읽었어. 거기에 다른 교훈을 덧붙이지 않고 받아둘게. 오늘 네 마음에 있던 이야기니까."),
      AcceptanceReply("accept_17_03", "reflect_optional", "감사한 마음이 남았구나. 어떤 말이나 순간이 떠오르는지 더 적고 싶다면 들려줘. 길게 설명할 필요는 없어."),
    ],
  ),
  "18": AcceptanceCategory(
    "18",
    "무사한 하루와 사람들에 대한 감사",
    [
      AcceptanceReply("accept_18_01", "receive", "오늘을 무사히 보낸 것과 함께한 사람들에게 고마운 마음이 들었구나. 하루 끝에 그 마음이 남아 있네. 네가 적어준 오늘의 이야기를 잘 받았어."),
      AcceptanceReply("accept_18_02", "receive", "하루를 무사히 보내고 함께한 사람들을 떠올렸구나. 그들에게 고맙다는 네 말을 읽었어. 오늘의 편지에는 그런 마음이 담겨 있네."),
      AcceptanceReply("accept_18_03", "reflect_optional", "무사히 보낸 하루와 함께한 사람들이 마음에 남았구나. 그중 기억해두고 싶은 순간이 있다면 더 적어도 좋아. 네가 고른 만큼만 들려줘."),
    ],
  ),
  "19": AcceptanceCategory(
    "19",
    "안도",
    [
      AcceptanceReply("accept_19_01", "receive", "이제 조금 안심이 되는구나. 마음이 놓인다는 네 말을 받았어. 언제까지 이 기분이 이어져야 한다고 정하지 않아도 돼."),
      AcceptanceReply("accept_19_02", "receive", "한숨 돌리는 마음으로 왔네. 지금 느끼는 안도감을 네 말로 남겨주었구나. 나도 옆에서 조용히 쉬고 있을게."),
      AcceptanceReply("accept_19_03", "reflect_optional", "마음이 조금 놓였구나. 무엇이 달라졌을 때 그렇게 느꼈는지 기억하고 싶다면 적어봐도 좋아. 지금은 안심된다는 한마디만 남겨도 되고."),
    ],
  ),
  "20": AcceptanceCategory(
    "20",
    "애정과 그리움",
    [
      AcceptanceReply("accept_20_01", "receive", "소중한 사람이 보고 싶구나. 네가 느끼는 그리움을 읽었어. 상대의 마음을 대신 짐작하지 않고 네 이야기에 머물게."),
      AcceptanceReply("accept_20_02", "receive", "누군가를 아끼는 마음이 담긴 편지네. 그 마음이 지금 네게 있다는 이야기를 받았어. 무엇을 해야 한다는 말을 덧붙이지 않을게."),
      AcceptanceReply("accept_20_03", "reflect_optional", "보고 싶은 사람이 있구나. 떠올리고 싶은 모습이나 말이 있다면 남겨도 좋아. 연락할지 말지는 네가 선택할 일이야."),
    ],
  ),
  "21": AcceptanceCategory(
    "21",
    "기쁨과 불안이 함께 있음",
    [
      AcceptanceReply("accept_21_01", "receive", "기쁨과 불안이 함께 있구나. 한쪽이 다른 쪽을 지워야 하는 건 아니야. 오늘은 두 마음이 함께 담긴 편지로 받아둘게."),
      AcceptanceReply("accept_21_02", "receive", "기쁘면서도 마음 한편이 불안하네. 어느 쪽만 진짜 마음이라고 고르지 않아도 돼. 나는 둘 다 네 이야기로 읽고 있어."),
      AcceptanceReply("accept_21_03", "reflect_optional", "좋은 마음과 불안이 나란히 있구나. 각각 어떤 장면과 이어지는지 궁금하다면 따로 적어봐도 좋아. 답을 하나로 모을 필요는 없어."),
    ],
  ),
  "22": AcceptanceCategory(
    "22",
    "여러 감정이 뒤섞임",
    [
      AcceptanceReply("accept_22_01", "receive", "여러 마음이 뒤섞여 있구나. 한 가지 감정으로 정리하지 않은 채 남겨도 돼. 네 편지를 서둘러 결론짓지 않을게."),
      AcceptanceReply("accept_22_02", "receive", "오늘 마음이 복잡하다는 말을 들었어. 앞에서 쓴 말과 뒤에서 쓴 말이 달라도, 지금은 함께 적어둘 수 있어. 나는 천천히 읽을게."),
      AcceptanceReply("accept_22_03", "reflect_optional", "한마디로 표현하기 어려운 마음이네. 이름 붙일 수 있는 감정만 하나씩 적어봐도 좋아. 아직 모르는 부분은 빈자리로 두고."),
    ],
  ),
  "23": AcceptanceCategory(
    "23",
    "들어주기만 원함",
    [
      AcceptanceReply("accept_23_01", "receive", "오늘은 들어주는 누군가가 필요하구나. 네가 남긴 말을 읽었어. 무엇을 해야 한다는 말 없이 여기 있을게."),
      AcceptanceReply("accept_23_02", "receive", "그냥 들어달라는 네 부탁을 받았어. 더 설명해달라고 묻지 않을게. 적어준 이야기에 조용히 머물고 있어."),
      AcceptanceReply("accept_23_03", "receive", "오늘 편지는 고치거나 평가하지 않고 읽을게. 답을 보태기보다 잠깐 곁에 앉아 있을게. 네 이야기를 받았어."),
    ],
  ),
  "24": AcceptanceCategory(
    "24",
    "내용을 확신하기 어려움",
    [
      AcceptanceReply("accept_24_01", "receive", "오늘의 이야기를 남겨주었네. 이 글만으로 네 마음을 다 안다고 말하지 않을게. 네가 적어준 말부터 읽고 있어."),
      AcceptanceReply("accept_24_02", "receive", "편지 잘 받았어. 내가 알 수 없는 부분에 이야기를 보태지는 않을게. 지금 남긴 그대로 여기 두어도 돼."),
      AcceptanceReply("accept_24_03", "receive", "네가 남긴 글을 읽었어. 더 적고 싶은 부분이 있다면 네 속도로 이어가도 좋아. 여기서 마쳐도 괜찮아."),
    ],
  ),
};
