/// 마음 온도 기록(주간/월간)을 심리학적으로 해석하기 위한 서비스.
///
/// 단순히 숫자와 그래프만 보여주던 화면에, 융(Jung)의 그림자 심리학
/// 관점에서 "지금 이 온도 흐름이 어떤 상태를 뜻하는지", "무엇을 하면
/// 좋을지", "따뜻한 위로와 응원", "지금 이 상태에 맞는 명상법"을 함께
/// 전달하기 위해 온도 기록을 분석합니다.
///
/// 마음 온도는 단순한 감정 점수가 아니라, 그림자(내가 외면해온 감정과
/// 욕구)를 얼마나 돌보고 있는지를 보여주는 지표로 다룹니다. 온도가
/// 낮다는 것은 "실패"가 아니라 "그림자가 관심을 필요로 한다는 신호"로
/// 해석하고, 온도가 높다는 것은 "그림자와의 관계가 편안해졌다는 신호"로
/// 해석합니다.
library;

import 'dart:math';

/// 평균 온도를 4단계로 나눈 구간 (CatMoodState와 동일한 임계값 사용).
enum TempBand { warm, calm, tired, recovering }

/// 기간 내 온도가 어떤 흐름을 보였는지.
enum TempTrend { rising, falling, stable, volatile }

/// 화면에 그대로 노출할 심리 해석 결과 묶음.
class TemperatureInsight {
  final TempBand band;
  final TempTrend trend;
  final double average;
  final int latest;
  final int highest;
  final int lowest;

  /// ① 구체적으로 어떤 상태인지
  final String stateDescription;

  /// ② 어떻게 하면 좋을지 (해결책)
  final String solution;

  /// ③ 따뜻한 위로와 응원
  final String comfort;

  /// ④ 지금 상태에 맞는 명상법 제안
  final String meditation;

  const TemperatureInsight({
    required this.band,
    required this.trend,
    required this.average,
    required this.latest,
    required this.highest,
    required this.lowest,
    required this.stateDescription,
    required this.solution,
    required this.comfort,
    required this.meditation,
  });

  String get bandLabel {
    switch (band) {
      case TempBand.warm:
        return '따뜻함이 머무는 시기';
      case TempBand.calm:
        return '평온이 자리잡는 시기';
      case TempBand.tired:
        return '그림자가 말을 거는 시기';
      case TempBand.recovering:
        return '회복이 시작되는 시기';
    }
  }

  String get trendLabel {
    switch (trend) {
      case TempTrend.rising:
        return '온기가 조금씩 차오르고 있어요';
      case TempTrend.falling:
        return '온기가 조금씩 식어가고 있어요';
      case TempTrend.stable:
        return '한결같은 흐름을 유지하고 있어요';
      case TempTrend.volatile:
        return '오르내림이 잦은 흐름이에요';
    }
  }

  String get emoji {
    switch (band) {
      case TempBand.warm:
        return '😊';
      case TempBand.calm:
        return '🌤';
      case TempBand.tired:
        return '🌧';
      case TempBand.recovering:
        return '🌱';
    }
  }
}

class TemperatureInsightService {
  TemperatureInsightService._();

