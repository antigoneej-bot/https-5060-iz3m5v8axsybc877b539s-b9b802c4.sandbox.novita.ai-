# 자연음 명상 추가

피곤할 때 목록에 불멍 3분 영상(정지 이미지와 실제 장작 소리), 빗소리와 먼 천둥 3분 오디오를 추가했습니다.
불멍은 기존 3분 영상 원본을 그대로 포함했습니다. 빗소리는 기존 M4A를 160 kbps MP3로 변환했습니다.
영상 시작 시 명상 오디오와 정원 BGM을 멈추고, 앱이 배경으로 이동하면 영상을 일시정지합니다.

음원 출처(CC0):
- https://bigsoundbank.com/fireplace-2-s0031.html
- https://bigsoundbank.com/rain-and-storm-2-s0740.html

검증: 수정 Dart 파일 분석 통과, 기존 meditation_audio_test 통과, 웹 릴리스 빌드 성공, 소스와 빌드 미디어 일치 및 에셋 등록 확인.
실제 Android/iPhone 재생 검증과 새 APK 빌드는 이번 작업에 포함되지 않았습니다.
