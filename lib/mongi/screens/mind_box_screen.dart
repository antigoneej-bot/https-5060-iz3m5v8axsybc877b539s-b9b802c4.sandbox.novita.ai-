import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../l10n/mongi_costume_l10n.dart';
import '../models/mongi_costume.dart';
import '../providers/garden_provider.dart';
import '../services/gacha_service.dart';

/// "마음 상자" - 빛의 정수로 몽이에게 어울릴 작은 선물(코스튬)을 열어보는 화면.
///
/// B2(순차 보장형): 예전에는 확률형 보상 + 천장(pity) 시스템으로 동작했지만,
/// 이는 가변비율 강화(variable-ratio reward) - 슬롯머신이 쓰는 것과 같은
/// 중독 유발 기제 - 라는 문제가 있어 메커니즘 자체를 바꿨다. 지금은 열 때마다
/// 어떤 선물이 나올지 순서는 무작위지만, 반드시 아직 없는 새 선물만 확정
/// 지급된다(중복도 꽝도 없음). "무엇이 나올지 모르는" 오프닝의 재미는
/// 남기면서, 확률/도박 요소는 완전히 제거한 것이 핵심이다.
class MindBoxScreen extends StatefulWidget {
  const MindBoxScreen({super.key});

  @override
  State<MindBoxScreen> createState() => _MindBoxScreenState();
}

class _MindBoxScreenState extends State<MindBoxScreen> {
  bool _pulling = false;

  Color _rarityColor(CostumeRarity r) {
    switch (r) {
      case CostumeRarity.common:
        return const Color(0xFF9AA5B1);
      case CostumeRarity.rare:
        return const Color(0xFF4E8FE0);
      case CostumeRarity.epic:
        return const Color(0xFFA36BE0);
      case CostumeRarity.legendary:
        return const Color(0xFFE0A93A);
    }
  }

  List<Color> _rarityGradient(CostumeRarity r) {
    switch (r) {
      case CostumeRarity.common:
        return const [Color(0xFFF3F4F6), Color(0xFFE1E4E9)];
      case CostumeRarity.rare:
        return const [Color(0xFFE6F0FF), Color(0xFFBFDBFF)];
      case CostumeRarity.epic:
        return const [Color(0xFFF3E8FF), Color(0xFFDEC1FF)];
      case CostumeRarity.legendary:
        return const [Color(0xFFFFF3D0), Color(0xFFFFD97A)];
    }
  }

  Future<void> _pullOnce() async {
    if (_pulling) return;
    final garden = context.read<GardenProvider>();
    if (garden.hasCollectedAllCostumes) {
      _showAllCollected();
      return;
    }
    if (garden.lightEssence < GachaService.singlePullCost) {
      _showNotEnough();
      return;
    }
    setState(() => _pulling = true);
    final result = await garden.pullGachaOnce();
    setState(() => _pulling = false);
    if (result == null) {
      _showNotEnough();
      return;
    }
    if (!mounted) return;
    await _showResults([result]);
  }

  /// 편의 기능으로서 여러 개를 한 번에 연다(가격 할인 없음, 여러 번 여는
  /// 수고만 덜어줌). 남은 미보유 선물이 [GachaService.maxBulkOpenCount]보다
  /// 적으면 그만큼만 열린다.
  Future<void> _pullBulk() async {
    if (_pulling) return;
    final garden = context.read<GardenProvider>();
    if (garden.hasCollectedAllCostumes) {
      _showAllCollected();
      return;
    }
    final bulkCount = _bulkCount(garden);
    final cost = GachaService.singlePullCost * bulkCount;
    if (garden.lightEssence < cost) {
      _showNotEnough();
      return;
    }
    setState(() => _pulling = true);
    final results = await garden.pullGachaBulk(count: bulkCount);
    setState(() => _pulling = false);
    if (results == null) {
      _showNotEnough();
      return;
    }
    if (!mounted) return;
    await _showResults(results);
  }

  /// 지금 "묶음 열기" 버튼을 누르면 실제로 몇 개가 열리는지 - 남은 미보유
  /// 선물 수와 [GachaService.maxBulkOpenCount] 중 더 작은 값.
  int _bulkCount(GardenProvider garden) {
    return garden.remainingGachaCostumeCount.clamp(
      0,
      GachaService.maxBulkOpenCount,
    );
  }

