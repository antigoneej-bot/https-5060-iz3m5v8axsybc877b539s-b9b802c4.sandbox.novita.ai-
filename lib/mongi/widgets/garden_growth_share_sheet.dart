import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/tree_growth_l10n.dart';
import '../models/tree_growth.dart';

/// "정원 공유 카드" - 몽이의 성장나무가 자라난 순간(또는 지금까지의 정원 상태)을
/// 예쁜 카드 이미지로 만들어 SNS/카톡으로 공유할 수 있는 바텀시트.
///
/// [EmotionShareSheet]와 같은 구조([RepaintBoundary] 캡처 -> [SharePlus])를 따르되,
/// 여기서는 프리미엄 프레임 같은 결제 요소 없이 순수하게 "자랑하고 싶은 순간"을
/// 부담 없이 바로 공유할 수 있도록 단순하게 구성한다.
/// (무한의 계단의 "기록 자랑" + Finch의 "감성 공유"를 결합한 아이디어)
class GardenGrowthShareSheet extends StatefulWidget {
  /// 지금 나무의 성장 단계 인덱스 (-1=아직 씨앗, 0=새싹...3=열매).
  final int stageIndex;

  /// 지금까지 쌓인 누적 점수.
  final int score;

  /// 연속으로 정원을 찾아온 일수.
  final int streakDays;

  /// 지금까지 정원에 심어진 꽃의 총 개수.
  final int totalFlowersPlanted;

  const GardenGrowthShareSheet({
    super.key,
    required this.stageIndex,
    required this.score,
    required this.streakDays,
    required this.totalFlowersPlanted,
  });

  /// 바텀시트 형태로 정원 공유 카드를 보여준다.
  static Future<void> show(
    BuildContext context, {
    required int stageIndex,
    required int score,
    required int streakDays,
    required int totalFlowersPlanted,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GardenGrowthShareSheet(
        stageIndex: stageIndex,
        score: score,
        streakDays: streakDays,
        totalFlowersPlanted: totalFlowersPlanted,
      ),
    );
  }

  @override
  State<GardenGrowthShareSheet> createState() => _GardenGrowthShareSheetState();
}

class _GardenGrowthShareSheetState extends State<GardenGrowthShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sharing = true);
    try {
      // 바텀시트 오픈 애니메이션 직후 캡처 시 빈 이미지가 되는 것을 방지.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError(l10n.shareCardNotFoundError);
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError(l10n.shareImageConvertError);
      }
      final bytes = byteData.buffer.asUint8List();
      final label = treeStageLabel(
        l10n,
        TreeGrowth.stageIndexForScore(widget.score),
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              name: 'mongi_growth_card.png',
              mimeType: 'image/png',
            ),
          ],
          text: l10n.gardenShareShareText(label),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('garden share error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.shareErrorSnackbar)));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final dateLabel =
        '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.gardenShareSheetTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.gardenShareSheetSubtitle,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            RepaintBoundary(key: _cardKey, child: _buildCard(l10n, dateLabel)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.ios_share),
                label: Text(
                  _sharing
                      ? l10n.gardenShareCardMakingButton
                      : l10n.gardenShareCardButton,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8A54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(AppLocalizations l10n, String dateLabel) {
    final hasTree = widget.stageIndex >= 0;
    final label = treeStageLabel(
      l10n,
      TreeGrowth.stageIndexForScore(widget.score),
    );
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6FA868), Color(0xFFBFE0A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('🐱', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                l10n.gardenShareCardName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                dateLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: hasTree
                ? Image.asset(
                    TreeGrowth.stageAssets[widget.stageIndex],
                    height: 96,
                  )
                : const Text('🕳️', style: TextStyle(fontSize: 60)),
          ),
          const SizedBox(height: 14),
          Text(
            hasTree
                ? l10n.gardenShareCardGrownLabel(label)
                : l10n.gardenShareCardNotGrownLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _cardStat(
                '🔥',
                l10n.gardenShareCardStreakStat(widget.streakDays),
                l10n.gardenShareCardStreakLabel,
              ),
              _cardStat(
                '🌷',
                l10n.gardenShareCardFlowersStat(widget.totalFlowersPlanted),
                l10n.gardenShareCardFlowersLabel,
              ),
              _cardStat(
                '✨',
                l10n.gardenShareCardScoreStat(widget.score),
                l10n.gardenShareCardScoreLabel,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.gardenShareCardFooter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
