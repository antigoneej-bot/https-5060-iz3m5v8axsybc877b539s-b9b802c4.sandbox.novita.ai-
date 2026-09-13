import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/stars_background.dart';
import '../widgets/garden_path_card.dart';

/// 앱 소개 화면 - "이 앱은 무엇을 기반으로 만들어졌는지, 어떤 기능이 있는지,
/// 42마리 고양이는 어떤 의미인지, 왜 감정을 기록해야 하는지"를 처음 만나는
/// 사용자도 편하게 이해할 수 있도록 설명하는 베이직 소개 화면.
/// 개인정보처리방침 화면과 같은 GlassBlob 카드 톤으로 구성합니다.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
                          '마음냥 정원 소개',
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
                          const _IntroHeaderCard(),
                          const SizedBox(height: 16),
                          _AboutSection(
                            emoji: '🌒',
                            title: '이 앱은 어떤 생각에서 시작됐나요?',
                            accent: AppColors.blobLavenderAccent,
                            background: AppColors.blobLavender,
                            body:
                                '마음냥 정원은 심리학자 칼 융(Carl Jung)의 '
                                '"그림자(Shadow)" 개념에서 출발했어요.\n\n'
                                '융은 우리 마음속에는 스스로 인정하고 싶지 않아 밀어내 버린 '
                                '감정이나 모습들이 있다고 말했어요. 슬픔, 질투, 무기력, 분노 같은 '
                                '감정들이요. 이런 감정들은 없애야 할 "나쁜 것"이 아니라, '
                                '오히려 있는 그대로 바라보고 인정할 때 우리를 더 온전하게 '
                                '만들어주는 "그림자"랍니다.\n\n'
                                '이 앱은 그 그림자를 고양이의 모습으로 바꿔, 매일 조금씩 만나고 '
                                '이야기 나누며 나 자신을 더 깊이 이해할 수 있도록 돕는 '
                                '마음챙김 정원이에요.',
                          ),
                          const SizedBox(height: 14),
                          _AboutSection(
                            emoji: '🐾',
                            title: '42마리 고양이는 무슨 의미인가요?',
                            accent: AppColors.blobPeachAccent,
                            background: AppColors.blobPeach,
                            body:
                                '정원에는 총 42마리의 그림자 고양이가 살고 있어요. 각 고양이는 '
                                '슬픔, 질투, 분노, 불안, 외로움처럼 우리가 자주 느끼지만 쉽게 '
                                '드러내지 못하는 감정부터, 행복, 다정함, 만족, 평온처럼 소중히 '
                                '간직하고 싶은 감정까지 사람이 느낄 수 있는 다양한 마음의 '
                                '스펙트럼을 하나씩 대표하고 있어요.\n\n'
                                '한 가지 감정만으로는 사람의 마음을 다 담을 수 없기에, 42가지로 '
                                '나누어 오늘 내 마음과 가장 닮은 고양이를 찾을 수 있게 했어요. '
                                '각 고양이에게는 왜 그런 감정을 느끼는지 이야기가 있고, 그 '
                                '감정을 다정하게 안아주는 위로의 말과, 오늘 해볼 수 있는 작은 '
                                '실천 지침이 함께 담겨 있어요.',
                          ),
                          const SizedBox(height: 14),
                          _AboutSection(
                            emoji: '🌿',
                            title: '앱에서는 어떤 걸 할 수 있나요?',
                            accent: AppColors.blobMintAccent,
                            background: AppColors.blobMint,
                            body: '',
                            customChild: const _FeatureList(),
                          ),
                          const SizedBox(height: 14),
                          _AboutSection(
                            emoji: '💌',
                            title: '왜 매일 감정을 기록해야 하나요?',
                            accent: AppColors.blobRoseAccent,
                            background: AppColors.blobRose,
                            body:
                                '오늘의 감정과 닮은 고양이를 직접 고르고 편지를 쓰며 '
                                '내 경험을 돌아볼 수 있어요.\n\n'
                                '오늘의 고양이 카드는 무작위로 뽑는 재미용 카드예요. '
                                '심리 검사나 무의식 분석, 미래 예측이 아니에요. '
                                '같은 카드가 반복되거나 내가 고른 고양이와 같아도 우연일 수 있어요.\n\n'
                                '카드 이야기에서 마음에 와닿는 부분만 골라 보세요. '
                                '맞지 않으면 그냥 넘겨도 괜찮아요. 내 마음은 내가 정해요.',
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: Text(
                              '마음냥 정원과 함께, 오늘의 마음을 천천히 들여다보세요 🌙',
                              textAlign: TextAlign.center,
                              style: bodyFont(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                                height: 1.6,
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

/// 최상단 인사말 카드
class _IntroHeaderCard extends StatelessWidget {
  const _IntroHeaderCard();

  @override
  Widget build(BuildContext context) {
    return GlassBlob(
      accent: AppColors.blobButterAccent,
      background: AppColors.blobButter,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🐈', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '마음냥 정원에 오신 걸 환영해요',
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
            '이 화면에서는 이 앱이 어떤 생각에서 시작됐는지, 42마리 고양이는 '
            '어떤 의미인지, 그리고 앱에서 무엇을 할 수 있는지 차근차근 '
            '소개해드려요.',
            style: bodyFont(fontSize: 13, color: AppColors.moon, height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String emoji;
  final String title;
  final Color accent;
  final Color background;
  final String body;
  final Widget? customChild;
  const _AboutSection({
    required this.emoji,
    required this.title,
    required this.accent,
    required this.background,
    required this.body,
    this.customChild,
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
          if (customChild != null)
            customChild!
          else
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

/// 앱의 주요 기능을 리스트 형태로 보여주는 위젯
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  static const _features = [
    ('😽', '오늘의 감정 고양이 만나기', '지금 내 기분과 가장 닮은 고양이를 42마리 중에서 직접 골라보세요.'),
    ('💌', '고양이에게 편지쓰기', '고른 고양이에게 하고 싶은 말을 편지로 남기며, 감정을 있는 그대로 들여다봐요.'),
    ('🌘', '오늘의 고양이 카드 (카드뽑기)', '오늘의 고양이 카드를 무작위로 한 장 뽑아보고, 위로와 실천 지침을 받아보세요.'),
    ('🐾', '마음 돌보기', '밥 주기 · 물 주기 · 목욕 · 청소로 나만의 아기고양이를 함께 키워나가요.'),
    ('🧘', '명상 · 움직임 가이드', '호흡법, 스트레칭, 걷기 명상 등 오늘의 감정에 어울리는 이완 가이드를 만나보세요.'),
    ('🌡️', '마음 온도 기록 · 리포트', '그동안 쌓인 감정과 기록을 그래프와 월간 리포트로 돌아볼 수 있어요.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in _features) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.$1, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.$2,
                      style: bodyFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.$3,
                      style: bodyFont(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (f != _features.last) const SizedBox(height: 12),
        ],
      ],
    );
  }
}
