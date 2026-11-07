# 정원 종료 및 명상 재생 통합

몽이 진입 시 정원 소리를 멈추고 정원 배경음 재시작을 차단합니다. 사용자 배경음 설정값은 보존합니다.
홈 상단 종료 버튼: 공통 미디어, 정원 소리, 몽이 소리를 정지합니다. Android는 Activity를 닫고 웹/iOS는 종료 화면 및 다시 열기를 제공합니다.
명상 오디오는 paused/inactive lifecycle에서 중단하지 않습니다. Android mediaPlayback foreground service, WAKE_LOCK과 재생 알림의 멈추기 동작을 추가했습니다. iOS UIBackgroundModes audio와 playback audio session을 설정했습니다. 영상은 백그라운드에서 일시정지합니다.
MediaCoordinator가 오디오와 모든 영상의 재생을 직렬화하고 이전 재생을 중단합니다. 정원 효과음은 명상 및 몽이 중 차단합니다.
오디오/영상 모두 MeditationCompletionService를 통해 하루 1회 공통 보상(씨앗 1, 정수 20)을 사용합니다. 중단은 완료로 처리하지 않습니다. 저장 실패는 다음 재생/완료에서 재시도합니다.

검증: 미디어 교차 전환, 화면 잠금 lifecycle, 명시적 종료, 몽이 중 BGM 차단, 완료 보상 중복과 재로드 후 재지급 방지 자동검사. 실제 VideoPlayer 완료 이벤트 위젯 검사. Android XML 및 iOS plist 파싱.
한계: Android SDK와 연결 기기 없음. Android 네이티브 서비스 컴파일/APK 및 장시간 잠금 재생 테스트 미수행. iOS Xcode 빌드/실기기 테스트 미수행. 웹 백그라운드 재생은 브라우저 정책에 따라 제한될 수 있습니다.
