import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/cloud_service.dart';
import 'my_garden_reservations_screen.dart';

/// Server history keeps a canceled/deleted event identifiable after its booking
/// disappears. All reads are scoped to the currently signed-in account.
class GardenUpdatesScreen extends StatefulWidget {
  const GardenUpdatesScreen({super.key});
  @override
  State<GardenUpdatesScreen> createState() => _GardenUpdatesScreenState();
}

class _GardenUpdatesScreenState extends State<GardenUpdatesScreen> {
  late final String? _owner = CloudService.currentUser?.uid;
  List<Map> _updates = [];
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_owner == null || CloudService.currentUser?.uid != _owner)
        throw const CloudException('authentication-required');
      final result = await CloudService.call('listGardenUpdates', {}, _owner);
      if (!mounted || CloudService.currentUser?.uid != _owner) return;
      setState(
        () => _updates = (result['updates'] as List? ?? [])
            .whereType<Map>()
            .toList(),
      );
    } catch (_) {
      if (mounted)
        setState(() => _error = '변경 소식을 확인하지 못했어요. 로그인과 연결을 확인한 뒤 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('예약 변경 소식')),
    body: StreamBuilder(
      stream: CloudService.enabled
          ? FirebaseAuth.instance.authStateChanges()
          : null,
      builder: (context, _) {
        final same = _owner != null && _owner == CloudService.currentUser?.uid;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('최근 30일의 모임 변경·취소 안내예요.'),
            FilledButton.tonal(
              onPressed: !same
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyGardenReservationsScreen(),
                      ),
                    ),
              child: const Text('내 신청 내역 보기'),
            ),
            if (_busy) const LinearProgressIndicator(),
            if (!same)
              const Text('로그인한 계정을 확인해 주세요.')
            else ...[
              if (_error != null) Text(_error!),
              if (!_busy && _error == null && _updates.isEmpty)
                const Text('새로운 변경 소식이 없어요.'),
              for (final row in _updates)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row['title']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (DateTime.tryParse('${row['sessionStartsAt']}')
                            case final DateTime date)
                          Text(
                            '예약 일정 · ${date.toLocal().toString().substring(0, 16)}',
                          ),
                        Text('${row['notice']}'),
                      ],
                    ),
                  ),
                ),
            ],
            TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('다시 확인'),
            ),
          ],
        );
      },
    ),
  );
}
