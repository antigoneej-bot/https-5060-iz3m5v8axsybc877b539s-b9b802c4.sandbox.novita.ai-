import subprocess, os, json
from pathlib import Path
project=str(Path(__file__).resolve().parents[2])
app='ca-app-pub-1234567890123456~1234567890';banner='ca-app-pub-1234567890123456/1234567890'
cases=[({},0),({'ADMOB_ANDROID_APP_ID':app},1),({'ADMOB_ANDROID_BANNER_ID':banner},1),({'ADMOB_ANDROID_APP_ID':app,'ADMOB_ANDROID_BANNER_ID':banner},0),({'ADMOB_ANDROID_APP_ID':app,'ADMOB_ANDROID_BANNER_ID':banner.replace('1234567890123456','1111111111111111')},1),({'ADMOB_TEST_ADS':'true'},0),({'ADMOB_TEST_ADS':'yes'},1),({'ADMOB_ANDROID_APP_ID':'ca-app-pub-3940256099942544~3347511713','ADMOB_ANDROID_BANNER_ID':'ca-app-pub-3940256099942544/9214589741'},1)]
for env, expected in cases:
 e={k:v for k,v in os.environ.items() if not k.startswith('ADMOB_')};e.update(env)
 r=subprocess.run(['bash','-c','set -eu; source tool/android_build_config.sh; android_release_args=(--release); prepare_android_ads; declare -p android_release_args'],cwd=project,env=e,text=True,capture_output=True)
 assert (r.returncode==0)==(expected==0),(env,r.stdout,r.stderr)
 if env.get('ADMOB_TEST_ADS')=='true': assert 'ADMOB_TEST_ADS=true' in r.stdout
 if env.get('ADMOB_ANDROID_APP_ID')==app and expected==0:assert app in r.stdout and banner in r.stdout
print(json.dumps({'build_configuration_checks':len(cases),'passed':len(cases)}))
