import '../models/emotion.dart';
import '../services/emotion_evolution_service.dart';
import 'gen/app_localizations.dart';

/// [Emotion]/[EmotionEvolutionService]의 언어-중립(Kind) 데이터를 실제
/// 번역 문자열로 바꿔주는 UI 레이어 헬퍼. 모델/서비스 자체는 항상 한국어
/// 원본 문자열을 갖고 있지만(다른 미번역 로직에서 여전히 쓰일 수 있음),
/// 화면/게임 레이어는 [EmotionType]만 넘겨 이 헬퍼를 통해 언어별 문구를
/// 얻는다.
///
/// 감정 카드/몬스터/도감 등에서 공통으로 쓰이는 4가지 텍스트 - 라벨,
/// 몽이의 대사(catQuestion), 위로 메시지(healMessage), 도감 스토리
/// (storyText) - 를 각각 EmotionType 기준 switch로 매핑한다.
String emotionLabel(AppLocalizations l10n, EmotionType type) {
  switch (type) {
    case EmotionType.hate:
      return l10n.emotionLabelHate;
    case EmotionType.anger:
      return l10n.emotionLabelAnger;
    case EmotionType.worry:
      return l10n.emotionLabelWorry;
    case EmotionType.sadness:
      return l10n.emotionLabelSadness;
    case EmotionType.loneliness:
      return l10n.emotionLabelLoneliness;
    case EmotionType.anxiety:
      return l10n.emotionLabelAnxiety;
    case EmotionType.shame:
      return l10n.emotionLabelShame;
    case EmotionType.irritation:
      return l10n.emotionLabelIrritation;
    case EmotionType.grievance:
      return l10n.emotionLabelGrievance;
    case EmotionType.fear:
      return l10n.emotionLabelFear;
    case EmotionType.joy:
      return l10n.emotionLabelJoy;
    case EmotionType.gratitude:
      return l10n.emotionLabelGratitude;
    case EmotionType.excitement:
      return l10n.emotionLabelExcitement;
    case EmotionType.calm:
      return l10n.emotionLabelCalm;
    case EmotionType.confidence:
      return l10n.emotionLabelConfidence;
    case EmotionType.tired:
      return l10n.emotionLabelTired;
    case EmotionType.boredom:
      return l10n.emotionLabelBoredom;
    case EmotionType.courage:
      return l10n.emotionLabelCourage;
    case EmotionType.thrill:
      return l10n.emotionLabelThrill;
    case EmotionType.happiness:
      return l10n.emotionLabelHappiness;
  }
}

String emotionCatQuestion(AppLocalizations l10n, EmotionType type) {
  switch (type) {
    case EmotionType.hate:
      return l10n.emotionCatQuestionHate;
    case EmotionType.anger:
      return l10n.emotionCatQuestionAnger;
    case EmotionType.worry:
      return l10n.emotionCatQuestionWorry;
    case EmotionType.sadness:
      return l10n.emotionCatQuestionSadness;
    case EmotionType.loneliness:
      return l10n.emotionCatQuestionLoneliness;
    case EmotionType.anxiety:
      return l10n.emotionCatQuestionAnxiety;
    case EmotionType.shame:
      return l10n.emotionCatQuestionShame;
    case EmotionType.irritation:
      return l10n.emotionCatQuestionIrritation;
    case EmotionType.grievance:
      return l10n.emotionCatQuestionGrievance;
    case EmotionType.fear:
      return l10n.emotionCatQuestionFear;
    case EmotionType.joy:
      return l10n.emotionCatQuestionJoy;
    case EmotionType.gratitude:
      return l10n.emotionCatQuestionGratitude;
    case EmotionType.excitement:
      return l10n.emotionCatQuestionExcitement;
    case EmotionType.calm:
      return l10n.emotionCatQuestionCalm;
    case EmotionType.confidence:
      return l10n.emotionCatQuestionConfidence;
    case EmotionType.tired:
      return l10n.emotionCatQuestionTired;
    case EmotionType.boredom:
      return l10n.emotionCatQuestionBoredom;
    case EmotionType.courage:
      return l10n.emotionCatQuestionCourage;
    case EmotionType.thrill:
      return l10n.emotionCatQuestionThrill;
    case EmotionType.happiness:
      return l10n.emotionCatQuestionHappiness;
  }
}

