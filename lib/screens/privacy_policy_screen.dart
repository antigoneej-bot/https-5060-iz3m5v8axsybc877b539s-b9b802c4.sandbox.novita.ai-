import '../services/cloud_service.dart';
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
                                '마음냥 정원은 다음과 같은 정보를 앱 안에서 만들고 저장합니다.\n\n'
                                '· 오늘의 감정 카드 선택 기록, 마음 온도 기록\n'
                                '· 고양이에게 쓴 편지(일기) 내용\n'
                                '· 먹이주기 · 물주기 · 목욕 · 청소 등 돌보기 기록\n'
                                '· 명상 · 내면소통 완료 기록, 연속 방문일, 성장 레벨\n\n'
                                '기록과 초안은 기기에 저장하며 암호화를 적용합니다. 파일 백업을 선택하면 사용자가 지정한 위치에 암호화 파일을 저장합니다.\n\n'
                                '${CloudService.enabled ? '서버 백업을 직접 켜면 정원 기록·초안·답장이 백업 암호로 암호화되어 서버로 전송됩니다. 로그인 이메일과 계정 식별자, 구매 토큰과 구독 상태도 계정·결제 기능에 사용됩니다.' : '서버 백업은 연결 준비 후 이용할 수 있습니다.'}\n\n'
                                '간편 로그인에는 Firebase Authentication을 사용합니다. 구글 로그인을 선택하면 Firebase가 제공받는 계정 식별자·이름·이메일·프로필 정보가 인증에 사용될 수 있습니다. 카카오·네이버·페이스북 로그인은 서버에서 제공사 계정 ID를 확인하고 해시 처리한 연결 식별자와 Firebase 계정 식별자를 보관합니다. 이 세 방식은 이메일·친구 목록·게시물·일기 내용을 요청하지 않습니다. 로그인 세션은 짧은 유효기간과 일회용 확인 절차로 보호합니다.\n\n'
                                '사용 통계 공유는 기본으로 꺼져 있으며 기록 보관과 백업에서 선택할 수 있습니다. 켜면 기능 이용 이벤트와 제한된 항목을 Firebase Analytics에 보냅니다. 일기 본문·선택한 감정은 보내지 않습니다. Firebase SDK는 앱 인스턴스 식별자·기기 및 앱 정보를 처리할 수 있으므로 완전히 익명인 통계라고 보장하지 않습니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🔒',
                            title: '정보 사용 목적과 보관',
                            accent: AppColors.blobLavenderAccent,
                            background: AppColors.blobLavender,
                            body:
                                '수집된 정보는 이용자 본인의 마음챙김 기록을 보여주고, '
                                '고양이 성장 · 마음 리포트 · 직접 선택한 이웃 교류 등 앱의 핵심 기능을 제공하기 위한 '
                                '목적으로만 사용됩니다.\n\n'
                                '편지를 삭제하면 해당 본문은 기록 목록에서 사라집니다. 나무의 성장을 유지하고 같은 날 중복 성장을 막기 위한 기록 날짜는 정원 성장 정보에 남습니다. 이 날짜와 편지 본문은 공개 정원에 표시하지 않습니다.\n\n'
                                '앱 삭제는 기기 기록에 영향을 줍니다. 별도로 내보낸 파일이나 서버 백업까지 삭제되지는 않습니다. 기록 하나를 지워도 이전 백업에는 남을 수 있습니다.\n\n'
                                '${CloudService.enabled ? '서버는 최근 10개 백업을 보관하며 구독 종료 후에도 기존 백업 복원을 허용합니다. 서버 계정과 백업 삭제는 기록 보관과 백업에서 요청할 수 있습니다. 중복 구매 연결을 막기 위한 구매 토큰의 해시 표식은 원문 토큰·계정 식별자 없이 남습니다.' : '내보낸 백업 파일은 저장한 위치에서 직접 관리·삭제해 주세요.'}\n\n'
                                '백업 암호는 서버로 보내지 않으며, 자동 백업을 켠 경우 기기 보안 저장소에 보관합니다. 암호를 잊으면 새 기기에서 복원할 수 없습니다. 한 기기에는 하나의 정원이 저장되며 로그아웃으로 기기 기록이 지워지지 않습니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🏡',
                            title: '냥이 마을 · 이웃과 나누는 정보',
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body:
                                '온라인 이웃 기능을 이용하면 계정 식별자, 정원 닉네임, 초대 코드, 공개 범위, 이웃 신청·수락 관계, 차단 설정을 서버에 저장합니다. 초대 코드를 가진 사람은 닉네임을 확인하고 이웃 신청을 보낼 수 있으며, 신청을 수락해야 이웃으로 연결됩니다.\n\n'
                                '정원은 나만 보기 · 이웃에게 공개 · 모두에게 공개 중 선택할 수 있습니다. 정원 둘러보기 목록에는 모두에게 공개하고 목록 노출에도 동의한 정원만 나타납니다. 공개하는 정원 모습에는 씨앗 수, 장식, 나무 성장 단계와 배치 등이 포함되며, 편지 본문·감정 통계·개인 기록 날짜는 포함하지 않습니다.\n\n'
                                '응원과 선물을 보내면 선택한 문구·이모티콘·꽃 종류, 보낸 계정과 닉네임, 보낸 날짜, 받기·심기·전달 상태를 서버에서 처리합니다. 상대는 받은 마음에서 보낸 사람과 날짜를 볼 수 있습니다. 정원의 이모티콘 효과는 24시간 동안 표시되지만 받은 마음 기록은 그 이후에도 남을 수 있습니다.\n\n'
                                '공개 범위와 목록 노출, 선물 받기 설정은 냥이 마을에서 바꿀 수 있습니다. 차단하면 서로의 정원 방문과 새로운 응원·선물 교류를 제한합니다. 신고하면 신고한 계정, 대상 계정과 선택한 신고 사유를 서버에 저장하며, 편지 본문은 신고 정보에 포함하지 않습니다.',
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🤝',
                            title: '제3자 제공',
                            accent: AppColors.blobRoseAccent,
                            background: AppColors.blobRose,
                            body:
                                '일기 내용을 광고 목적으로 전송하는 기능은 없습니다. 사용자가 공유·백업 파일 저장을 선택하면 해당 대상에 기록이 전달될 수 있습니다.\n\n'
                                '선택적 통계에는 Firebase Analytics를 사용합니다. 계정 인증에는 Google Firebase와 직접 선택한 로그인 제공사(구글·카카오·네이버·페이스북)를 이용하며, 스토어 결제에는 Google Play를 사용합니다. ${CloudService.enabled ? '암호화 백업·서버 결제 확인·냥이 마을의 이웃과 선물 정보 처리에는 Google Firebase를 사용합니다.' : ''} 고양이 답장은 기기 안의 문장 조합 방식이며 외부 생성형 AI에 일기를 보내지 않습니다.',
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
                              '데이터 처리 안내 · v8',
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
            '마음냥 정원은 감정을 돌아보고 작은 실천으로 마음을 돌보는 것을 '
            '돕는 자기돌봄(self-care) 및 마음챙김 보조 앱입니다.\n\n'
            '이 앱은 의료 서비스가 아니며, 전문적인 진단·치료·상담을 대체할 수 없습니다. '
            '앱에서 제공하는 감정 기록, 명상, 조언은 정서적 참고 자료일 뿐 의학적 '
            '조언이 아닙니다.\n\n'
            '만약 지속적으로 힘든 감정이 계속되거나, 스스로 또는 타인을 해치고 싶은 '
            '생각이 든다면 반드시 정신건강 전문가, 의료기관 또는 아래의 상담 기관에 '
            '도움을 요청해 주세요.\n\n'
            '· 자살예방상담전화 109 (24시간)\n'
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
