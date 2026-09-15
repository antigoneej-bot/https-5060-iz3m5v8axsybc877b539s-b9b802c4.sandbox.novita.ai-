/// "빛의 정수 충전" - 실제 결제(원화)로 소프트 화폐(빛의 정수)를 직접 채워주는
/// 소모성(consumable) 인앱 상품.
///
/// 지금까지의 다른 상품(프리미엄 프레임/정원 장식팩/시즌 패스)은 전부
/// "관리형(비소모성) 코스메틱"이었지만, 이 팩은 게임 플레이로 자연스럽게
/// 벌 수 있는 빛의 정수를 "지금 당장 더 많이 갖고 싶을 때" 직접 채워주는
/// 용도다. 강제성은 없다 - 안 사도 세션을 플레이하면 계속 모을 수 있고,
/// 이 팩은 그 과정을 앞당기고 싶을 때만 쓰는 선택지일 뿐이다.
///
/// Play Console(수익 창출 > 인앱 상품)에 아래 [productId]와 완전히 동일한
/// 문자열로 "소모성(consumable)" 상품을 등록해야 하고, 가격도 원화 기준으로
/// 아래 [priceKrw]와 맞춰서 등록해야 한다 (Play Console 가격이 최종 기준이며,
/// 여기 [priceKrw]는 상품 정보를 불러오기 전에도 화면에 보여줄 표시용 값이다).
class LightEssencePack {
  final String productId;
  final String label;
  final int amount;
  final int priceKrw;

  const LightEssencePack({
    required this.productId,
    required this.label,
    required this.amount,
    required this.priceKrw,
  });

  /// 100 빛의 정수당 가격(원) - 팩 간 "어느 쪽이 더 이득인지"를 화면에
  /// 보여주기 위한 단가 계산. 대량 팩일수록 이 값이 낮아지도록 가격을
  /// 설계했다(가치 앵커링 - 카운트다운/긴급성 문구 없이도 "큰 걸 사는 게
  /// 이득"이라는 합리적 이유만으로 구매 동기를 만든다).
  double get pricePer100 => priceKrw / amount * 100;

  static const List<LightEssencePack> all = [
    LightEssencePack(
      productId: 'light_essence_100',
      label: '작은 빛 주머니',
      amount: 100,
      priceKrw: 5000,
    ),
    LightEssencePack(
      productId: 'light_essence_1000',
      label: '커다란 빛 항아리',
      amount: 1000,
      priceKrw: 10000,
    ),
  ];

  static LightEssencePack byProductId(String id) =>
      all.firstWhere((p) => p.productId == id, orElse: () => all.first);
}
