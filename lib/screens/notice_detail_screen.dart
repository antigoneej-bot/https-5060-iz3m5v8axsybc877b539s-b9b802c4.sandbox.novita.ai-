import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notice.dart';
import '../models/garden_event_booking.dart';
import '../services/garden_event_service.dart';
import '../services/garden_news_admin_service.dart';
import '../theme.dart';
import '../widgets/garden_booking_calendar.dart';
import 'account_screen.dart';
import 'garden_news_reservations_screen.dart';

class NoticeDetailScreen extends StatefulWidget {
  final Notice notice;
  final GardenEventService? eventService;
  const NoticeDetailScreen({
    super.key,
    required this.notice,
    this.eventService,
  });
  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  late final GardenNewsAdminService _admin;
  late Notice _notice;
  late final GardenEventService _events;
  GardenEventBooking? _reservation;
  String? _selectedSessionId;
  String? _owner;
  int _refreshGeneration = 0;
  bool _loaded = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
    _events = widget.eventService ?? GardenEventService();
    _admin = GardenNewsAdminService.firebase()..addListener(_adminChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _adminChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _admin.removeListener(_adminChanged);
    _admin.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted || _busy) return;
    final owner = _events.currentOwner;
    final generation = ++_refreshGeneration;
    setState(() {
      _error = null;
      _loaded = false;
    });
    try {
      await _admin.refresh();
      final notice = await _events.refresh(_notice.id);
      // Older edits may have removed capacity while a booking still exists.
      final reservation = await _events.reservation(notice.id);
      if (!mounted ||
          generation != _refreshGeneration ||
          _events.currentOwner != owner) {
        return;
      }
      setState(() {
        _notice = notice;
        _reservation = reservation;
        _owner = owner;
        _loaded = true;
        _selectedSessionId = reservation?.sessionId ?? _selectedSessionId;
        if (_selectedSessionId != null &&
            !notice.sessions.any((s) => s.id == _selectedSessionId)) {
          _selectedSessionId = null;
        }
      });
    } catch (e) {
      if (mounted &&
          generation == _refreshGeneration &&
          _events.currentOwner == owner) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _reserve() async {
    if (_busy) return;
    if (_events.currentOwner == null &&
        (!await AccountScreen.ensureSignedIn(context) || !mounted)) {
      return;
    }
    final owner = _events.currentOwner;
    final details = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _BookingDetailsDialog(summary: _bookingSummary()),
    );
    if (details == null || !mounted || _events.currentOwner != owner) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final confirmation = await _events.reserve(
        _notice.id,
        sessionId: _selectedSessionId,
        displayName: details['displayName'],
        note: details['note'],
      );
      if (mounted && _events.currentOwner == owner) {
        setState(() {
          if (confirmation.news != null) _notice = confirmation.news!;
          _reservation = confirmation.reservation;
          _selectedSessionId = confirmation.reservation.sessionId;
          _owner = owner;
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted && _events.currentOwner == owner) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (_busy || _owner != _events.currentOwner) return;
    final owner = _owner;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이 모임 신청을 취소할까요?'),
        content: const Text('취소한 자리는 다른 사람이 신청할 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('유지하기'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('신청 취소'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || owner != _events.currentOwner) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notice = await _events.cancel(_notice.id);
      if (mounted && _events.currentOwner == owner) {
        setState(() {
          if (notice != null) _notice = notice;
          _reservation = null;
          _owner = owner;
          _loaded = true;
        });
      }
    } catch (e) {
      if (mounted && _events.currentOwner == owner) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      if (mounted) setState(() => _error = '운영자가 모임 접속 링크를 준비 중이에요.');
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        setState(() => _error = '페이지를 열지 못했어요. 잠시 후 다시 시도해 주세요.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = '페이지를 열지 못했어요.');
    }
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _open(await _events.meetingUrl(_notice.id));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime date) =>
      DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(date.toLocal());

  String _bookingSummary() {
    for (final slot in _notice.sessions) {
      if (slot.id == _selectedSessionId) {
        return '${_notice.title}\n${_date(slot.startsAt)} ~ ${_date(slot.endsAt)}';
      }
    }
    return _notice.title;
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    final known = _loaded && _owner == _events.currentOwner;
    final booked = known && _reservation != null;
    GardenEventSession? selected;
    for (final slot in notice.sessions) {
      if (slot.id == _selectedSessionId) selected = slot;
    }
    final canBook =
        known &&
        !booked &&
        !_busy &&
        _events.backendEnabled &&
        notice.isReservable &&
        notice.status != NoticeStatus.closed &&
        (notice.sessions.isEmpty
            ? !notice.isReservationFull
            : selected?.canBookAt(DateTime.now()) == true);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: const Text('정원소식'),
        backgroundColor: AppColors.bg0,
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(notice.emoji, style: const TextStyle(fontSize: 28)),
                Chip(label: Text(notice.type.label)),
                if (notice.status != null)
                  Chip(label: Text(notice.status!.label)),
                if (notice.eventMode != null)
                  Chip(
                    label: Text(notice.eventMode == 'online' ? '온라인' : '오프라인'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notice.title,
              style: titleFont(fontSize: 22, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              notice.date,
              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            if (notice.period != null)
              _info(Icons.calendar_today, '기간', notice.period!),
            if (notice.location != null)
              _info(Icons.place_outlined, '장소', notice.location!),
            if (notice.cost != null)
              _info(Icons.payments_outlined, '비용', notice.cost!),
            const SizedBox(height: 16),
            Text(
              notice.body,
              style: bodyFont(fontSize: 14, color: AppColors.ink, height: 1.7),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              TextButton(
                onPressed: _busy ? null : _refresh,
                child: const Text('연결 다시 확인'),
              ),
            ],
            if (notice.isReservable || booked) ...[
              const SizedBox(height: 24),
              Text(
                '참여 신청',
                style: titleFont(fontSize: 18, color: AppColors.ink),
              ),
              if (notice.sessions.isNotEmpty) ...[
                if (!booked)
                  GardenBookingCalendar(
                    sessions: notice.sessions,
                    selectedId: _selectedSessionId,
                    enabled:
                        known && !_busy && notice.status != NoticeStatus.closed,
                    onChanged: (id) => setState(() => _selectedSessionId = id),
                  ),
                if (selected != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.blobMint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _bookingSummary(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!booked)
                    Text(
                      '신청 마감 ${_date(selected.bookingClosesAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                ],
              ] else ...[
                if (notice.capacity != null)
                  Text('신청 ${notice.reservedCount} / ${notice.capacity}명')
                else
                  const Text('새 신청은 받지 않아요. 기존 신청을 확인하거나 취소할 수 있어요.'),
              ],
              const SizedBox(height: 12),
              if (!known && _error == null)
                const Center(child: CircularProgressIndicator()),
              if (booked) ...[
                const Text(
                  '신청이 완료됐어요.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (selected?.state == 'canceled')
                  const Text(
                    '운영자가 이 일정을 취소했어요.',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                if (notice.eventMode == 'online' &&
                    selected?.state != 'canceled')
                  FilledButton.icon(
                    onPressed: _busy ? null : _join,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('모임 접속 링크 열기'),
                  ),
                OutlinedButton(
                  onPressed: _busy ? null : _cancel,
                  child: const Text('신청 취소하기'),
                ),
              ] else if (known)
                FilledButton(
                  onPressed: canBook ? _reserve : null,
                  child: Text(
                    _busy
                        ? '확인 중…'
                        : notice.sessions.isNotEmpty && selected == null
                        ? '날짜와 시간을 선택해 주세요'
                        : canBook
                        ? '선택한 모임 신청하기'
                        : '현재 신청할 수 없어요',
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                '편지와 감정 기록은 운영자에게 전달되지 않아요. 신청할 때 직접 적은 이름·요청 사항과 계정에서 확인된 이메일만 전달돼요. 비용이 있는 모임은 운영자의 결제 안내를 확인해 주세요.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ],
            if (notice.applyUrl != null &&
                !notice.isReservable &&
                notice.status != NoticeStatus.closed) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _open(notice.applyUrl),
                child: const Text('외부 신청 페이지 열기'),
              ),
            ],
            if (_admin.canManage &&
                (notice.isReservable ||
                    notice.hasReservations ||
                    notice.deleting)) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GardenNewsReservationsScreen(news: notice),
                  ),
                ),
                icon: const Icon(Icons.list_alt),
                label: const Text('(관리자) 날짜별 신청자 보기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text('$label  '),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _BookingDetailsDialog extends StatefulWidget {
  final String summary;
  const _BookingDetailsDialog({required this.summary});
  @override
  State<_BookingDetailsDialog> createState() => _BookingDetailsDialogState();
}

class _BookingDetailsDialogState extends State<_BookingDetailsDialog> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('예약 확인'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.summary,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 40,
            decoration: const InputDecoration(labelText: '모임에서 사용할 이름 (선택)'),
          ),
          TextField(
            controller: _note,
            maxLength: 200,
            maxLines: 3,
            decoration: const InputDecoration(labelText: '운영자에게 요청할 내용 (선택)'),
          ),
          const Text(
            '입력한 내용과 인증된 이메일이 있는 경우 이메일이 운영자에게 전달돼요. 개인적인 편지나 건강 정보는 적지 않아도 돼요.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('닫기'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, {
          'displayName': _name.text.trim(),
          'note': _note.text.trim(),
        }),
        child: const Text('신청 확인'),
      ),
    ],
  );
}
