import 'package:flutter/material.dart';
import '../data/cat_emotion_tone.dart';
import '../models/letter_entry.dart';
import '../models/shadow_bubble.dart';
import '../services/bubble_garden_service.dart';
import '../services/bubble_memo_service.dart';
import '../services/buried_emotion_service.dart';
import '../services/sound_service.dart';

/// locked: 오늘의 감정체크(편지쓰기)를 아직 하지 않아 방울이 생기지 않은 상태
/// ready: 방울밭이 준비되어 하나씩 터뜨릴 수 있는 상태
/// allPopped: 오늘의 방울을 모두 터뜨리거나 묻어주어 의식을 마친 상태
enum BubbleGardenStage { locked, ready, allPopped }

/// '오늘의 그림자 방울 터뜨리기' 화면의 상태를 관리하는 Provider.
///
/// 이 기능은 오락이 아니라 "오늘 기록한 감정을 해소하는 의식"이라는 컨셉을
/// 지키기 위해, 랭킹·타이머·성공/실패 같은 경쟁 요소를 전혀 갖지 않습니다.
///
/// v2부터는 오늘 생성된 방울 중 감정 강도가 가장 높았던 것 1개에 한해,
/// 터뜨리는 대신 '묻어두기'(그림자 작업의 핵심 - 억압된 감정은 나중에
/// 다시 떠오른다)를 선택할 수 있습니다. 강제가 아니며, 하루 최대 1개까지만
/// 묻을 수 있습니다(누적 방지). 다른 방울들을 모두 터뜨린 뒤에야 그
/// 마지막 방울에 한해 묻어두기 선택지가 조용히 나타납니다.
class BubbleGardenProvider extends ChangeNotifier {
  BubbleGardenStage stage = BubbleGardenStage.locked;
  bool isLoading = true;
  List<ShadowBubble> bubbles = [];

  /// 오늘 이 화면에서 새로 얻은 포인트(누적 포인트가 아니라, 이번에 이
  /// 세션에서 얻은 만큼만 - 완료 축하 문구에 사용).
  int pointsEarnedThisSession = 0;

  /// 방금 터뜨린 방울에 어울리는 그림자 고양이의 한마디. 팝업으로 잠깐
  /// 보여준 뒤 [clearReaction]으로 비웁니다.
  String? reactionCatId;
  String? reactionLine;

  /// 오늘 생성된 방울 중 감정 강도가 가장 높았던 방울의 index. 방울이
  /// 없거나 판별할 수 없다면 null.
  int? heaviestBubbleIndex;

  /// 오늘 이미 다른 방울을 하나 묻어두었는지(하루 최대 1개 제한).
  bool alreadyBuriedToday = false;

  /// 방금 묻은 방울에 어울리는 안내 문구(연출용, 짧게 보여준 뒤 비웁니다).
  bool showBuryReflection = false;

  /// 오늘 방울을 모두 놓아준 뒤, 그림자 고양이가 과거에 남긴 한마디를
  /// 회상하며 건네는 대사(있다면). 팝업이 아니라 완료 화면의 대사창에
  /// 조용히 노출되며, [clearRecalledMemo]로 비웁니다.
  String? recalledMemoCatId;
  String? recalledMemoLine;

  void clearReaction() {
    reactionCatId = null;
    reactionLine = null;
  }

  void clearRecalledMemo() {
    recalledMemoCatId = null;
    recalledMemoLine = null;
  }

  /// 오늘 방울밭에 등장한 감정(catId)들을 훑어, 낮은 확률로 과거의 한마디를
  /// 회상합니다. 완료 시점(모든 방울을 터뜨리거나 묻었을 때) 딱 한 번만
  /// 시도됩니다.
  Future<void> _tryRecallPastMemo() async {
    final todaysCatIds = bubbles.map((b) => b.catId).toList();
    final memo = BubbleMemoService.maybeRecallOnCompletion(todaysCatIds);
    if (memo == null) return;
    await BubbleMemoService.markRecalled(memo.id);
    recalledMemoCatId = memo.catId;
    recalledMemoLine = BubbleMemoService.buildRecallLine(memo.message);
  }

  void clearBuryReflection() {
    showBuryReflection = false;
    notifyListeners();
  }

  bool _isHandled(ShadowBubble b) => b.popped || b.buried;

  /// 감정 강도가 가장 높은 방울의 index를 찾습니다. 부정적이면서 고강도인
  /// 감정을 최우선으로 보고, 그런 방울이 없다면 고강도(중립/긍정 포함)
  /// 감정 중 가장 먼저 나온 것을 고릅니다. 판별 대상이 없으면 null.
  int? _findHeaviestIndex(List<ShadowBubble> list) {
    int? bestIndex;
    int bestWeight = -1;
    for (final b in list) {
      if (b.catId.isEmpty) continue;
      final tone = emotionToneFor(b.catId);
      final intensity = emotionIntensityFor(b.catId);
      int weight;
      if (tone == EmotionTone.negative && intensity == EmotionIntensity.high) {
        weight = 3;
      } else if (tone == EmotionTone.negative) {
        weight = 2;
      } else if (intensity == EmotionIntensity.high) {
        weight = 1;
      } else {
        weight = 0;
      }
      if (weight > bestWeight) {
        bestWeight = weight;
        bestIndex = b.index;
      }
    }
    // 아무 감정도 뚜렷하게 무겁지 않다면(모두 weight 0) 묻어두기를 굳이
    // 권할 필요는 없으므로 null로 둡니다.
    return bestWeight > 0 ? bestIndex : null;
  }

