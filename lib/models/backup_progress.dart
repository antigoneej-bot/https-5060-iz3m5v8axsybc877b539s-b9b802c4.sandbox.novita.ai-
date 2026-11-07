import '../l10n/app_language.dart';
import '../services/cloud_service.dart';
import 'account_status_summary.dart';

enum BackupPhase {
  off,
  restoring,
  unchanged,
  waiting,
  preparing,
  encrypting,
  uploading,
  saved,
  changedAfterSave,
  failed,
}

/// Keep state, not translated strings: changing language updates the same result.
class BackupProgress {
  const BackupProgress(this.phase, {this.confirmedAt, this.errorCode});
  final BackupPhase phase;
  final DateTime? confirmedAt;
  final String? errorCode;
  String get message => switch (phase) {
    BackupPhase.off => tr('자동 백업 꺼짐'),
    BackupPhase.restoring => tr('복원을 마친 뒤 자동 백업을 다시 시도해요'),
    BackupPhase.unchanged => tr('최근 확인한 기록까지 백업했어요. 새 기록은 앱 사용 중 다시 확인해요.'),
    BackupPhase.waiting => tr('새 기록 백업 대기 중 · 앱을 열어 두면 곧 저장해요'),
    BackupPhase.preparing => tr('백업 준비 중'),
    BackupPhase.encrypting => tr('기록을 암호화하고 있어요. 앱을 잠시 열어 두세요.'),
    BackupPhase.uploading => tr('암호화한 백업을 서버에 저장하고 있어요.'),
    BackupPhase.saved => tr('서버 백업 완료'),
    BackupPhase.changedAfterSave => tr('백업 후 새 기록이 생겼어요 · 다음 백업 대기 중'),
    BackupPhase.failed => _failure,
  };
  String get _failure => switch (errorCode) {
    'authentication-required' ||
    'authentication-timeout' ||
    'account-changed' ||
    'garden-owner-mismatch' ||
    'subscription-required' ||
    'attestation-timeout' ||
    'network-timeout' ||
    'account-busy' => CloudException(errorCode!).toString(),
    'password-unavailable' => tr('백업 암호를 불러오지 못했어요. 자동 백업 설정을 다시 확인해 주세요.'),
    'encryption-failed' => tr(
      '백업을 암호화하지 못했어요. 기기 기록은 유지돼요. 파일 백업 또는 재시도를 선택해 주세요.',
    ),
    'network-unavailable' => tr('서버에 연결하지 못했어요. 기기 기록은 유지돼요. 연결 후 다시 시도해 주세요.'),
    'receipt-unconfirmed' => tr('서버의 백업 완료 확인을 받지 못했어요. 마지막 성공 시각은 변경하지 않았어요.'),
    _ => tr('백업을 완료하지 못했어요. 기기 기록은 유지돼요. 다시 시도하거나 파일 백업을 이용해 주세요.'),
  };
  String get lastSuccess => confirmedAt == null
      ? tr('이 기기에서 확인한 서버 백업이 없어요. 파일 백업도 이용할 수 있어요.')
      : tr('마지막 서버 백업: {0}', [accountStatusDate(confirmedAt!)]);
}
