"""Encode frames captured from the production garden widget; no generated imagery."""
import argparse, hashlib, json, subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--directory',type=Path,required=True);p.add_argument('--ffmpeg',default='ffmpeg');a=p.parse_args()
def run(args,name):
 r=subprocess.run([a.ffmpeg,*args],capture_output=True,text=True)
 (a.directory/name).write_text(r.stdout+'\n'+r.stderr,encoding='utf-8')
 assert r.returncode==0,name
 return r.stdout
def verify(file,frames):
 s=run(['-v','error','-i',str(file),'-progress','pipe:1','-f','null','-'],file.stem+'-decode.log')
 assert [int(l.split('=')[1]) for l in s.splitlines() if l.startswith('frame=')][-1]==frames
 return hashlib.sha256(file.read_bytes()).hexdigest()
rows=[]
for name in ['day','night']:
 meta=json.loads((a.directory/f'nature-{name}-execution.json').read_text())
 frames=a.directory/f'nature-{name}-frames';assert len(list(frames.glob('frame-*.png')))==meta['frames']==75
 out=a.directory/f'nature-{name}.mp4'
 run(['-y','-framerate','15','-i',str(frames/'frame-%05d.png'),'-frames:v','75','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(out)],f'nature-{name}-encode.log')
 rows.append({'file':str(out),'frames':75,'seconds':5,'sha256':verify(out,75),'environment':meta['environment']})
combined=a.directory/'nature-day-night.mp4'
run(['-y','-i',rows[0]['file'],'-i',rows[1]['file'],'-filter_complex','[0:v][1:v]concat=n=2:v=1:a=0[v]','-map','[v]','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',str(combined)],'nature-combined-encode.log')
result={'videos':rows,'combined':{'file':str(combined),'frames':150,'seconds':10,'sha256':verify(combined,150)},'environment':'Flutter production widget rendering with virtual time and synthetic data; not Android/emulator recording'}
(a.directory/'NATURE-VIDEO-VERIFICATION.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({'videos':2,'combinedFramesDecoded':150}))
