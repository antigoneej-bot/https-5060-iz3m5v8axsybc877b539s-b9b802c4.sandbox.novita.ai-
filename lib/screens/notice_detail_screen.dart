import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notice.dart';
import '../theme.dart';

/// 소식(공지) 상세 화면.
///
/// [설계 원칙] 이 화면은 운영자가 직접 올린 문구만 그대로 보여준다 -
/// 참여 인원수, 마감 임박 같은 가짜 긴급함을 자동으로 만들어 붙이지 않는다.
/// 신청은 서버가 생기기 전까지 외부 신청폼([Notice.applyUrl])으로 연결한다.
class NoticeDetailScreen extends StatelessWidget {
  final Notice notice;
  const NoticeDetailScreen({super.key, required this.notice});

  Color _accent() {
    switch (notice.type) {
      case NoticeType.update:
        return AppColors.blobMintAccent;
      case NoticeType.event:
        return AppColors.blobPeachAccent;
      case NoticeType.info:
        return AppColors.blobLavenderAccent;
    }
  }

  Color _statusColor(NoticeStatus status) {
    switch (status) {
      case NoticeStatus.recruiting:
        return AppColors.blobMintAccent;
      case NoticeStatus.ongoing:
        return AppColors.blobPeachAccent;
      case NoticeStatus.closed:
        return AppColors.inkSoft;
    }
  }

  Future<void> _openApplyLink(BuildContext context) async {
    final url = notice.applyUrl;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('신청 페이지를 열지 못했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final canApply =
        notice.applyUrl != null && notice.status != NoticeStatus.closed;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text('소식', style: pathLabelFont(fontSize: 16, color: AppColors.ink)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(notice.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      notice.type.label,
                      style: bodyFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  if (notice.status != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(
                          notice.status!,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        notice.status!.label,
                        style: bodyFont(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(notice.status!),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notice.title,
                style: titleFont(fontSize: 21, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                notice.date,
                style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 20),
              if (notice.period != null || notice.location != null || notice.cost != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notice.period != null)
                        _InfoRow(icon: Icons.calendar_today_rounded, label: '기간', value: notice.period!),
                      if (notice.location != null)
                        _InfoRow(icon: Icons.place_rounded, label: '장소', value: notice.location!),
                      if (notice.cost != null)
                        _InfoRow(icon: Icons.payments_rounded, label: '비용', value: notice.cost!),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                notice.body,
                style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft, height: 1.7),
              ),
              if (canApply) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _openApplyLink(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      '신청하기',
                      style: pathLabelFont(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '외부 신청 페이지로 이동해요',
                  textAlign: TextAlign.center,
                  style: bodyFont(fontSize: 11, color: AppColors.inkSoft),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.inkSoft),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(label, style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
          ),
          Expanded(
            child: Text(
              value,
              style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
