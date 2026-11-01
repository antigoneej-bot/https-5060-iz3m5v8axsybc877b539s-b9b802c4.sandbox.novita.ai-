import 'package:flutter/material.dart';
import 'meditation_library_screen.dart';
import 'coloring_healing_screen.dart';
import 'self_care_screen.dart';
import '../widgets/healing_activities.dart';

class MindCareHub extends StatefulWidget {
  const MindCareHub({super.key});
  @override
  State<MindCareHub> createState() => _MindCareHubState();
}

class _MindCareHubState extends State<MindCareHub> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        '명상 · 힐링',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('호흡·명상'),
            selected: selected == 0,
            onSelected: (_) => setState(() => selected = 0),
          ),
          ChoiceChip(
            label: const Text('소리·휴식'),
            selected: selected == 1,
            onSelected: (_) => setState(() => selected = 1),
          ),
        ],
      ),
      Card(
        color: const Color(0xFFFFE6D7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: const Text('🎨', style: TextStyle(fontSize: 32)),
          title: const Text('색칠 힐링'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ColoringHealingScreen()),
          ),
        ),
      ),
      const HealingActivities(),
      TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SelfCareScreen()),
        ),
        child: const Text('나의 마음 돌봄 기록'),
      ),
      MeditationLibraryScreen(
        key: ValueKey(selected),
        initialVoice: selected == 1 ? 'silent' : 'all',
      ),
    ],
  );
}
