import 'package:flutter/material.dart';
import 'meditation_library_screen.dart';

/// All meditation entry points share the existing library and its filters.
/// Other healing activities remain on the main Healing page.
class MindCareHub extends StatelessWidget {
  const MindCareHub({super.key});
  @override
  Widget build(BuildContext context) => const MeditationLibraryScreen();
}
