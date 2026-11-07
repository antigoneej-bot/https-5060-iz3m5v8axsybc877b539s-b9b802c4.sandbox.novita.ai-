import 'package:flutter/material.dart';
import '../models/backup_progress.dart';

class BackupProgressView extends StatelessWidget {
  const BackupProgressView(this.progress, {super.key});
  final BackupProgress progress;
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(progress.message), Text(progress.lastSuccess)],
      ),
    );
  }
}