  /// 오늘 마주한 감정(들)을 바탕으로 방울밭을 준비합니다.
  /// [todaysLetters]가 비어 있다면(=오늘 감정체크를 아직 하지 않았다면)
  /// 방울은 생기지 않고 [BubbleGardenStage.locked] 상태로 남습니다.
  Future<void> load(List<LetterEntry> todaysLetters) async {
    isLoading = true;
    // 회상 대사는 "이번 세션에서 방금 완료했을 때"만 보여주는 연출이므로,
    // 화면을 새로 열 때마다(=예전 회상이 남아있지 않도록) 비워둡니다.
    recalledMemoCatId = null;
    recalledMemoLine = null;
    notifyListeners();

    if (todaysLetters.isEmpty) {
      stage = BubbleGardenStage.locked;
      bubbles = [];
      heaviestBubbleIndex = null;
      isLoading = false;
      notifyListeners();
      return;
    }

    final catIds = await BubbleGardenService.ensureSessionToday(todaysLetters);
    final poppedIndices = await BubbleGardenService.getPoppedIndicesToday();
    alreadyBuriedToday = BuriedEmotionService.hasBuriedToday();

    bubbles = List.generate(
      catIds.length,
      (i) => ShadowBubble(
        index: i,
        catId: catIds[i],
        popped: poppedIndices.contains(i),
      ),
    );
    heaviestBubbleIndex = alreadyBuriedToday
        ? null
        : _findHeaviestIndex(bubbles);
    stage = bubbles.every(_isHandled)
        ? BubbleGardenStage.allPopped
        : BubbleGardenStage.ready;
    isLoading = false;
    notifyListeners();
  }

  /// 방울 하나를 터뜨립니다. 이미 터뜨렸거나 묻은 방울이면 아무 변화가 없습니다.
  /// [reactionLineFor]로 그 방울(고양이)에 어울리는 한마디를 함께 넘겨주면
  /// 팝업으로 보여줄 수 있습니다.
  Future<void> popBubble(int index, {String? reactionLineFor}) async {
    final target = bubbles.firstWhere(
      (b) => b.index == index,
      orElse: () => ShadowBubble(index: index, catId: ''),
    );
    if (_isHandled(target)) return;

    final (_, isNew) = await BubbleGardenService.popBubble(index);
    if (!isNew) return;

    bubbles = bubbles
        .map((b) => b.index == index ? b.copyWith(popped: true) : b)
        .toList();
    pointsEarnedThisSession += BubbleGardenService.pointsPerBubble;
    reactionCatId = target.catId;
    reactionLine = reactionLineFor;
    await SoundService().playBubblePop();

    if (bubbles.isNotEmpty && bubbles.every(_isHandled)) {
      stage = BubbleGardenStage.allPopped;
      await SoundService().playGardenComplete();
      await _tryRecallPastMemo();
    }
    notifyListeners();
  }

  /// 방울을 터뜨리며(또는 터뜨린 직후) 그 감정 고양이에게 남기는 아주 짧은
  /// 한마디(선택, 20~50자 권장)를 저장합니다. 정식 편지 기능과는 별도의
  /// "짧은 메모" 데이터로 저장되며, 팝핑 자체의 성공/실패와는 무관하게
  /// 독립적으로 호출할 수 있습니다. 빈 문자열이면 아무 일도 하지 않습니다.
  Future<void> leaveBubbleMemo({
    required String catId,
    required String message,
  }) async {
    if (catId.isEmpty || message.trim().isEmpty) return;
    await BubbleMemoService.saveMemo(catId: catId, message: message);
  }

  /// 지금 딱 하나(가장 무거웠던 감정)만 남았고, 나머지는 모두 터뜨렸는지.
  /// 이 조건에서만 '묻어두기' 선택지를 화면에 조용히 보여줍니다.
  bool get canOfferBury {
    if (heaviestBubbleIndex == null || alreadyBuriedToday) return false;
    final target = bubbles.firstWhere(
      (b) => b.index == heaviestBubbleIndex,
      orElse: () => const ShadowBubble(index: -1, catId: ''),
    );
    if (target.index == -1 || _isHandled(target)) return false;
    final others = bubbles.where((b) => b.index != heaviestBubbleIndex);
    return others.every(_isHandled);
  }

  /// 가장 무거웠던 방울을 터뜨리지 않고 땅에 묻습니다. 오늘 이미 하나를
  /// 묻었다면(또는 대상이 없다면) false를 반환하고 아무 일도 하지 않습니다.
  Future<bool> buryHeaviestBubble({required String letterSnippet}) async {
    final index = heaviestBubbleIndex;
    if (index == null || alreadyBuriedToday) return false;
    final target = bubbles.firstWhere(
      (b) => b.index == index,
      orElse: () => const ShadowBubble(index: -1, catId: ''),
    );
    if (target.index == -1 || _isHandled(target)) return false;

    final ok = await BuriedEmotionService.buryEmotion(
      catId: target.catId,
      letterSnippet: letterSnippet,
    );
    if (!ok) return false;

    bubbles = bubbles
        .map((b) => b.index == index ? b.copyWith(buried: true) : b)
        .toList();
    alreadyBuriedToday = true;
    showBuryReflection = true;
    await SoundService().playChime();

    if (bubbles.isNotEmpty && bubbles.every(_isHandled)) {
      stage = BubbleGardenStage.allPopped;
      await SoundService().playGardenComplete();
      await _tryRecallPastMemo();
    }
    notifyListeners();
    return true;
  }
}
