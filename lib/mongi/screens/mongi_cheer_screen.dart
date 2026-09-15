import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/mongi_cheer_l10n.dart';
import '../models/mongi_cheer.dart';
import '../providers/garden_provider.dart';

/// "몽이의 응원 우편함" 화면 - Finch "Good Vibes"를 벤치마킹한 경량 소셜
/// 기능의 로컬 경량판.
///
/// 이 앱은 완전 로컬 우선 구조라 실제 타인과 실시간으로 메시지를 주고받는
/// "진짜 소셜"은 만들지 않는다. 대신 화면 상단에 항상 정직하게 안내한다:
/// "이 앱은 아직 다른 사람과 직접 연결되지 않아요. 대신 몽이가 마음을
/// 이어줘요." 보내기는 큐레이션된 문구 중 하나를 몽이에게 맡기는 제스처(실제
/// 수신자 없음, 하루 1회), 받기는 하루 1회 큐레이션된 응원 풀에서 무작위로
/// 하나를 받는 것이다.
class MongiCheerScreen extends StatefulWidget {
  const MongiCheerScreen({super.key});

  @override
  State<MongiCheerScreen> createState() => _MongiCheerScreenState();
}

class _MongiCheerScreenState extends State<MongiCheerScreen> {
  int? _pickedSendOption;

  Future<void> _confirmSend(int optionIndex) async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    final ok = await garden.sendCheer(optionIndex);
    if (!ok || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.cheerSendConfirmSnackbar),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openTodayCheer() async {
    final garden = context.read<GardenProvider>();
    await garden.ensureTodayCheerReceived();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.cheerScreenAppBarTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildHonestyNotice(l10n),
          const SizedBox(height: 18),
          _buildReceiveSection(l10n, garden),
          const SizedBox(height: 18),
          _buildSendSection(l10n, garden),
        ],
      ),
    );
  }

  Widget _buildHonestyNotice(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.catSageBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🐱', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.cheerScreenHonestyNotice,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8A7F76),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveSection(AppLocalizations l10n, GardenProvider garden) {
    final hasReceived = garden.hasReceivedCheerToday;
    final receivedIndex = garden.todayCheerReceivedIndex;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE3EC), Color(0xFFFFC9DB)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cheerReceiveSectionTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Color(0xFF9A3A5C),
            ),
          ),
          const SizedBox(height: 14),
          if (hasReceived && receivedIndex != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cheerReceiveCardLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB1466E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cheerReceiveMessageText(l10n, receivedIndex),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openTodayCheer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB1466E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.cheerReceiveButtonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSendSection(AppLocalizations l10n, GardenProvider garden) {
    final hasSent = garden.hasSentCheerToday;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cheerSendSectionTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.cheerSendSectionSubtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          if (hasSent) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Color(0xFF7FB37A),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.cheerSendDoneTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.cheerSendDoneSubtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(MongiCheer.sendOptionCount, (index) {
                final selected = _pickedSendOption == index;
                return GestureDetector(
                  onTap: () => setState(() => _pickedSendOption = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF7FB37A)
                          : AppColors.catSageBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cheerSendOptionText(l10n, index),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6A5F55),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pickedSendOption == null
                    ? null
                    : () => _confirmSend(_pickedSendOption!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FB37A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD8D2C8),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.cheerSendSectionTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
