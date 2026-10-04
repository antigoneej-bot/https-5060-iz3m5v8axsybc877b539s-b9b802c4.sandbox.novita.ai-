import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/notice_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import 'notice_detail_screen.dart';

/// 공지사항 목록 화면.
/// 화면에 들어오는 순간 모든 공지를 읽음으로 표시합니다.
class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final List<Notice> _notices = NoticeService.fetchNotices();

  @override
  void initState() {
    super.initState();
    NoticeService.markAllAsRead();
  }

  Color _accentFor(NoticeType type) {
    switch (type) {
      case NoticeType.update:
        return AppColors.blobMintAccent;
      case NoticeType.event:
        return AppColors.blobPeachAccent;
      case NoticeType.info:
        return AppColors.blobLavenderAccent;
    }
  }

  Color _bgFor(NoticeType type) {
    switch (type) {
      case NoticeType.update:
        return AppColors.blobMint;
      case NoticeType.event:
        return AppColors.blobPeach;
      case NoticeType.info:
        return AppColors.blobLavender;
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

  @override
  Widget build(BuildContext context) {
    if (_notices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Text(
            '아직 등록된 공지가 없어요',
            style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final notice in _notices) ...[
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NoticeDetailScreen(notice: notice),
              ),
            ),
            child: GlassBlob(
              accent: _accentFor(notice.type),
              background: _bgFor(notice.type),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(notice.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          notice.type.label,
                          style: bodyFont(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _accentFor(notice.type),
                          ),
                        ),
                      ),
                      if (notice.status != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              notice.status!,
                            ).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            notice.status!.label,
                            style: bodyFont(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(notice.status!),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        notice.date,
                        style: bodyFont(
                          fontSize: 10.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notice.title,
                    style: pathLabelFont(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notice.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: bodyFont(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                      height: 1.6,
                    ),
                  ),
                  if (notice.applyUrl != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '자세히 보기',
                          style: bodyFont(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _accentFor(notice.type),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: _accentFor(notice.type),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
