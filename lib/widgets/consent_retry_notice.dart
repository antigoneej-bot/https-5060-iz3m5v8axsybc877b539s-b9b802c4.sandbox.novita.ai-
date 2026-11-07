import 'package:flutter/material.dart';
import '../l10n/app_language.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';

const analyticsOptOutMessage =
    '사용 통계 공유를 끄는 중이에요. 앱의 새 이벤트 전송은 중지했지만 기기 설정 적용을 확인하지 못했어요. 다시 시도해 주세요.';
const notificationCancellationMessage =
    '알림 끄기를 선택했어요. 휴대전화의 예약 취소는 아직 확인하지 못해 알림이 올 수 있어요. 다시 시도하거나 휴대전화 설정에서 알림을 꺼 주세요.';

class AnalyticsOptOutNotice extends StatelessWidget {
  const AnalyticsOptOutNotice({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: AnalyticsService.optOutPending,
    builder: (_, pending, __) => pending
        ? _RetryNotice(
            message: analyticsOptOutMessage,
            retry: AnalyticsService().retryOptOut,
          )
        : const SizedBox.shrink(),
  );
}

class NotificationCancellationNotice extends StatelessWidget {
  final NotificationService service;
  final Set<String> kinds;
  const NotificationCancellationNotice({
    super.key,
    required this.service,
    this.kinds = const {'morning', 'evening', 'visit', 'streak'},
  });
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
    valueListenable: service.cancellationPending,
    builder: (_, pending, __) => pending.intersection(kinds).isNotEmpty
        ? _RetryNotice(
            message: notificationCancellationMessage,
            retry: service.retryPendingCancellations,
          )
        : const SizedBox.shrink(),
  );
}

class _RetryNotice extends StatefulWidget {
  final String message;
  final Future<void> Function() retry;
  const _RetryNotice({required this.message, required this.retry});
  @override
  State<_RetryNotice> createState() => _RetryNoticeState();
}

class _RetryNoticeState extends State<_RetryNotice> {
  bool _busy = false;
  Future<void> _retry() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.retry();
    } catch (_) {
      // Keep the outstanding notice; no exception text or success claim.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr(widget.message)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _busy ? null : _retry,
            child: Text(tr('다시 시도')),
          ),
        ),
      ],
    ),
  );
}
