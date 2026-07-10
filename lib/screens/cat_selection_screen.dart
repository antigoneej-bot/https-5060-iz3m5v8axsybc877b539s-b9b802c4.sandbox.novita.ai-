import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';

/// 36마리 그림자 감정 고양이 카드 그리드에서 지금 내 기분과 닮은
/// 고양이 한 마리를 골라 선택하는 화면.
class CatSelectionScreen extends StatelessWidget {
  const CatSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '지금 내 기분과 가장 닮은\n고양이를 골라보세요',
          textAlign: TextAlign.center,
          style: serifFont(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '36마리의 그림자 감정 고양이 카드 중\n마음에 닿는 카드를 골라보세요',
          textAlign: TextAlign.center,
          style: bodyFont(
            fontSize: 12.5,
            color: AppColors.inkSoft,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shadowCats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, index) {
            final cat = shadowCats[index];
            return _CatCard(
              cat: cat,
              onTap: () => context.read<AppStateProvider>().selectCat(cat),
            );
          },
        ),
      ],
    );
  }
}

class _CatCard extends StatelessWidget {
  final ShadowCat cat;
  final VoidCallback onTap;
  const _CatCard({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    cat.imageAsset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(cat.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                cat.nameKr,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyFont(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
