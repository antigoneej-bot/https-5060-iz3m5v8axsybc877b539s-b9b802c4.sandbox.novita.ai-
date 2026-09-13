import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/shadow_cats_data.dart';
import '../services/analytics_service.dart';
import '../theme.dart';
import '../utils/cat_palette.dart';
import 'lively_cat_image.dart';

/// "주간/월간 돌아보기" 결과를 SNS(인스타 스토리 등)에 공유할 수 있는 세로형
/// 카드를 보여주고, 캡처 → 공유까지 처리하는 다이얼로그를 엽니다.
///
/// [share_cat_card.dart]의 공유 다이얼로그 패턴을 그대로 따르되, 내부에
/// 보여줄 카드 콘텐츠([cardContent])와 공유 시 첨부할 문구([shareText])만
/// 다르게 받는 범용 버전입니다.
Future<void> showShareReflectionCard(
  BuildContext context, {
  required Widget cardContent,
  required String shareText,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _ShareReflectionCardDialog(
      cardContent: cardContent,
      shareText: shareText,
    ),
  );
}

class _ShareReflectionCardDialog extends StatefulWidget {
  final Widget cardContent;
  final String shareText;
  const _ShareReflectionCardDialog({
    required this.cardContent,
    required this.shareText,
  });

  @override
  State<_ShareReflectionCardDialog> createState() =>
      _ShareReflectionCardDialogState();
}