String emotionHealMessage(AppLocalizations l10n, EmotionType type) {
  switch (type) {
    case EmotionType.hate:
      return l10n.emotionHealMessageHate;
    case EmotionType.anger:
      return l10n.emotionHealMessageAnger;
    case EmotionType.worry:
      return l10n.emotionHealMessageWorry;
    case EmotionType.sadness:
      return l10n.emotionHealMessageSadness;
    case EmotionType.loneliness:
      return l10n.emotionHealMessageLoneliness;
    case EmotionType.anxiety:
      return l10n.emotionHealMessageAnxiety;
    case EmotionType.shame:
      return l10n.emotionHealMessageShame;
    case EmotionType.irritation:
      return l10n.emotionHealMessageIrritation;
    case EmotionType.grievance:
      return l10n.emotionHealMessageGrievance;
    case EmotionType.fear:
      return l10n.emotionHealMessageFear;
    case EmotionType.joy:
      return l10n.emotionHealMessageJoy;
    case EmotionType.gratitude:
      return l10n.emotionHealMessageGratitude;
    case EmotionType.excitement:
      return l10n.emotionHealMessageExcitement;
    case EmotionType.calm:
      return l10n.emotionHealMessageCalm;
    case EmotionType.confidence:
      return l10n.emotionHealMessageConfidence;
    case EmotionType.tired:
      return l10n.emotionHealMessageTired;
    case EmotionType.boredom:
      return l10n.emotionHealMessageBoredom;
    case EmotionType.courage:
      return l10n.emotionHealMessageCourage;
    case EmotionType.thrill:
      return l10n.emotionHealMessageThrill;
    case EmotionType.happiness:
      return l10n.emotionHealMessageHappiness;
  }
}

String emotionStoryText(AppLocalizations l10n, EmotionType type) {
  switch (type) {
    case EmotionType.hate:
      return l10n.emotionStoryTextHate;
    case EmotionType.anger:
      return l10n.emotionStoryTextAnger;
    case EmotionType.worry:
      return l10n.emotionStoryTextWorry;
    case EmotionType.sadness:
      return l10n.emotionStoryTextSadness;
    case EmotionType.loneliness:
      return l10n.emotionStoryTextLoneliness;
    case EmotionType.anxiety:
      return l10n.emotionStoryTextAnxiety;
    case EmotionType.shame:
      return l10n.emotionStoryTextShame;
    case EmotionType.irritation:
      return l10n.emotionStoryTextIrritation;
    case EmotionType.grievance:
      return l10n.emotionStoryTextGrievance;
    case EmotionType.fear:
      return l10n.emotionStoryTextFear;
    case EmotionType.joy:
      return l10n.emotionStoryTextJoy;
    case EmotionType.gratitude:
      return l10n.emotionStoryTextGratitude;
    case EmotionType.excitement:
      return l10n.emotionStoryTextExcitement;
    case EmotionType.calm:
      return l10n.emotionStoryTextCalm;
    case EmotionType.confidence:
      return l10n.emotionStoryTextConfidence;
    case EmotionType.tired:
      return l10n.emotionStoryTextTired;
    case EmotionType.boredom:
      return l10n.emotionStoryTextBoredom;
    case EmotionType.courage:
      return l10n.emotionStoryTextCourage;
    case EmotionType.thrill:
      return l10n.emotionStoryTextThrill;
    case EmotionType.happiness:
      return l10n.emotionStoryTextHappiness;
  }
}

