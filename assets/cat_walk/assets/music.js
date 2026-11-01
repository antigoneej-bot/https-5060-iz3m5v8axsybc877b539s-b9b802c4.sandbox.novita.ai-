// The app SoundService owns the single BGM player and existing effects.
let musicEnabled=false,musicVolume=.35,effectVolume=1,fxBus=null,musicCtx=null;
function musicStart(){WalkHost.postMessage(JSON.stringify({type:'startMusic'}))}
function musicStop(){} function silenceAudio(){} function musicTick(){}
function playEffect(freq){if(sound)WalkHost.postMessage(JSON.stringify({type:'chime'}))}
function purrEffect(){if(sound)WalkHost.postMessage(JSON.stringify({type:'purr'}))}
function musicControls(){const b=document.getElementById('musicToggle');b.textContent=musicEnabled?'앱 배경음악 켜짐':'앱 배경음악 꺼짐';b.setAttribute('aria-pressed',String(musicEnabled));document.getElementById('musicVolume').value=Math.round(musicVolume*100)}
function setupMusic(){musicControls();document.getElementById('effectVolume').parentElement.style.display='none';document.getElementById('musicToggle').onclick=()=>WalkHost.postMessage(JSON.stringify({type:'bgm',value:!musicEnabled}));document.getElementById('musicVolume').onchange=e=>WalkHost.postMessage(JSON.stringify({type:'volume',value:Number(e.target.value)/100}));}
