# 마음냥 결제 설정 진단

사용자의 기존 Cloud Shell에서 `python3 Mindnyang-Billing-Check.py`로 실행합니다. 소스 검토와 모의 테스트만 수행했으며 이 파일로 실제 클라우드 조회를 실행하지 않았습니다.

이 스크립트는 프로젝트와 Play Console 설정을 변경하지 않습니다. 배포, IAM 권한 부여, API 활성화, 구매 생성·승인·환불은 실행하지 않습니다. 사용자·주문·영수증 데이터도 읽지 않습니다.

확인 항목:

- 기존 `gardenApi` 활성 여부 및 런타임 서비스 계정 확인
- Android Publisher API 활성화 여부
- `playNotifications` 함수와 지정 Pub/Sub 주제 연결
- Google Play 알림 서비스의 주제/프로젝트 내 발행 권한 등록
- 월 4,900원·연 29,000원 상품, 한국 신규 가입 가능한 활성 자동갱신 기본 요금제
- 무료체험 기간과 현재 앱의 단일 15일 무료체험 오퍼 호환 여부

상품을 조회할 때만 기존 Cloud Shell 인증과 기존 권한으로, 이미 확인된 런타임 서비스 계정의 600초짜리 `androidpublisher` 범위 액세스 토큰 발급을 한 번 요청합니다. 권한이 거절되면 다른 계정이나 인증 방식으로 우회하지 않습니다. 토큰은 메모리에만 보관되며 출력·파일 저장하지 않습니다. 리소스 설정을 변경하지 않지만 이 임시 토큰 발급은 IAM Credentials API의 인증 작업입니다.

`PASS`는 해당 조회 항목만 확인됐다는 뜻입니다. 상품 카탈로그 조회는 영수증 검증·구매 승인 권한의 증거가 아닙니다. 실제 결제·복원·갱신·해지·환불과 Play Console RTDN 설정/메시지 수신은 별도 테스트가 필요합니다. 조건부 IAM, 조직/폴더 상속, 맞춤 역할, IAM Deny까지 완전 평가하지 않으므로 발행 권한 등록 확인도 실제 전달 성공을 보증하지 않습니다.

토큰/키/서비스 계정 주소/원시 API 응답/원시 오류/환경 변수 값은 출력하지 않습니다. 사용자에게는 `PASS`, `CHECK`, `UNKNOWN` 결과만 요청합니다. API 응답은 2 MiB, 개별 명령 30초, HTTP 20초, 전체 조회 예산 240초로 제한합니다. HTTP 리다이렉트는 거부합니다. 무료체험 목록에 추가 페이지가 있으면 완료로 오인하지 않고 `UNKNOWN`으로 표시합니다.

## 모의 테스트

```bash
python3 -m unittest -v test_billing_check.py
```

외부 네트워크·클라우드 명령 없이 정상/권한 거절/API 미활성/요금·기간 불일치/무료체험/알림 연결/비밀정보 출력 방지/HTTP 요청 범위/시간 제한을 확인합니다.

## 확인한 공식 문서

- [Google Play Developer API 준비 및 서비스 계정 권한](https://developers.google.com/android-publisher/getting_started): Play Billing 권한은 Play Console의 금융 데이터 조회 및 주문·구독 관리 권한과 연관됩니다. Cloud IAM 역할만으로 입증되지 않습니다.
- [구독 상품 조회 GET](https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.subscriptions/get)
- [기본 요금제 및 한국 가격/가입 가능 설정](https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.subscriptions)
- [오퍼 조회 GET](https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.subscriptions.basePlans.offers/list)
- [오퍼 기간·무료 단계 구조](https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.subscriptions.basePlans.offers)
- [RTDN 주제·발행 계정·Play Console 연결](https://developer.android.com/google/play/billing/getting-ready)
- [기존 서비스 계정의 임시 액세스 토큰 발급](https://docs.cloud.google.com/iam/docs/reference/credentials/rest/v1/projects.serviceAccounts/generateAccessToken): `iam.serviceAccounts.getAccessToken` 권한이 필요합니다. 스크립트가 이 권한을 부여하지 않습니다.
