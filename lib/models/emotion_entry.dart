import 'package:flutter/material.dart';

/// 하루하루 기록하는 감정의 종류
/// 긍정(평온·기쁨·감사) / 부정(불안·슬픔·분노·외로움·피곤함)으로 나뉘어
/// 월간 리포트의 흐름 분석에 사용됩니다.
enum EmotionType {
  calm,
  joy,
  anxiety,
  sadness,
  anger,
  loneliness,
  tired,
  gratitude,
}

enum EmotionValence { positive, negative }

extension EmotionTypeX on EmotionType {
  String get label {
    switch (this) {
      case EmotionType.calm:
        return '평온';
      case EmotionType.joy:
        return '기쁨';
      case EmotionType.anxiety:
        return '불안';
      case EmotionType.sadness:
        return '슬픔';
      case EmotionType.anger:
        return '분노';
      case EmotionType.loneliness:
        return '외로움';
      case EmotionType.tired:
        return '피곤함';
      case EmotionType.gratitude:
        return '감사';
    }
  }

  String get emoji {
    switch (this) {
      case EmotionType.calm:
        return '🌙';
      case EmotionType.joy:
        return '🌞';
      case EmotionType.anxiety:
        return '🌊';
      case EmotionType.sadness:
        return '🌧️';
      case EmotionType.anger:
        return '🔥';
      case EmotionType.loneliness:
        return '🍂';
      case EmotionType.tired:
        return '🌫️';
      case EmotionType.gratitude:
        return '🌸';
    }
  }

  EmotionValence get valence {
    switch (this) {
      case EmotionType.calm:
      case EmotionType.joy:
      case EmotionType.gratitude:
        return EmotionValence.positive;
      case EmotionType.anxiety:
      case EmotionType.sadness:
      case EmotionType.anger:
      case EmotionType.loneliness:
      case EmotionType.tired:
        return EmotionValence.negative;
    }
  }

  /// 은은하고 차분한, 감정별 고유 색 (달빛 정원 톤에 맞춘 무드 컬러)
  Color get color {
    switch (this) {
      case EmotionType.calm:
        return const Color(0xFF8B96C9); // 차분한 라벤더 블루
      case EmotionType.joy:
        return const Color(0xFFE7B65C); // 따뜻한 골드
      case EmotionType.anxiety:
        return const Color(0xFF7FA6C4); // 물결처럼 흔들리는 블루
      case EmotionType.sadness:
        return const Color(0xFF7C93B8); // 비 오는 듯한 소프트 블루
      case EmotionType.anger:
        return const Color(0xFFC1685F); // 은은하게 가라앉힌 레드
      case EmotionType.loneliness:
        return const Color(0xFF9A8FB0); // 낙엽빛 뮤트 퍼플
      case EmotionType.tired:
        return const Color(0xFFA79C8C); // 안개빛 그레이브라운
      case EmotionType.gratitude:
        return const Color(0xFF7FA88C); // 세이지 그린
    }
  }

  Color get bgColor => color.withValues(alpha: 0.14);

  static const List<EmotionType> all = EmotionType.values;
}

/// 하루의 감정 기록 - 감정 종류 + 강도(1~5) + 짧은 메모
class EmotionEntry {
  final String id;
  final DateTime date;
  final EmotionType emotion;
  final int intensity; // 1~5
  final String memo;

  EmotionEntry({
    required this.id,
    required this.date,
    required this.emotion,
    required this.intensity,
    this.memo = '',
  });

  /// 감정 흐름 분석용 부호 있는 점수 (-5 ~ +5)
  double get signedScore => emotion.valence == EmotionValence.positive
      ? intensity.toDouble()
      : -intensity.toDouble();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'emotion': emotion.name,
      'intensity': intensity,
      'memo': memo,
    };
  }

  factory EmotionEntry.fromMap(Map<dynamic, dynamic> map) {
    return EmotionEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      emotion: EmotionType.values.firstWhere(
        (e) => e.name == map['emotion'],
        orElse: () => EmotionType.calm,
      ),
      intensity: (map['intensity'] as num?)?.toInt() ?? 3,
      memo: map['memo'] as String? ?? '',
    );
  }
}
