import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme.dart';
import 'cat_selection_screen.dart';
import 'meditation_flow_screen.dart';

/// 고양이선택 탭 - 고양이를 고르고 나면 사연 → 편지 → 명상 → 온도체크 → 완료 흐름이
/// 같은 탭 안에서 이어집니다.
class CatFlowTabScreen extends StatelessWidget {
  const CatFlowTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    if (app.selectedCat == null) {
      return const CatSelectionScreen();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.read<AppStateProvider>().backToSelecting(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(
            Icons.arrow_back,
            size: 15,
            color: AppColors.inkSoft,
          ),
          label: Text(
            '다른 고양이 고르기',
            style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
          ),
        ),
        const SizedBox(height: 12),
        MeditationFlowScreen(key: ValueKey(app.selectedCat!.id)),
      ],
    );
  }
}
