/// Published media metadata, measured from bundled files (rounded seconds).
class MeditationMediaInfo {
  final String kind;
  final int seconds;
  const MeditationMediaInfo(this.kind, this.seconds);
  bool get hasVoice => kind.contains('목소리 안내');
  String get durationLabel => seconds % 60 == 0
      ? '${seconds ~/ 60}분'
      : '${seconds ~/ 60}분 ${seconds % 60}초';
  String get label => '$kind · $durationLabel';
}

const meditationMedia = <String, MeditationMediaInfo>{
  'singingBowlRest': MeditationMediaInfo('시작·마무리 목소리 안내 · 싱잉볼', 300),
  'busyMindRest': MeditationMediaInfo('목소리 안내 · 물소리', 195),
  'angerCooling': MeditationMediaInfo('목소리 안내 · 파도 소리', 288),
  'rainThunderRest': MeditationMediaInfo('자연음 · 목소리 없음', 180),
  'sleepMeditation': MeditationMediaInfo('목소리 안내 · 장작 소리', 434),
  'mindfulThought': MeditationMediaInfo('목소리 안내 · 기타 음악', 420),
  'forestRest': MeditationMediaInfo('목소리 안내 · 새소리', 120),
  'fireplaceRest': MeditationMediaInfo('장작 이미지 영상 · 자연음 · 목소리 없음', 180),
  '478Breathing': MeditationMediaInfo('호흡 영상 · 무음', 88),
  'breathing': MeditationMediaInfo('호흡 영상 · 배경음', 60),
};
