# A 코드·운영 리스크 감사 + B-1 범위·공수 산정 리포트

| 항목 | 내용 |
|------|------|
| 프로젝트 | 마음냥 정원 (구: 고양이 그림자 정원 / Mystic Cat Journal) |
| 패키지 | `com.mysticcat.journal` |
| 계약 | A + B-1 (최소 출시형) / 112만 원(부가세 별도) |
| 기준일 | 2026-08-02 작성 / **2026-08-04 M1 합의 반영** |
| 작성 | 베로 (을) |
| 실행 검증 | `flutter run -d chrome` **성공** |
| M1 | **08.04 고객 확정** — 방향 동의, 방침·약관 URL 수령, 키 파일 전달 대기, 구독·테스터는 을 콘솔 작업 |

---

## 1. 한줄 요약

앱 **코어 기능은 동작**하며, B-1 중 **로컬 로그인 · Hive 암호화 · 백업 차단 · 가짜 결제 차단**은 완료입니다.  
**M1 합의·방침/약관 URL은 08.04 고객 확정**했습니다.  
**바로 할 일**: 키스토어 파일 수령 → Play 구독 상품·테스터 세팅(을) → 실결제 연동 · 서명 AAB.  
실 OAuth·서버 동기화·iOS는 계약 범위 밖입니다.

---

## 2. 점검·실행 환경

| 항목 | 결과 |
|------|------|
| 소스 | 수령 완료 |
| 실행 경로 | `C:\work\mystic_cat_journal` |
| Flutter | 3.44.6 (HANDOVER 권장 3.35.4와 상이 → 본 환경 기준 진행) |
| `flutter pub get` | 성공 |
| `google_fonts` | **6.3.2** (6.2.1은 Flutter 3.44 웹 컴파일 실패) |
| `flutter run -d chrome` | **성공** — Hive `__enc` 박스 9종 오픈 확인 |
| Android SDK / 실기기 | 미설치·미연결 → APK·AAB·실 IAP 검증은 환경 준비 후 |
| 릴리즈 키 (디스크) | 워크스페이스에 **파일 없음** — 고객: 2026-07-11 생성·alias `release`·~2053, **전달 예정** |
| Firebase | `google-services.json` 존재 (`mycatapp-99bc8`) |
| 방침 URL | https://antigoneej-bot.github.io/https-5060-iz3m5v8axsybc877b539s-b9b802c4.sandbox.novita.ai-/ |
| 약관 URL | https://antigoneej-bot.github.io/https-5060-iz3m5v8axsybc877b539s-b9b802c4.sandbox.novita.ai-/terms.html |

---

## 3. 영역별 현황

심각도: **P0** 출시 불가 · **P1** 정책·보안 · **P2** 품질·운영 · **P3** 개선

### 3.1 결제·구독 — P0 (가드 완료 / 실결제 진행)

| 항목 | 현황 |
|------|------|
| 가드 | `storeBillingEnabled=false` — 가짜 무료 부여 불가 |
| UI | 「곧 스토어에서 만나요」 |
| 합의 가격 | 월 4,900 / 연 29,000 (**08.04 고객 동의**) |
| 상품 ID | `garden_plus_monthly` / `garden_plus_yearly` |
| 다음 | 을이 Console에서 구독·테스터 생성 후 `in_app_purchase` 연동 |

### 3.2 로그인·온보딩 — 해소 · **합의 완료**

「이 기기에서 계속하기」 로컬 전용 — **08.04 동의**. 실 OAuth는 B-2.

### 3.3 민감 데이터·백업 — 해소

Hive AES + Secure Storage (`__enc` 9종 런타임 확인), `allowBackup=false`.  
잔여 P2: 마이그레이션 실패 시 빈 박스 가능(업그레이드 QA).

### 3.4 스토어·배포

| 항목 | 현황 | 심각도 |
|------|------|--------|
| applicationId / 앱명 | `com.mysticcat.journal` / 마음냥 정원 (**합의**) | OK |
| 서명 코드 | `build.gradle.kts` 준비 | OK |
| 키스토어 파일 | 고객 보유 확인, **수령 대기** | P0 → 수령 후 해소 |
| 방침·약관 HTTPS | **수령·접속 확인** | OK |
| 문의처 | `hello@catshadowgarden.com` | OK |
| pubspec `name` | `flutter_app` | P3 |

### 3.5 Analytics · 방침 — P2

Firebase 연동. 결제 이벤트는 실연동 전까지 Firebase 제외 유지.

### 3.6 양호 (코어)

감정 체크인 · 편지 · 돌보기 · 도감 · 회고 · 온보딩 · 페이월 UI · 프리미엄 잠금 · Analytics — 구현·실행 가능.

### 3.7 간단 코드리뷰 (엔지니어링 품질)

계약 A는 **리스크·출시 가능 여부 감사**가 본령이고, 전 파일 라인 리뷰는 범위 밖입니다.  
다만 핵심 모듈을 열어본 **개발자 관점 요약**을 남깁니다.

