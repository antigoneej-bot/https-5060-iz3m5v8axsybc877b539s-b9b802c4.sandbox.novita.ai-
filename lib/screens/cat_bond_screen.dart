import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../providers/app_state_provider.dart';
import '../services/analytics_service.dart';
import '../services/compatibility_service.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/garden_path_card.dart';
import '../widgets/lively_cat_image.dart';
import '../widgets/stars_background.dart';
import '../widgets/share_reflection_card.dart';

/// "묘연(猫緣) 나누기" — 내가 최근에 만난 그림자 고양이의 코드를 친구에게
/// 보내고, 친구가 그 코드를 입력하면 두 그림자를 나란히 놓고 관찰하는
/// 화면입니다.
///
/// 리퍼럴 구조: 받는 사람이 반드시 "자기 코드를 입력"해야 결과가 완성되므로,
/// 단순 공유(일방향 감상)보다 실제 신규 사용자 유입 전환 가능성이 높습니다.
/// 서버·딥링크 없이 완전히 로컬 인코딩만으로 동작합니다.
class CatBondScreen extends StatefulWidget {
  const CatBondScreen({super.key});

  @override
  State<CatBondScreen> createState() => _CatBondScreenState();
}

class _CatBondScreenState extends State<CatBondScreen> {
  final _codeController = TextEditingController();
  String? _friendCatId;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _checkCode() {
    final catId = CompatibilityService.catIdForCode(_codeController.text);
    setState(() {
      if (catId == null) {
        _error = '코드를 다시 확인해주세요';
        _friendCatId = null;
      } else {
        _error = null;
        _friendCatId = catId;
      }
    });
    if (catId == null) {
      AnalyticsService().logEvent(AnalyticsEvents.bondCodeInvalid);
    } else {
      AnalyticsService().logEvent(AnalyticsEvents.bondCodeRedeemed, {
        'friend_cat_id': catId,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final myCatId = app.history.isNotEmpty ? app.history.first.catId : null;
    final myCode = myCatId != null
        ? CompatibilityService.codeForCat(myCatId)
        : null;

    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.ink,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '묘연 나누기',
                          style: titleFont(
                            fontSize: 19,
                            color: AppColors.titlePastelGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '내 그림자 고양이 코드를 친구에게 보내보세요.\n친구가 코드를 입력하면 두 그림자가 나란히 놓여요.',
                            textAlign: TextAlign.center,
                            style: bodyFont(
                              fontSize: 13,
                              color: AppColors.inkSoft,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 22),
                          if (myCatId != null && myCode != null)
                            _MyCodeCard(catId: myCatId, code: myCode)
                          else
                            _NoCatYet(),
                          const SizedBox(height: 26),
                          _FriendCodeInput(
                            controller: _codeController,
                            error: _error,
                            onCheck: _checkCode,
                          ),
                          if (_friendCatId != null && myCatId != null) ...[
                            const SizedBox(height: 26),
                            _BondResultCard(
                              myCatId: myCatId,
                              friendCatId: _friendCatId!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoCatYet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          const Text('🐾', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 12),
          Text(
            '아직 만난 고양이가 없어요',
            style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Text(
            '고양이를 먼저 만나면 내 코드가 만들어져요',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _MyCodeCard extends StatelessWidget {
  final String catId;
  final String code;
  const _MyCodeCard({required this.catId, required this.code});

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('코드를 복사했어요')));
  }

  /// 코드만 텍스트로 보내지 않고, 내 그림자 고양이 카드 이미지를 함께
  /// 캡처해서 보냅니다(받는 사람이 어떤 고양이인지 바로 볼 수 있도록).
  void _shareCode(BuildContext context) {
    final cat = shadowCatById(catId);
    showShareReflectionCard(
      context,
      cardContent: _MyCodeShareCardContent(catId: catId, code: code),
      shareText:
          '내 그림자 고양이는 \'${cat.nameKr}\'예요 🐾\n'
          '내 묘연 코드: $code\n\n'
          '"마음냥 정원" 앱에서 이 코드를 입력하고\n'
          '네 그림자와 나란히 놓아볼래? #마음냥정원',
    );
    AnalyticsService().logEvent(AnalyticsEvents.bondCodeGenerated, {
      'cat_id': catId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final cat = shadowCatById(catId);
    final accent = CatPalette.accentFor(catId);
    final background = CatPalette.backgroundFor(catId);
    return GlassBlob(
      accent: accent,
      background: background,
      floatSeed: 31,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Column(
        children: [
          Text(
            '내 그림자 고양이',
            style: pathLabelFont(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          LivelyCatImage(
            imageAsset: cat.imageAsset,
            width: 76,
            height: 76,
            borderRadius: BorderRadius.circular(18),
          ),
          const SizedBox(height: 10),
          Text(
            cat.nameKr,
            style: titleFont(fontSize: 17, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _copyCode(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: numberFont(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.copy_rounded, size: 14, color: accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '탭해서 코드 복사',
            style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          _RoundButton(
            icon: Icons.ios_share_rounded,
            label: '친구에게 코드 보내기',
            accent: accent,
            onTap: () => _shareCode(context),
          ),
        ],
      ),
    );
  }
}

/// 내 묘연 코드를 공유할 때 함께 캡처되는 카드(그림자 고양이 이미지 +
/// 이름 + 코드를 한 장에 담아, 받는 사람이 코드만이 아니라 내 고양이가
/// 어떤 모습인지도 바로 볼 수 있게 합니다).
class _MyCodeShareCardContent extends StatelessWidget {
  final String catId;
  final String code;
  const _MyCodeShareCardContent({required this.catId, required this.code});

  @override
  Widget build(BuildContext context) {
    final cat = shadowCatById(catId);
    final accent = CatPalette.accentFor(catId);
    final background = CatPalette.backgroundFor(catId);
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, background.withValues(alpha: 0.9)],
        ),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MIND CAT GARDEN',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 10,
              color: AppColors.titlePastelGreenSoft,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '내 그림자 고양이',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              cat.imageAsset,
              width: 140,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            cat.nameKr,
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 17, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: numberFont(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '이 코드를 입력하고\n내 그림자와 나란히 놓아보세요',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 11.5, color: accent, height: 1.5),
          ),
          const SizedBox(height: 14),
          Text(
            '🐈‍⬛  마음냥 정원',
            textAlign: TextAlign.center,
            style: brandFont(fontSize: 15, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: pathLabelFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onCheck;
  const _FriendCodeInput({
    required this.controller,
    required this.error,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobLavenderAccent,
      background: AppColors.blobLavender,
      floatSeed: 32,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '친구의 묘연 코드 입력하기',
            style: pathLabelFont(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: '예: M7K9',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: numberFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: 1.5,
                  ),
                  onSubmitted: (_) => onCheck(),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onCheck,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: AppColors.blobLavenderAccent,
                    ),
                    child: Text(
                      '확인',
                      style: pathLabelFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: bodyFont(fontSize: 11.5, color: AppColors.blobRoseAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _BondResultCard extends StatefulWidget {
  final String myCatId;
  final String friendCatId;
  const _BondResultCard({required this.myCatId, required this.friendCatId});

  @override
  State<_BondResultCard> createState() => _BondResultCardState();
}

class _BondResultCardState extends State<_BondResultCard> {
  late final String _sentence;

  @override
  void initState() {
    super.initState();
    _sentence = CompatibilityService.compatibilitySentence(
      myCatId: widget.myCatId,
      friendCatId: widget.friendCatId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final myCat = shadowCatById(widget.myCatId);
    final friendCat = shadowCatById(widget.friendCatId);
    return GlassBlob(
      accent: AppColors.blobPeachAccent,
      background: AppColors.blobPeach,
      floatSeed: 33,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      child: Column(
        children: [
          Text(
            '오늘의 묘연',
            style: pathLabelFont(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniCat(cat: myCat, label: '나'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('🐾', style: TextStyle(fontSize: 20)),
              ),
              _MiniCat(cat: friendCat, label: '친구'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _sentence,
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 15.5, color: AppColors.ink, height: 1.6),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              showShareReflectionCard(
                context,
                cardContent: _BondShareCardContent(
                  myCatId: widget.myCatId,
                  friendCatId: widget.friendCatId,
                  sentence: _sentence,
                ),
                shareText:
                    '오늘의 묘연: ${myCat.nameKr} × ${friendCat.nameKr} 🐾 #마음냥정원',
              );
            },
            icon: Icon(
              Icons.ios_share_rounded,
              size: 15,
              color: AppColors.blobPeachAccent,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blobPeachAccent,
              side: BorderSide(
                color: AppColors.blobPeachAccent.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            label: Text(
              '묘연 카드 공유하기',
              style: pathLabelFont(
                fontSize: 12.5,
                color: AppColors.blobPeachAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCat extends StatelessWidget {
  final dynamic cat;
  final String label;
  const _MiniCat({required this.cat, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LivelyCatImage(
          imageAsset: cat.imageAsset as String,
          width: 64,
          height: 64,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 6),
        Text(
          '$label · ${cat.nameKr}',
          style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

/// 묘연 결과를 공유 카드로 캡처할 때 쓰는 콘텐츠(300px 고정 폭 세로형).
class _BondShareCardContent extends StatelessWidget {
  final String myCatId;
  final String friendCatId;
  final String sentence;
  const _BondShareCardContent({
    required this.myCatId,
    required this.friendCatId,
    required this.sentence,
  });

  @override
  Widget build(BuildContext context) {
    final myCat = shadowCatById(myCatId);
    final friendCat = shadowCatById(friendCatId);
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8EE), Color(0xFFFBE3D9)],
        ),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MIND CAT GARDEN',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 10,
              color: AppColors.titlePastelGreenSoft,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '오늘의 묘연',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShareMiniCat(cat: myCat, label: '나'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('🐾', style: TextStyle(fontSize: 18)),
              ),
              _ShareMiniCat(cat: friendCat, label: '친구'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            sentence,
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 15, color: AppColors.ink, height: 1.6),
          ),
          const SizedBox(height: 16),
          Text(
            '🐈‍⬛  마음냥 정원',
            textAlign: TextAlign.center,
            style: brandFont(fontSize: 15, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _ShareMiniCat extends StatelessWidget {
  final dynamic cat;
  final String label;
  const _ShareMiniCat({required this.cat, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            cat.imageAsset as String,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$label · ${cat.nameKr}',
          style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
