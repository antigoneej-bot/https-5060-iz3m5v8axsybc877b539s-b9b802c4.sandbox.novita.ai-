import 'package:flutter/material.dart';

/// Shown after a backup/legacy-record restore succeeds on disk. The app must
/// still reload its in-memory caches before the restored data is visible —
/// this dialog drives that reload and, if it fails, offers a safe retry
/// instead of a sentence telling the user to force-quit. [PopScope.canPop]
/// is false so the user cannot dismiss this screen while the in-memory state
/// is still stale: the only ways out are a successful reload (which replaces
/// this dialog's route) or a retry attempt.
class RestoreCompleteDialog extends StatefulWidget {
  final String title;
  final int added;
  final Future<void> Function() reload;
  const RestoreCompleteDialog({
    super.key,
    required this.title,
    required this.added,
    required this.reload,
  });

  @override
  State<RestoreCompleteDialog> createState() => _RestoreCompleteDialogState();
}

class _RestoreCompleteDialogState extends State<RestoreCompleteDialog> {
  bool _opening = false;
  bool _failed = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _failed = false;
    });
    try {
      await widget.reload();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: AlertDialog(
      title: Text(widget.title),
      content: Text(
        '${widget.added}개 항목을 추가했어요. 같은 ID는 현재 기록을 유지했어요.\n\n'
        '${_failed ? '기록은 복원했지만 화면을 새로 열지 못했어요. 다시 시도해 주세요.' : '복원한 기록을 반영해 정원을 다시 열어요.'}',
      ),
      actions: [
        FilledButton(
          onPressed: _opening ? null : _open,
          child: Text(
            _opening
                ? '정원을 여는 중…'
                : _failed
                ? '다시 열기'
                : '복원한 정원 열기',
          ),
        ),
      ],
    ),
  );
}
