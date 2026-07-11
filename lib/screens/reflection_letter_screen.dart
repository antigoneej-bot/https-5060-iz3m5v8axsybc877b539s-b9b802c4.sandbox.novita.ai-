import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../data/shadow_cats_data.dart';
import '../services/reflection_service.dart';
import '../services/storage_service.dart';
import '../models/reflection_letter_entry.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import '../widgets/journal_box.dart';
import '../widgets/animated_cat_art.dart';
import '../widgets/stars_background.dart';

/// 프리미엄 전용 — 이번 달에 만난 그림자 고양이들이 순서대로(처음 만난
/// 순서) 등장하고, 각각에게 짧은 답장을 남기는 화면.
///
/// 위로나 조언이 아니라, 그 감정을 마주했던 나에게 스스로 건네는 짧은
/// 답장이라는 톤을 유지합니다.
class ReflectionLetterScreen extends StatefulWidget {
  const ReflectionLetterScreen({super.key});

  @override
  State<ReflectionLetterScreen> createState() => _ReflectionLetterScreenState();
}

class _ReflectionLetterScreenState extends State<ReflectionLetterScreen> {
  late List<String> _catIds;
  int _index = 0;
  final TextEditingController _controller = TextEditingController();
  final Set<int> _savedIndexes = {};

  @override
  void initState() {
    super.initState();
    final app = context.read<AppStateProvider>();
    _catIds = app.catIdsMetThisMonth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentAndNext() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final catId = _catIds[_index];
      final monthKey = ReflectionService.monthKeyFor(DateTime.now());
      final entry = ReflectionLetterEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}_$catId',
        catId: catId,
        monthKey: monthKey,
        date: DateTime.now(),
        letterText: text,
      );
      await StorageService.saveReflectionLetter(entry);
      _savedIndexes.add(_index);
    }
    if (_index < _catIds.length - 1) {
      setState(() {
        _index += 1;
        _controller.clear();
      });
    } else {
      if (!mounted) return;
      _showFinished();
    }
  }

  void _showFinished() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.blobLavender, AppColors.bg0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 14),
              Text(
                '이번 달의 그림자들에게\n답장을 모두 남겼어요',
                textAlign: TextAlign.center,
                style: titleFont(fontSize: 18, color: AppColors.ink),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blobLavenderAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    '닫기',
                    style: serifFont(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                        const SizedBox(width: 4),
                        Text(
                          '리플렉션 레터',
                          style: titleFont(
                            fontSize: 19,
                            color: AppColors.titlePastelGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _catIds.isEmpty
                        ? const _NoCatsThisMonth()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
                            child: _LetterStep(
                              catId: _catIds[_index],
                              index: _index,
                              total: _catIds.length,
                              controller: _controller,
                              onNext: _saveCurrentAndNext,
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

class _NoCatsThisMonth extends StatelessWidget {
  const _NoCatsThisMonth();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('🌙', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          Text(
            '이번 달 만난 고양이가 없어요',
            style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _LetterStep extends StatelessWidget {
  final String catId;
  final int index;
  final int total;
  final TextEditingController controller;
  final VoidCallback onNext;
  const _LetterStep({
    required this.catId,
    required this.index,
    required this.total,
    required this.controller,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final cat = shadowCatById(catId);
    final accent = CatPalette.accentFor(catId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            '${index + 1} / $total',
            style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: AnimatedCatArt(imageAsset: cat.imageAsset, size: 110)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            cat.nameKr,
            style: titleFont(fontSize: 20, color: AppColors.ink),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            cat.keyword,
            style: bodyFont(fontSize: 12.5, color: accent),
          ),
        ),
        const SizedBox(height: 20),
        JournalBox(
          question: '${cat.nameKr}에게, 이번 달을 돌아보며 답장을 남겨보세요',
          controller: controller,
          hint: '짧아도 괜찮아요. 그때의 나에게 지금의 내가 건네는 말이에요',
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              index == total - 1 ? '마지막 답장 남기기' : '다음 고양이에게',
              style: serifFont(fontSize: 14.5, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
