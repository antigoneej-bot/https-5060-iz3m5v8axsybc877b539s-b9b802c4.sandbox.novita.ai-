import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/letter_entry.dart';
import '../data/shadow_cats_data.dart';
import '../theme.dart';
import '../widgets/lively_cat_image.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppStateProvider>();
    if (app.history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Text('🌙', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 14),
            Text(
              '아직 기록된 편지가 없어요',
              style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 6),
            Text(
              '그림자 고양이를 만나 첫 편지를 써보세요',
              style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      );
    }
    return Column(
      children: app.history.map((entry) => _HistoryItem(entry: entry)).toList(),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final LetterEntry entry;
  const _HistoryItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cat = shadowCatById(entry.catId);
    final dateStr = DateFormat(
      'yyyy.MM.dd (E) HH:mm',
      'ko_KR',
    ).format(entry.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDetail(context, entry, cat.imageAsset, cat.nameKr),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                LivelyCatImage(
                  imageAsset: cat.imageAsset,
                  width: 38,
                  height: 38,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                      ),
                      Text(
                        '${cat.emoji} ${cat.nameKr}',
                        style: serifFont(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry.improved)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFFD9695A),
                      size: 18,
                    ),
                  ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.inkSoft.withValues(alpha: 0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    LetterEntry entry,
    String imageAsset,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: serifFont(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.inkSoft,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('yyyy년 M월 d일 HH:mm', 'ko_KR').format(entry.date),
                style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imageAsset,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
              if (entry.tempAfter != null)
                Text(
                  '마음 온도: 실천 전 ${entry.tempBefore.round()}° → 실천 후 ${entry.tempAfter!.round()}°',
                  style: bodyFont(fontSize: 12.5, color: AppColors.goldSoft),
                )
              else
                Text(
                  '마음 온도: ${entry.tempBefore.round()}°',
                  style: bodyFont(fontSize: 12.5, color: AppColors.goldSoft),
                ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg0,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.letterText.isEmpty ? '(기록된 내용이 없어요)' : entry.letterText,
                  style: bodyFont(
                    fontSize: 13.5,
                    color: AppColors.moon,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.read<AppStateProvider>().deleteHistoryEntry(
                      entry.id,
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    '삭제하기',
                    style: bodyFont(fontSize: 12.5, color: AppColors.rose),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
