import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

/// (관리자 전용) 특정 정원소식의 신청자 목록 화면.
///
/// 이름/연락처 등은 애초에 수집하지 않으므로 보여줄 수 없다 - 신청 시
/// 로그인 계정의 인증된 이메일과, 사용자가 남긴 선택적 한줄 메모만 있다.
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
          '신청자 목록',
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
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
              '아직 신청자가 없어요.',
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
                r['email']?.toString() ?? '(이메일 없음)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.ink,
                ),
              ),
              if (r['note'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  r['note'].toString(),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
