import '../l10n/app_language.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/garden_event_booking.dart';
import '../services/garden_event_service.dart';
import '../services/social_auth_service.dart';
import '../theme.dart';
import 'notice_detail_screen.dart';

/// Only the signed-in account's actual bookings; no private journal content.
class MyGardenReservationsScreen extends StatefulWidget {
  final GardenEventService? service;
  const MyGardenReservationsScreen({super.key, this.service});
  @override
  State<MyGardenReservationsScreen> createState() =>
      _MyGardenReservationsScreenState();
}

class _MyGardenReservationsScreenState extends State<MyGardenReservationsScreen>
    with WidgetsBindingObserver {
  late final GardenEventService _service;
  StreamSubscription<User?>? _auth;
  List<GardenEventBooking> _bookings = [];
  String? _owner, _error;
  bool _loading = true, _busy = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GardenEventService();
    _owner = _service.currentOwner;
    WidgetsBinding.instance.addObserver(this);
    if (SocialAuthService.firebaseReady) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted || user?.uid == _owner) return;
        _generation++;
        setState(() {
          _bookings = [];
          _loading = false;
          _error = tr("계정이 바뀌었어요. 화면을 닫고 다시 열어 주세요.");
        });
      });
    }
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _service.myReservations();
      if (!mounted || generation != _generation) return;
      if (_owner != _service.currentOwner) {
        setState(() {
          _bookings = [];
          _loading = false;
          _error = tr("계정이 바뀌었어요. 화면을 닫고 다시 열어 주세요.");
        });
        return;
      }
      rows.sort((a, b) {
        final now = DateTime.now();
        final first = a.sessionStartsAt, second = b.sessionStartsAt;
        if (first == null) return second == null ? 0 : 1;
        if (second == null) return -1;
        final firstPast = first.isBefore(now),
            secondPast = second.isBefore(now);
        if (firstPast != secondPast) return firstPast ? 1 : -1;
        return firstPast ? second.compareTo(first) : first.compareTo(second);
      });
      setState(() {
        _bookings = List.of(rows);
        _loading = false;
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _bookings = [];
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _open(GardenEventBooking booking) async {
    if (_busy || _owner != _service.currentOwner || booking.eventUnavailable) {
      return;
    }
    setState(() => _busy = true);
    try {
      final news = await _service.refresh(booking.newsId);
      if (!mounted || _owner != _service.currentOwner) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              NoticeDetailScreen(notice: news, eventService: _service),
        ),
      );
    } catch (error) {
      if (mounted && _owner == _service.currentOwner) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _load();
      }
    }
  }

  Future<void> _cancel(GardenEventBooking booking) async {
    if (_busy || _owner != _service.currentOwner) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr("이 모임 신청을 취소할까요?")),
        content: Text(booking.news?.title ?? tr("신청 내역을 삭제하고 자리를 돌려드려요.")),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr("유지하기")),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr("신청 취소")),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || _owner != _service.currentOwner) {
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.cancel(booking.newsId);
      if (!mounted || _owner != _service.currentOwner) return;
      setState(
        () => _bookings.removeWhere((row) => row.newsId == booking.newsId),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr("신청을 취소했어요."))));
    } catch (error) {
      if (mounted && _owner == _service.currentOwner) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _date(DateTime value) => DateFormat(
    'yyyy.MM.dd (E) HH:mm',
    AppLanguage.instance.isEnglish ? 'en_US' : 'ko_KR',
  ).format(value.toLocal());
  String _status(GardenEventBooking booking) {
    if (booking.eventUnavailable) return tr("소식이 삭제 또는 정리 중이에요");
    if (booking.session?.state == 'canceled') return tr("운영자가 취소한 일정");
    if (booking.session?.endsAt.isBefore(DateTime.now()) == true) {
      return tr("종료된 일정");
    }
    return tr("신청 완료");
  }

  @override
  Widget build(BuildContext context) {
    final sameOwner = _owner != null && _owner == _service.currentOwner;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(tr("내 신청 내역")),
        actions: [
          IconButton(
            onPressed: _busy || _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: tr("새로고침"),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Text(tr("신청한 모임의 날짜와 상태를 확인할 수 있어요. 시간은 이 기기의 현지 시간으로 표시해요.")),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null) ...[
                Text(_error!),
                TextButton(onPressed: _load, child: Text(tr("다시 확인"))),
              ] else if (sameOwner && _bookings.isEmpty)
                Text(tr("아직 신청한 모임이 없어요."))
              else if (sameOwner)
                for (final booking in _bookings)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            booking.news?.title ?? tr("신청한 모임"),
                            style: titleFont(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            booking.sessionStartsAt == null
                                ? tr("날짜는 정원소식에서 확인해 주세요.")
                                : _date(booking.sessionStartsAt!),
                          ),
                          if (booking.session?.label != null)
                            Text(booking.session!.label!),
                          if (booking.news?.location != null)
                            Text(booking.news!.location!),
                          Text(_status(booking)),
                          if (!booking.eventUnavailable)
                            TextButton(
                              onPressed: _busy ? null : () => _open(booking),
                              child: Text(tr("모임 안내와 접속 링크 보기")),
                            ),
                          OutlinedButton(
                            onPressed: _busy ? null : () => _cancel(booking),
                            child: Text(tr("신청 취소하기")),
                          ),
                        ],
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
