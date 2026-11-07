#!/usr/bin/env python3
"""Read only configuration metadata for mycatapp-99bc8 in the owner's Cloud Shell.
No records, object contents, log entries, secrets, access tokens, writes or deployment.
Only allowlisted metadata is emitted. Unknown != pass. No shell interpolation.
"""
import json
import os
import re
import shutil
import subprocess
import sys

PROJECT = 'mycatapp-99bc8'
BUCKET = 'mycatapp-99bc8.firebasestorage.app'
QUERIES = [
 ('firestore', ['firestore','databases','describe','--database=(default)'],
  'locationId,type,pointInTimeRecoveryEnablement,versionRetentionPeriod,deleteProtectionState'),
 ('storage', ['storage','buckets','describe','gs://'+BUCKET],
  'location,soft_delete_policy,retention_policy,versioning_enabled'),
 ('logs', ['logging','buckets','list'],
  'name,retentionDays,lifecycleState,locked'),
 ('login_session_ttl', ['firestore','fields','ttls','list','--database=(default)'],
  'name,ttlConfig'),
 ('garden_runtime', ['functions','describe','gardenApi','--gen2','--region=asia-northeast3'],
  'state,updateTime,serviceConfig.environmentVariables.RELEASE_ENV,serviceConfig.environmentVariables.PREMIUM_TEST_ACCESS'),
]

def atom(value):
    if isinstance(value,bool) or isinstance(value,int): return value
    if isinstance(value,str) and re.fullmatch(r'[A-Za-z0-9_.():/ -]{1,250}',value): return value
    return 'UNKNOWN'

def safe_fields(value,fields):
    return {key:atom(value[key]) for key in fields if key in value}

def project_result(kind,value):
    if kind in ('logs','login_session_ttl'):
        if not isinstance(value,list): raise ValueError()
        out=[]
        for item in value:
            if not isinstance(item,dict): raise ValueError()
            name=item.get('name','')
            if kind=='logs':
                match=re.fullmatch(r'projects/[^/]+/locations/([A-Za-z0-9-]+)/buckets/([A-Za-z0-9_-]+)',name)
                if not match: continue
                row={'location':match[1], 'bucket':match[2], **safe_fields(item,['retentionDays','lifecycleState','locked'])}
            else:
                match=re.search(r'/collectionGroups/(socialAuthSessions|socialAuthStates|socialAuthLimits)/fields/expireAt$',name)
                if not match: continue
                config=item.get('ttlConfig') or {}
                row={'collection':match[1], 'field':'expireAt', 'state':atom(config.get('state'))}
            out.append(row)
        return out
    if not isinstance(value,dict): raise ValueError()
    if kind=='firestore':
        return safe_fields(value,['locationId','type','pointInTimeRecoveryEnablement','versionRetentionPeriod','deleteProtectionState'])
    if kind=='storage':
        out=safe_fields(value,['location','versioning_enabled'])
        for key in ['soft_delete_policy','retention_policy']:
            if isinstance(value.get(key),dict):
                # CLI naming depends on SDK version; absent values remain unknown.
                out[key]=safe_fields(value[key],['retentionDurationSeconds','retention_duration_seconds','retentionPeriod','retention_period','isLocked','is_locked'])
        return out
    env=(value.get('serviceConfig') or {}).get('environmentVariables') or {}
    return {**safe_fields(value,['state','updateTime']),
            'RELEASE_ENV':atom(env.get('RELEASE_ENV')),
            'PREMIUM_TEST_ACCESS':atom(env.get('PREMIUM_TEST_ACCESS'))}

def query(kind,args,fields,run=subprocess.run):
    env=os.environ.copy()
    env.update(CLOUDSDK_CORE_DISABLE_PROMPTS='1',CLOUDSDK_CORE_DISABLE_FILE_LOGGING='true',CLOUDSDK_CORE_LOG_HTTP='false')
    try:
        result=run(['gcloud',*args,'--project='+PROJECT,'--quiet','--verbosity=error','--format=json('+fields+')'],
                   stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=35,env=env,check=False)
        if result.returncode: return {'status':'UNKNOWN','reason':'QUERY_FAILED_OR_NO_PERMISSION'}
        if len(result.stdout)>2*1024*1024: return {'status':'UNKNOWN','reason':'RESPONSE_TOO_LARGE'}
        value=project_result(kind,json.loads(result.stdout))
        return {'status':'OBSERVED' if value else 'UNKNOWN','metadata':value}
    except (OSError,subprocess.TimeoutExpired,ValueError,TypeError,AttributeError):
        return {'status':'UNKNOWN','reason':'UNAVAILABLE_OR_INVALID_RESPONSE'}

def main():
    if not shutil.which('gcloud'):
        print(json.dumps({'status':'UNKNOWN','reason':'CLOUD_SHELL_REQUIRED','project':PROJECT}))
        return 2
    checks={kind:query(kind,args,fields) for kind,args,fields in QUERIES}
    print(json.dumps({'project':PROJECT,'read_only':True,'checks':checks,
      'notice':'OBSERVED means metadata was read, not policy approval. Missing fields/TTL and all live purchase/deletion tests remain unverified.'},ensure_ascii=False,indent=2))
    return 0 if all(r['status']=='OBSERVED' for r in checks.values()) else 2
if __name__=='__main__': sys.exit(main())
