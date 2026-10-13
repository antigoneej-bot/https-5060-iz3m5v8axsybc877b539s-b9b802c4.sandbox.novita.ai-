import 'package:flutter/material.dart';

class RunnerReadyOverlay extends StatelessWidget {
  final bool ready, started, practice;
  final bool endless;
  final int? countdown;
  final int target, seconds;
  final VoidCallback onStart, onPause, onExit;
  const RunnerReadyOverlay({
    super.key,
    required this.ready,
    required this.started,
    required this.practice,
    this.endless = false,
    required this.countdown,
    required this.target,
    required this.seconds,
    required this.onStart,
    required this.onPause,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: ModalBarrier(dismissible: false, color: Color(0x66000000)),
      ),
      Positioned.fill(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          started ? '잠깐 쉬어가요' : '준비되면 시작해요',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (countdown != null)
                          Semantics(
                            liveRegion: true,
                            label: '$countdown초 뒤에 달려요',
                            child: Text(
                              '$countdown',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 48),
                            ),
                          )
                        else ...[
                          const Text(
                            '왼쪽 주먹: 작은 장애물 치우기\n오른쪽 점프: 큰 장애물 넘기\n점프를 길게 누르면 조금 더 높이 뛰어요.',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            endless
                                ? '무한 도전 · 시간 제한 없이 달려요'
                                : practice
                                ? '연습 · 시간 제한 없이 마음 $target개 만나기'
                                : '이번 판 · $seconds초 안에 마음 $target개 만나기',
                          ),
                          const SizedBox(height: 8),
                          const Text('쉬는 동안 시간과 캐릭터는 멈춰 있어요.'),
                        ],
                        const SizedBox(height: 18),
                        if (!ready) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 8),
                          const Text(
                            '정원을 준비하고 있어요',
                            textAlign: TextAlign.center,
                          ),
                        ] else if (countdown != null)
                          OutlinedButton(
                            onPressed: onPause,
                            child: const Text('아직 쉬고 싶어요'),
                          )
                        else
                          FilledButton.icon(
                            key: const ValueKey('runner-ready-start'),
                            onPressed: onStart,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(started ? '계속 달리기' : '달리기 시작'),
                          ),
                        TextButton(
                          onPressed: onExit,
                          child: const Text('그만하기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
