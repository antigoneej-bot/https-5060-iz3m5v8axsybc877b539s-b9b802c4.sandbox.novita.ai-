// Runs real file persistence across fresh Flutter tester processes.
// Requires FLUTTER_SDK and an empty SYNTHETIC_RECOVERY_OUTPUT directory.
const fs=require('fs'),path=require('path'),cp=require('child_process');
const sdk=process.env.FLUTTER_SDK,out=process.env.SYNTHETIC_RECOVERY_OUTPUT;
if(!sdk||!out||!path.isAbsolute(out)||fs.existsSync(out))throw Error('Use a new absolute synthetic output directory and FLUTTER_SDK');
fs.mkdirSync(out,{recursive:true});fs.writeFileSync(path.join(out,'SYNTHETIC-ONLY'),'Generated test fixtures only. No device or user data.\n');
const dart=path.join(sdk,'bin/cache/dart-sdk/bin',process.platform==='win32'?'dart.exe':'dart');
const snapshot=path.join(sdk,'bin/cache/flutter_tools.snapshot');
const results=[];
(async()=>{
 for(const phase of ['source','fresh','reopen','interrupt','resume','corrupt']){
  const fd=fs.openSync(path.join(out,phase+'.log'),'w');
  const code=await new Promise((resolve,reject)=>{
   const child=cp.spawn(dart,[snapshot,'--suppress-analytics','test','--no-pub','--reporter','expanded','--concurrency','1','tool/verification/recovery_process_probe_test.dart'],{cwd:path.resolve(__dirname,'..'),windowsHide:true,env:{...process.env,MINDNYANG_RECOVERY_RUN:out,MINDNYANG_RECOVERY_PHASE:phase},stdio:['ignore',fd,fd]});
   child.on('error',reject);child.on('close',resolve);
  });fs.closeSync(fd);results.push({phase,code});
  fs.writeFileSync(path.join(out,'run-status.json'),JSON.stringify({results,running:code===0,physicalDevice:false,nativePreferences:false,realEncryptedFiles:true},null,2));
  if(code!==0)throw Error('Phase failed: '+phase);
 }
 const pids=results.map(x=>JSON.parse(fs.readFileSync(path.join(out,x.phase+'-result.json'))).pid);
 if(new Set(pids).size!==pids.length)throw Error('Expected independent test processes');
 fs.writeFileSync(path.join(out,'run-status.json'),JSON.stringify({results,pids,running:false,completed:true,physicalDevice:false,nativePreferences:false,realEncryptedFiles:true},null,2));
 console.log('Six independent process phases passed; synthetic files retained for review.');
})().catch(e=>{console.error(e.message);process.exitCode=1;});
