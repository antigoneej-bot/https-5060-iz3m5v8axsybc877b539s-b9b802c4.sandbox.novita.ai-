import 'package:flutter/material.dart';
import '../models/tree_growth.dart';

/// 몽이의 성장나무가 다음 단계로 자라날 때(새싹→나무→꽃→열매) 재생되는
/// 짧은 성장 전환 애니메이션. [SeedPlantingAnimation]과 같은 구조([_phase] 헬퍼로
/// 하나의 [AnimationController] 값을 여러 구간으로 나눠 쓰는 방식)를 그대로 따른다.
///
/// 연출 순서:
///  1) 이전 단계 나무가 잠시 흔들리며 반짝인다 (성장의 기운이 차오름)
///  2) 화면이 살짝 밝아지는 빛 번짐과 함께 이전 나무가 사라진다
///  3) 새 단계 나무가 elasticOut 커브로 통통 튀어오르며 나타난다
///  4) 주변에 반짝임이 흩날리며 마무리
class TreeGrowthAnimation extends StatefulWidget {
  /// 자라나기 전 단계 인덱스. null이면 "아직 씨앗도 심기 전" 상태에서 시작한다.
  final int? fromStageIndex;

  /// 자라난 뒤 도달한 단계 인덱스 (0=새싹 ... 3=열매).
  final int toStageIndex;

  final VoidCallback? onFinished;

  const TreeGrowthAnimation({
    super.key,
    required this.fromStageIndex,
    required this.toStageIndex,
    this.onFinished,
  });

  @override
  State<TreeGrowthAnimation> createState() => _TreeGrowthAnimationState();
}

class _TreeGrowthAnimationState extends State<TreeGrowthAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onFinished?.call();
        }
      });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double start, double end, double t) {
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    final fromAsset = widget.fromStageIndex != null
        ? TreeGrowth.stageAssets[widget.fromStageIndex!]
        : null;
    final toAsset = TreeGrowth.stageAssets[widget.toStageIndex];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        // 0.00~0.30: 이전 나무가 두근두근 커졌다 작아졌다 (기운이 차오름)
        final chargeT = _phase(0.0, 0.30, t);
        final chargeScale = 1.0 + 0.08 * (0.5 - (chargeT - 0.5).abs()) * 4;

        // 0.28~0.48: 빛이 화면을 확 밝히며 이전 나무가 사라짐
        final flashT = _phase(0.28, 0.48, t);
        final oldOpacity = (1 - flashT).clamp(0.0, 1.0);
        final flashOpacity = flashT < 1
            ? (flashT < 0.5 ? flashT / 0.5 : (1 - flashT) / 0.5)
            : 0.0;

        // 0.45~0.85: 새 나무가 elasticOut으로 통통 튀며 등장
        final growT = Curves.elasticOut.transform(_phase(0.45, 0.88, t));
        final showNew = t > 0.44;

        // 0.75~1.0: 반짝임이 주변에 흩날리며 마무리
        final sparkleT = _phase(0.78, 1.0, t);
        final sparkleOpacity = sparkleT < 1
            ? (sparkleT < 0.6 ? sparkleT / 0.6 : (1 - sparkleT) / 0.4)
            : 0.0;

        return SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 이전 단계 나무 (있으면) - 두근거리다가 빛과 함께 사라짐
              if (fromAsset != null && oldOpacity > 0)
                Opacity(
                  opacity: oldOpacity,
                  child: Transform.scale(
                    scale: chargeScale,
                    child: Image.asset(fromAsset, height: 150),
                  ),
                ),

              // 밝은 빛 번짐 효과
              if (flashOpacity > 0)
                Opacity(
                  opacity: flashOpacity.clamp(0.0, 1.0),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

              // 새 단계 나무 - 통통 튀어오르며 등장
              if (showNew)
                Transform.scale(
                  scale: growT.clamp(0.0, 1.25),
                  child: Image.asset(toAsset, height: 160),
                ),

              // 주변에 흩날리는 반짝임
              if (sparkleOpacity > 0) ...[
                Positioned(
                  top: 12,
                  left: 30,
                  child: Opacity(
                    opacity: sparkleOpacity.clamp(0.0, 1.0),
                    child: const Text('✨', style: TextStyle(fontSize: 20)),
                  ),
                ),
                Positioned(
                  top: 24,
                  right: 26,
                  child: Opacity(
                    opacity: sparkleOpacity.clamp(0.0, 1.0),
                    child: const Text('🌟', style: TextStyle(fontSize: 16)),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 40,
                  child: Opacity(
                    opacity: sparkleOpacity.clamp(0.0, 1.0),
                    child: const Text('✨', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
