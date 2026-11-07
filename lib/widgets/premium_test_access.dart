import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../utils/feature_flags.dart';

/// Product classification is separate from the temporary QA entitlement.
class MembershipFeatures {
  static List<String> get free => [
    tr("37마리 감정 고양이·감정 기록·기본 마음돌보기"),
    tr("추억 카드 수집·교환·진열"),
    tr("기존 기본 고양이와 움직임·교감"),
  ];
  static List<String> get subscriber => [
    tr("동반 고양이 외형 6종 선택·변경"),
    tr("고양이 성장과 새 아기 고양이 가족"),
    tr("열매 나무 5종 재배·수확·판매·선물"),
    tr("기억의 씨앗 6종 심기·보석나무 성장"),
  ];
  static String get testLabel => tr("테스트 모드 · 구독 기능 개방 중");
}

class PremiumTestFrame extends StatelessWidget {
  final Widget child;
  const PremiumTestFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.debugUnlockAllPremium) return child;
    return Column(
      children: [
        Material(
          color: const Color(0xffe7efe2),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.science_outlined, size: 17),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      MembershipFeatures.testLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class PremiumFeatureLabel extends StatelessWidget {
  final String label;
  const PremiumFeatureLabel(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      tr("{0} · 구독 기능{1}", [
        label,
        FeatureFlags.debugUnlockAllPremium ? tr(" · 테스트 개방 중") : '',
      ]),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xff795c91),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class MembershipTestScreen extends StatelessWidget {
  const MembershipTestScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr("무료·구독 기능 안내"))),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              tr(
                "지금은 테스트 기간이에요.\n구현된 구독 기능은 결제 없이 체험할 수 있어요. 실제 유료 구독에 가입된 상태는 아니에요.",
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tr("무료 이용"),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        for (final s in MembershipFeatures.free)
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(s),
          ),
        const SizedBox(height: 16),
        Text(
          tr("구독 혜택 · 테스트에서는 개방"),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        for (final s in MembershipFeatures.subscriber)
          ListTile(leading: const Icon(Icons.stars_outlined), title: Text(s)),
        const SizedBox(height: 16),
        Text(
          tr(
            "하루 첫 고양이 인사로 출석 보상을 받아요. 씨앗은 심기에, 빛의 정수는 정원 아이템에, 돌봄 포인트는 돌봄 상점에 사용해요. 이웃 기능에는 로그인과 연결이 필요해요.",
          ),
        ),
      ],
    ),
  );
}
