"""Encode actual Flutter home test frames; never synthesizes cat poses."""
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path

parser=argparse.ArgumentParser()
parser.add_argument('--directory', required=True, type=Path)
parser.add_argument('--ffmpeg', default='ffmpeg')
args=parser.parse_args()
directory=args.directory.resolve()
coats=['ginger','white','tabby','black','tuxedo','calico']
results=[]

def run(command, log):
    result=subprocess.run([args.ffmpeg,*command],capture_output=True,text=True)
    (directory/log).write_text(result.stdout+'\n'+result.stderr,encoding='utf-8')
    if result.returncode:
        raise RuntimeError('Video command failed; inspect '+str(directory/log))
    return result.stdout

def verify(file, expected):
    progress=run(['-v','error','-i',str(file),'-progress','pipe:1','-f','null','-'],file.stem+'-decode.log')
    counts=[int(line.split('=',1)[1]) for line in progress.splitlines() if line.startswith('frame=')]
    assert counts and counts[-1]==expected, (file.name,counts)
    return hashlib.sha256(file.read_bytes()).hexdigest()

for coat in coats:
    metadata=json.loads((directory/f'home-{coat}-execution.json').read_text(encoding='utf-8'))
    frames=directory/'home-video-frames'/coat
    assert len(list(frames.glob('frame-*.png')))==metadata['frames']==75
    assert len(metadata['poseTimeline'])==75 and set(metadata['poseTimeline']) >= {0,1,2,3}
    assert metadata['fps']==15
    output=directory/f'home-{coat}.mp4'
    run(['-y','-framerate','15','-start_number','0','-i',str(frames/'frame-%05d.png'),
         '-frames:v','75','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p',
         '-movflags','+faststart',str(output)],f'home-{coat}-encode.log')
    sha=verify(output,75)
    closed=metadata['poseTimeline'].index(2)
    shutil.copy2(frames/f'frame-{closed:05}.png',directory/f'home-{coat}-blink.png')
    results.append({'coat':coat,'file':str(output),'seconds':5,'frames':75,'fps':15,'sha256':sha,
                    'environment':metadata['environment']})

combined=directory/'home-six-companions.mp4'
inputs=[part for row in results for part in ['-i',row['file']]]
graph=''.join(f'[{i}:v]' for i in range(6))+'concat=n=6:v=1:a=0[home]'
run(['-y',*inputs,'-filter_complex',graph,'-map','[home]','-c:v','libx264',
     '-preset','fast','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(combined)],'home-six-companions-encode.log')
sha=verify(combined,450)
report={'videos':results,'combined':{'file':str(combined),'seconds':30,'frames':450,'fps':15,'sha256':sha},
        'provenance':'Production Home widgets and CompanionPresence animation controller executed in Flutter widget tests with virtual time and synthetic local data. Not an Android device screen recording. Original cat atlases, not AI-generated cat animation.'}
(directory/'HOME-VIDEO-VERIFICATION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'videos':6,'combined':str(combined),'framesDecoded':450,'sha256':sha},ensure_ascii=False))
