import 'package:flutter/material.dart';
import '../theme.dart';
import 'stars_background.dart';

/// 홈 대시보드에서 새로운 기능 화면으로 진입할 때 쓰는 공용 네비게이션 헬퍼.
/// 여러 화면(홈 탭, 감정기록 시트 등)에서 같은 톤의 전체화면 래퍼가 필요해
/// 공용 위젯 파일로 분리했습니다.
void pushFullScreen(BuildContext context, String title, Widget child) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => FeatureScaffold(title: title, child: child),
    ),
  );
}

/// 기존 탭들과 톤을 맞춘 배경과 뒤로가기 버튼을 제공하는 공용 화면 래퍼.
class FeatureScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const FeatureScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                      child: child,
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
