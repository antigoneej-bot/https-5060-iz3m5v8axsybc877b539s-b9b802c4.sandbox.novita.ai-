"""Run the cumulative patch's real Flutter checks once, in dependency order.
No SDK installation, server restart, signing, or deployment is performed.
"""
import argparse
from pathlib import Path
import shutil
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--flutter', default='flutter', help='Flutter executable path')
parser.add_argument('--full', action='store_true', help='Run the whole test suite instead of the focused suite')
parser.add_argument('--web', action='store_true', help='Build web release once after checks pass')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
flutter = shutil.which(args.flutter)
if not flutter:
    sys.exit('Flutter SDK를 찾지 못했습니다. --flutter /경로/flutter/bin/flutter 로 지정하세요. 앱 검사와 빌드는 실행하지 않았습니다.')
logs = root / 'verification' / 'flutter-refinement'
logs.mkdir(parents=True, exist_ok=True)
focused = [
    'test/draft_service_test.dart', 'test/legacy_scope_migration_test.dart',
    'test/meditation_completion_recovery_test.dart', 'test/meditation_course_test.dart',
    'test/notification_consent_test.dart', 'test/garden_navigation_test.dart',
    'test/restore_complete_dialog_test.dart', 'test/subscription_provider_refresh_test.dart', 'test/cat_care_startup_test.dart',
    'test/reliability_regression_test.dart', 'test/backup_safety_test.dart',
    'test/meditation_library_test.dart', 'test/meditation_audio_test.dart',
    'test/meditation_sleep_test.dart', 'test/meditation_video_completion_test.dart',
    'test/runner_readiness_test.dart', 'test/mongi_sound_readiness_test.dart',
    'test/core_experience_test.dart', 'test/self_care_test.dart',
    'test/garden_world_view_test.dart',
]
steps = [
    ('dependencies', ['pub', 'get']),
    ('analysis', ['analyze', '--no-pub', '--no-fatal-infos', '--no-fatal-warnings']),
    ('tests', ['test', '--no-pub', *([] if args.full else focused)]),
]
if args.web:
    steps.append(('web-build', ['build', 'web', '--release', '--no-pub']))
for name, command in steps:
    print(f'{name}: 시작', flush=True)
    with (logs / f'{name}.log').open('w') as log:
        result = subprocess.run([flutter, *command], cwd=root, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        sys.exit(f'{name}: 실패({result.returncode}). 다음 단계는 실행하지 않았습니다. 로그: {logs / (name + ".log")}')
    print(f'{name}: 통과', flush=True)
print('요청한 Flutter 검사가 완료됐습니다. 실기기 조작·결제·기기 간 통신 검증은 별도로 필요합니다.')
