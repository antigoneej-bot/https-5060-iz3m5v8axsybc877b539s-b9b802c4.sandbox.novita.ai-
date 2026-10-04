import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notice.dart';
import '../services/cloud_service.dart';
import '../services/subscription_service.dart';
import '../theme.dart';
import 'garden_news_reservations_screen.dart';

/// 정원소식(구 "공지") 상세 화면.
///
/// [설계 원칙] 이 화면은 운영자가 직접 올린 문구만 그대로 보여준다 -
/// 참여 인원수를 부풀리거나 "마감 임박" 같은 가짜 긴급함을 자동으로 만들어
/// 붙이지 않는다. [Notice.isReservable]인 소식은 앱 안에서 선착순으로
/// 신청/취소할 수 있고, 그 외에는 과거처럼 외부 신청폼
/// ([Notice.applyUrl])으로만 연결한다.
class NoticeDetailScreen extends StatefulWidget {
  final Notice notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  late Notice _notice;
  bool? _reserved; // null = 아직 모름(로딩 중)
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
    if (_notice.isReservable) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadReserved());
    }
  }

  Future<void> _loadReserved() async {
    if (!CloudService.enabled) return;
    try {
      final ids = await CloudService.myGardenNewsReservations();
      if (mounted) setState(() => _reserved = ids.contains(_notice.id));
    } catch (_) {
      // 조용히 실패 - 버튼은 "신청하기" 기본 상태로 둔다.
      if (mounted) setState(() => _reserved = false);
    }
  }

  Future<void> _reserve() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await CloudService.reserveGardenNews(_notice.id);
      if (mounted) {
        setState(() {
          _reserved = true;
          _notice = Notice(
            id: _notice.id,
            title: _notice.title,
            body: _notice.body,
            emoji: _notice.emoji,
            type: _notice.type,
            date: _notice.date,
            status: _notice.status,
            period: _notice.period,
            location: _notice.location,
            cost: _notice.cost,
            applyUrl: _notice.applyUrl,
            capacity: _notice.capacity,
            reservedCount: _notice.reservedCount + 1,
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelReservation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await CloudService.cancelGardenNewsReservation(_notice.id);
      if (mounted) {
        setState(() {
          _reserved = false;
          _notice = Notice(
            id: _notice.id,
            title: _notice.title,
            body: _notice.body,
            emoji: _notice.emoji,
            type: _notice.type,
            date: _notice.date,
            status: _notice.status,
            period: _notice.period,
            location: _notice.location,
            cost: _notice.cost,
            applyUrl: _notice.applyUrl,
            capacity: _notice.capacity,
            reservedCount: _notice.reservedCount > 0
                ? _notice.reservedCount - 1
                : 0,
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _accent() {
    switch (_notice.type) {
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
    final url = _notice.applyUrl;
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
    final notice = _notice;
    final canApply =
        notice.applyUrl != null &&
        !notice.isReservable &&
        notice.status != NoticeStatus.closed;
    final isAdmin = SubscriptionService.isAdminUser && CloudService.enabled;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          '소식',
          style: pathLabelFont(fontSize: 16, color: AppColors.ink),
        ),
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
              if (notice.period != null ||
                  notice.location != null ||
                  notice.cost != null)
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
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: '기간',
                          value: notice.period!,
                        ),
                      if (notice.location != null)
                        _InfoRow(
                          icon: Icons.place_rounded,
                          label: '장소',
                          value: notice.location!,
                        ),
                      if (notice.cost != null)
                        _InfoRow(
                          icon: Icons.payments_rounded,
                          label: '비용',
                          value: notice.cost!,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                notice.body,
                style: bodyFont(
                  fontSize: 13.5,
                  color: AppColors.inkSoft,
                  height: 1.7,
                ),
              ),
              if (notice.isReservable) ...[
                const SizedBox(height: 24),
                _buildReservationCard(context, accent),
              ],
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
              if (isAdmin && notice.isReservable) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          GardenNewsReservationsScreen(news: notice),
                    ),
                  ),
                  icon: const Icon(Icons.list_alt_rounded, size: 18),
                  label: const Text('(관리자) 신청자 목록 보기'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Color accent) {
    final notice = _notice;
    final full = notice.isReservationFull;
    final closed = notice.status == NoticeStatus.closed;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                '신청 ${notice.reservedCount} / ${notice.capacity}명',
                style: bodyFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: bodyFont(fontSize: 11.5, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 14),
          if (_reserved == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_reserved == true)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: _busy ? null : _cancelReservation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  side: BorderSide(color: AppColors.inkSoft.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('신청 취소하기'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: (_busy || full || closed) ? null : _reserve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  disabledBackgroundColor: AppColors.inkSoft.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        closed
                            ? '신청이 마감됐어요'
                            : full
                            ? '신청 인원이 모두 찼어요'
                            : '신청하기',
                        style: pathLabelFont(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          if (!CloudService.enabled) ...[
            const SizedBox(height: 8),
            Text(
              '서버 연결이 준비되지 않아 지금은 신청할 수 없어요.',
              textAlign: TextAlign.center,
              style: bodyFont(fontSize: 11, color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

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
            child: Text(
              label,
              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: bodyFont(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
