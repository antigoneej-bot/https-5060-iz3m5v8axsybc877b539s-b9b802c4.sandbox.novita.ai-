import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../screens/premium_screen.dart';

Future<bool> requestSubscription(
  BuildContext context, {
  String? message,
}) async {
  if (await SubscriptionService().isPremium()) return true;
  if (!context.mounted) return false;
  if (message != null) {
    final open = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('마음냥 구독'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('계속 무료로 이용'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('구독 알아보기'),
          ),
        ],
      ),
    );
    if (open != true || !context.mounted) return false;
  }
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
  return SubscriptionService().isPremium();
}

class SubscriptionNotice extends StatelessWidget {
  final String message;
  final VoidCallback? onReturn;
  const SubscriptionNotice({super.key, required this.message, this.onReturn});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline),
          const SizedBox(height: 8),
          Text(message),
          TextButton(
            onPressed: () async {
              await requestSubscription(context);
              if (context.mounted) onReturn?.call();
            },
            child: const Text('마음냥 구독 알아보기'),
          ),
        ],
      ),
    ),
  );
}

/// Builds protected content only after entitlement is checked; raw records are
/// never removed. Rechecks after returning from the common subscription screen.
class SubscriptionGate extends StatefulWidget {
  final WidgetBuilder builder;
  final String message;
  final bool free;
  const SubscriptionGate({
    super.key,
    required this.builder,
    required this.message,
    this.free = false,
  });
  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  late Future<bool> _access;
  @override
  void initState() {
    super.initState();
    _access = SubscriptionService().isPremium();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.free) return widget.builder(context);
    return FutureBuilder<bool>(
      future: _access,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data == true) return widget.builder(context);
        return SubscriptionNotice(
          message: widget.message,
          onReturn: () =>
              setState(() => _access = SubscriptionService().isPremium()),
        );
      },
    );
  }
}
