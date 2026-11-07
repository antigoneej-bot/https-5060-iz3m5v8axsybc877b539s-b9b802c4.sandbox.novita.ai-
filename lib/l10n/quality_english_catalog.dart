const qualityEnglishCatalog = <String, String>{
  "오류 보고 공유는 기본으로 꺼져 있으며 사용 통계 공유와 별도로 선택합니다. 기록 보관과 백업에서 켜면 Firebase Crashlytics에 오류 유형·호출 위치, 앱·운영체제·기기 및 설치 진단 정보와 제한된 연결 소요 시간을 보내 안정성 개선에 사용합니다. 앱은 편지·감정 원문, 선택한 감정 ID, 이메일·계정 식별자와 인증 정보를 보고서에 직접 첨부하지 않습니다. 사용 통계에도 동의하면 이용 이벤트가 오류 분석에 포함될 수 있습니다.\n\n언제든 오류 보고 공유를 끌 수 있습니다. 끄면 앱의 새 오류 전송을 중단하고 SDK 수집 중지와 미전송 보고서 삭제를 시도합니다. SDK 적용 실패는 안내하며 앱을 다시 실행하면 저장된 끄기 설정을 다시 적용합니다. 이미 전송된 보고서가 즉시 삭제된다는 의미는 아닙니다. 수집을 새로 켜기 전에는 미전송 보고서 정리를 먼저 시도하고 정리에 실패하면 켜지 않습니다. Google의 진단 처리·보관 및 국외 처리에 관한 문의는 운영자에게 요청할 수 있습니다.":
      "Error reporting is off by default and is separate from usage analytics. When enabled in Storage & backup, Firebase Crashlytics receives error types, code locations, app, operating-system, device and installation diagnostics, and limited connection durations to improve reliability. The app does not directly attach letters, emotion text, selected emotion IDs, email addresses, account identifiers or authentication data. If you also consent to analytics, usage events may be included in error analysis.\n\nYou can turn error reporting off at any time. The app stops sending new error events and attempts to disable SDK collection and delete unsent reports. SDK failures are shown; restarting the app reapplies the saved off setting. Turning it off does not immediately delete reports already sent. Before enabling collection again, the app attempts to clear unsent reports and will not enable it if that cleanup fails. Contact the operator about Google diagnostic processing, retention or international processing.",
  "선택적 오류 보고": "Optional error reporting",
  "사용 통계 공유를 끄는 중이에요. 앱의 새 이벤트 전송은 중지했지만 기기 설정 적용을 확인하지 못했어요. 다시 시도해 주세요.":
      "Turning usage sharing off. The app has stopped sending new events, but the device setting is not yet confirmed. Please retry.",
  "알림 끄기를 선택했어요. 휴대전화의 예약 취소는 아직 확인하지 못해 알림이 올 수 있어요. 다시 시도하거나 휴대전화 설정에서 알림을 꺼 주세요.":
      "You've turned notifications off in the app. We haven't confirmed that your phone canceled them, so a notification may still arrive. Try again, or turn off notifications in your phone's settings.",

  '기록을 불러오지 못했어요. 기록을 삭제하지 않고 다시 시도할 수 있어요.':
      'Your records could not be loaded. You can retry without deleting them.',
  '로그인 확인이 오래 걸리고 있어요. 연결을 확인한 뒤 다시 시도해 주세요.':
      'Sign-in verification is taking longer than expected. Check your connection and try again.',
  '앱 인증 확인이 오래 걸리고 있어요. 잠시 후 다시 시도해 주세요.':
      'App verification is taking longer than expected. Please try again shortly.',
  '서버 응답이 늦어지고 있어요. 완료 여부를 확인한 뒤 다시 시도해 주세요.':
      'The server is taking longer to respond. Check whether the action completed before trying again.',
  '복원을 마친 뒤 자동 백업을 다시 시도해요':
      "Auto-backup will try again when the restore is complete.",
  '새 기록 백업 대기 중 · 앱을 열어 두면 곧 저장해요':
      "There are new entries to back up. Keep the app open to let the backup finish.",
  '백업 준비 중': 'Preparing backup',
  '기록을 암호화하고 있어요. 앱을 잠시 열어 두세요.':
      'Encrypting your records. Please keep the app open.',
  '암호화한 백업을 서버에 저장하고 있어요.': 'Saving your encrypted backup to the server.',
  '서버 백업 완료': "Cloud backup complete",
  '백업 후 새 기록이 생겼어요 · 다음 백업 대기 중':
      "You've added entries since the last backup. Waiting for the next one.",
  '백업 암호를 불러오지 못했어요. 자동 백업 설정을 다시 확인해 주세요.':
      'Your backup password could not be loaded. Check your automatic backup settings.',
  '백업을 암호화하지 못했어요. 기기 기록은 유지돼요. 파일 백업 또는 재시도를 선택해 주세요.':
      "Couldn't encrypt your backup. Your entries are still on this device. Try again or export a backup file.",
  '서버에 연결하지 못했어요. 기기 기록은 유지돼요. 연결 후 다시 시도해 주세요.':
      "Couldn't reach the server. Your entries are still on this device. Reconnect and try again.",
  '서버의 백업 완료 확인을 받지 못했어요. 마지막 성공 시각은 변경하지 않았어요.':
      'The server did not confirm the backup. The last successful backup time has not changed.',
  '백업을 완료하지 못했어요. 기기 기록은 유지돼요. 다시 시도하거나 파일 백업을 이용해 주세요.':
      "Couldn't finish the backup. Your entries are still on this device. Try again or export a backup file.",
  '마지막 서버 백업: {0}': 'Last confirmed server backup: {0}',
  '오류 보고 공유': 'Share error reports',
  '선택 사항이에요. 오류 유형·호출 위치와 기기 진단 정보를 Firebase에 보내요. 편지·감정 원문과 계정 식별자는 앱에서 첨부하지 않아요.':
      'Optional. Send error types, code locations and device diagnostics to Firebase. The app does not attach your letters, emotion text or account identifiers.',
  '복원한 기록을 다시 불러오고 있어요.': 'Reloading your restored records.',
  '기록을 다시 불러오지 못했어요. 저장된 기록은 유지돼요.':
      "Couldn't reload your entries. Your saved entries are still safe.",
  '다시 불러오기': 'Reload',
  '하루 첫 고양이 인사로 출석 보상을 받아요. 돌봄 포인트·빛의 정수·씨앗은 각각 사용하는 곳이 달라요. 추가 보상 통합은 준비 중이에요. 서버 기능은 로그인과 서버 연결이 필요해요.':
      "Say hello to your cat to earn a reward once a day. Care points, Light Essence, and seeds each have different uses. More ways to connect these rewards are still in development. Online features need sign-in and an internet connection.",
};
