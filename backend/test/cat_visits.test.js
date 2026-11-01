import test from 'node:test';
import assert from 'node:assert/strict';
import {memoryDb} from '../testing/memory-db.js';
import * as cats from '../cat-visits.js';
import {accountHash} from '../policy.js';
const now=1780000000000, host={coat:'ginger',stage:3,name:'몽이'}, guest={coat:'white',stage:0,name:'아기'};
function prepared(){return memoryDb({
 'publicGardens/host':{nickname:'정원사',seedCounts:{},equippedDecorationIds:[]},
 'villageProfiles/host':{visibility:'neighbors'},
 'users/host/neighbors/guest':{status:'accepted'},
 'users/guest/neighbors/host':{status:'accepted'},
});}
const invite=db=>cats.inviteCatVisit(db,'host',{gardenId:'guest',cat:host},{now});
const accept=(db,inv)=>cats.respondCatVisit(db,'guest',{gardenId:'host',invitationId:inv.id,accept:true,cat:guest},{now:now+1000});
test('offline invite, accept and persistent history expose only public cat appearance',async()=>{
 const db=prepared();const {invitation}=await invite(db);
 assert.equal((await cats.listCatVisits(db,'guest',{}, {now})).invitations.length,1);
 const {visit}=await accept(db,invitation);
 assert.deepEqual(visit.hostCat,host);assert.deepEqual(visit.guestCat,guest);
 assert.equal((await cats.listCatVisits(db,'host',{}, {now})).memories.length,1);
 assert.equal((await cats.getCatVisit(db,'guest',{visitId:visit.id},{now:now+2000})).visit.id,visit.id);
 assert.equal((await cats.listCatVisits(db,'stranger',{}, {now})).memories.length,0);
 await assert.rejects(cats.getCatVisit(db,'stranger',{visitId:visit.id},{now}),/cat-visit-unavailable/);
 await assert.rejects(cats.getCatVisit(db,'host',{visitId:visit.id},{now}),/cat-visit-unavailable/);
});
test('retries and concurrent acceptance create exactly one visit and reject changed cat payload',async()=>{
 const db=prepared(); const {invitation}=await invite(db);
 assert.equal((await invite(db)).invitation.id,invitation.id);
 await assert.rejects(cats.inviteCatVisit(db,'host',{gardenId:'guest',cat:{...host,coat:'black'}},{now}),/request-conflict/);
 await Promise.all([accept(db,invitation),accept(db,invitation)]);
 assert.equal((await db.collection('users/host/catVisits').get()).docs.length,1);
 await assert.rejects(cats.respondCatVisit(db,'guest',{gardenId:'host',invitationId:invitation.id,accept:true,cat:{...guest,stage:1}},{now}),/request-conflict/);
});
test('private host, either block, unfriend and deleted accounts cannot invite or accept',async()=>{
 for(const [path,data] of [
 ['villageProfiles/host',{visibility:'private'}],
 ['users/host/blockedNeighbors/guest',{}],['users/guest/blockedNeighbors/host',{}],
 ['users/guest/neighbors/host',{status:'none'}],
 [`accountLocks/${accountHash('host')}`,{deleted:true}],
 [`accountLocks/${accountHash('guest')}`,{deleting:true}],['users/host/neighbors/guest',{status:'none'}],
 ]) {
  const db=prepared(), {invitation}=await invite(db);await db.doc(path).set(data);
  await assert.rejects(accept(db,invitation),/cat-visit-unavailable/);
  await assert.rejects(invite(db),/cat-visit-unavailable/);
  assert.equal((await cats.listCatVisits(db,'guest',{}, {now})).invitations.length,0);
 }
});
test('expiry, forged sender, mismatched token, declined and cancelled invitations are denied',async()=>{
 const db=prepared(),{invitation}=await invite(db);
 await assert.rejects(cats.respondCatVisit(db,'guest',{gardenId:'host',invitationId:invitation.id,accept:true,cat:guest},{now:now+8*86400000}),/cat-visit-unavailable/);
 await assert.rejects(cats.respondCatVisit(db,'guest',{gardenId:'host',invitationId:'wrong',accept:true,cat:guest},{now}),/cat-visit-unavailable/);
 await assert.rejects(cats.cancelCatVisit(db,'stranger',{gardenId:'guest',invitationId:invitation.id}),/cat-visit-unavailable/);
 await cats.cancelCatVisit(db,'host',{gardenId:'guest',invitationId:invitation.id});
 await assert.rejects(accept(db,invitation),/cat-visit-unavailable/);
 await assert.rejects(invite(db),/cat-invite-daily-limit/);
 const db2=prepared(),next=(await invite(db2)).invitation;
 await cats.respondCatVisit(db2,'guest',{gardenId:'host',invitationId:next.id,accept:false},{now});
 await assert.rejects(accept(db2,next),/cat-visit-unavailable/);
});
test('active visits expire and recheck bilateral access; deletion removes peer copies',async()=>{
 const db=prepared(),{invitation}=await invite(db),{visit}=await accept(db,invitation);
 await assert.rejects(cats.getCatVisit(db,'guest',{visitId:visit.id},{now:now+31*60000}),/cat-visit-unavailable/);
 await db.doc('users/host/blockedNeighbors/guest').set({});
 await assert.rejects(cats.getCatVisit(db,'guest',{visitId:visit.id},{now:now+2000}),/cat-visit-unavailable/);
 await cats.removeCatVisits(db,'guest');
 assert.equal((await db.collection('users/host/catVisits').get()).docs.length,0);
 assert.equal((await db.collection('users/host/catInvitationsSent').get()).docs.length,0);
});
test('appearance cannot contain diary fields, unknown coats or invalid growth stages',()=>{
 for(const bad of [{...host,diary:'private'},{...host,coat:'../../other'},{...host,stage:4},{...host,name:'x'.repeat(21)}])assert.throws(()=>cats.catAppearance(bad),/invalid-cat-visit/);
});
