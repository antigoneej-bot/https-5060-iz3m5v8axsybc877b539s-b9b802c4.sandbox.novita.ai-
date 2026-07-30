import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cat_care_provider.dart';
import '../providers/app_state_provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/graduation_celebration_overlay.dart';
import 'premium_screen.dart';

/// 졸업 앨범 - 성체까지 다 키워 졸업시킨 그림자 고양이들을 졸업일과 함께
/// 모아보는 화면. 42마리를 모두 졸업시키는 것이 궁극적인 목표입니다.
class GraduationAlbumScreen extends StatelessWidget {
  const GraduationAlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = context.watch<CatCareProvider>();
    final appState = context.watch<AppStateProvider>();
    final graduated = care.graduatedCats;
    // 무료 42마리를 모두 졸업시킨, 앱에 가장 깊이 몰입한 사용자입니다.
    // 아직 구독하지 않았다면 이 시점이 가장 자연스러운 업셀 타이밍입니다.
    final allFreeGraduated = graduated.length >= freeShadowCats.length;
    final showGraduationUpsell = allFreeGraduated && !appState.isPremiumUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassBlob(
          accent: AppColors.gold,
          background: const Color(0xFFFCEFD2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              const Text('🎓', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '졸업 앨범',
                      style: pathLabelFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      // ⚠️ 유료(Basic 구독) 10마리는 육성 대상에서 제외되어
                      // 있어 shadowCats.length(52)를 분모로 쓰면 영원히
                      // 채울 수 없는 목표가 됩니다. 무료 42마리 기준으로 표시합니다.
                      '${graduated.length} / ${freeShadowCats.length}마리 졸업 완료',
                      style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showGraduationUpsell) ...[
          const SizedBox(height: 14),
          const _GraduationCompleteUpsellCard(),
        ],
        const SizedBox(height: 18),
        if (graduated.isEmpty)
          GlassBlob(
            accent: AppColors.blobLavenderAccent,
            background: AppColors.blobLavender,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 10),
                Text(
                  '아직 졸업한 고양이가 없어요',
                  style: pathLabelFont(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '지금 키우는 고양이가 다 자라면\n첫 졸업생이 이곳에 남게 돼요',
                  textAlign: TextAlign.center,
                  style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          )
        else
          ...graduated.reversed.map((entry) {
            final (catId, date) = entry;
            ShadowCat cat;
            try {
              cat = shadowCatById(catId);
            } catch (_) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GraduateTile(cat: cat, graduatedAt: date),
            );
          }),
      ],
    );
  }
}

/// 무료 42마리를 모두 졸업시킨 사용자에게 보여주는 축하 + 구독 유도 카드.
/// 가장 몰입도 높은 순간(완주 시점)에 자연스럽게 업셀을 제안합니다.
class _GraduationCompleteUpsellCard extends StatelessWidget {
  const _GraduationCompleteUpsellCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.blobButterAccent.withValues(alpha: 0.85),
              AppColors.gold.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '42마리 완주를 축하해요!',
                    style: pathLabelFont(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '이제 냉소·시기·두려움 같은\n더 섬세한 10가지 감정을 만나볼 준비가 됐어요',
                    style: bodyFont(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _GraduateTile extends StatelessWidget {
  final ShadowCat cat;
  final DateTime graduatedAt;
  const _GraduateTile({required this.cat, required this.graduatedAt});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${graduatedAt.year}.${graduatedAt.month.toString().padLeft(2, '0')}.${graduatedAt.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blobButter.withValues(alpha: 0.75),
            AppColors.blobButter.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(
          color: AppColors.blobButterAccent.withValues(alpha: 0.3),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: AppColors.blobButterAccent.withValues(alpha: 0.4),
              ),
            ),
            padding: const EdgeInsets.all(5),
            child: ClipOval(
              child: Image.asset(cat.imageAsset, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.nameKr,
                  style: pathLabelFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr 졸업',
                  style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const Text('🎓', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

/// 새 아기고양이 고르기 - 성체가 된 고양이를 졸업시킨 뒤, 다음에 함께할
/// 그림자 고양이를 골라 새로운 육성을 시작하는 화면.
class NewBabyPickerScreen extends StatefulWidget {
  const NewBabyPickerScreen({super.key});

  @override
  State<NewBabyPickerScreen> createState() => _NewBabyPickerScreenState();
}

class _NewBabyPickerScreenState extends State<NewBabyPickerScreen> {
  ShadowCat? _selected;
  bool _celebrating = false;
  bool _busy = false;
  final TextEditingController _nameController = TextEditingController();
  String? _graduatedName;
  String? _graduatedImageAsset;
  String? _newBabyImageAsset;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _confirmGraduation() async {
    if (_selected == null || _busy) return;
    setState(() => _busy = true);
    final care = context.read<CatCareProvider>();
    ShadowCat? oldCat;
    try {
      oldCat = shadowCatById(care.state.companionCatId);
    } catch (_) {
      oldCat = null;
    }
    final oldName = care.displayName;
    final newCat = _selected!;
    await care.graduateAndStartNewBaby(newCat.id);
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      await StorageService.setCompanionName(newName);
      await care.load();
    }
    if (!mounted) return;
    setState(() {
      _graduatedName = oldName;
      _graduatedImageAsset = oldCat?.imageAsset ?? newCat.imageAsset;
      _newBabyImageAsset = 'assets/growth/baby_cat.png';
      _celebrating = true;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _selected == null ? _buildPickerGrid() : _buildConfirmStage(),
        if (_celebrating)
          GraduationCelebrationOverlay(
            graduatedName: _graduatedName ?? '',
            graduatedImageAsset: _graduatedImageAsset ?? '',
            newBabyImageAsset:
                _newBabyImageAsset ?? 'assets/growth/baby_cat.png',
            onDismiss: () {
              Navigator.of(context)
                ..pop()
                ..pop();
            },
          ),
      ],
    );
  }

  Widget _buildPickerGrid() {
    // 보류(reserved)된 캐릭터와 유료(Basic 구독) 캐릭터는 새로 입양할
    // 목록에서는 제외합니다. (유료 캐릭터의 잠금 미리보기/안내 플로우는
    // 감정체크 화면에만 적용되며, 이 화면에서는 결제 우회를 막기 위해
    // 아예 노출하지 않습니다)
    final selectableCats = shadowCats
        .where((c) => c.selectable && !c.isPremium)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '다음에 함께할 고양이를 골라주세요',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          '아기 고양이부터 다시 정성껏 키워보세요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selectableCats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final cat = selectableCats[index];
            return GestureDetector(
              onTap: () => setState(() => _selected = cat),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.7),
                      border: Border.all(
                        color: AppColors.blobLavenderAccent.withValues(
                          alpha: 0.35,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset(cat.imageAsset, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.nameKr,
                    textAlign: TextAlign.center,
                    style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildConfirmStage() {
    final cat = _selected!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassBlob(
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.85),
                  border: Border.all(color: AppColors.blobMintAccent, width: 2),
                ),
                padding: const EdgeInsets.all(8),
                child: ClipOval(
                  child: Image.asset(cat.imageAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                cat.nameKr,
                style: titleFont(fontSize: 18, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                cat.keyword,
                style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '아기고양이의 이름을 지어주세요 (선택)',
                  hintStyle: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: bodyFont(fontSize: 13, color: AppColors.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : _confirmGraduation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blobMintAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            child: Text(
              _busy ? '졸업 처리 중...' : '${cat.nameKr}와 새로 시작하기',
              style: pathLabelFont(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _selected = null),
          child: Text(
            '다시 고르기',
            style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
          ),
        ),
      ],
    );
  }
}
