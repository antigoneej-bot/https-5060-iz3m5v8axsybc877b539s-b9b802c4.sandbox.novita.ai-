import '../models/letter_tags.dart';

/// 52개 그림자 고양이(`shadow_cats_data.dart`)의 `id`를 편지 시스템의
/// 11종 [EmotionTag]로 매핑합니다.
///
/// 그림자 고양이는 52종으로 세분화되어 있지만, 편지 문장 데이터는 11개의
/// 상위 감정 축으로만 작성되어 있어(설계서 3장), 다대일 매핑이 필요합니다.
/// 이 매핑은 각 고양이의 `keyword`(한글 감정명)와 의미가 가장 가까운
/// [EmotionTag]를 고른 것으로, 정답이 하나만 있는 분류는 아닙니다 - 추후
/// 필요하면 이 맵만 수정하면 됩니다(문장 데이터/엔진 코드는 그대로 둬도 됨).
const Map<String, EmotionTag> catIdToEmotionTag = {
  'dreamy': EmotionTag.calm, // 몽상
  'sad': EmotionTag.sad, // 슬픔
  'jealous': EmotionTag.angry, // 질투
  'angry': EmotionTag.angry, // 분노
  'proud': EmotionTag.joyful, // 자신감
  'cautious': EmotionTag.anxious, // 경계심
  'weary': EmotionTag.weary, // 무기력
  'anxious': EmotionTag.anxious, // 불안
  'lonely': EmotionTag.lonely, // 외로움
  'confused': EmotionTag.anxious, // 혼란
  'nostalgic': EmotionTag.lonely, // 그리움
  'stubborn': EmotionTag.calm, // 고집
  'vulnerable': EmotionTag.sad, // 상처
  'indifferent': EmotionTag.calm, // 무심함
  'impatient': EmotionTag.anxious, // 조바심
  'needy': EmotionTag.lonely, // 애정결핍
  'mischievous': EmotionTag.joyful, // 장난기
  'selfCritical': EmotionTag.regretful, // 자책
  'grieving': EmotionTag.sad, // 애도
  'hesitant': EmotionTag.anxious, // 망설임
  'surprised': EmotionTag.excited, // 놀람
  'sleepy': EmotionTag.weary, // 피곤
  'sulky': EmotionTag.angry, // 삐짐
  'excluded': EmotionTag.lonely, // 소외감
  'joyful': EmotionTag.joyful, // 행복
  'affectionate': EmotionTag.grateful, // 다정함
  'focused': EmotionTag.calm, // 몰입
  'excited': EmotionTag.excited, // 신남
  'curious': EmotionTag.excited, // 호기심
  'comforted': EmotionTag.calm, // 포근함
  'playful': EmotionTag.joyful, // 놀이
  'enchanted': EmotionTag.calm, // 모르겠어
  'serene': EmotionTag.calm, // 평온
  'studious': EmotionTag.calm, // 탐구
  'protective': EmotionTag.calm, // 보호본능
  'content': EmotionTag.joyful, // 만족
  'ashamed': EmotionTag.regretful, // 수치심
  'wronged': EmotionTag.angry, // 억울함
  'hollow': EmotionTag.weary, // 허무함
  'grateful': EmotionTag.grateful, // 감사
  'courageous': EmotionTag.hopeful, // 용기
  'witty': EmotionTag.joyful, // 유머
  'cynical': EmotionTag.weary, // 냉소
  'envious': EmotionTag.angry, // 시기
  'hurtFeelings': EmotionTag.sad, // 서운함
  'inferior': EmotionTag.regretful, // 열등감
  'dread': EmotionTag.anxious, // 두려움
  'guilty': EmotionTag.regretful, // 죄책감
  'openHearted': EmotionTag.hopeful, // 취약함 인정
  'creative': EmotionTag.excited, // 창의성
  'leaderly': EmotionTag.hopeful, // 리더십
  'convicted': EmotionTag.hopeful, // 확신
};

/// 고양이 id로 [EmotionTag]를 조회합니다. 알 수 없는 id는 [EmotionTag.calm]
/// (가장 무난한 중립값)으로 처리합니다.
EmotionTag emotionTagForCatId(String catId) =>
    catIdToEmotionTag[catId] ?? EmotionTag.calm;