/// 진화 단계 이름 4개(기본형 → 1차 진화 → 2차 진화/마스터형 → 히든
/// 4단계/초월형)를 언어별로 반환한다. 항상 길이 4를 유지한다.
List<String> evolutionNamesFor(AppLocalizations l10n, EmotionType type) {
  switch (type) {
    case EmotionType.hate:
      return [
        l10n.evolutionNameHate0,
        l10n.evolutionNameHate1,
        l10n.evolutionNameHate2,
        l10n.evolutionNameHate3,
      ];
    case EmotionType.anger:
      return [
        l10n.evolutionNameAnger0,
        l10n.evolutionNameAnger1,
        l10n.evolutionNameAnger2,
        l10n.evolutionNameAnger3,
      ];
    case EmotionType.worry:
      return [
        l10n.evolutionNameWorry0,
        l10n.evolutionNameWorry1,
        l10n.evolutionNameWorry2,
        l10n.evolutionNameWorry3,
      ];
    case EmotionType.sadness:
      return [
        l10n.evolutionNameSadness0,
        l10n.evolutionNameSadness1,
        l10n.evolutionNameSadness2,
        l10n.evolutionNameSadness3,
      ];
    case EmotionType.loneliness:
      return [
        l10n.evolutionNameLoneliness0,
        l10n.evolutionNameLoneliness1,
        l10n.evolutionNameLoneliness2,
        l10n.evolutionNameLoneliness3,
      ];
    case EmotionType.anxiety:
      return [
        l10n.evolutionNameAnxiety0,
        l10n.evolutionNameAnxiety1,
        l10n.evolutionNameAnxiety2,
        l10n.evolutionNameAnxiety3,
      ];
    case EmotionType.shame:
      return [
        l10n.evolutionNameShame0,
        l10n.evolutionNameShame1,
        l10n.evolutionNameShame2,
        l10n.evolutionNameShame3,
      ];
    case EmotionType.irritation:
      return [
        l10n.evolutionNameIrritation0,
        l10n.evolutionNameIrritation1,
        l10n.evolutionNameIrritation2,
        l10n.evolutionNameIrritation3,
      ];
    case EmotionType.grievance:
      return [
        l10n.evolutionNameGrievance0,
        l10n.evolutionNameGrievance1,
        l10n.evolutionNameGrievance2,
        l10n.evolutionNameGrievance3,
      ];
    case EmotionType.fear:
      return [
        l10n.evolutionNameFear0,
        l10n.evolutionNameFear1,
        l10n.evolutionNameFear2,
        l10n.evolutionNameFear3,
      ];
    case EmotionType.joy:
      return [
        l10n.evolutionNameJoy0,
        l10n.evolutionNameJoy1,
        l10n.evolutionNameJoy2,
        l10n.evolutionNameJoy3,
      ];
    case EmotionType.gratitude:
      return [
        l10n.evolutionNameGratitude0,
        l10n.evolutionNameGratitude1,
        l10n.evolutionNameGratitude2,
        l10n.evolutionNameGratitude3,
      ];
    case EmotionType.excitement:
      return [
        l10n.evolutionNameExcitement0,
        l10n.evolutionNameExcitement1,
        l10n.evolutionNameExcitement2,
        l10n.evolutionNameExcitement3,
      ];
    case EmotionType.calm:
      return [
        l10n.evolutionNameCalm0,
        l10n.evolutionNameCalm1,
        l10n.evolutionNameCalm2,
        l10n.evolutionNameCalm3,
      ];
    case EmotionType.confidence:
      return [
        l10n.evolutionNameConfidence0,
        l10n.evolutionNameConfidence1,
        l10n.evolutionNameConfidence2,
        l10n.evolutionNameConfidence3,
      ];
    case EmotionType.tired:
      return [
        l10n.evolutionNameTired0,
        l10n.evolutionNameTired1,
        l10n.evolutionNameTired2,
        l10n.evolutionNameTired3,
      ];
    case EmotionType.boredom:
      return [
        l10n.evolutionNameBoredom0,
        l10n.evolutionNameBoredom1,
        l10n.evolutionNameBoredom2,
        l10n.evolutionNameBoredom3,
      ];
    case EmotionType.courage:
      return [
        l10n.evolutionNameCourage0,
        l10n.evolutionNameCourage1,
        l10n.evolutionNameCourage2,
        l10n.evolutionNameCourage3,
      ];
    case EmotionType.thrill:
      return [
        l10n.evolutionNameThrill0,
        l10n.evolutionNameThrill1,
        l10n.evolutionNameThrill2,
        l10n.evolutionNameThrill3,
      ];
    case EmotionType.happiness:
      return [
        l10n.evolutionNameHappiness0,
        l10n.evolutionNameHappiness1,
        l10n.evolutionNameHappiness2,
        l10n.evolutionNameHappiness3,
      ];
  }
}

/// 지금까지 마주한 횟수([count])로 진화 단계에 맞는 언어별 이름을 반환한다.
/// [EmotionEvolutionService.stageIndexForCount]로 인덱스를 계산한다.
String evolutionNameForCount(
  AppLocalizations l10n,
  EmotionType type,
  int count,
) {
  final names = evolutionNamesFor(l10n, type);
  return names[EmotionEvolutionService.stageIndexForCount(count)];
}

/// 진화가 더 남아있을 때, 다음 단계의 언어별 이름 (없으면 null).
/// stage < 2에서만 다음 이름을 반환한다(마스터 이상에서는 히든 단계
/// 이름을 미리 노출하지 않는다).
String? evolutionNextNameFor(
  AppLocalizations l10n,
  EmotionType type,
  int count,
) {
  final stage = EmotionEvolutionService.stageIndexForCount(count);
  if (stage >= 2) return null;
  final names = evolutionNamesFor(l10n, type);
  return names[stage + 1];
}

/// 몬스터(감정)를 먹는 순간 화면에 잠깐 떠오르는 한 줄(FloatingLabel용).
/// [GameNarrativeService.eatenLine]과 동일한 분기 기준(streak<=1)을 재사용해
/// 언어별 문구를 만든다.
String gameEatenLineText(
  AppLocalizations l10n,
  EmotionType type, {
  required int streak,
}) {
  final label = emotionLabel(l10n, type);
  if (streak <= 1) {
    return l10n.gameEatenLineSingle(label);
  }
  return l10n.gameEatenLineStreak(label, streak);
}

/// 긍정적인 감정을 몽이가 가슴으로 받아 안는 순간 화면에 잠깐 떠오르는
/// 한 줄(FloatingLabel용). [GameNarrativeService.receivedLine]과 동일한
/// 분기 기준을 재사용한다.
String gameReceivedLineText(
  AppLocalizations l10n,
  EmotionType type, {
  required int streak,
}) {
  final label = emotionLabel(l10n, type);
  if (streak <= 1) {
    return l10n.gameReceivedLineSingle(label);
  }
  return l10n.gameReceivedLineStreak(label, streak);
}
