import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/garden_path_card.dart';

/// 개인정보처리방침 · 정신건강 디스클레이머 화면.
/// '힐링 정원' 낮 무드에 맞춰, 딱딱한 법률 문서 느낌보다는 GlassBlob 카드로
/// 섹션을 나눠 부드럽게 읽히도록 구성합니다.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                          '개인정보 · 이용안내',
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
                          const _DisclaimerCard(),
                          const SizedBox(height: 16),
                          _PolicySection(
                            emoji: '🌱',
                            title: '수집하는 정보',
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body:
                                '고양이 그림자 정원은 다음과 같은 정보를 앱 안에서 만들고 저장합니다.\n\n'
                                '· 오늘의 감정 카드 선택 기록, 마음 온도 기록\n'
                                '· 고양이에게 쓴 편지(일기) 내용\n'
                                '· 먹이주기 · 물주기 · 목욕 · 청소 등 돌보기 기록\n'
                                '· 명상 · 내면소통 완료 기록, 연속 방문일, 성장 레벨\n\n'
                                '위 감정 기록과 편지 등 개인화된 콘텐츠는 이용자의 기기 안에만 '
                                '저장되며, 그 내용 자체가 외부 서버로 전송되지는 않습니다.\n\n'
                                '다만, 앱 개선을 위해 어떤 기능을 얼마나 사용했는지에 대한 익명 '
                                '통계(예: 편지 작성 횟수, 명상 완료 횟수 등 이벤트 발생 여부)는 '
                                'Google Firebase Analytics를 통해 집계됩니다. 이 통계에는 '
                                '편지 · 감정 기록의 실제 내용이나 이용자를 특정할 수 있는 정보는 '
                                '포함되지 않습니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🔒',
                            title: '정보 사용 목적과 보관',
                            accent: AppColors.blobLavenderAccent,
                            background: AppColors.blobLavender,
                            body:
                                '수집된 정보는 오직 이용자 본인의 마음챙김 기록을 보여주고, '
                                '고양이 성장 · 마음 리포트 등 앱의 핵심 기능을 제공하기 위한 '
                                '목적으로만 사용됩니다.\n\n'
                                '이용자가 앱을 삭제하거나 기록을 직접 삭제하면 해당 정보도 함께 '
                                '삭제됩니다. 저희는 이용자의 감정 기록이나 편지 내용을 광고, '
                                '마케팅 등 다른 목적으로 이용하거나 제3자에게 제공하지 않습니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🤝',
                            title: '제3자 제공',
                            accent: AppColors.blobRoseAccent,
                            background: AppColors.blobRose,
                            body:
                                '저희는 법령에 따라 요구되는 경우를 제외하고, 이용자의 감정 기록, '
                                '편지 등 개인화된 콘텐츠를 제3자에게 제공하지 않습니다.\n\n'
                                '단, 앱 사용 통계 수집을 위해 Google Firebase Analytics를 '
                                '이용하고 있으며, 익명화된 이벤트 통계(기능 사용 여부 등)가 이 '
                                '서비스로 전달됩니다. 향후 클라우드 로그인/백업 기능이 추가될 '
                                '경우, 관련 내용을 이 화면에서 다시 안내드리겠습니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '✉️',
                            title: '문의',
                            accent: AppColors.blobButterAccent,
                            background: AppColors.blobButter,
                            body:
                                '개인정보 처리와 관련해 궁금한 점이 있으시면 아래 이메일로 '
                                '문의해 주세요.\n\nhello@catshadowgarden.com',
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

/// 정신건강 관련 중요 안내를 가장 눈에 잘 띄는 위치(최상단)에 강조해서 보여줍니다.
class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobRoseAccent,
      background: AppColors.blobRose,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💛', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '꼭 읽어주세요 · 정신건강 안내',
                  style: pathLabelFont(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '고양이 그림자 정원은 감정을 돌아보고 작은 실천으로 마음을 돌보는 것을 '
            '돕는 자기돌봄(self-care) 및 마음챙김 보조 앱입니다.\n\n'
            '이 앱은 의료 서비스가 아니며, 전문적인 진단·치료·상담을 대체할 수 없습니다. '
            '앱에서 제공하는 감정 기록, 명상, 조언은 정서적 참고 자료일 뿐 의학적 '
            '조언이 아닙니다.\n\n'
            '만약 지속적으로 힘든 감정이 계속되거나, 스스로 또는 타인을 해치고 싶은 '
            '생각이 든다면 반드시 정신건강 전문가, 의료기관 또는 아래의 상담 기관에 '
            '도움을 요청해 주세요.\n\n'
            '· 자살예방상담전화 1393 (24시간)\n'
            '· 정신건강상담전화 1577-0199 (24시간)\n'
            '· 청소년상담전화 1388',
            style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.7),
          ),
        ],
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
