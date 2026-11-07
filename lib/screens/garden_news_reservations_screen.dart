import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../models/notice.dart';
import 'package:intl/intl.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

/// (관리자 전용) 특정 정원소식의 신청자 목록 화면.
///
/// 신청자가 직접 입력한 이름·요청과 계정의 검증된 이메일만 운영자에게 보여준다.
class GardenNewsReservationsScreen extends StatefulWidget {
  final Notice news;
  const GardenNewsReservationsScreen({super.key, required this.news});

  @override
  State<GardenNewsReservationsScreen> createState() =>
      _GardenNewsReservationsScreenState();
}

class _GardenNewsReservationsScreenState
    extends State<GardenNewsReservationsScreen> {
  List<Map<String, dynamic>>? _reservations;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final result = await CloudService.adminListGardenNewsReservations(
        widget.news.id,
      );
      if (mounted) setState(() => _reservations = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        title: Text(
          tr("신청자 목록"),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
      ),
    );
  }

  String _sessionDate(dynamic value) {
    final date = DateTime.tryParse(value.toString());
    return date == null
        ? tr("날짜 확인 필요")
        : DateFormat('yyyy.MM.dd HH:mm').format(date.toLocal());
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Center(
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ),
        ],
      );
    }
    if (_reservations == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reservations!.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          Center(
            child: Text(
              tr("아직 신청자가 없어요."),
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: _reservations!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = _reservations![index];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r['displayName']?.toString().isNotEmpty == true
                    ? r['displayName'].toString()
                    : r['email']?.toString() ?? tr("신청자 {0}", [index + 1]),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.ink,
                ),
              ),
              if (r['sessionStartsAt'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  tr("신청 일정: {0}", [_sessionDate(r['sessionStartsAt'])]),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
              if (r['email'] != null && r['displayName'] != null) ...[
                const SizedBox(height: 4),
                Text(r['email'].toString()),
              ],
              if (r['note'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  r['note'].toString(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
