import 'package:flutter/material.dart';
import '../theme.dart';
import 'garden_path_card.dart';
import 'feature_scaffold.dart';

/// 카테고리 화면에 나열되는 하위 기능 하나를 표현합니다.
///
/// [onTap]에는 카테고리 목록 화면의 [BuildContext]가 넘어옵니다.
/// 탭 전환(하단 네비)처럼 목록 아래에 있는 셸을 바꾸려면, 먼저
/// `Navigator.pop(context)`로 이 목록을 닫은 뒤 탭을 바꿔야 합니다.
/// (목록을 닫지 않으면 화면이 그대로 보여 "안 들어간 것처럼" 보입니다.)
class CategoryItem {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final Color background;
  final void Function(BuildContext context) onTap;
  const CategoryItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.background,
    required this.onTap,
  });
}

/// 홈 화면에 흩어져 있던 여러 기능을 하나의 큰 카테고리로 묶어 보여주는
/// 공용 화면. 홈 화면에서 카테고리 카드를 누르면 이 화면으로 들어와,
/// 그 안에 속한 하위 기능들을 다시 정원 산책로 카드 형태로 나열합니다.
/// (기능이 많고 중복돼 보인다는 피드백을 반영해, 홈 화면의 진입점 수를
/// 줄이고 관련된 기능들을 한 곳에 모아두었습니다.)
class CategoryListScreen extends StatelessWidget {
  final String title;
  final String headerEmoji;
  final String headerSubtitle;
  final List<CategoryItem> items;
  const CategoryListScreen({
    super.key,
    required this.title,
    required this.headerEmoji,
    required this.headerSubtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(
            child: Text(headerEmoji, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 22, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            headerSubtitle,
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 26),
          for (int i = 0; i < items.length; i++) ...[
            GardenPathCard(
              emoji: items[i].emoji,
              title: items[i].title,
              subtitle: items[i].subtitle,
              accent: items[i].accent,
              background: items[i].background,
              alignX: i.isEven ? -0.06 : 0.06,
              widthFactor: 0.94,
              floatSeed: 60 + i,
              onTap: () => items[i].onTap(context),
            ),
            if (i != items.length - 1)
              GardenPathConnector(
                startX: i.isEven ? -0.06 : 0.06,
                endX: i.isOdd ? -0.06 : 0.06,
                decorEmoji: i.isEven ? '🐾' : '🦋',
              ),
          ],
        ],
      ),
    );
  }
}
