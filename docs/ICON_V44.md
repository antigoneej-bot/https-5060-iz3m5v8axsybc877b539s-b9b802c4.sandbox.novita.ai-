# 마음냥 정원 v44 — 선명한 아이콘 적용

Version: 1.0.41+44. Application ID: com.mysticcat.journal.

사용자가 승인한 크림색 고양이와 분홍 하트, 선명한 윤곽선, 민트 배경 아이콘을 적용했습니다. Android 런처 및 원형/적응형 아이콘, Flutter 아이콘 원본, iOS/macOS/web 아이콘 리소스를 갱신했습니다. Android 기본 배경색은 #A6EFCE입니다. Play 스토어용 512px PNG는 별도 제공됩니다.

## Build and validation

This Android AAB is a resource-only rebuild of the signed v43 compiled base module using official bundletool 1.18.2, not a fresh Flutter/Gradle compilation. Android manifest version, launcher PNG resources, icon asset and background color were updated. All DEX and native shared libraries, other app assets and all seven companion animation assets are byte-identical to v43. Original release signing certificate retained. Source resources and pubspec version were updated to match.

Bundle validation, signature verification, universal APK generation, APK package/version/app-name checks passed. Icon appearance reviewed at 48/64/96px with round and rounded-square masks. Functional tests were not rerun (v43 baseline: 715 passed). No physical-device test or Play Console upload performed. iOS/macOS/web source icons updated, but those platforms were not built.

Private signing keys and credentials are excluded. Upload the AAB to the appropriate Play Console release track and publish it to deliver the update. Upload the supplied 512px icon separately for the store listing.
