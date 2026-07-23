import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/garden_path_card.dart';

/// 이용약관 화면.
/// '힐링 정원' 낮 무드에 맞춰, 딱딱한 법률 문서 느낌보다는 GlassBlob 카드로
/// 섹션을 나눠 부드럽게 읽히도록 구성합니다. (개인정보처리방침 화면과 동일한
/// 톤 앤 매너를 유지합니다.)
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GardenScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.ink,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '이용약관',
                          style: titleFont(
                            fontSize: 20,
                            color: AppColors.titlePastelGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PolicySection(
                            emoji: '📜',
                            title: '제1조 (목적)',
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body:
                                '이 약관은 고양이 그림자 정원(이하 "앱")을 이용함에 있어 이용자와 '
                                '앱 운영자 사이의 권리, 의무 및 책임사항, 이용 조건 및 절차 등 '
                                '기본적인 사항을 규정하는 것을 목적으로 합니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🌱',
                            title: '제2조 (서비스의 성격)',
                            accent: AppColors.blobLavenderAccent,
                            background: AppColors.blobLavender,
                            body:
                                '앱은 감정을 돌아보고 작은 실천으로 마음을 돌보는 것을 돕는 자기돌봄'
                                '(self-care) 및 마음챙김 보조 도구입니다.\n\n'
                                '앱은 의료 서비스가 아니며, 전문적인 진단·치료·상담을 대체하지 '
                                '않습니다. 앱이 제공하는 감정 기록, 명상, 조언, 고양이 캐릭터의 '
                                '메시지 등은 정서적 참고 자료일 뿐 의학적 조언으로 간주되지 '
                                '않습니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🐾',
                            title: '제3조 (이용자의 의무)',
                            accent: AppColors.blobRoseAccent,
                            background: AppColors.blobRose,
                            body:
                                '이용자는 다음 각 호의 행위를 하지 않아야 합니다.\n\n'
                                '· 앱의 정상적인 운영을 방해하는 행위\n'
                                '· 타인의 개인정보를 무단으로 수집·저장하는 행위\n'
                                '· 관계 법령 또는 이 약관에서 금지하는 행위\n\n'
                                '이용자는 본인의 기기 및 계정 관리에 책임이 있으며, 이로 인해 '
                                '발생하는 문제에 대해 앱 운영자는 책임을 지지 않습니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '💳',
                            title: '제4조 (유료 서비스)',
                            accent: AppColors.blobButterAccent,
                            background: AppColors.blobButter,
                            body:
                                '앱은 일부 기능을 유료 구독(프리미엄) 형태로 제공할 수 있습니다. '
                                '유료 서비스의 구체적인 가격, 결제 방법, 환불 정책은 앱 내 결제 '
                                '화면 및 이용하시는 앱 마켓(Google Play 등)의 정책에 따릅니다.\n\n'
                                '유료 서비스가 실제로 제공되기 전까지, 관련 화면에는 정확한 '
                                '이용 가능 여부가 안내됩니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🔧',
                            title: '제5조 (서비스의 변경 및 중단)',
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body:
                                '앱 운영자는 서비스의 내용, 운영상 또는 기술상 필요에 따라 제공 '
                                '중인 서비스의 전부 또는 일부를 변경하거나 중단할 수 있으며, 이 '
                                '경우 앱 내 공지 등을 통해 이용자에게 사전에 안내합니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🙅',
                            title: '제6조 (면책 조항)',
                            accent: AppColors.blobLavenderAccent,
                            background: AppColors.blobLavender,
                            body:
                                '앱 운영자는 천재지변, 이용자의 귀책사유 등 불가항력적인 사유로 '
                                '서비스를 제공할 수 없는 경우 책임이 면제됩니다.\n\n'
                                '앱을 통해 얻은 정서적 조언이나 기록은 참고 자료이며, 이를 근거로 '
                                '한 이용자의 판단과 행동에 대해 앱 운영자는 법적 책임을 지지 '
                                '않습니다. 위급한 상황에는 반드시 전문가 또는 관련 기관(하단 '
                                '참고)의 도움을 받으시기 바랍니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '✉️',
                            title: '제7조 (문의)',
                            accent: AppColors.blobRoseAccent,
                            background: AppColors.blobRose,
                            body:
                                '이 약관과 관련해 궁금한 점이 있으시면 마이 탭의 문의하기 기능을 '
                                '이용해 주세요.',
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: Text(
                              '시행일: 2025년 1월 1일',
                              style: bodyFont(
                                fontSize: 11,
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String emoji;
  final String title;
  final Color accent;
  final Color background;
  final String body;
  const _PolicySection({
    required this.emoji,
    required this.title,
    required this.accent,
    required this.background,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: accent,
      background: background,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Text(
                title,
                style: pathLabelFont(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: bodyFont(
              fontSize: 12.5,
              color: AppColors.moon,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