  /// [entries]는 이미 원하는 기간(주간 7일 / 월간 30일)으로 필터링된
  /// (날짜, 온도) 목록이어야 하며, 날짜 오름차순으로 정렬되어 있어야
  /// 합니다(화면에서 이미 그렇게 정렬해 넘겨줍니다).
  static TemperatureInsight? analyze(List<MapEntry<DateTime, int>> entries) {
    if (entries.isEmpty) return null;

    final values = entries.map((e) => e.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final highest = values.reduce(max);
    final lowest = values.reduce(min);
    final latest = values.last;

    final band = _bandFor(average);
    final trend = _trendFor(values);

    return TemperatureInsight(
      band: band,
      trend: trend,
      average: average,
      latest: latest,
      highest: highest,
      lowest: lowest,
      stateDescription: _stateDescription(band, trend, average),
      solution: _solution(band, trend),
      comfort: _comfort(band, trend),
      meditation: _meditation(band, trend),
    );
  }

  static TempBand _bandFor(double average) {
    if (average >= 75) return TempBand.warm;
    if (average >= 50) return TempBand.calm;
    if (average >= 25) return TempBand.tired;
    return TempBand.recovering;
  }

  static TempTrend _trendFor(List<int> values) {
    if (values.length < 2) return TempTrend.stable;

    final n = values.length;
    final mean = values.reduce((a, b) => a + b) / n;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
        n;
    final stddev = sqrt(variance);

    final splitIndex = (n / 2).floor().clamp(1, n - 1);
    final firstHalf = values.sublist(0, splitIndex);
    final secondHalf = values.sublist(splitIndex);
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    final diff = secondAvg - firstAvg;

    if (stddev >= 20) return TempTrend.volatile;
    if (diff >= 6) return TempTrend.rising;
    if (diff <= -6) return TempTrend.falling;
    return TempTrend.stable;
  }

  // ── ① 상태 설명 ──────────────────────────────────────────────
  static String _stateDescription(
    TempBand band,
    TempTrend trend,
    double average,
  ) {
    final avgText = average.round().toString();
    final base = switch (band) {
      TempBand.warm =>
        '평균 마음 온도가 $avgText도로, 그림자와 꽤 편안한 거리를 유지하고 계신 시기예요. '
            '외면하고 싶었던 감정을 억누르기보다 있는 그대로 바라볼 수 있는 여유가 생겼다는 뜻이에요. '
            '융 심리학에서는 이런 상태를 "그림자와의 대화가 시작된 상태"라고 표현해요. '
            '완전히 다 해결됐다는 뜻이 아니라, 그림자를 적으로 여기지 않게 되었다는 신호랍니다.',
      TempBand.calm =>
        '평균 마음 온도가 $avgText도로, 크게 흔들리지도 무너지지도 않는 평온한 흐름 위에 계세요. '
            '이 평온함은 감정을 억지로 참아서 만들어진 게 아니라, 스스로를 돌보는 리듬을 조금씩 익혀가고 있다는 증거예요. '
            '다만 평온함 아래에는 아직 다 꺼내놓지 못한 그림자의 조각들이 조용히 남아 있을 수 있어요.',
      TempBand.tired =>
        '평균 마음 온도가 $avgText도로, 지금 그림자가 조용히 신호를 보내고 있는 시기예요. '
            '무기력하거나 자꾸 미루고 싶은 마음, 이유 없이 가라앉는 기분은 나약함의 증거가 아니라 '
            '오랫동안 외면해온 감정이 "이제는 나를 좀 봐줘"라고 말을 거는 방식이에요. '
            '지금 느끼는 지침은 실패가 아니라, 그림자가 당신에게 관심을 요청하는 신호랍니다.',
      TempBand.recovering =>
        '평균 마음 온도가 $avgText도로, 지금은 마음이 스스로를 지키기 위해 잠시 웅크리고 있는 회복의 시기예요. '
            '온도가 낮다는 건 마음이 고장 났다는 뜻이 아니라, 지금은 에너지를 아끼며 안전하게 회복하는 중이라는 뜻이에요. '
            '그림자 심리학에서는 이런 시기를 "무의식이 재정비를 요청하는 시간"으로 봐요. 지금은 애써 밝아지려 하지 않아도 괜찮아요.',
    };
    final trendNote = switch (trend) {
      TempTrend.rising =>
        ' 최근 흐름을 보면 온도가 조금씩 오르고 있어요 — 스스로를 돌보는 작은 선택들이 실제로 마음에 온기를 더해주고 있다는 뜻이에요.',
      TempTrend.falling =>
        ' 다만 최근 며칠 사이 온도가 조금씩 내려가고 있어요 — 최근에 마음을 무겁게 한 일이 있었는지, 잠시 멈춰서 스스로에게 물어봐 주세요.',
      TempTrend.stable =>
        ' 최근 흐름은 큰 오르내림 없이 비교적 일정하게 유지되고 있어요 — 지금의 리듬이 몸과 마음에 잘 맞고 있다는 신호일 수 있어요.',
      TempTrend.volatile =>
        ' 최근 온도가 꽤 크게 오르내리고 있어요 — 감정이 하루 사이에도 크게 널뛰는 시기라면, 지금은 큰 결정을 미루고 안정을 우선하는 게 좋아요.',
    };
    return base + trendNote;
  }

  // ── ② 해결책 ─────────────────────────────────────────────────
  static String _solution(TempBand band, TempTrend trend) {
    final base = switch (band) {
      TempBand.warm =>
        '지금처럼 잘 하고 계세요. 다만 따뜻함이 오래 갈수록 "이제 괜찮으니 돌보지 않아도 되겠지"라는 방심이 생기기 쉬워요. '
            '하루 1가지씩이라도 작은 돌봄(밥·물·목욕·청소 또는 호흡·걷기·기록·감사) 습관을 계속 이어가 주세요. '
            '온기는 한 번에 완성되는 게 아니라, 매일의 작은 반복으로 유지되는 거예요.',
      TempBand.calm =>
        '평온함을 유지하는 지금이야말로, 아직 다 꺼내지 못한 감정 하나를 안전하게 들여다보기 좋은 시기예요. '
            '데일리 내면소통에서 오늘 뽑은 카드나 마음기록을 다시 읽어보면서, "요즘 자꾸 피하고 있는 감정이 있나?"를 스스로에게 물어봐 주세요. '
            '평가하거나 판단하지 말고, 그냥 "그런 마음이 있었구나"라고 알아채는 것만으로도 충분해요.',
      TempBand.tired =>
        '지금은 많이 하려고 애쓰기보다, 딱 한 가지만 골라 오늘 실천해보는 게 훨씬 더 도움이 돼요. '
            '몸돌보기(밥·물·목욕·청소) 중 가장 쉬운 것 하나, 또는 짧은 호흡명상 3분만 해보세요. '
            '그림자 작업의 원칙은 "빨리 없애기"가 아니라 "판단하지 않고 곁에 머물기"예요. 조급해하지 않아도 괜찮아요.',
      TempBand.recovering =>
        '지금 단계에서 가장 좋은 해결책은 "아무것도 억지로 하지 않는 것"일 수 있어요. '
            '오늘 할 수 있는 가장 작은 돌봄 한 가지(물 한 잔 마시기, 잠깐 창밖 보기)를 골라 해보고, 그것으로 충분하다고 스스로를 인정해 주세요. '
            '온도는 다시 오를 거예요. 지금은 회복에 필요한 시간을 마음에게 선물해 주세요.',
    };
    final trendNote = switch (trend) {
      TempTrend.rising => ' 지금 하고 있는 방식이 잘 맞고 있으니, 무리해서 더 늘리기보다 같은 리듬을 유지해 주세요.',
      TempTrend.falling =>
        ' 최근 하락세라면, 완수해야 할 목표를 잠시 줄이고 "오늘 하나만 해도 성공"으로 기준을 낮춰보세요.',
      TempTrend.stable => ' 지금의 안정적인 리듬을 기록해두면, 나중에 힘들 때 다시 꺼내볼 수 있는 나만의 회복 매뉴얼이 돼요.',
      TempTrend.volatile => ' 큰 변화 대신, 매일 같은 시간에 같은 작은 돌봄을 반복해 마음에 예측 가능한 안전감을 만들어 주세요.',
    };
    return base + trendNote;
  }

  // ── ③ 위로와 응원 ────────────────────────────────────────────
  static String _comfort(TempBand band, TempTrend trend) {
    final base = switch (band) {
      TempBand.warm =>
        '여기까지 오는 동안 스스로를 외면하지 않고 계속 들여다봐 준 당신, 정말 잘하고 있어요. '
            '그림자를 밀어내지 않고 함께 걸어가는 법을 배워가는 중이라는 게 이 온도에 그대로 담겨 있어요. 이 온기, 당신이 만든 거예요.',
      TempBand.calm =>
        '화려하지 않아도, 무너지지 않고 매일을 살아내고 있는 것만으로도 충분히 대단한 일이에요. '
            '평온함은 아무것도 하지 않아서 생기는 게 아니라, 스스로를 잘 다독여왔기 때문에 만들어지는 거예요. 지금 이대로도 잘 하고 있어요.',
      TempBand.tired =>
        '지금 느끼는 지침과 무기력은 당신이 약해서가 아니에요. 오히려 그동안 너무 애쓰며 버텨왔다는 증거예요. '
            '조금 쉬어가도 괜찮아요. 온도가 잠시 낮아졌다고 해서 그동안의 노력이 사라지는 건 아니에요. 당신은 지금도 충분히 애쓰고 있어요.',
      TempBand.recovering =>
        '지금 이 순간에도 앱을 열어 스스로의 마음을 들여다보고 있다는 것 자체가, 이미 회복을 시작했다는 증거예요. '
            '온도가 낮다고 스스로를 탓하지 않아도 돼요. 겨울이 지나야 봄이 오듯, 지금은 다시 따뜻해지기 위한 필요한 시간이에요. 곁에서 함께 기다려줄게요.',
    };
    final trendNote = switch (trend) {
      TempTrend.rising => ' 조금씩 나아지고 있는 지금의 변화를 스스로 꼭 알아차려 주세요. 당신 스스로 만들어낸 변화예요.',
      TempTrend.falling => ' 지금 잠시 흔들려도 괜찮아요. 흔들림은 무너짐이 아니라, 다시 중심을 잡아가는 과정의 일부예요.',
      TempTrend.stable => ' 큰 굴곡 없이 꾸준히 나아가고 있는 지금의 리듬, 그 자체로 충분히 훌륭해요.',
      TempTrend.volatile => ' 마음이 오르내리는 건 당신이 살아있고, 매일 다른 하루를 진심으로 겪어내고 있다는 뜻이에요.',
    };
    return base + trendNote;
  }

  // ── ④ 명상법 제안 ────────────────────────────────────────────
  static String _meditation(TempBand band, TempTrend trend) {
    if (trend == TempTrend.volatile) {
      return '오늘은 "그라운딩 호흡"을 해보세요. 발바닥이 바닥에 닿는 느낌에 집중하며 4초 들이쉬고 6초 내쉬기를 5회 반복해보세요. '
          '오르내리는 감정 사이에서도 몸의 감각으로 돌아오면, 마음이 다시 안전한 지금 이 순간에 닻을 내릴 수 있어요.';
    }
    return switch (band) {
      TempBand.warm =>
        '오늘은 "감사 확장 명상"을 해보세요. 오늘 하루 감사했던 일 3가지를 천천히 떠올리며, '
            '그 감사함이 몸의 어디에서 따뜻하게 느껴지는지 가만히 느껴보세요. 이 온기를 몸으로 기억해두면, 힘든 날에도 다시 꺼내 쓸 수 있어요.',
      TempBand.calm =>
        '오늘은 "걷기명상"을 추천해요. 5분이라도 천천히 걸으며 발걸음 하나하나에 집중해보세요. '
            '평온한 지금, 몸을 움직이며 마음속 그림자의 목소리에도 조용히 귀 기울여 주세요.',
      TempBand.tired =>
        '오늘은 "3분 호흡명상"만 해보세요. 눈을 감고 숨이 들어오고 나가는 것만 가만히 지켜보세요. '
            '아무것도 바꾸려 하지 말고, 그냥 지금의 지침을 있는 그대로 느껴보는 것만으로도 충분한 돌봄이 돼요.',
      TempBand.recovering =>
        '오늘은 "이름 붙이기 명상"을 해보세요. 지금 마음에 있는 감정에 이름을 붙여보세요(예: "지금 나는 서운함을 느끼고 있구나"). '
            '이름을 붙이는 것만으로도 그 감정과 거리를 두고 바라볼 힘이 생겨요. 서두르지 말고, 딱 한 문장이면 충분해요.',
    };
  }
}
