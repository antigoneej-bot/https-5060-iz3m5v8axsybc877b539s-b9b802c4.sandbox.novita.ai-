import '../mongi/integration/unified_garden_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/garden_path_card.dart';

/// '나의 정원' - 지금까지 만난 그림자 고양이들을 한 화면에서 둘러볼 수 있는
/// 도감(컬렉션) 뷰.
///
/// 홈 화면 배경에 은은하게 떠다니는 정원 애니메이션과는 별개로, 사용자가
/// 직접 "정원에 들어가" 지금까지 함께한 고양이들을 한눈에 확인할 수 있는
/// 전용 진입점입니다. 아직 만나지 않은 고양이는 실루엣(그레이스케일)으로
/// 표시되어, 앞으로 채워나갈 자리라는 걸 은은하게 보여줍니다.
class MyGardenScreen extends StatelessWidget {
  final VoidCallback onGoMeetCat;
  final bool showMongiPanel;
  const MyGardenScreen({super.key, required this.onGoMeetCat, this.showMongiPanel = true});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    final metIds = app.metCatIds;
    final cats = shadowCats.where((cat) => !cat.isPremium || metIds.contains(cat.id)).toList();
    final metCount = cats.where((c) => metIds.contains(c.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMongiPanel) const UnifiedGardenPanel(),
        const SizedBox(height: 20),
        GlassBlob(
          accent: AppColors.blobMintAccent,
          background: AppColors.blobMint,
          floatSeed: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌷', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '함께한 고양이',
                      style: pathLabelFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '$metCount / ${cats.length}',
                    style: numberFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blobMintAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: cats.isEmpty ? 0 : metCount / cats.length,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.55),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.blobMintAccent,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                metCount == 0
                    ? '아직 정원에 아무도 없어요. 첫 고양이를 만나 정원을 채워보세요'
                    : '지금까지 만난 고양이들이 정원 곳곳에 자리를 잡았어요',
                style: bodyFont(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 18,
            childAspectRatio: 0.76,
          ),
          itemBuilder: (context, i) {
            final cat = cats[i];
            final met = metIds.contains(cat.id);
            return _GardenCatTile(
              cat: cat,
              met: met,
              meetingCount: met ? app.meetingCountFor(cat.id) : 0,
              onTap: () => _showCatSheet(context, cat, met),
            );
          },
        ),
        const SizedBox(height: 24),
        if (metCount < cats.length)
          Center(
            child: TextButton(
              onPressed: onGoMeetCat,
              child: Text(
                '오늘의 고양이 만나러 가기 →',
                style: pathLabelFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blobPeachAccent,
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _showCatSheet(BuildContext context, ShadowCat cat, bool met) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          _GardenCatSheet(cat: cat, met: met, onGoMeetCat: onGoMeetCat),
    );
  }
}

/// 정원 그리드 한 칸 - 만난 고양이는 이미지 + 포인트 컬러 테두리로,
/// 아직 만나지 않은 고양이는 그레이스케일 실루엣 + '???'로 표시합니다.
class _GardenCatTile extends StatelessWidget {
  final ShadowCat cat;
  final bool met;
  final int meetingCount;
  final VoidCallback onTap;
  const _GardenCatTile({
    required this.cat,
    required this.met,
    required this.meetingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = met
        ? CatPalette.accentFor(cat.id)
        : AppColors.inkSoft.withValues(alpha: 0.32);
    final bg = met
        ? CatPalette.backgroundFor(cat.id)
        : Colors.white.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: accent, width: met ? 2 : 1.2),
              boxShadow: met
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: ClipOval(
              child: met
                  ? Image.asset(
                      cat.imageAsset,
                      fit: BoxFit.cover,
                      cacheWidth: 130,
                      cacheHeight: 130,
                    )
                  : Opacity(
                      opacity: 0.45,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          0.33, 0.33, 0.33, 0, 0, //
                          0.33, 0.33, 0.33, 0, 0, //
                          0.33, 0.33, 0.33, 0, 0, //
                          0, 0, 0, 1, 0, //
                        ]),
                        child: Image.asset(
                          cat.imageAsset,
                          fit: BoxFit.cover,
                          cacheWidth: 130,
                          cacheHeight: 130,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            met ? cat.keyword : '???',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bodyFont(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: met ? AppColors.ink : AppColors.inkSoft,
            ),
          ),
          if (met && meetingCount > 1)
            Text(
              '$meetingCount번째 만남',
              style: bodyFont(fontSize: 9, color: AppColors.inkSoft),
            ),
        ],
      ),
    );
  }
}

/// 정원 칸을 탭했을 때 뜨는 작은 카드 - 만난 고양이는 이름/위로 메시지를,
/// 아직 만나지 않은 고양이는 "만나러 가기" CTA를 보여줍니다.
class _GardenCatSheet extends StatelessWidget {
  final ShadowCat cat;
  final bool met;
  final VoidCallback onGoMeetCat;
  const _GardenCatSheet({
    required this.cat,
    required this.met,
    required this.onGoMeetCat,
  });

  @override
  Widget build(BuildContext context) {
    final accent = met ? CatPalette.accentFor(cat.id) : AppColors.inkSoft;
    final bg = met ? CatPalette.backgroundFor(cat.id) : AppColors.bg2;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  child: Text(
                    met ? cat.emoji : '❓',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    met ? cat.nameKr : '아직 만나지 않은 고양이',
                    style: titleFont(fontSize: 18, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              met
                  ? cat.comfortMessage
                  : '이 고양이는 아직 정원에 나타나지 않았어요.\n오늘의 감정 체크에서 만나볼 수 있어요.',
              style: bodyFont(
                fontSize: 13,
                color: AppColors.inkSoft,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: met
                  ? OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(
                          color: accent.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '닫기',
                        style: pathLabelFont(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onGoMeetCat();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blobPeachAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '오늘의 고양이 만나러 가기',
                        style: pathLabelFont(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
