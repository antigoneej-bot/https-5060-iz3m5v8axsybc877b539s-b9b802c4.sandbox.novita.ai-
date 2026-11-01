import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import {setPushDevice,queuePush,deliverPushJob,eventNoticeChanged} from '../push-notifications.js';
const token='device-token-abcdefghijklmnopqrstuvwxyz123456789';
const now=Date.now();
async function job(db,uid='a',category='social') {
  await db.runTransaction(async tx=>queuePush(tx,db,'same-event',uid,category,now));
  return [...db.rows.keys()].find(p=>p.startsWith('gardenPushJobs/')).split('/')[1];
}
test('opt-in is required and account changes cannot leave token attached to previous owner',async()=>{
  const db=memoryDb(); await setPushDevice(db,'a',{token,enabled:true,social:true,booking:false},now);
  await setPushDevice(db,'b',{token,enabled:true,social:true,booking:false},now);
  await setPushDevice(db,'a',{token,enabled:false},now);
  let sends=0;await deliverPushJob(db,await job(db),{send:async()=>sends++},now);
  assert.equal(sends,0);assert.equal([...db.rows.values()].find(v=>v.token===token).uid,'b');
});
test('successful receipt suppresses duplicate trigger; private text never enters payload',async()=>{
  const db=memoryDb();await setPushDevice(db,'a',{token,enabled:true,social:true,booking:false},now);
  const id=await job(db);const messages=[];const sender={send:async msg=>messages.push(msg)};
  await deliverPushJob(db,id,sender,now);await deliverPushJob(db,id,sender,now);
  assert.equal(messages.length,1);assert.deepEqual(Object.keys(messages[0].data).sort(),['kind','notice','owner']);
});
test('failed transport retries while invalid tokens are removed',async()=>{
  const db=memoryDb();await setPushDevice(db,'a',{token,enabled:true,social:true,booking:true},now);const id=await job(db);
  await assert.rejects(deliverPushJob(db,id,{send:async()=>{throw {code:'messaging/server-unavailable'};}},now),/push-delivery-retry/);
  let sends=0;await deliverPushJob(db,id,{send:async()=>sends++},now+1);assert.equal(sends,1);
  const db2=memoryDb();await setPushDevice(db2,'a',{token,enabled:true,social:true,booking:true},now);
  await deliverPushJob(db2,await job(db2),{send:async()=>{throw {code:'messaging/registration-token-not-registered'};}},now);
  assert.equal([...db2.rows.keys()].some(k=>k.startsWith('gardenPushDevices/')),false);
});
test('opt-out, disabled category, expired and stale device do not send',async()=>{
  for (const kind of ['off','category','expired','stale']) {
    const db=memoryDb();await setPushDevice(db,'a',{token,enabled:true,social:kind!=='category',booking:true},kind==='stale'?now-31*86400000:now);
    const id=await job(db);if(kind==='off')await setPushDevice(db,'a',{token,enabled:false},now);
    let sends=0;await deliverPushJob(db,id,{send:async()=>sends++},kind==='expired'?now+86400001:now);assert.equal(sends,0,kind);
  }
});
test('seat counts and intake closure are not cancellations; actual venue or canceled session changes notify',()=>{
  const a={type:'event',title:'모임',location:'A',sessions:[{id:'a',state:'open',reservedCount:1}]};
  assert.equal(eventNoticeChanged(a,{...a,reservedCount:3,sessions:[{...a.sessions[0],reservedCount:3,state:'closed'}]}),false);
  assert.equal(eventNoticeChanged(a,{...a,location:'B'}),true);
  assert.equal(eventNoticeChanged(a,{...a,sessions:[{...a.sessions[0],state:'canceled'}]}),true);
});

test('booking fanout uses bounded pages and notifies each eligible reservation once',async()=>{
 const db=memoryDb();const id='fanout';await db.doc(`gardenPushJobs/${id}`).set({kind:'bookingFanout',newsId:'event',title:'모임',createdAt:now,expiresAt:now+86400000,state:'queued'});
 for(let i=0;i<105;i++)await db.doc(`gardenNewsReservations/booking${String(i).padStart(3,'0')}`).set({uid:`person${i}`,newsId:'event',createdAt:new Date(now-1000).toISOString()});
 await db.doc('gardenNewsReservations/future').set({uid:'new-person',newsId:'event',createdAt:new Date(now+1).toISOString()});
 await assert.rejects(deliverPushJob(db,id,{},now),/push-fanout-continue/);
 await deliverPushJob(db,id,{},now+1);await deliverPushJob(db,id,{},now+2);
 const queued=[...db.rows.values()].filter(v=>v.category==='booking');assert.equal(queued.length,105);
 assert.equal(queued.some(v=>v.uid==='new-person'),false);assert.equal(db.rows.get(`gardenPushJobs/${id}`).state,'sent');
});

test('new clients select bell or silent channel and old clients retain legacy channel',async()=>{
 for(const bell of [true,false,undefined]) {
  const db=memoryDb();await setPushDevice(db,'a',{token,enabled:true,social:true,booking:true,...(bell===undefined?{}:{bellSound:bell})},now);
  const messages=[];await deliverPushJob(db,await job(db),{send:async m=>messages.push(m)},now);
  assert.equal(messages[0].android.notification.channelId,bell===true?'garden_updates_bell_v1':bell===false?'garden_updates_silent_v1':'garden_updates');
  assert.equal(messages[0].android.notification.sound,bell===true?'garden_bell':undefined);
 }
 const db=memoryDb();await assert.rejects(setPushDevice(db,'a',{token,enabled:true,social:true,booking:true,bellSound:'yes'},now),/invalid-push-settings/);
});
test('simultaneous deliveries use one bell and silent subsequent channel',async()=>{
 const db=memoryDb();await setPushDevice(db,'a',{token,enabled:true,social:true,booking:true,bellSound:true},now);
 for(const id of ['one','two']) await db.doc(`gardenPushJobs/${id}`).set({uid:'a',category:'social',createdAt:now,expiresAt:now+10000,state:'queued'});
 const messages=[];for(const id of ['one','two'])await deliverPushJob(db,id,{send:async m=>messages.push(m)},now);
 assert.equal(messages.filter(m=>m.android.notification.sound==='garden_bell').length,1);
 assert.equal(messages[1].android.notification.channelId,'garden_updates_silent_v1');
});
