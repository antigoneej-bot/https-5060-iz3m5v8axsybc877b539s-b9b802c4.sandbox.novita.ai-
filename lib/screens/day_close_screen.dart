import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/promise_provider.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';

/// "하루 닫기" - 하루를 마무리하며 오늘 지킨 약속을 조용히 되돌아보는 화면.
/// 무료/프리미엄 여부와 무관하게 모든 사용자에게 같은 요약을 보여줍니다.
/// 지키지 못한 약속이 있어도 '실패'나 '미완료'라는 말은 쓰지 않고, 그저
/// 오늘 하루를 다정하게 닫아주는 톤을 유지합니다.
class DayCloseScreen extends StatefulWidget {
  const DayCloseScreen({super.key});

  @override
  State<DayCloseScreen> createState() => _DayCloseScreenState();
}

class _DayCloseScreenState extends State<DayCloseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PromiseProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final promise = context.watch<PromiseProvider>();

    if (promise.isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.blobMintAccent),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '오늘 하루를\n조용히 닫아볼까요?',
          textAlign: TextAlign.center,
          style: titleFont(fontSize: 22, color: AppColors.ink, height: 1.4),
        ),
        const SizedBox(height: 10),
        Text(
          '오늘 곁에 남긴 약속들을 살짝 들여다봐요',
          textAlign: TextAlign.center,
          style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 26),
        GlassBlob(
          accent: AppColors.blobLavenderAccent,
          background: AppColors.blobLavender,
          floatSeed: 21,
          child: Column(
            children: [
              const Text('🌙', style: TextStyle(fontSize: 26)),
              const SizedBox(height: 12),
              Text(
                promise.eveningSummary,
                textAlign: TextAlign.center,
                style: pathLabelFont(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '남은 약속들은 오늘 밤 조용히 곁을 떠나,\n내일 새로운 약속으로 다시 만나요',
                textAlign: TextAlign.center,
                style: bodyFont(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassBlob(
          accent: AppColors.blobPeachAccent,
          background: AppColors.blobPeach,
          floatSeed: 22,
          child: Row(
            children: [
              const Text('🐈‍⬛', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '고양이가 오늘도 당신 곁에서 웅크리고 하루를 함께 보냈어요',
                  style: bodyFont(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
