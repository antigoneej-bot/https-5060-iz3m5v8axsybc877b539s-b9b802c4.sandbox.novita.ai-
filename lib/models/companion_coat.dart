/// Free appearance choices; independent of emotion-card collection and purchases.
enum CompanionCoat {
  ginger('치즈태비', 0xFFFFE9C7),
  white('흰고양이', 0xFFFFE3EC),
  tabby('고등어태비', 0xFFE2EFDA),
  black('검정고양이', 0xFFECE1FA),
  tuxedo('턱시도 고양이', 0xFFDDEFFA),
  calico('삼색 고양이', 0xFFFFF1BF);

  const CompanionCoat(this.label, this.color);
  final String label;
  final int color;
  static CompanionCoat? parse(Object? id) {
    for (final coat in values) {
      if (coat.name == id) return coat;
    }
    return null;
  }
}
