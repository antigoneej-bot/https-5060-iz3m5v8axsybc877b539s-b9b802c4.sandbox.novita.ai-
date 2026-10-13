import 'package:flutter/material.dart';

/// Three stable, readable entry points. No autoplay scene on the home screen.
class HomeCoreActions extends StatelessWidget {
  final VoidCallback onWrite;
  final VoidCallback onGarden;
  final VoidCallback onReflect;
  const HomeCoreActions({
    super.key,
    required this.onWrite,
    required this.onGarden,
    required this.onReflect,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        '지금 필요한 곳으로 가요',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      const Text('한 줄을 남겨도, 잠깐 쉬어가도 괜찮아요.'),
      const SizedBox(height: 16),
      _action(
        'home-write',
        Icons.edit_outlined,
        '마음 남기기',
        '고양이에게 오늘의 마음을 들려줘요',
        const Color(0xFFF6E8DD),
        onWrite,
      ),
      _action(
        'home-garden',
        Icons.park_outlined,
        '내 정원',
        '함께한 시간과 나무를 만나러 가요',
        const Color(0xFFE5EFE2),
        onGarden,
      ),
      _action(
        'home-reflect',
        Icons.history,
        '지난 마음 돌아보기',
        '기록을 살펴보고 작은 돌봄을 이어가요',
        const Color(0xFFEAE8F1),
        onReflect,
      ),
    ],
  );
  Widget _action(
    String id,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback tap,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: color,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      key: ValueKey(id),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Icon(icon, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: tap,
    ),
  );
}
