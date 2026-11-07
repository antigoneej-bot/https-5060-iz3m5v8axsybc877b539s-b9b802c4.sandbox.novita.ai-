from pathlib import Path
import shutil, os
root=Path(__file__).resolve().parent.parent
lines=['마음냥 정원 빌드 환경 확인 (키/비밀번호 내용은 읽거나 출력하지 않음)']
for name in ['flutter','dart','java','adb','node','python3']:
 lines.append(f'{name}: '+('사용 가능' if shutil.which(name) else '명령 경로에서 찾지 못함'))
lines.append('현재 프로젝트 Android 서명 설정: '+('있음' if (root/'android/key.properties').is_file() else '없음'))
found=[]
for folder in ['Downloads','Desktop','Documents']:
 base=Path.home()/folder
 if not base.is_dir():continue
 count=0
 for current,dirs,files in os.walk(base):
  count+=1
  rel=Path(current).relative_to(base)
  dirs[:]=[x for x in dirs if not x.startswith('.') and x not in ['node_modules','build','Pods']]
  if len(rel.parts)>=5:dirs[:]=[]
  if count>5000:break
  if Path(current).name=='android' and 'key.properties' in files:
   found.append(str(Path(current).parent))
lines.append('기존 서명 설정 후보 프로젝트 폴더:')
lines.extend(found or ['기본 검색 범위에서 찾지 못함. 예전에 APK를 만든 작업 환경 확인이 필요합니다.'])
lines.append('key.properties가 있어도 실제 서명 키의 존재·일치 여부는 별도 확인해야 합니다.')
lines.append('이 결과는 환경 진단이며 앱 검사·빌드 성공 결과가 아닙니다.')
text='\n'.join(lines)+'\n'
(root/'BUILD-ENVIRONMENT-RESULT.txt').write_text(text)
print(text)
