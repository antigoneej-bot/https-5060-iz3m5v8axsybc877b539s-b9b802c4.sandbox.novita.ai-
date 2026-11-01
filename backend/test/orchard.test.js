import test from 'node:test';import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';import {getOrchard,mutateOrchard} from '../orchard.js';
const start=Date.parse('2026-10-29T00:00:00Z'),day=86400000;let sequence=0;
const run=(db,op,kind='apple',extra={},now=start)=>mutateOrchard(db,'a',{requestId:(++sequence).toString(16).padStart(32,'0'),op,kind,...extra},{now});
const state=(db,now=start)=>getOrchard(db,'a',{}, {now});
async function ripe(db){await state(db);await run(db,'harvest','apple',{},start+7*day);}
test('one free apple persists; natural growth never withers and yields 10 without care',async()=>{
 const db=memoryDb();assert.deepEqual((await state(db)).orchard.stock,{});assert.equal((await state(db)).orchard.trees.apple.stage,0);
 await assert.rejects(run(db,'harvest'),/orchard-not-ready/);
 assert.equal((await state(db,start+100*day)).orchard.trees.apple.yield,10);
 const r=await run(db,'harvest','apple',{},start+100*day);assert.equal(r.orchard.stock.apple,10);assert.equal(r.orchard.trees.apple.cycle,1);assert.equal(r.orchard.trees.apple.stage,0);
 await assert.rejects(run(db,'harvest','apple',{},start+100*day),/orchard-not-ready/);
});
test('care once per Korean day, at most five times, yields 30 and no repeat on harvest day',async()=>{
 const db=memoryDb();await state(db);
 for(let i=0;i<5;i++){await run(db,'water','apple',{},start+i*day);await assert.rejects(run(db,'water','apple',{},start+i*day),/orchard-watered/);}
 const r=await run(db,'harvest','apple',{},start+4.5*day);assert.equal(r.result.quantity,30);
 await assert.rejects(run(db,'water','apple',{},start+4.5*day),/orchard-watered/);
});
test('sale funds seedlings; owned trees cannot be bought twice; stock cannot go negative',async()=>{
 const db=memoryDb();await ripe(db);await assert.rejects(run(db,'buy','persimmon'),/orchard-coins/);
 await run(db,'sell','apple',{quantity:10});const r=await run(db,'buy','persimmon');assert.equal(r.orchard.coins,0);assert.ok(r.orchard.trees.persimmon);
 await assert.rejects(run(db,'buy','persimmon'),/orchard-owned/);await assert.rejects(run(db,'sell'),/orchard-stock/);
});
test('replayed and concurrent sale request is exactly once; altered payload conflicts',async()=>{
 const db=memoryDb();await ripe(db);const body={requestId:'f'.repeat(32),op:'sell',kind:'apple',quantity:5};
 await Promise.all([mutateOrchard(db,'a',body),mutateOrchard(db,'a',body)]);assert.equal((await state(db)).orchard.coins,25);assert.equal((await state(db)).orchard.stock.apple,5);
 await assert.rejects(mutateOrchard(db,'a',{...body,quantity:4}),/request-conflict/);
});
test('competing harvest and sale operations conserve inventory',async()=>{
 const db=memoryDb();await state(db);const rs=await Promise.allSettled([run(db,'harvest','apple',{},start+8*day),run(db,'harvest','apple',{},start+8*day)]);assert.equal(rs.filter(r=>r.status==='fulfilled').length,1);
 const sales=await Promise.allSettled([run(db,'sell','apple',{quantity:10}),run(db,'sell','apple',{quantity:10})]);assert.equal(sales.filter(r=>r.status==='fulfilled').length,1);assert.equal((await state(db)).orchard.coins,50);
});
const neighbor=()=>memoryDb({'users/a/neighbors/b':{status:'accepted'},'users/b/neighbors/a':{status:'accepted'},'villageProfiles/a':{nickname:'보리'},'villageProfiles/b':{receiveGifts:true}});
test('gift atomically transfers stock to offline neighbor, preserves sender label and cannot duplicate',async()=>{
 const db=neighbor();await ripe(db);const body={requestId:'d'.repeat(32),op:'gift',kind:'apple',quantity:3,gardenId:'b'};await mutateOrchard(db,'a',body);await mutateOrchard(db,'a',body);
 const a=(await state(db)).orchard,b=(await getOrchard(db,'b',{})).orchard;assert.equal(a.stock.apple,7);assert.equal(b.stock.apple,3);assert.equal(b.gifts.length,1);assert.equal(b.gifts[0].senderName,'보리');
});
test('gift refusal and either block or missing reciprocal neighbor leave both inventories unchanged',async()=>{
 for(const [path,value] of [['villageProfiles/b',{receiveGifts:false}],['users/a/blockedNeighbors/b',{}],['users/b/blockedNeighbors/a',{}],['users/b/neighbors/a',{status:'none'}]]){
 const db=neighbor();await ripe(db);await db.doc(path).set(value);await assert.rejects(run(db,'gift','apple',{quantity:3,gardenId:'b'}),/gifts-disabled|neighbor-required/);assert.equal((await state(db)).orchard.stock.apple,10);assert.equal((await getOrchard(db,'b',{})).orchard.stock.apple,undefined);
 }
});
test('invalid quantities, unknown kind, target paths and non-cat fruit feeding are rejected',async()=>{
 const db=neighbor();await ripe(db);
 for(const quantity of [0,-1,1.5,1000,'2'])await assert.rejects(run(db,'sell','apple',{quantity}),/invalid-orchard/);
 await assert.rejects(run(db,'buy','unknown'),/invalid-orchard/);await assert.rejects(run(db,'gift','apple',{gardenId:'../b'}),/invalid-target/);await assert.rejects(run(db,'feed','apple'),/invalid-orchard/);assert.equal((await state(db)).orchard.stock.apple,10);
});
test('feeding consumes one cat snack and replay does not consume again',async()=>{
 const db=memoryDb({'users/a/orchard/state':{coins:0,trees:{},stock:{tuna:2},gifts:[],fed:0}});const body={requestId:'c'.repeat(32),op:'feed',kind:'tuna'};await mutateOrchard(db,'a',body);await mutateOrchard(db,'a',body);const s=(await state(db)).orchard;assert.equal(s.stock.tuna,1);assert.equal(s.fed,1);
});
