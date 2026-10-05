import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cat_care_provider.dart';

Future<void> editCompanionName(BuildContext context) async {
  final care = context.read<CatCareProvider>();
  final controller = TextEditingController(text: care.companionName ?? '');
  final value = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('고양이 이름'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 16,
        decoration: const InputDecoration(
          hintText: '어떤 이름으로 불러줄까요?',
          helperText: '비워 두면 고양이로 표시해요.',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('저장'),
        ),
      ],
    ),
  );
  // The route keeps its TextField during the closing animation.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  controller.dispose();
  if (value == null || !context.mounted) return;
  try {
    await care.renameCompanion(value);
  } catch (_) {
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 저장하지 못했어요. 다시 시도해 주세요.')),
      );
  }
}
