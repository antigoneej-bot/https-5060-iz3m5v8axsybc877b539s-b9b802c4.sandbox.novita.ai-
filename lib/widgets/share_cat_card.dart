import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/shadow_cats_data.dart';
import '../models/shadow_cat.dart';
import '../services/analytics_service.dart';
import '../theme.dart';
import 'lively_cat_image.dart';

/// "오늘 만난 그림자 고양이"를 SNS(인스타 스토리 등)에 공유할 수 있는
/// 세로형 카드를 보여주고, 캡처 → 공유까지 처리하는 다이얼로그를 엽니다.
///
/// [meetingCount]가 1보다 크면 "벌써 N번째 만남"이라는 관계 누적 문구를
/// 함께 보여주어, 다시 만난 고양이에 대한 서사를 확장합니다.
Future<void> showShareCatCard(
  BuildContext context, {
  required ShadowCat cat,
  required int meetingCount,
  required int metCount,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _ShareCatCardDialog(
      cat: cat,
      meetingCount: meetingCount,
      metCount: metCount,
    ),
  );
}

class _ShareCatCardDialog extends StatefulWidget {
  final ShadowCat cat;
  final int meetingCount;
  final int metCount;
  const _ShareCatCardDialog({
    required this.cat,
    required this.meetingCount,
    required this.metCount,
  });

  @override
  State<_ShareCatCardDialog> createState() => _ShareCatCardDialogState();
}

class _ShareCatCardDialogState extends State<_ShareCatCardDialog> {
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
        name:
            'shadow_cat_${widget.cat.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      await AnalyticsService().logEvent(AnalyticsEvents.saveCardToGallery, {
        'card_type': 'cat_card',
        'cat_id': widget.cat.id,
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
        '${dir.path}/shadow_cat_${widget.cat.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      // 사진첩(갤러리)에도 함께 저장합니다. 저장이 실패해도(권한 거부 등)
      // 공유 자체는 계속 진행되도록 별도로 감싸서 처리합니다.
      bool savedToGallery = false;
      try {
        await Gal.putImageBytes(
          bytes,
          name:
              'shadow_cat_${widget.cat.id}_${DateTime.now().millisecondsSinceEpoch}',
        );
        savedToGallery = true;
        await AnalyticsService().logEvent(AnalyticsEvents.saveCardToGallery, {
          'card_type': 'cat_card',
          'cat_id': widget.cat.id,
        });
      } catch (e) {
        if (kDebugMode) debugPrint('갤러리 저장 실패: $e');
      }

      await SharePlus.instance.share(
        ShareParams(
          text: '오늘은 ${widget.cat.nameKr} 고양이를 만났어요 🐾 #마음냥정원',
          files: [XFile(file.path)],
        ),
      );
      await AnalyticsService().logEvent(AnalyticsEvents.shareCard, {
        'card_type': 'cat_card',
        'cat_id': widget.cat.id,
      });

      if (savedToGallery && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사진첩에도 저장했어요 📷')));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('공유 카드 생성 실패: $e');
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: ShareCatCardContent(
              cat: widget.cat,
              meetingCount: widget.meetingCount,
              metCount: widget.metCount,
            ),
          ),
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
                ? AppColors.blobPeachAccent
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

/// 실제로 캡처되어 공유되는 세로형(9:16에 가까운) 카드 디자인.
/// 인스타그램 스토리 등에 바로 올릴 수 있도록 세로가 긴 비율로 만들었습니다.
class ShareCatCardContent extends StatelessWidget {
  final ShadowCat cat;
  final int meetingCount;
  final int metCount;
  const ShareCatCardContent({
    super.key,
    required this.cat,
    required this.meetingCount,
    required this.metCount,
  });

  @override
  Widget build(BuildContext context) {
    // ⚠️ 유료(Basic 구독) 고양이는 잠겨있으면 탭해도 "만남" 처리가 되지
    // 않아, 비구독자는 42마리를 넘어 "만날" 수 없습니다. shadowCats.length
    // (52)를 분모로 쓰면 영원히 채울 수 없는 목표가 되므로 무료 42마리
    // 기준으로 표시합니다.
    final total = freeShadowCats.length;
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8EE), Color(0xFFFBE3D9)],
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
          const SizedBox(height: 6),
          Text(
            '오늘 만난 그림자 고양이',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 18, color: AppColors.ink),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: LivelyCatImage(
              imageAsset: cat.imageAsset,
              width: 256,
              height: 220,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${cat.emoji}  ${cat.nameKr}',
            textAlign: TextAlign.center,
            style: titleFont(fontSize: 22, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            cat.keyword,
            textAlign: TextAlign.center,
            style: bodyFont(fontSize: 12.5, color: AppColors.blobPeachAccent),
          ),
          const SizedBox(height: 14),
          if (meetingCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '벌써 $meetingCount번째 만남이에요',
                style: bodyFont(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$total마리 중 $metCount마리를 만났어요',
              textAlign: TextAlign.center,
              style: bodyFont(
                fontSize: 12,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '🐈‍⬛  마음냥 정원',
            textAlign: TextAlign.center,
            style: brandFont(fontSize: 15, color: AppColors.inkSoft),
          ),
          Text(
            '$metCount / $total',
            textAlign: TextAlign.center,
            style: numberFont(
              fontSize: 10,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