class _ShareReflectionCardDialogState
    extends State<_ShareReflectionCardDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _sharing = false;
  bool _saving = false;

  Future<Uint8List?> _captureBytes() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return Uint8List.view(byteData.buffer);
  }

  /// 공유 없이, 카드 이미지를 곧바로 휴대폰 사진첩에만 저장합니다.
  Future<void> _saveOnly() async {
    if (_saving || _sharing) return;
    setState(() => _saving = true);
    try {
      final bytes = await _captureBytes();
      if (bytes == null) return;

      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카드 이미지가 만들어졌어요 (모바일 앱에서 저장 가능해요)')),
        );
        return;
      }

      await Gal.putImageBytes(
        bytes,
        name: 'bond_card_${DateTime.now().millisecondsSinceEpoch}',
      );
      await AnalyticsService().logEvent(AnalyticsEvents.saveCardToGallery, {
        'card_type': 'reflection_card',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카드를 사진첩에 저장했어요 📷')));
    } catch (e) {
      if (kDebugMode) debugPrint('카드 저장 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장 권한을 확인해주세요')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    if (_sharing || _saving) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _captureBytes();
      if (bytes == null) return;

      if (kIsWeb) {
        // 웹 프리뷰에서는 파일 시스템 공유가 지원되지 않으므로, 캡처
        // 성공 여부만 안내합니다(모바일 앱(APK)에서 정상 공유됩니다).
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카드 이미지가 만들어졌어요 (모바일 앱에서 공유 가능해요)')),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/reflection_card_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      // 사진첩(갤러리)에도 함께 저장합니다. 저장이 실패해도(권한 거부 등)
      // 공유 자체는 계속 진행되도록 별도로 감싸서 처리합니다.
      bool savedToGallery = false;
      try {
        await Gal.putImageBytes(
          bytes,
          name: 'reflection_card_${DateTime.now().millisecondsSinceEpoch}',
        );
        savedToGallery = true;
        await AnalyticsService().logEvent(AnalyticsEvents.saveCardToGallery, {
          'card_type': 'reflection_card',
        });
      } catch (e) {
        if (kDebugMode) debugPrint('갤러리 저장 실패: $e');
      }

      await SharePlus.instance.share(
        ShareParams(text: widget.shareText, files: [XFile(file.path)]),
      );
      await AnalyticsService().logEvent(AnalyticsEvents.shareCard, {
        'card_type': 'reflection_card',
      });

      if (savedToGallery && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사진첩에도 저장했어요 📷')));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('회고 공유 카드 생성 실패: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카드를 만드는 데 문제가 있었어요')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(key: _boundaryKey, child: widget.cardContent),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _RoundButton(
                  icon: Icons.close_rounded,
                  label: '닫기',
                  filled: false,
                  onTap: () => Navigator.pop(context),
                ),
                _RoundButton(
                  icon: Icons.download_rounded,
                  label: _saving ? '저장 중...' : '폰에 저장',
                  filled: false,
                  onTap: (_sharing || _saving) ? null : _saveOnly,
                ),
                _RoundButton(
                  icon: Icons.ios_share_rounded,
                  label: _sharing ? '만드는 중...' : '공유하기',
                  filled: true,
                  onTap: (_sharing || _saving) ? null : _share,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: filled
                ? AppColors.blobMintAccent
                : Colors.white.withValues(alpha: 0.85),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: filled ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: pathLabelFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 공유 카드 공통 프레임(세로형, 300px 고정 폭 · 브랜드 헤더/푸터 포함).
/// 배경 그라데이션 색만 다르게 받아, 주간/월간 카드가 같은 톤을 유지하도록
/// 합니다.
class _ShareCardFrame extends StatelessWidget {
  final List<Color> gradientColors;
  final Widget child;
  const _ShareCardFrame({required this.gradientColors, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'MIND CAT GARDEN',
            textAlign: TextAlign.center,
            style: bodyFont(
              fontSize: 10,
              color: AppColors.titlePastelGreenSoft,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          child,
          const SizedBox(height: 18),
          Text(
            '🐈‍⬛  마음냥 정원',
            textAlign: TextAlign.center,
            style: brandFont(fontSize: 15, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// 요일 라벨(월~일) 색상 도트 한 줄. 공유 카드용으로 크기를 작게 고정한
/// 버전입니다(주간 회고 화면의 바 그래프와 달리, 캡처 시 잘리지 않도록
/// 단순한 원형 도트를 씁니다).
class _WeekdayDots extends StatelessWidget {
  final List<MapEntry<DateTime, String?>> days;
  const _WeekdayDots({required this.days});

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final entry in days)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.value != null
                        ? CatPalette.accentFor(
                            entry.value!,
                          ).withValues(alpha: 0.9)
                        : CatPalette.emptyDay,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _weekdayLabels[entry.key.weekday - 1],
                  style: bodyFont(fontSize: 9.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 주간 그림자 지도 결과를 담은 공유용 카드 콘텐츠.
class ShareWeeklyCardContent extends StatelessWidget {
  final String? topCatId;
  final int recordedDays;
  final List<MapEntry<DateTime, String?>> days;
  const ShareWeeklyCardContent({
    super.key,
    required this.topCatId,
    required this.recordedDays,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final hasCat = topCatId != null;
    final cat = hasCat ? shadowCatById(topCatId!) : null;
    final accent = hasCat
        ? CatPalette.accentFor(topCatId!)
        : AppColors.blobMintAccent;
    final background = hasCat
        ? CatPalette.backgroundFor(topCatId!)
        : AppColors.blobMint;
    return _ShareCardFrame(
      gradientColors: [Colors.white, background.withValues(alpha: 0.9)],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '이번 주 그림자 지도',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 18),
          if (cat != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              // 카드 안쪽 가로(300 - 좌우 패딩 44)에 맞춘 유한 너비.
              // infinity를 넘기면 LivelyCatImage의 cacheWidth 계산이 깨진다.
              child: LivelyCatImage(
                imageAsset: cat.imageAsset,
                width: 256,
                height: 190,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            cat != null
                ? "이번 주, 나는\n'${cat.nameKr}'과\n가장 자주 함께 있었어요"
                : '이번 주 기록을 살펴보고 있어요',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 17, color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 6),
          Text(
            '7일 중 $recordedDays일 · 관찰 결과입니다',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 11.5, color: accent),
          ),
          const SizedBox(height: 16),
          _WeekdayDots(days: days),
        ],
      ),
    );
  }
}

/// 월간 돌아보기 결과를 담은 공유용 카드 콘텐츠.
class ShareMonthlyCardContent extends StatelessWidget {
  final String sentence;
  final String? accentCatId;
  const ShareMonthlyCardContent({
    super.key,
    required this.sentence,
    required this.accentCatId,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentCatId != null
        ? CatPalette.accentFor(accentCatId!)
        : AppColors.blobLavenderAccent;
    final background = accentCatId != null
        ? CatPalette.backgroundFor(accentCatId!)
        : AppColors.blobLavender;
    return _ShareCardFrame(
      gradientColors: [Colors.white, background.withValues(alpha: 0.9)],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '이번 달 돌아보기',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          const Text('📖', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 16),
          Text(
            sentence,
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 17, color: AppColors.ink, height: 1.6),
          ),
          const SizedBox(height: 10),
          Text(
            '4주간의 기록을 살펴본 관찰 결과입니다',
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 11.5, color: accent),
          ),
        ],
      ),
    );
  }
}
