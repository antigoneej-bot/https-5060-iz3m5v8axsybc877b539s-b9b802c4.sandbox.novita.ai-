import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

/// User-initiated navigation only. No score, diary, GPS or contact form is sent.
/// Official directory checked 2026-10-13. Maps are search, not vetted partners.
class CareConnectionScreen extends StatelessWidget {
  const CareConnectionScreen({super.key});
  static const officialDirectory =
      'https://www.mentalhealth.go.kr/portal/health/fac/PotalHealthFacListTab1.do';

  static Uri mapSearch(String category) => Uri.https(
    'www.google.com',
    '/maps/search/',
    {'api': '1', 'query': category},
  );

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(
        uri,
        mode: uri.scheme == 'https'
            ? LaunchMode.externalApplication
            : LaunchMode.platformDefault,
      ))
        return;
    } catch (_) {
      /* Show a usable address/number when no handler is available. */
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('직접 열 수 있는 주소'),
        content: SelectableText(
          uri.scheme == 'tel' ? uri.path : uri.toString(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    String button,
    Uri uri,
  ) => Card(
    elevation: 0,
    color: AppColors.blobMint,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, color: AppColors.titlePastelGreen, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(description),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _open(context, uri),
            child: Text(button),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg0,
    appBar: AppBar(title: const Text('원할 때, 사람과 연결')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '혼자 돌아보는 것만으로 충분하지 않을 때',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              const Text(
                '어떤 도움을 받을지는 내가 선택해요. 점수와 관계없이 이용할 수 있어요.\n일상생활이 어려울 만큼 힘든 상태가 계속된다면 전문기관에 상담을 요청할 수 있어요.',
              ),
              const SizedBox(height: 20),
              _option(
                context,
                Icons.support_agent,
                '지역 정신건강복지센터',
                '공식 기관 정보를 확인하고 상담 방법을 문의할 수 있어요. 정신건강사회복지사 등 전문요원과의 상담·생활 지원이 가능한지 기관에 물어보세요. 운영시간과 이용 대상은 기관마다 달라요.',
                '공식 기관 안내 열기',
                Uri.parse(officialDirectory),
              ),
              _option(
                context,
                Icons.chat_bubble_outline,
                '심리상담센터',
                '내 이야기를 전문 상담자와 나누고 싶을 때 찾아볼 수 있어요. 예약 전에 상담자의 자격·경력, 상담 분야, 비용과 취소 규정을 확인해 주세요.',
                '지도에서 심리상담센터 검색',
                mapSearch('심리상담센터'),
              ),
              _option(
                context,
                Icons.spa_outlined,
                '명상센터 · 마음챙김 모임',
                '명상이나 쉼을 함께 경험하고 싶을 때 찾아볼 수 있어요. 진행자, 프로그램, 참가 비용을 확인하고 나에게 불편한 활동은 중단할 수 있어요. 명상 프로그램은 전문 진료를 대신하지 않아요.',
                '지도에서 명상센터 검색',
                mapSearch('명상센터'),
              ),
              const Text(
                '현재는 기관 정보와 지도 검색을 연결해요. 마음냥의 제휴·자격 검증·예약 확정을 뜻하지 않아요. 신청과 예약은 해당 기관에서 직접 진행해 주세요.',
                style: TextStyle(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 12),
              const Text(
                '기관에 마음 기록을 자동으로 보내지 않아요. 외부 사이트를 열면 해당 서비스의 개인정보처리방침이 적용돼요. 지도에는 기관 종류만 검색어로 전달돼요.',
                style: TextStyle(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const Text(
                '지금 안전이 걱정된다면 · 대한민국',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                '자살 생각으로 힘들 때는 24시간 상담전화 109를 이용할 수 있어요. 즉각적인 위험이나 응급상황에는 112·119에 연락해 주세요.',
              ),
              Wrap(
                spacing: 10,
                children: [
                  for (final number in ['109', '112', '119'])
                    OutlinedButton.icon(
                      onPressed: () =>
                          _open(context, Uri(scheme: 'tel', path: number)),
                      icon: const Icon(Icons.phone_outlined),
                      label: Text('$number 전화'),
                    ),
                ],
              ),
              TextButton(
                onPressed: () =>
                    _open(context, Uri.parse('https://findahelpline.com')),
                child: const Text('대한민국 밖에서 도움 찾기'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
