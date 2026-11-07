import '../l10n/app_language.dart';
import '../services/cloud_service.dart';
import '../services/privacy_config.dart';
import '../mongi/services/consent_service.dart';
import 'package:url_launcher/url_launcher.dart';
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
    Localizations.localeOf(context);
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
                        Expanded(
                          child: Text(
                            tr("개인정보 · 이용안내"),
                            style: titleFont(
                              fontSize: 20,
                              color: AppColors.titlePastelGreen,
                            ),
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
                            title: tr("수집하는 정보"),
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body: tr(
                              "마음냥 정원은 다음과 같은 정보를 앱 안에서 만들고 저장합니다.\n\n· 오늘의 감정 카드 선택 기록, 마음 온도 기록\n· 고양이에게 쓴 편지(일기) 내용\n· 먹이주기 · 물주기 · 목욕 · 청소 등 돌보기 기록\n· 명상 · 내면소통 완료 기록, 연속 방문일, 성장 레벨\n\n· 선택한 편지 마무리 감정·문장, 돌봄 계획·실천 여부·도움 여부, 직접 간직한 응원\n· 정원 기록집에 선택한 문장·나무·실천 기록, 정원 모습의 저장 시각과 나중에 덧붙인 글\n\n기록과 초안은 기기에 저장하며 암호화를 적용합니다. 파일 백업을 선택하면 사용자가 지정한 위치에 암호화 파일을 저장합니다.\n\n{0}\n\n간편 로그인에는 Firebase Authentication을 사용합니다. 구글 로그인을 선택하면 Firebase가 제공받는 계정 식별자·이름·이메일·프로필 정보가 인증에 사용될 수 있습니다. 카카오·네이버·페이스북 로그인은 서버에서 제공사 계정 ID를 확인하고 해시 처리한 연결 식별자와 Firebase 계정 식별자를 보관합니다. 이 세 방식은 이메일·친구 목록·게시물·일기 내용을 요청하지 않습니다. 로그인 세션은 짧은 유효기간과 일회용 확인 절차로 보호합니다.\n\n이웃·예약 소식 알림을 켜면 Firebase Cloud Messaging의 기기 등록 토큰·계정 식별자·알림 선택을 서버에 저장합니다. 알림에는 편지나 감정 내용을 넣지 않습니다. 마이에서 끌 수 있고 로그아웃 시 기기 연결을 해제합니다. 30일 이상 갱신되지 않은 기기에는 보내지 않습니다.\n\n사용 통계 공유는 기본으로 꺼져 있으며 기록 보관과 백업에서 선택할 수 있습니다. 켜면 기능 이용 이벤트와 제한된 항목을 Firebase Analytics에 보냅니다. 일기 본문·선택한 감정은 보내지 않습니다. Firebase SDK는 앱 인스턴스 식별자·기기 및 앱 정보를 처리할 수 있으므로 완전히 익명인 통계라고 보장하지 않습니다.",
                              [
                                CloudService.enabled
                                    ? tr(
                                        "서버 백업을 직접 켜면 정원 기록·초안·답장이 백업 암호로 암호화되어 서버로 전송됩니다. 로그인 이메일과 계정 식별자, 구매 토큰과 구독 상태도 계정·결제 기능에 사용됩니다.",
                                      )
                                    : tr("서버 백업은 연결 준비 후 이용할 수 있습니다."),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🔒',
                            title: tr("정보 사용 목적과 보관"),
                            accent: AppColors.blobLavenderAccent,
                            background: AppColors.blobLavender,
                            body: tr(
                              "마음 기록은 이용자 본인의 마음챙김 기록을 보여주고, 고양이 성장 · 마음 리포트 · 직접 선택한 이웃 교류 등 앱의 핵심 기능을 제공하기 위한 목적으로만 사용됩니다.\n\n편지를 삭제하면 해당 본문은 기록 목록에서 사라집니다. 나무의 성장을 유지하고 같은 날 중복 성장을 막기 위한 기록 날짜는 정원 성장 정보에 남습니다. 이 날짜와 편지 본문은 공개 정원에 표시하지 않습니다.\n\n편지의 문장을 내 식물의 기억에 연결하면 원본 편지의 식별자와 날짜, 직접 고른 문장을 기기에 저장합니다. 이 기억은 개인 기록이며 공개 정원이나 공동 나무로 전송하지 않습니다. 편지를 삭제할 때 연결된 마무리 기록과 식물 기억·정원 기록집의 해당 문장도 지웁니다. 돌봄 실천이나 식물 기억을 삭제하면 기록집에 선택해 둔 해당 항목도 지웁니다. 이미 외부로 공유한 파일과 이전 백업에는 사본이 남을 수 있습니다. 기록집의 정원 그림은 표시된 저장 시각에 보관한 배치를 다시 그린 것이며, 과거 날짜에 촬영한 사진은 아닙니다.\n\n앱 삭제는 기기 기록에 영향을 줍니다. 별도로 내보낸 파일이나 서버 백업까지 삭제되지는 않습니다. 기록 하나를 지워도 이전 백업에는 남을 수 있습니다.\n\n{0}\n\n백업 암호는 서버로 보내지 않으며, 자동 백업을 켠 경우 기기 보안 저장소에 보관합니다. 암호를 잊으면 새 기기에서 복원할 수 없습니다. 한 기기에는 하나의 정원이 저장되며 로그아웃으로 기기 기록이 지워지지 않습니다.",
                              [
                                CloudService.enabled
                                    ? tr(
                                        "서버는 최근 10개 백업을 보관하며 구독 종료 후에도 기존 백업 복원을 허용합니다. 서버 계정과 백업 삭제는 기록 보관과 백업에서 요청할 수 있습니다. 중복 구매 연결을 막기 위한 구매 토큰의 해시 표식은 원문 토큰·계정 식별자 없이 남습니다. 계정 해시 기반 삭제 상태와 소셜 로그인 연결 식별자·연결 UID·세대 정보도 남으며 현재 자동 만료기간은 없습니다. 정식 운영 보유기간과 최소 보관 범위는 확정 전입니다.",
                                      )
                                    : tr("내보낸 백업 파일은 저장한 위치에서 직접 관리·삭제해 주세요."),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🏡',
                            title: tr("냥이 마을 · 이웃과 나누는 정보"),
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body: tr(
                              "온라인 이웃 기능을 이용하면 계정 식별자, 정원 닉네임, 초대 코드, 공개 범위, 이웃 신청·수락 관계, 차단 설정을 서버에 저장합니다. 초대 코드를 가진 사람은 닉네임을 확인하고 이웃 신청을 보낼 수 있으며, 신청을 수락해야 이웃으로 연결됩니다.\n\n정원은 나만 보기 · 이웃에게 공개 · 모두에게 공개 중 선택할 수 있습니다. 정원 둘러보기 목록에는 모두에게 공개하고 목록 노출에도 동의한 정원만 나타납니다. 공개하는 정원 모습에는 씨앗 수, 장식, 나무 성장 단계와 배치 등이 포함되며, 편지 본문·감정 통계·개인 기록 날짜는 포함하지 않습니다.\n\n응원과 선물을 보내면 선택한 문구·이모티콘·꽃 종류, 보낸 계정과 닉네임, 보낸 날짜, 받기·심기·전달 상태를 서버에서 처리합니다. 상대는 받은 마음에서 보낸 사람과 날짜를 볼 수 있습니다. 정원의 이모티콘 효과는 24시간 동안 표시되지만 받은 마음 기록은 그 이후에도 남을 수 있습니다.\n\n공동 기념 나무는 수락한 이웃을 직접 초대하고 상대가 참여를 수락해야 함께 돌볼 수 있습니다. 나무 이름·기념일·물주기 기록과 공동 메모는 서버에 저장하고 참여자끼리 봅니다. 개인 편지·감정 통계는 공유하지 않습니다. 공동 메모는 작성자가 삭제할 수 있습니다. 이웃 연결이 끝나거나 차단된 뒤에도 ‘내가 남긴 공동 메모 관리’에서 본인의 메모를 삭제할 수 있습니다. 이웃을 다시 연결해도 이전 공동 나무의 참여는 자동으로 재개되지 않으며 새 초대와 수락이 필요합니다. 새 활동 표시를 위해 참여자의 마지막 확인 상태를 저장합니다. 나가기와 계정 삭제의 차이는 나무 화면과 계정 삭제 화면에서 확인할 수 있습니다.\n\n공개 범위와 목록 노출, 선물 받기 설정은 냥이 마을에서 바꿀 수 있습니다. 차단하면 서로의 정원 방문과 새로운 응원·선물 교류를 제한합니다. 신고하면 신고한 계정, 대상 계정과 선택한 신고 사유를 서버에 저장하며, 편지 본문은 신고 정보에 포함하지 않습니다.",
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '📅',
                            title: tr("정원 소식 · 클래스 신청"),
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body: tr(
                              "클래스나 모임에 신청하면 계정 식별자·선택한 일정·신청 및 취소 상태·신청 메모를 서버에 저장합니다. 운영자는 신청 관리에 필요한 내용을 확인합니다. 편지와 감정 기록은 신청에 포함되지 않습니다.\n\n일정·장소·참가비·신청 마감은 각 공지에 표시합니다. 온라인 참여 주소가 있는 경우 신청한 참여자에게 안내합니다. 앱 구독만으로 모든 클래스의 참가비가 면제되는 것은 아닙니다. 외부 센터로 따로 정보를 전달하거나 외부에서 결제해야 하는 경우 해당 안내를 확인한 후 선택해 주세요.",
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🛠️',
                            title: tr('선택적 오류 보고'),
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body: tr(PrivacyConfig.errorReportingNotice),
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🤝',
                            title: tr("제3자 제공"),
                            accent: AppColors.blobRoseAccent,
                            background: AppColors.blobRose,
                            body: tr(
                              "일기 내용을 광고 목적으로 전송하는 기능은 없습니다. 사용자가 공유·백업 파일 저장을 선택하면 해당 대상에 기록이 전달될 수 있습니다.\n\n선택적 통계에는 Firebase Analytics를 사용합니다. 계정 인증에는 Google Firebase와 직접 선택한 로그인 제공사(구글·카카오·네이버·페이스북)를 이용하며, 스토어 결제에는 Google Play를 사용합니다. {0} 새 자동 답장은 만들지 않으며 예전에 저장된 답장만 열람할 수 있습니다. 외부 생성형 AI에 일기를 보내지 않습니다. 정원 기록집을 공유할 때에는 미리보기에서 선택한 내용만 내보냅니다.",
                              [
                                CloudService.enabled
                                    ? tr(
                                        "암호화 백업·서버 결제 확인·냥이 마을·공동 나무·클래스 신청 정보 처리에는 Google Firebase를 사용합니다.",
                                      )
                                    : '',
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🌿',
                            title: tr("무료 이용과 광고"),
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body: tr(
                              "광고가 연결된 Android 버전에서는 무료 이용자에게 홈 하단의 Google AdMob 배너 광고가 표시될 수 있습니다. 구독과 구독 무료체험 기간에는 광고를 표시하지 않습니다. 편지 작성·정원 산책·명상 화면에는 광고를 넣지 않습니다.\n\n앱은 비맞춤 광고를 요청하며 편지 본문, 선택한 감정, 마음 점수, 나무의 추억, 친구 코드나 로그인 계정을 광고 타기팅 정보로 전달하지 않습니다. 비맞춤 광고도 광고 제공·측정·부정 이용 방지를 위해 Google 광고 SDK가 IP 주소, 광고 상호작용, 진단 정보와 기기 식별자 등을 처리할 수 있습니다. 데이터 수집이 전혀 없는 방식이라는 뜻은 아닙니다.\n\n필요한 지역에서는 광고 개인정보 선택 화면을 제공합니다. 광고가 연결된 버전의 마이 → 광고 개인정보 선택에서 해당 선택을 확인하거나 변경할 수 있습니다. 사용 통계 공유 설정은 광고 개인정보 선택과 별도로 관리합니다.",
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '✉️',
                            title: tr("문의"),
                            accent: AppColors.blobButterAccent,
                            background: AppColors.blobButter,
                            body: tr(
                              "일반 문의, 개인정보 문의 또는 계정 삭제 요청은 아래 이메일로 문의해 주세요.\n\n{0}",
                              [PrivacyConfig.operatorNotice],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PolicySection(
                            emoji: '🌐',
                            title: tr("처리 위탁·국외 처리·삭제 안내"),
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body: tr(
                              "Firebase·Google Cloud와 로그인·광고 제공사의 서비스에서 정보를 처리합니다. 서버 함수는 서울 리전으로 구성되어 있으나 인증·광고·통계 및 지원 과정의 처리 국가가 모두 한국이라는 뜻은 아닙니다. 제공사별 수탁자·처리 국가·이전 항목과 시점·방법·보유 기간은 운영 계약 확인 후 공개 방침에 확정해야 합니다.\n\n기기 기록은 직접 삭제하거나 앱 데이터를 지울 때까지 보관합니다. 설정·이용 카운터 등 일부 보조 정보는 앱 전용 저장소에 보관되며 모두 별도 암호화되는 것은 아닙니다. 앱 재설치 시 자동 복원을 보장하지 않으며, 직접 만든 암호화 백업과 암호가 필요합니다.\n\n기록 보관과 백업에서 서버 계정 삭제를 요청할 수 있습니다. 로그아웃은 삭제가 아닙니다. 기기 기록·내보낸 파일의 삭제와 Google Play 구독 해지는 별도로 진행해야 합니다. 앱 없이도 아래 웹 링크에서 이메일로 계정·데이터 삭제를 요청할 수 있습니다. 이메일 작성만으로 자동 전송되거나 삭제되지는 않습니다. 처리 기한과 신고·운영 로그의 보유 기간은 정식 출시 전 확정해야 합니다.",
                            ),
                          ),
                          if (PrivacyConfig.policyUrl.isNotEmpty)
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse(PrivacyConfig.policyUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(tr("공개 개인정보처리방침")),
                            ),
                          if (PrivacyConfig.deletionUrl.isNotEmpty)
                            TextButton(
                              onPressed: () => launchUrl(
                                Uri.parse(PrivacyConfig.deletionUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                              child: Text(tr("웹에서 계정·데이터 삭제 요청")),
                            ),
                          TextButton(
                            onPressed: () async {
                              final opened = await ConsentService.instance
                                  .showPrivacyOptionsFormIfRequired();
                              if (!opened && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr("현재 표시할 광고 개인정보 선택 화면이 없어요."),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(tr("광고 개인정보 선택")),
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: Text(
                              tr("데이터 처리 안내 · 2026.10.31 테스트 운영"),
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
    Localizations.localeOf(context);
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
                  tr("꼭 읽어주세요 · 정신건강 안내"),
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
            tr(
              "마음냥 정원은 감정을 돌아보고 작은 실천으로 마음을 돌보는 것을 돕는 자기돌봄(self-care) 및 마음챙김 보조 앱입니다.\n\n이 앱은 의료 서비스가 아니며, 전문적인 진단·치료·상담을 대체할 수 없습니다. 앱에서 제공하는 감정 기록, 명상, 조언은 정서적 참고 자료일 뿐 의학적 조언이 아닙니다.\n\n만약 지속적으로 힘든 감정이 계속되거나, 스스로 또는 타인을 해치고 싶은 생각이 든다면 반드시 정신건강 전문가, 의료기관 또는 아래의 상담 기관에 도움을 요청해 주세요.\n\n· 자살예방상담전화 109 (24시간)\n· 정신건강상담전화 1577-0199 (24시간)\n· 청소년상담전화 1388",
            ),
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
    Localizations.localeOf(context);
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
              Expanded(
                child: Text(
                  title,
                  style: pathLabelFont(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
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
