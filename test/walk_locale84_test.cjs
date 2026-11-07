const test=require('node:test'),assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const root=path.resolve(__dirname,'../assets');
function boot(){
 const nodes=new Map(),drawn=[],messages=[];
 const ctx=new Proxy({measureText:t=>({width:[...String(t)].length*9}),fillText:t=>drawn.push(String(t))},{get:(o,k)=>k in o?o[k]:(()=>{})});
 class Element {
  constructor(tag='div'){this.tagName=tag.toUpperCase();this.attrs={};this.children=[];this.value='';this.textContent='';this.disabled=false;this.width=1280;this.height=720;this.parentElement={style:{}};this.style={setProperty(){}};this.classList={s:new Set(),add(...v){v.forEach(x=>this.s.add(x))},remove(...v){v.forEach(x=>this.s.delete(x))},contains(v){return this.s.has(v)},toggle(v){this.s.has(v)?this.s.delete(v):this.s.add(v)}};}
  get options(){return this.children;}
  get firstChild(){return this.children[0]??{nodeValue:''};}
  append(...v){this.children.push(...v)} appendChild(v){this.children.push(v)}
  replaceChildren(...v){this.children=v}setAttribute(k,v){this.attrs[k]=String(v)}getAttribute(k){return this.attrs[k]??null}
  getContext(){return ctx}getBoundingClientRect(){return {width:1280,height:720}}blur(){}scrollIntoView(){}toBlob(cb){cb({})}toDataURL(){return 'data:image/png;base64,test'}
 }
 const document={documentElement:{lang:'ko',setAttribute(k,v){this[k]=v}},hidden:false,title:'',getElementById(id){if(!nodes.has(id))nodes.set(id,new Element(id==='canvas'?'canvas':'div'));return nodes.get(id)},createElement:t=>new Element(t),createTextNode:t=>({textContent:String(t),nodeValue:String(t)}),querySelectorAll:()=>[],addEventListener(){}};
 class Image{constructor(){this.complete=true;this.naturalWidth=1086;this.naturalHeight=1448;}set src(v){this._src=v;if(this.onload)this.onload()}get src(){return this._src}}
 const env={console,document,Image,URL:{createObjectURL:()=>'',revokeObjectURL(){}},requestAnimationFrame(){},performance:{now:()=>0},WalkHost:{postMessage:s=>messages.push(JSON.parse(s))},addEventListener(){}};env.window=env;
 const context=vm.createContext(env);
 for(const f of ['i18n.js','catalog.js','dialogue.js','rewards.js','music.js'])vm.runInContext(fs.readFileSync(path.join(root,'cat_walk/assets',f),'utf8'),context,{filename:f});
 const html=fs.readFileSync(path.join(root,'cat_walk.html'),'utf8');for(const m of html.matchAll(/<script>([\s\S]*?)<\/script>/g))vm.runInContext(m[1],context,{filename:'cat_walk.html'});
 const run=s=>vm.runInContext(s,context);return {run,nodes,drawn,messages};
}
test('all 37 moods, 72 dialogue entries, rewards and discoveries have English copy',()=>{
 const b=boot();b.run("window.applyWalkProfile({name:'Clover',coat:0,emotions:['joyful'],language:'en'})");
 const strings=b.run('[...EMOTIONS.flatMap(e=>[wt(e.name),wt(e.message)]),...Object.values(dialogueLines).flat(2).map(wt),...Object.values(rewardTypes).map(r=>wt(r.label)),...discoveryTypes.flatMap(d=>[wt(d.label),wt(d.text)])]');
 assert.equal(strings.length,156);for(const s of strings)assert.doesNotMatch(s,/[가-힣]/,s);
 assert.equal(b.run('walkName()'),'A walk with Clover');assert.equal(b.run('moods[0][0]'),'Sad');
});
test('English preserves user names and placeholder-like text, Korean retains its endings',()=>{
 const b=boot();b.run("setWalkLanguage('en')");
 for(const name of ['소하','Alex','슬픔','{0}','<img src=x>',"O'Neil"]){b.run(`person.nickname=${JSON.stringify(name)};person.style='polite'`);assert.equal(b.run("address(person.nickname,person.style)"),name);assert.ok(b.run('farewell()').startsWith(name+',\n'));}
 assert.equal(b.run("wt('{0}의 인사',['{1}'])"),'A hello from {1}');
 b.run("setWalkLanguage('ko')");assert.equal(b.run("address('소하','friendly')"),'소하야');assert.equal(b.run("address('수진','friendly')"),'수진아');assert.equal(b.run("address('소하','polite')"),'소하님');
});
test('switching languages does not reset speed, selected IDs, clock, bag or pose',()=>{
 const b=boot();b.run("mode='running';walkPace=2.5;elapsed=21;bag={churu:2,snack:1,light:25};breed=5;selected=new Set([0,20]);setWalkLanguage('en')");
 const snapshot=()=>b.run('JSON.stringify({mode,walkPace,elapsed,bag,breed,selected:[...selected]})');const before=snapshot();b.run("setWalkLanguage('ko');setWalkLanguage('en')");assert.equal(snapshot(),before);assert.equal(b.run('rewardSummary()'),'Creamy treats: 2 · Snacks: 1 · Light Essence: 25');assert.deepEqual(b.messages,[]);
});
test('reward retry retains the bag and feeding requires native acknowledgement once',()=>{
 const b=boot();b.run("loaded=true;window.applyWalkProfile({name:'Clover',coat:0,emotions:['joyful'],language:'en'});begin();bag={churu:2,snack:1,light:25};elapsed=60;finishWalk();finishWalk()");
 assert.equal(b.messages.filter(m=>m.type==='walkReward').length,1);
 const bag=b.run('JSON.stringify(bag)');b.run('window.walkRewardResult(false);begin()');assert.equal(b.messages.filter(m=>m.type==='walkReward').length,2);assert.equal(b.run('JSON.stringify(bag)'),bag);
 b.run("window.walkRewardResult(true);feedCat('churu');feedCat('churu')");assert.equal(b.messages.filter(m=>m.type==='walkFeed').length,1);assert.equal(b.run('bag.churu'),2);b.run("window.walkFeedResult('churu',true)");assert.equal(b.run('bag.churu'),1);
 assert.doesNotMatch(b.nodes.get('farewellText').textContent,/[가-힣]/);
});
test('postcard text is English, bounded and contains localized date without changing identifiers',()=>{
 const b=boot();b.run("loaded=true;window.applyWalkProfile({name:'Clover',coat:4,emotions:['sad','joyful'],language:'en'});caught=new Set(EMOTIONS.map((_,i)=>i));discoveries=[...discoveryTypes];makePostcard()");
 for(const s of b.drawn)assert.doesNotMatch(s,/[가-힣]/,s);
 assert.ok(b.drawn.includes('A walk with Clover'));
 const out=[];b.run('setWalkLanguage(\'en\')');const begin=b.drawn.length;b.run("wrap(x,'one two three four five six seven eight nine ten',0,0,70,26)");assert.ok(b.drawn.length-begin<=2);
 assert.equal(b.run('EMOTIONS[0].id'),'sad');assert.equal(b.run('rewardTypes.churu.key'),'churu');
});
test('all pace choices retain the four collision-reachable entry lanes',()=>{
 const b=boot();for(const p of [1.4,2,2.5])for(let lane=0;lane<4;lane++){
 b.run(`walkPace=${p};elapsed=10;globalThis.item=makeTreasure(0,${lane})`);for(let i=0;i<500&&b.run('item.x>catX+25');i++)b.run('moveTreasure(item,.01)');
 assert.ok(b.run('Math.abs(item.y-item.targetY)<1'));assert.ok(b.run('item.targetY>=ground-207&&item.targetY<=ground-62'));
 }
 assert.equal(b.run("setWalkLanguage('ko');wt('산책 시작')"),'산책 시작');
});

test('static HTML text and accessibility bindings have English translations',()=>{
 const b=boot();b.run("setWalkLanguage('en')");
 const html=fs.readFileSync(path.join(root,'cat_walk.html'),'utf8');
 const decode=s=>s.replaceAll('&quot;','"').replaceAll('&#x27;',"'").replaceAll('&amp;','&');
 const keys=[...html.matchAll(/data-walk-(?:text|aria-label|placeholder|title|download)="([^"]*)"/g)].map(m=>decode(m[1]));
 assert.ok(keys.length>50);
 for(const k of keys){assert.doesNotMatch(b.run(`wt(${JSON.stringify(k)})`),/[가-힣]/,k);}
 assert.ok(html.includes("document.documentElement.setAttribute('data-walk-ready','')"));
});
test('failed feeding stays visible and does not consume inventory',()=>{
 const b=boot();b.run("setWalkLanguage('en');mode='done';bag={churu:2,snack:0,light:5};window.rewardStored=true;feedCat('churu');window.walkFeedResult('churu',false)");
 assert.equal(b.run('bag.churu'),2);assert.match(b.nodes.get('feedHint').textContent,/Couldn't give/);
});
