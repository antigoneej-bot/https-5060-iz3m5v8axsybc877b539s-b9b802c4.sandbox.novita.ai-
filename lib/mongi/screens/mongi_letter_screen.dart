import '../../theme.dart' show AppColors;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/gen/app_localizations.dart';
import '../l10n/mongi_letter_l10n.dart';
import '../providers/garden_provider.dart';
import '../services/mongi_letter_service.dart';

/// "몽이의 주간 편지" - 감정 데이터 되돌려주기 3단계.
///
/// [WeeklyReportScreen]이 최근 7일을 숫자/그래프로 보여준다면, 이 화면은
/// 같은 데이터를 몽이가 직접 쓴 것 같은 손편지 문단들로 바꿔서 들려준다.
/// 서버/AI 없이 로컬 데이터 + 룰 기반 템플릿([MongiLetterService])만으로
/// 동작하며, 화면을 열면 봉투가 열리며 편지지가 나타나고, 문단이 하나씩
/// 순서대로 페이드인되어 "편지를 읽어나가는" 느낌을 준다.
class MongiLetterScreen extends StatefulWidget {
  const MongiLetterScreen({super.key});

  @override
  State<MongiLetterScreen> createState() => _MongiLetterScreenState();
}

class _MongiLetterScreenState extends State<MongiLetterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _envelopeController;
  bool _envelopeOpened = false;

  @override
  void initState() {
    super.initState();
    _envelopeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    // 화면에 들어오면 봉투가 이미 도착해 있는 채로 시작 -> 유저가 탭하면 열린다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GardenProvider>().markMongiLetterRead();
    });
  }

  void _openEnvelope() {
    if (_envelopeOpened) return;
    setState(() => _envelopeOpened = true);
    _envelopeController.forward();
  }

  @override
  void dispose() {
    _envelopeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final garden = context.watch<GardenProvider>();
    final letter = MongiLetterService.buildWeeklyLetter(
      diaryEntries: garden.diaryEntries,
      checkInStreak: garden.checkInStreak,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE8EE), Color(0xFFFFF3E9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, l10n),
              Expanded(
                child: !letter.hasEnoughData
                    ? _buildNotEnoughData(l10n)
                    : (_envelopeOpened
                          ? _buildLetterPaper(l10n, letter)
                          : _buildEnvelope(l10n)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.mongiLetterHeaderTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEnoughData(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✉️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              l10n.mongiLetterNotEnoughMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 아직 열지 않은 편지 봉투. 탭하면 [_openEnvelope]로 편지지 화면으로 전환.
  Widget _buildEnvelope(AppLocalizations l10n) {
    return Center(
      child: GestureDetector(
        onTap: _openEnvelope,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 220,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0A72E), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 봉투 접힌 삼각형 모양(위쪽 flap).
                  CustomPaint(
                    size: const Size(220, 150),
                    painter: _EnvelopeFlapPainter(),
                  ),
                  const Positioned(
                    bottom: 34,
                    child: Text('🐱', style: TextStyle(fontSize: 30)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.mongiLetterArrivedTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.mongiLetterTapToOpenHint,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }

  /// 열린 편지지 - 문단들이 순서대로 페이드인되며 나타난다.
  Widget _buildLetterPaper(AppLocalizations l10n, MongiWeeklyLetter letter) {
    final paragraphs = <String>[
      l10n.mongiLetterGreeting,
      mongiLetterBodyText(l10n, letter.bodyResult!),
      mongiLetterStreakText(l10n, letter.streakResult!),
      l10n.mongiLetterClosing,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: FadeTransition(
        opacity: _envelopeController,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(
              parent: _envelopeController,
              curve: Curves.easeOutBack,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE0A72E).withValues(alpha: 0.35),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < paragraphs.length; i++) ...[
                  _AnimatedLetterParagraph(
                    text: paragraphs[i],
                    delay: Duration(milliseconds: 250 * i),
                  ),
                  if (i != paragraphs.length - 1) const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 편지 봉투 위쪽 접힌 부분(flap) 모양을 그리는 페인터.
class _EnvelopeFlapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFE8C2)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height * 0.42)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = const Color(0xFFE0A72E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 편지 문단 하나를 [delay]만큼 기다린 뒤 스스로 페이드인 + 살짝 위로
/// 올라오며 나타나게 하는 위젯. 편지 전체 애니메이션과 별개로 각 문단이
/// 독립적으로 순서대로 나타나는 "읽어나가는" 느낌을 만든다.
class _AnimatedLetterParagraph extends StatefulWidget {
  final String text;
  final Duration delay;

  const _AnimatedLetterParagraph({required this.text, required this.delay});

  @override
  State<_AnimatedLetterParagraph> createState() =>
      _AnimatedLetterParagraphState();
}

class _AnimatedLetterParagraphState extends State<_AnimatedLetterParagraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
        child: Text(
          widget.text,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.7,
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
