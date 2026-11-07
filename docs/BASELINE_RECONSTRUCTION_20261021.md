# Baseline reconstruction — 2026-10-21

## Scope
This is a source reconstruction for the approved care/garden feature work, not a claim that a newly built binary or live backend has been verified. No live deployment, account changes, purchase, secret update, or signing-key replacement was performed.

Source sequence:
1. Original preserved `mindnyang-reply-fixed-source.zip` (1.0.15+18).
2. Newer complete Korean-source archive recovered on 2026-10-21 (Library item `libfile_65b63740e0188191856f2b2565203c26`; source dated 2026-10-18). A complete byte comparison found 48 additions/changes and no removals relative to the original archive. This restores legacy-record migration, backup restore/reload, self-care storage/UI, and meditation fixes.
3. Kakao diagnostics patch: payload hashes validated, same as newer full source for its runtime changes.
4. Billing fix 1.0.17+20: owner-bound purchase stream verification, entitlement cache and premium UI fixes.
5. Notification fix 1.0.18+21: Gson TypeToken R8 preservation and notification icon resource retention.
6. Play Integrity 1.0.19+22: default production attestation and verified production build script settings.
7. News admin 1.0.20+23: verified social-account admin role and explicit RTDN CloudEvent registration.

Every versioned patch payload was checked against its distributed SHA-256 manifest. Before-hash differences were reviewed against the actual file diff; older and newer patch stages were not silently treated as identical. Source snapshots and detailed applied-stage manifests remain in the working audit directory.

## Immutable comparison snapshot
`/workspace/scratch/3fd06e8c8253/baseline-v23/` was assembled independently from the newer full source plus the ordered patches. It contains 703 files under lib/backend/test/tool/docs/android/ios/third_party and build configuration, excluding large unchanged assets. It was not copied from the feature agents' changing working tree. `BASELINE_V23_SHA256.json` lists every snapshot file hash. Keep this snapshot unchanged for final feature-diff packaging.

The working source's backup_service.dart and storage_service.dart were assigned to the root agent to combine the newer baseline with new care storage changes. Their baseline hashes below identify the pre-feature versions. No feature-agent changes were overwritten while constructing this snapshot.

## Preserved release behavior
- Package remains `com.mysticcat.journal`.
- Production build explicitly sets `APP_CHECK_DEBUG_PROVIDER=false` and `UNLOCK_ALL_PREMIUM=false`.
- `tool/build_mindnyang_play_bundle.sh` keeps the previously verified deployed login and garden endpoints.
- App Check and verified Firebase identity checks remain in place.
- Purchase product IDs, ownership binding, receipt verification, and existing subscription handling remain from the billing fix.
- Notification R8 TypeToken and icon retention files are restored.
- News admin role checks are retained.
- Existing village routes, account deletion safeguards and social login exports remain. The older server fixtures in the admin package were NOT copied over the application backend: the `deployed` fixture lacks village routes and the `village` fixture has an older identity guard.
- The RTDN v3 explicit CloudEvent registration is included from the distributed v23 source patch. Backend package dependency resolution must still be verified before any future server deployment; the historical package manifest does not directly declare `@google-cloud/functions-framework` even though the v3 entry imports it.

## Validation performed during reconstruction
`node --test test/social_auth.test.js test/account_identity.test.js test/policy.test.js test/garden_news_admin.test.js` passed 60/60 tests. This checks provider callback/error handling, App Check boundaries, verified social identities, subscription ownership policy and news admin authorization with local tests only.

Flutter analysis/tests and build verification are assigned to the toolchain/root verification work. Earlier release receipts remain historical evidence, not evidence of this turn's rebuilt artifact. Actual Play-installed device login, purchase renewal, cross-device interactions and server deployment remain separate end-to-end checks.

## Signing/configuration
No `android/key.properties` or release `.jks` is present in the recovered source. No replacement key was created. Existing Firebase client configuration bytes were preserved. A new installable release artifact must use the original authorized signing configuration and a version code above the published version.

## Selected baseline hashes

| Path | SHA-256 |
| --- | --- |
| `pubspec.yaml` | `821dec34c0608c4abe91da2f54fc4afd687dba9ca658695eb5ecd73c2b507331` |
| `lib/main.dart` | `37a4f83175fde643a44cb8000c797ef2a64acdf0c76e3987f361c98d015a3376` |
| `lib/utils/feature_flags.dart` | `998874317ef73e472af3183002719474c26fa9759c4c6430a6d69b6d4c4841c3` |
| `lib/services/social_auth_service.dart` | `e491ce71857abaab43aaedcc0f82da3feaf092861e7d6b2531c2329a1ac69a42` |
| `lib/services/account_identity_policy.dart` | `ee07c38052ef4c643e383e93c8c988c283ff191d498ffb46fac5a07a05945e5e` |
| `lib/services/cloud_service.dart` | `ee1d0d77d69433d7da3d4a851cdd4c91479e364809f0a1f8e3361c17fc5002b7` |
| `lib/services/subscription_service.dart` | `9768a4758b2a97cfa07dea531cc8d8bbc66b5c399888353cfe98c94a4f717cc9` |
| `lib/screens/account_screen.dart` | `519942f121923d76f4c51ef3aa57165730087f4b0ccff2d001a9faeed9ab2cb3` |
| `lib/screens/premium_screen.dart` | `f77d3d17d7a8f4443544201cbf37d7e9071a901c0aa65557f0fc95389cdfea01` |
| `lib/services/storage_service.dart` | `3d512ab9ad2e74743451dd36ca91f5337120a4a303cf46df233447189e1e2551` |
| `lib/services/backup_service.dart` | `812b6029e25fdff469061c027ec489d1d5267f2799fbc6b5f3175361a7b6f16e` |
| `lib/services/app_reload_service.dart` | `9082cb914be64341ed8a7ff6cf1f4b5090e32274733873488352891b6c27fbce` |
| `lib/services/legacy_record_migration.dart` | `d58cdaf8e0d1a47f62cb4358cdbe722c77e22caed657b148b29d145fbe79bd23` |
| `android/app/build.gradle.kts` | `e74c4b82f767c74db9afe01558df7509d2e87da675eae55cb732b6df8a3526cb` |
| `android/app/proguard-rules.pro` | `c39aa0e3972b664ca54b3b4eb8ffa20470d2f99f018ffc1fbfde9f1f06339abf` |
| `android/app/src/main/res/raw/keep.xml` | `f689b618e01d9835dc190015564669260e8cf02c75112e73c773f1701e1c8173` |
| `android/app/src/main/AndroidManifest.xml` | `eddbb767b26cfef550b9f3823b0d63f8bcce9c6fe1a76cbd428ebd02c1e4211c` |
| `android/app/google-services.json` | `9aa04490cec204b3ef413cd6d38b43ae22540c1e37177c3eea08d61b2720e327` |
| `lib/firebase_options.dart` | `e26f3ee96ddd0d1d6bcbc7b2d7fc3f875566bc495ae4aa82a51302359fd05222` |
| `backend/index.js` | `0165f9c2a04af159e08f4557b342eedefb91a689451ded8bdc64629f5e083739` |
| `backend/social-auth-core.js` | `73503cd8b63b2fd7eaf603a657144369d893c9737fb0669749588fde016bd58f` |
| `backend/garden-village.js` | `74e8040da3f9be441c71b991a5e5c6d436a07c4173ef06f45b32132bb77b7ffc` |
| `backend/policy.js` | `07d033d7b5d87fc6f7cfa441c116b750cb6b263c73c8e1a31a3bed0c329da87c` |
