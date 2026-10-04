import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/cloud_service.dart';
import '../services/notice_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import '../widgets/garden_path_card.dart';
import 'garden_news_editor_screen.dart';
import 'notice_detail_screen.dart';

/// 정원소식(구 "공지사항") 목록 화면.
///
/// 관리자 계정으로 로그인하면 상단에 "+ 새 소식 작성" 버튼과 각 소식에
/// 수정/삭제 메뉴가 보인다(서버가 다시 한번 관리자 여부를 검증하므로,
/// 여기서 숨기는 것은 UX일 뿐 보안 경계가 아니다). 화면에 들어오는 순간
/// 모든 소식을 읽음으로 표시한다.
///
/// [FeatureScaffold]가 이미 바깥에서 세로 스크롤을 제공하므로, 이 화면은
/// 스스로 스크롤하지 않는 [Column]으로 내용을 쌓는다(중첩 스크롤 방지).
class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  List<Notice> _notices = NoticeService.cachedNotices();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notices = await NoticeService.fetchNotices();
      await NoticeService.markAllAsRead();
      if (mounted) setState(() => _notices = notices);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor({Notice? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GardenNewsEditorScreen(existing: existing),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Notice notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 소식을 삭제할까요?'),
        content: Text(notice.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CloudService.adminDeleteGardenNews(notice.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
    final isAdmin = SubscriptionService.isAdminUser && CloudService.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (isAdmin)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('새 소식 작성'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blobMintAccent,
                    side: BorderSide(color: AppColors.blobMintAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.inkSoft),
              tooltip: '새로고침',
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_loading && _notices.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null && _notices.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                _error!,
                style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
              ),
            ),
          )
        else if (_notices.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                '아직 등록된 소식이 없어요',
                style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
              ),
            ),
          )
        else
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
                        if (isAdmin) ...[
                          InkWell(
                            onTap: () => _openEditor(existing: notice),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () => _delete(notice),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: AppColors.inkSoft,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
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
                    if (notice.isReservable || notice.applyUrl != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            notice.isReservable ? '예약 보기' : '자세히 보기',
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
