import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';

import '../l10n/breathing_technique_l10n.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/breathing_technique.dart';

/// 2번(벤치마킹 제안: 감정 선택 -> 맞춤 호흡 자동 제안 흐름 연결) - 감정을
/// 고르고 게임을 시작하기 직전에, [EmotionBreathingService]가 골라준 호흡
/// 기법을 잠깐 제안하는 시트.
///
/// [ReviveOfferSheet]와 톤/구조를 맞춘 가벼운 바텀시트다 - 강요가 아니라
/// 다정한 제안으로 느껴지도록, "바로 시작할게요"로 언제든 건너뛸 수 있고
/// 뒤로가기 제스처로도 건너뛴 것과 동일하게 처리된다(매판 강제로 막지
/// 않는 것이 힐링 앱다운 태도라는 판단).
///
/// 반환값: true면 "숨 고르고 시작하기"를 선택한 것(호출부에서
/// [BreathingInterstitial]을 이어서 띄운다), false(또는 null/뒤로가기)면
/// 건너뛰고 곧바로 게임을 시작하기로 한 것.
class BreathingSuggestionSheet extends StatelessWidget {
  final BreathingTechniqueDef technique;

  const BreathingSuggestionSheet({super.key, required this.technique});

  static Future<bool> show(
    BuildContext context, {
    required BreathingTechniqueDef technique,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BreathingSuggestionSheet(technique: technique),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = breathingTechniqueName(l10n, technique);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.bg0,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(technique.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              l10n.breathingSuggestionTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.breathingSuggestionSubtitle(technique.emoji, name),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.air),
                label: Text(
                  l10n.breathingSuggestionStartButton,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8FAB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.breathingSuggestionSkipButton,
                style: const TextStyle(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