  /// 이미 몽이의 모든 선물을 다 모았을 때 - 더 열 게 없다는 안내.
  void _showAllCollected() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.mindBoxAllCollectedSnackbar),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 빛의 정수가 부족해 뽑기를 못 했을 때 - 엔드리스 모드로 더 모아보라는 안내만 표시한다.
  Future<void> _showNotEnough() async {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.mindBoxNotEnoughEssenceSnackbar),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showResults(List<GachaPullResult> results) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GachaResultSheet(
        results: results,
        rarityColor: _rarityColor,
        rarityGradient: _rarityGradient,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF3D6), AppColors.bg0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, garden),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      _buildCollectionProgressCard(garden),
                      const SizedBox(height: 18),
                      _buildPullButtons(garden),
                      const SizedBox(height: 24),
                      _buildCollectionSection(garden),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.mindBoxHeaderTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  '${garden.lightEssence}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF8A6D1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 예전엔 "천장까지 N번 남음" 진행바였지만, 확률/천장 시스템 자체가
  /// 사라진 지금은 "도감을 몇 % 채웠는지" 수집 진행률로 대체했다.
  Widget _buildCollectionProgressCard(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final total = MongiCostume.gachaPool.length;
    final owned = total - garden.remainingGachaCostumeCount;
    final allCollected = garden.hasCollectedAllCostumes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            allCollected
                ? l10n.mindBoxAllCollectedTitle
                : l10n.mindBoxOpenHintTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: allCollected ? const Color(0xFFB1791F) : AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : owned / total,
              minHeight: 10,
              backgroundColor: const Color(0xFFF1E7D3),
              color: const Color(0xFFE0A93A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.mindBoxCollectionProgressLabel(
              owned,
              total,
              garden.gachaTotalPulls,
            ),
            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildPullButtons(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    final allCollected = garden.hasCollectedAllCostumes;
    final bulkCount = _bulkCount(garden);
    final oneCost = GachaService.singlePullCost;
    final bulkCost = GachaService.singlePullCost * bulkCount;
    final canOne = !allCollected && garden.lightEssence >= oneCost;
    // 묶음 열기는 남은 선물이 2개 이상일 때만 의미가 있다(1개면 1개 열기와 동일).
    final canBulk =
        !allCollected && bulkCount >= 2 && garden.lightEssence >= bulkCost;
    return Row(
      children: [
        Expanded(
          child: _pullButton(
            label: l10n.mindBoxOpenOneButton,
            cost: oneCost,
            enabled: canOne && !_pulling,
            onTap: _pullOnce,
            filled: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _pullButton(
            label: bulkCount >= 2
                ? l10n.mindBoxOpenBulkButtonCount(bulkCount)
                : l10n.mindBoxOpenBulkButtonGeneric,
            cost: bulkCost,
            enabled: canBulk && !_pulling,
            onTap: _pullBulk,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _pullButton({
    required String label,
    required int cost,
    required bool enabled,
    required VoidCallback onTap,
    required bool filled,
  }) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled
              ? AppColors.roseStrong
              : Colors.white.withValues(alpha: 0.9),
          foregroundColor: filled ? Colors.white : AppColors.ink,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: filled ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFE7DECF)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              '💡 $cost',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: filled
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionSection(GardenProvider garden) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            l10n.mindBoxCollectionSectionTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: MongiCostume.all.length,
          itemBuilder: (context, index) {
            final costume = MongiCostume.all[index];
            final owned = garden.hasCostume(costume);
            final equipped = garden.equippedCostumeId == costume.id;
            return _CostumeTile(
              costume: costume,
              owned: owned,
              equipped: equipped,
              color: _rarityColor(costume.rarity),
              l10n: l10n,
              onTap: owned
                  ? () {
                      garden.equipCostume(equipped ? null : costume.id);
                    }
                  : null,
            );
          },
        ),
      ],
    );
  }
}

class _CostumeTile extends StatelessWidget {
  final MongiCostume costume;
  final bool owned;
  final bool equipped;
  final Color color;
  final AppLocalizations l10n;
  final VoidCallback? onTap;

  const _CostumeTile({
    required this.costume,
    required this.owned,
    required this.equipped,
    required this.color,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: owned
              ? Colors.white.withValues(alpha: 0.9)
              : AppColors.catSageBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped
                ? AppColors.roseStrong
                : color.withValues(alpha: owned ? 0.5 : 0.2),
            width: equipped ? 2.4 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: owned ? 1.0 : 0.35,
              child: owned
                  ? Image.asset(
                      costume.imageAsset,
                      height: 40,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.checkroom,
                        size: 32,
                        color: Colors.grey,
                      ),
                    )
                  : ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0, //
                        0.2126, 0.7152, 0.0722, 0, 0, //
                        0.2126, 0.7152, 0.0722, 0, 0, //
                        0, 0, 0, 1, 0, //
                      ]),
                      child: Image.asset(
                        costume.imageAsset,
                        height: 40,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.checkroom,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              owned ? costumeName(l10n, costume) : '???',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: owned ? AppColors.ink : const Color(0xFFAAA096),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: owned ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                costumeRarityLabel(l10n, costume.rarity),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: owned ? color : const Color(0xFFAAA096),
                ),
              ),
            ),
            if (equipped) ...[
              const SizedBox(height: 3),
              Text(
                l10n.mindBoxEquippedBadge,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.roseStrong,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 상자를 연 결과를 보여주는 바텀시트. 1개를 열면 큰 카드 하나, 10개를
/// 열면 스크롤 가능한 그리드로 결과를 한눈에 보여준다. 가장 귀한(레전더리)
/// 선물이 나오면 다른 등급보다 화려한 색/문구로 강조된다.
class _GachaResultSheet extends StatefulWidget {
  final List<GachaPullResult> results;
  final Color Function(CostumeRarity) rarityColor;
  final List<Color> Function(CostumeRarity) rarityGradient;

  const _GachaResultSheet({
    required this.results,
    required this.rarityColor,
    required this.rarityGradient,
  });

  @override
  State<_GachaResultSheet> createState() => _GachaResultSheetState();
}

class _GachaResultSheetState extends State<_GachaResultSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSingle = widget.results.length == 1;
    final hasLegendary = widget.results.any(
      (r) => r.costume.rarity == CostumeRarity.legendary,
    );
    return DraggableScrollableSheet(
      initialChildSize: isSingle ? 0.55 : 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bg0,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                hasLegendary
                    ? l10n.mindBoxResultTitleLegendary
                    : l10n.mindBoxResultTitleNormal,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: hasLegendary ? const Color(0xFFB1791F) : AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isSingle
                    ? _buildSingleResult(widget.results.first, l10n)
                    : GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.78,
                            ),
                        itemCount: widget.results.length,
                        itemBuilder: (context, index) {
                          return _buildResultCard(
                            widget.results[index],
                            compact: true,
                            l10n: l10n,
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.roseStrong,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      l10n.mindBoxConfirmButton,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSingleResult(GachaPullResult result, AppLocalizations l10n) {
    return Center(
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        child: _buildResultCard(result, compact: false, l10n: l10n),
      ),
    );
  }

  Widget _buildResultCard(
    GachaPullResult result, {
    required bool compact,
    required AppLocalizations l10n,
  }) {
    final costume = result.costume;
    final color = widget.rarityColor(costume.rarity);
    final gradient = widget.rarityGradient(costume.rarity);
    final isLegendary = costume.rarity == CostumeRarity.legendary;

    return Container(
      width: compact ? null : 220,
      padding: EdgeInsets.all(compact ? 8 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(compact ? 16 : 26),
        border: Border.all(color: color, width: isLegendary ? 2.6 : 1.6),
        boxShadow: isLegendary
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            costume.imageAsset,
            height: compact ? 40 : 84,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.checkroom, size: compact ? 30 : 60, color: color),
          ),
          SizedBox(height: compact ? 6 : 14),
          Text(
            costumeName(l10n, costume),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 10.5 : 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 12,
              vertical: compact ? 2 : 5,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              costumeRarityLabel(l10n, costume.rarity),
              style: TextStyle(
                fontSize: compact ? 9 : 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              l10n.mindBoxNewItemLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ] else ...[
            const SizedBox(height: 2),
            const Text(
              'NEW',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppColors.roseStrong,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
