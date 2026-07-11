import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emotion_entry.dart';
import '../providers/emotion_provider.dart';
import '../theme.dart';
import '../screens/todays_promise_screen.dart';
import 'feature_scaffold.dart';

/// 오늘의 감정을 기록하는 바텀시트 - 감정 선택 → 강도(1~5) → 짧은 메모
class EmotionRecordSheet extends StatefulWidget {
  const EmotionRecordSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EmotionRecordSheet(),
    );
  }

  @override
  State<EmotionRecordSheet> createState() => _EmotionRecordSheetState();
}

class _EmotionRecordSheetState extends State<EmotionRecordSheet> {
  EmotionType? _selected;
  int _intensity = 3;
  final _memoController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);
    await context.read<EmotionProvider>().addEntry(
      emotion: _selected!,
      intensity: _intensity,
      memo: _memoController.text.trim(),
    );
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    // 마음 기록을 마친 직후, 자연스럽게 "오늘의 약속" 화면으로 이어집니다.
    // (바텀시트가 닫힌 뒤이므로, 여전히 살아있는 navigator의 context를 사용합니다)
    pushFullScreen(navigator.context, '오늘의 약속', const TodaysPromiseScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '지금 마음은 어떤가요?',
                  style: serifFont(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '오늘의 감정을 골라 달빛 정원에 남겨보세요',
                  style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: EmotionType.values
                      .map(
                        (e) => _EmotionChip(
                          emotion: e,
                          selected: _selected == e,
                          onTap: () => setState(() => _selected = e),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  '감정의 강도',
                  style: serifFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1(약하게) ~ 5(강하게)',
                  style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (i) {
                    final level = i + 1;
                    final active = _intensity >= level;
                    final color = _selected?.color ?? AppColors.gold;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _intensity = level),
                        child: Container(
                          margin: EdgeInsets.only(right: i == 4 ? 0 : 8),
                          height: 36,
                          decoration: BoxDecoration(
                            color: active
                                ? color.withValues(alpha: 0.85)
                                : AppColors.bg0,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active ? color : AppColors.line,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$level',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: active ? Colors.white : AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 22),
                Text(
                  '짧은 메모 (선택)',
                  style: serifFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _memoController,
                  maxLines: 3,
                  maxLength: 80,
                  style: bodyFont(fontSize: 13.5, color: AppColors.moon),
                  decoration: InputDecoration(
                    hintText: '오늘 하루, 마음에 남는 순간이 있었나요?',
                    hintStyle: bodyFont(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                    filled: true,
                    fillColor: AppColors.bg0,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selected == null || _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      disabledBackgroundColor: AppColors.line,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _saving ? '기록하는 중...' : '마음 기록하기',
                      style: serifFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  final EmotionType emotion;
  final bool selected;
  final VoidCallback onTap;
  const _EmotionChip({
    required this.emotion,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? emotion.color.withValues(alpha: 0.18)
              : AppColors.bg0,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? emotion.color : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emotion.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              emotion.label,
              style: bodyFont(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? emotion.color : AppColors.moon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
