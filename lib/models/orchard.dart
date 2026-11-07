import '../l10n/app_language.dart';

class OrchardKind {
  final String id, _name, _fruit;
  String get name => tr(_name);
  String get fruit => tr(_fruit);
  final int price, sale;
  const OrchardKind(this.id, this._name, this._fruit, this.price, this.sale);
  bool get edible => const ['tuna', 'chicken', 'kibble'].contains(id);
  static const all = [
    OrchardKind('apple', '사과나무', '사과', 0, 5),
    OrchardKind('persimmon', '감나무', '감', 50, 6),
    OrchardKind('tuna', '참치 츄르나무', '참치 간식', 70, 7),
    OrchardKind('chicken', '닭고기 츄르나무', '닭고기 간식', 90, 8),
    OrchardKind('kibble', '고양이 사료나무', '사료 꾸러미', 110, 9),
  ];
  static OrchardKind byId(String id) => all.firstWhere((k) => k.id == id);
}

class OrchardTree {
  final int stage, yieldCount, care, cycle;
  final bool ready, canWater;
  final double progress;
  OrchardTree.fromJson(Map<String, dynamic> j)
    : cycle = j['cycle'] as int,
      stage = j['stage'] as int,
      yieldCount = j['yield'] as int,
      care = j['care'] as int,
      ready = j['ready'] == true,
      canWater = j['canWater'] == true,
      progress = (j['progress'] as num).toDouble();
  String get stageLabel => cycle > 0 && stage < 2
      ? '다음 꽃을 준비해요'
      : const ['묘목', '어린 나무', '꽃 피는 나무', '열매가 자라요', '수확을 기다려요'][stage.clamp(
          0,
          4,
        )];
}

class OrchardState {
  final int coins;
  final Map<String, OrchardTree> trees;
  final Map<String, int> stock;
  final List<Map<String, dynamic>> gifts;
  OrchardState.fromJson(Map<String, dynamic> j)
    : coins = j['coins'] as int,
      trees = (j['trees'] as Map).map(
        (k, v) => MapEntry(
          k as String,
          OrchardTree.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      stock = (j['stock'] as Map).map(
        (k, v) => MapEntry(k as String, v as int),
      ),
      gifts = (j['gifts'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
}
