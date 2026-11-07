import 'package:flutter/material.dart';
import '../../l10n/app_language.dart';

/// A display of the existing saved balance, never a separate currency store.
class GardenEssenceChip extends StatelessWidget {
  const GardenEssenceChip({super.key, required this.amount});
  final int amount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xF5FFFDF5),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE9DABF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.auto_awesome, color: Color(0xFFD5A740), size: 18),
        const SizedBox(width: 4),
        Text(
          tr('빛의 정수 {0}', [amount]),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
