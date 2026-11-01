#!/usr/bin/env python3
"""마음냥 정원 v48: existing gardenApi source-only update for Google Cloud Shell.
Run without arguments to prepare and review. Run with --deploy to deploy.
Never prints environment variables or credentials. No database data is changed.
"""
import argparse, base64, hashlib, json, os, shutil, subprocess, sys, tempfile, zipfile, zlib
from pathlib import Path
PROJECT = 'mycatapp-99bc8'
REGION = 'asia-northeast3'
FUNCTION = 'gardenApi'
BASELINE_INDEX = '091d73e8eb7d9305e0540607b859a6480ac2c349a20fda562a2d2aefb8860a5a'
BASELINE_VILLAGE = '006d98b2cbd4a69436c73ba171da20b15fab22d3f539a394e44ef1f9ca2bfe65'
PAYLOAD = {'index.js': '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', 'cat-visits.js': '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'}

def sha(raw): return hashlib.sha256(raw).hexdigest()
def check_source(root):
    index = root / 'index.js'
    village = root / 'garden-village.js'
    new = {n: zlib.decompress(base64.b64decode(s)) for n,s in PAYLOAD.items()}
    if not index.is_file() or not village.is_file():
        raise RuntimeError('Expected backend files are absent. Nothing deployed.')
    if sha(village.read_bytes()) != BASELINE_VILLAGE:
        raise RuntimeError('Deployed garden-village.js differs from reviewed baseline. Nothing deployed.')
    if index.read_bytes() == new['index.js'] and (root/'cat-visits.js').is_file() and (root/'cat-visits.js').read_bytes() == new['cat-visits.js']:
        return False
    if sha(index.read_bytes()) != BASELINE_INDEX:
        raise RuntimeError('Deployed index.js differs from reviewed v47 baseline. Nothing deployed. Review this server version before merging.')
    if (root/'cat-visits.js').exists():
        raise RuntimeError('An unrecognized cat-visits.js already exists. Nothing deployed.')
    return new

def extract_safely(archive, target):
    with zipfile.ZipFile(archive) as z:
        for info in z.infolist():
            p=Path(info.filename)
            if p.is_absolute() or '..' in p.parts or (info.external_attr >> 16) & 0o170000 == 0o120000:
                raise RuntimeError('Unsafe source archive. Nothing deployed.')
        z.extractall(target)

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--deploy', action='store_true', help='Deploy the verified source patch to existing gardenApi')
    args=parser.parse_args()
    os.umask(0o077)
    for cmd in ['gcloud','node']:
        if not shutil.which(cmd): raise RuntimeError(cmd+' is required; run this in Google Cloud Shell.')
    flags=['--project='+PROJECT,'--region='+REGION,'--gen2']
    def describe():
        return json.loads(subprocess.check_output(['gcloud','functions','describe',FUNCTION,*flags,'--format=json'],text=True))
    meta=describe();build=meta.get('buildConfig',{});storage=build.get('source',{}).get('storageSource',{})
    if meta.get('environment')!='GEN_2' or build.get('entryPoint')!=FUNCTION or not storage.get('bucket') or not storage.get('object'):
        raise RuntimeError('Existing function identity/source could not be verified. Nothing deployed.')
    runtime=build.get('runtime','')
    if runtime!='nodejs22': raise RuntimeError('Expected existing Node.js 22 runtime. Nothing deployed.')
    work=Path(tempfile.mkdtemp(prefix='mindnyang-v48-',dir=Path.home()))
    archive=work/'original-source.zip';original=work/'original';patched=work/'patched'
    uri='gs://'+storage['bucket']+'/'+storage['object']
    if storage.get('generation'): uri+='#'+str(storage['generation'])
    subprocess.run(['gcloud','storage','cp',uri,str(archive),'--quiet'],check=True)
    extract_safely(archive,original)
    roots=[p.parent for p in original.rglob('index.js') if (p.parent/'garden-village.js').is_file()]
    if len(roots)!=1: raise RuntimeError('Cannot identify one backend source root. Nothing deployed.')
    root=roots[0];patch=check_source(root)
    if patch is False:
        print('v48 server code is already installed. No deployment needed.');return
    shutil.copytree(root,patched)
    for name,raw in patch.items(): (patched/name).write_bytes(raw)
    for name in patch: subprocess.run(['node','--check',str(patched/name)],check=True)
    # Default gcloud ignore handling preserves the original project configuration.
    deploy=['gcloud','functions','deploy',FUNCTION,*flags,'--runtime='+runtime,'--entry-point='+FUNCTION,'--source='+str(patched),'--quiet']
    rollback=[*deploy];rollback[rollback.index('--source='+str(patched))]='--source='+str(root)
    import shlex
    (work/'ROLLBACK.txt').write_text(shlex.join(rollback)+'\n')
    print('Verified patch ready:',patched)
    print('Original source and rollback command:',work)
    print('Only index.js and cat-visits.js change. No environment, secret, IAM, or database mutation flags are used.')
    if not args.deploy:
        print('Review these files; rerun this script with --deploy to apply.');return
    # Abort if another deployment happened while downloading/preparing.
    current=describe()
    if current.get('updateTime')!=meta.get('updateTime') or current.get('buildConfig',{}).get('source')!=build.get('source'):
        raise RuntimeError('Function changed during preparation. Nothing deployed; retry after review.')
    subprocess.run(deploy,check=True)
    after=describe()
    if after.get('state')!='ACTIVE': raise RuntimeError('Deployment did not report ACTIVE. Inspect Cloud Console; backup retained.')
    print('Deployment is ACTIVE. Test invitations with two accepted-neighbor accounts in the v48 app.')

if __name__=='__main__':
    try: main()
    except (RuntimeError,subprocess.CalledProcessError) as e:
        print('Stopped:',str(e),file=sys.stderr);sys.exit(1)