**총평**  
로컬 저널 앱으로 Service + Provider 분리가 분명하고, B-1 의도(로컬 전용·결제 가드·암호화)가 코드에 반영되어 있습니다. **구조 재작성은 불필요**하고, 남은 문제는 결제 연동·서명·일부 권한/온보딩 연결입니다.

**잘된 점**
- 결제 kill-switch (`storeBillingEnabled`)로 구매·복원·데모 프리미엄을 한곳에서 차단
- PremiumScreen이 서비스 API만 의존 → IAP는 내부 교체로 확장 가능
- Hive AES + `__enc` 분리·평문 마이그레이션 경로 존재
- 가짜 소셜 제거, Analytics 결제 이벤트 Firebase 제외로 지표 오염 방지
- Android `allowBackup=false`로 저널 유출면 축소

**보완 권고 (출시 전·중)**

| 심각도 | 내용 | 위치 |
|--------|------|------|
| P1 | 암호 마이그레이션 실패 시 빈 enc로 진행 → 체감 데이터 소실 가능 | `hive_encryption.dart` |
| P1 | 온보딩 「알림 동의」가 플래그만 저장, 실제 권한·스케줄과 미연결로 보임 | `onboarding_flow_screen.dart` |
| P1 | Exact Alarm 권한 선언 vs 실제 inexact 스케줄 — Play 권한 심사 이슈 여지 | `AndroidManifest.xml` |
| P2 | pubspec `name: flutter_app` vs applicationId 불일치 | `pubspec.yaml` |
| P2 | 구독·암호화·온보딩 자동 테스트 부재 | `test/` |

**B-1에서 다시 짤 필요 없는 것**  
MultiProvider·로컬 단일 유저·온보딩 스텝 골격·SubscriptionService 퍼블릭 API·콘텐츠/편지 엔진.

---

## 4. B-1 작업 목록 · 일정

### 4.1 작업 목록

| 우선 | ID | 작업 | 공수 | 상태 |
|------|-----|------|------|------|
| 1 | ENV-1 | 웹 실행 환경 | 0.5일 | **완료(웹)** — Android SDK·AAB 잔여 |
| 2 | A-1 | 리포트·M1 합의 | 포함 | **완료 (08.04)** |
| 3 | AUTH-1 | 로컬 로그인 UI | 0.5~1일 | **완료** |
| 4 | SEC-1 | Hive AES | 1~1.5일 | **완료** |
| 5 | SEC-2 | 백업 차단 | 0.5일 | **완료** |
| 6 | PAY-2 | CTA 준비 중 가드 | 0.5일 | **완료** |
| 7 | PAY-1 | 실 `in_app_purchase` | 2~3일 | **착수 가능** (콘솔 구독·테스터 = 을) |
| 8 | STORE-1 | 서명·AAB | 0.5일 | **키 파일 수령 후** |
| 9 | STORE-2 | 방침 URL·스토어 메타 | 0.5일 | **URL 완료** / 메타 입력 잔여 |
| 10 | QA-1 | 검수·인수인계 | 1~1.5일 | **대기** |

### 4.2 일정

| 단계 | 일정 | 내용 |
|------|------|------|
| 0~1 | ~08.04 | 착수·실행 검증·**M1 완료** |
| 2 B-1 | 08.05~08.16 | 구독·결제·서명 AAB (M2) |
| 3 인수 | 08.17~08.22 | 통합·검수 (M3) |

키 파일 전달 지연 시 **동일 일수 순연**.

### 4.3 고객 제공물

- [x] Play Console 앱 접근
- [x] M1 방향 합의 (08.04)
- [x] 방침·약관 HTTPS URL
- [ ] 키스토어 **파일** (`key.properties` + `release-key.jks`) — 암호화 전달 대기
- [ ] 구독·테스터 — **을 진행** (권한 부족 시 추가 요청)
- [ ] (선택) Firebase 콘솔 초대
- 문의·리포트: `hello@catshadowgarden.com`

---

## 5. 계약 제외

B-2 실 OAuth·서버 · 다중기기 동기화 · iOS · 디자인 리뉴얼·유지보수

---

## 6. 검수 기준

1. A 점검 리포트 ← 본 문서  
2. B-1 기능 (로그인·암호화·결제·배포)  
3. 내부 테스트 빌드 + 인수인계

---

## 7. M1 합의안 — **08.04 확정**

| 주제 | 합의 |
|------|------|
| 로그인 | 「이 기기에서 계속하기」 |
| 결제 | Play 구독, 월 4,900 / 연 29,000 |
| 브랜드 | 마음냥 정원 |
| 구독·테스터 | 을이 Console에서 진행 |
| 키 | 기존 키(07-11, alias `release`) 전달 |

---

## 8. PAY-1 실행 설계

`SubscriptionService` + init + PremiumScreen(복원·해지) + Analytics 제외 해제.  
선행: 구독 2종 · 내부 테스트 AAB · 라이선스 테스터 → `storeBillingEnabled=true` + 실기기 QA.

---

*계약서 A 산출물. 08.04 M1 고객 최종안 반영.*
