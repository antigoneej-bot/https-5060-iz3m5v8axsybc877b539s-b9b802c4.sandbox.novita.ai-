import 'dart:io';

import 'package:flutter/services.dart';

/// Review-only font input. No machine-specific file is bundled in the app.
Future<void> loadReviewEmojiFont() async {
  final configured = Platform.environment['REVIEW_EMOJI_FONT'];
  final windows = Platform.environment['WINDIR'];
  final candidate =
      configured ??
      (Platform.isWindows && windows != null
          ? '$windows/Fonts/seguiemj.ttf'
          : '${Directory.systemTemp.path}/NotoColorEmoji.ttf');
  final file = File(candidate);
  if (!await file.exists()) {
    throw StateError(
      'Set REVIEW_EMOJI_FONT to an existing emoji font for screenshots.',
    );
  }
  await (FontLoader(
    'NotoColorEmoji',
  )..addFont(file.readAsBytes().then(ByteData.sublistView))).load();
}
