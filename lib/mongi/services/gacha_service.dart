import 'dart:math';

import '../models/mongi_costume.dart';

/// "마음 상자" 가챠 뽑기 결과. B2(순차 보장형) 방식에서는 항상 "새로 얻은
/// 코스튬"만 나오므로(중복/꽝 없음), 담을 정보는 어떤 코스튬을 얻었는지뿐이다.
class GachaPullResult {
  final MongiCostume costume;

  const GachaPullResult({required this.costume});
}

/// "마음 상자" 가챠의 뽑기 로직을 담당하는 순수 로직 서비스.
///
/// 예전에는 등급별 확률 + 천장(pity) 시스템으로 동작했지만, 확률형 보상은
/// 가변비율 강화(variable-ratio reward) — 슬롯머신이 쓰는 것과 같은 중독
/// 유발 기제 — 라는 문제가 있어 완전히 제거했다. 대신 "열 때마다 순서는
/// 무작위지만, 반드시 아직 없는 새 선물만 확정 지급"하는 방식(B2)으로 바꿔,
/// "무엇이 나올지 모르는" 즐거움은 남기면서 확률/도박 요소는 없앴다.
class GachaService {
  /// 1회 뽑기 비용 (빛의 정수). 10개를 한꺼번에 열어도 할인 없이 이 값의
  /// 정수배로만 계산한다 - "묶음 구매가 이득"이라는 확률형 F2P 심리를
  /// 자극하는 대신, 그냥 여러 번 열기의 편의만 제공한다.
  static const int singlePullCost = 30;

  /// 한 번에 열 수 있는 최대 개수(편의 기능으로서의 "묶음 열기").
  static const int maxBulkOpenCount = 10;

  /// 실제 뽑기가 이 서비스의 핵심 역할이다: [excludeIds]에 없는 코스튬 중에서
  /// 무작위로 하나를 골라 반환한다. 이미 다 모았다면(고를 게 없으면) null.
  static MongiCostume? pickUnownedCostume(Set<String> excludeIds) {
    final pool = MongiCostume.gachaPool
        .where((c) => !excludeIds.contains(c.id))
        .toList();
    if (pool.isEmpty) return null;
    return pool[Random().nextInt(pool.length)];
  }
}
