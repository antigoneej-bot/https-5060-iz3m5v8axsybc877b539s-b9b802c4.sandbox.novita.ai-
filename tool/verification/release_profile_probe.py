"""Inspect actual production build arguments with a fake Flutter executable.
No key, package, upload, purchase, or production setting is created/changed.
"""
from pathlib import Path
import json, os, shutil, subprocess, tempfile
root=Path(__file__).resolve().parents[2]
output=Path(os.environ['RELEASE_PROFILE_OUTPUT'])
assert not output.exists(), 'Preserve previous evidence'
output.mkdir(parents=True)
fixture=Path(tempfile.mkdtemp(prefix='mindnyang-release-profile-'))
(fixture/'tool').mkdir();(fixture/'android').mkdir();(fixture/'bin').mkdir()
for name in ['android_build_config.sh','build_store_bundle.sh']:
 (fixture/'tool'/name).write_text((root/'tool'/name).read_text(encoding='utf-8'),encoding='utf-8',newline='\n')
# Only satisfy the presence preflight; no real keystore, alias or password.
(fixture/'android/key.properties').write_text('# synthetic presence fixture\n')
stub=fixture/'bin/flutter'
stub.write_text('#!/usr/bin/env bash\nprintf "CALL\\n" >> "$CAPTURE_FILE"\nprintf "%s\\n" "$@" >> "$CAPTURE_FILE"\n',newline='\n')
stub.chmod(0o755)
capture=fixture/'arguments.txt'
env=os.environ.copy()
for key in ['ADMOB_ANDROID_APP_ID','ADMOB_ANDROID_BANNER_ID','PRIVACY_OPERATOR','PRIVACY_CONTACT','PRIVACY_POLICY_URL','ACCOUNT_DELETION_URL']:
 env.pop(key,None)
env.update(PATH=str(fixture/'bin')+os.pathsep+env['PATH'],CAPTURE_FILE=capture.as_posix(),
 GARDEN_BACKEND_URL='https://gardenapi-zk2q7ixdva-du.a.run.app',
 SOCIAL_AUTH_URL='https://asia-northeast3-mycatapp-99bc8.cloudfunctions.net/socialAuth',
 UNLOCK_ALL_PREMIUM='true',APP_CHECK_DEBUG_PROVIDER='true',RELEASE_ENV='internal',ADMOB_TEST_ADS='false')
run=subprocess.run(['bash','tool/build_store_bundle.sh'],cwd=fixture,env=env,capture_output=True,text=True)
(output/'production-profile.log').write_text(run.stdout+run.stderr,encoding='utf-8')
assert run.returncode==0,run.stderr
calls=[x.splitlines() for x in capture.read_text().split('CALL\n') if x.strip()]
build=[x for x in calls if x[:2]==['build','appbundle']]
assert len(build)==1
args=build[0]
expected=['--release','--dart-define=UNLOCK_ALL_PREMIUM=false',
 '--dart-define=APP_CHECK_DEBUG_PROVIDER=false','--dart-define=TEST_SHOW_ONBOARDING=false',
 '--dart-define=RELEASE_ENV=production']
assert all(v in args for v in expected)
assert not any(v.endswith('=true') for v in args if 'UNLOCK_ALL_PREMIUM' in v or 'APP_CHECK_DEBUG_PROVIDER' in v)
assert not list(fixture.rglob('*.aab')) and not list(fixture.rglob('*.apk'))
result={'passed':True,'buildInvocations':calls,'realBuild':False,'realKeyUsed':False,
 'internal93ArtifactChanged':False,'inheritedTestFlagsOverridden':True,'fixture':str(fixture)}
(output/'RESULT.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print('Production argument preflight passed; original internal artifacts unchanged.')
