import test from 'node:test';
import assert from 'node:assert/strict';
import {confirmGardenBloom,bloomReceiptId} from '../garden-blooms.js';
function memoryDb(initial) {
 const docs = new Map(Object.entries(initial));
 return {docs, doc:p=>p, async runTransaction(fn) {
  const writes=[];
  const result=await fn({get:async p=>({exists:docs.has(p),data:()=>docs.get(p)}),update:(p,v)=>writes.push([p,{...docs.get(p),...v}]),set:(p,v)=>writes.push([p,v])});
  for(const [p,v] of writes)docs.set(p,v);
  return result;
 }};
}
const deps={stamp:()=> 'server-time',accountHash:uid=>'hash-'+uid};
test('planting emits exactly one notice and excludes recipient identity and diary',async()=>{
 const db=memoryDb({'users/receiver/receivedCheers/cheer1':{senderId:'sender',flowerKind:'tulip'}});
 const first=await confirmGardenBloom(db,'receiver','cheer1','tulip',deps);
 assert.deepEqual(first,{confirmed:true,notified:true});
 const notice=db.docs.get('users/sender/flowerBlooms/'+bloomReceiptId('receiver','cheer1'));
 assert.deepEqual(notice,{flowerKind:'tulip',createdAt:'server-time'});
 const second=await confirmGardenBloom(db,'receiver','cheer1','daisy',deps);
 assert.equal(second.notified,false);
 assert.equal(notice.flowerKind,'tulip');
 assert.equal([...db.docs.keys()].filter(k=>k.includes('/flowerBlooms/')).length,1);
});
test('caller cannot confirm another recipients cheer or invent sender/flower',async()=>{
 const db=memoryDb({'users/receiver/receivedCheers/cheer1':{senderId:'sender'}});
 await assert.rejects(confirmGardenBloom(db,'attacker','cheer1','tulip',deps),/cheer-not-found/);
 await assert.rejects(confirmGardenBloom(db,'receiver','../cheer1','tulip',deps),/invalid-bloom/);
 await assert.rejects(confirmGardenBloom(db,'receiver','cheer1','custom',deps),/invalid-bloom/);
 assert.equal(db.docs.size,1);
});
test('legacy and deleted sender records never create pretend notices or recreate account data',async()=>{
 for(const [cheer,lock] of [[{},{}],[{senderId:'sender'},{deleted:true}],[{senderId:'sender'},{deleting:true}]]){
  const db=memoryDb({'users/receiver/receivedCheers/cheer1':cheer,'accountLocks/hash-sender':lock});
  const result=await confirmGardenBloom(db,'receiver','cheer1','daisy',deps);
  assert.equal(result.notified,false);
  assert.equal([...db.docs.keys()].some(k=>k.includes('/flowerBlooms/')),false);
 }
});
