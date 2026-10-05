import '../lib/utils/companion_name.dart';

void main() {
  final cases = <String, String>{
    companionCopy('몽이가 몽이를 몽이는 몽이와 몽이의 집', '구름'): '구름이 구름을 구름은 구름과 구름의 집',
    companionCopy('몽이가 몽이를 몽이는 몽이와', '보리'): '보리가 보리를 보리는 보리와',
    companionCopy('몽이가', '  '): '고양이가',
    companionCopy("Mongi's garden", 'Nabi'): "Nabi's garden",
    companionCopy('몽이가', '몽이가'): '몽이가가',
  };
  for (final entry in cases.entries) {
    if (entry.key != entry.value)
      throw StateError('${entry.key} != ${entry.value}');
  }
  if (companionDisplayName('  보리  ') != '보리') throw StateError('trim');
  print('6 name/fallback/particle cases passed');
}
