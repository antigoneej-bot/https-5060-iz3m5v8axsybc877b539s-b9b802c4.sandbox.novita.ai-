import 'package:flutter/material.dart';

/// 마음 돌보기 탭 전용 마스코트 - 치즈태비 아기 고양이 "모찌".
///
/// ⚠️ 주의: 이 애셋(assets/mochi/*)은 마음 돌보기(Heart Care) 탭 히어로
/// 영역 전용입니다. 사용자가 키우는 42마리 그림자 고양이(AnimatedCatArt,
/// assets/cards36/*)와는 완전히 별개의 캐릭터이니 혼동하지 마세요.
///
/// [CatEmotion.happy]는 평소(오늘 이미 방문했거나 정상적으로 매일 오는 중)에
/// 보여주는 기본 감정입니다. [waiting]/[missing]/[worried]는 마지막 방문일로
/// 부터 며칠이 지났는지에 따라 순서대로 보여주는 "결석 감지" 감정입니다
/// ([CatEmotion.forDaysAway] 참고). 문구로 "왜 안 왔어요"를 설명하지 않고,
/// 오직 표정과 몸짓만으로 반가움/그리움을 전달하는 것이 원칙입니다.
/// (추후 호기심/잠자기/놀람/꾹꾹이 등은 애셋이 추가되면 enum 케이스만
/// 늘려서 확장할 수 있습니다.)
class MochiCat extends StatelessWidget {
  final double size;
  final bool static;
  final String? semanticLabel;
  final CatEmotion emotion;

  const MochiCat({
    super.key,
    this.size = 240,
    this.static = false,
    this.semanticLabel,
    this.emotion = CatEmotion.happy,
  });

  @override
  Widget build(BuildContext context) {
    final asset = static ? emotion.staticAsset : emotion.animatedAsset;
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel ?? emotion.label,
      gaplessPlayback: true,
      cacheWidth: (size * 2).round(),
      cacheHeight: (size * 2).round(),
    );
  }
}

enum CatEmotion {
  happy(
    animatedAsset: 'assets/mochi/mochi_happy_animated.webp',
    staticAsset: 'assets/mochi/mochi_happy_static.png',
    label: '해맑은 모찌',
  ),

  /// 하루 결석 - 문 쪽을 바라보며 조용히 기다리는 모습. 살짝 고개를
  /// 갸웃하며 몸을 좌우로 천천히 흔듭니다.
  waiting(
    animatedAsset: 'assets/mochi/mochi_waiting_animated.webp',
    staticAsset: 'assets/mochi/mochi_waiting_static.png',
    label: '기다리는 모찌',
  ),

  /// 3일 이상 결석 - 몸을 동그랗게 말고 꼬리를 끌어안은 채 그리워하는
  /// 모습. 아주 느리게 숨쉬듯 커졌다 작아집니다.
  missing(
    animatedAsset: 'assets/mochi/mochi_missing_animated.webp',
    staticAsset: 'assets/mochi/mochi_missing_static.png',
    label: '그리워하는 모찌',
  ),

  /// 7일 이상 결석 - 두 발을 모으고 걱정스러운 눈빛으로 미세하게
  /// 떨듯 움직이는 모습.
  worried(
    animatedAsset: 'assets/mochi/mochi_worried_animated.webp',
    staticAsset: 'assets/mochi/mochi_worried_static.png',
    label: '걱정하는 모찌',
  );
  // TODO: curious/sleeping/shocked/kneading 추후 추가

  const CatEmotion({
    required this.animatedAsset,
    required this.staticAsset,
    required this.label,
  });

  final String animatedAsset;
  final String staticAsset;
  final String label;

  /// 마지막 방문일로부터 지난 일수(결석일수)에 따라 어떤 감정을 보여줄지
  /// 결정합니다. 0~1일(정상 범위)은 [happy], 2~2일은 [waiting],
  /// 3~6일은 [missing], 7일 이상은 [worried]를 반환합니다.
  ///
  /// ⚠️ 참고: [StorageService.daysSinceLastVisit]는 streak 갱신
  /// ([StorageService.updateStreakOnOpen]) *이전에* 호출해야 정확한 값을
  /// 얻을 수 있습니다(streak 갱신 시 마지막 방문일이 오늘로 덮어써짐).
  static CatEmotion forDaysAway(int daysAway) {
    if (daysAway >= 7) return CatEmotion.worried;
    if (daysAway >= 3) return CatEmotion.missing;
    if (daysAway >= 2) return CatEmotion.waiting;
    return CatEmotion.happy;
  }
}
