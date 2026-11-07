import 'package:flutter/material.dart';
import '../l10n/app_language.dart';

/// A failed provider load must keep the existing records and offer a retry.
class RecordLoadFailure extends StatelessWidget {
  const RecordLoadFailure({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('기록을 불러오지 못했어요. 기록을 삭제하지 않고 다시 시도할 수 있어요.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(tr('다시 불러오기'))),
            ],
          ),
        ),
      ),
    ),
  );
}
