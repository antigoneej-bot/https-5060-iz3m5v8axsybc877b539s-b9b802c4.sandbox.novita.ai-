import fs from 'node:fs/promises';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const root = new URL('../', import.meta.url).pathname.replace(/\/$/, '');
const {memoryDb} = await import('./memory-db.js');
const db = memoryDb();
const rows = db.rows;
const deleted = db.deleted;
class Timestamp {
 constructor(seconds, nanoseconds) {this.seconds = seconds; this.nanoseconds = nanoseconds;}
 toDate() {return new Date(this.seconds * 1000 + this.nanoseconds / 1000000);}
}
const stamp=()=>new Timestamp(Date.parse('2026-10-13T11:00:00Z') / 1000, 0);
let tokenIdentity;
let deleteAuthError;
const auth={
 async verifyIdToken(uid){return tokenIdentity ?? {uid,email:uid+'@example.invalid',email_verified:true,
  firebase:{sign_in_provider:'password'},auth_time:Date.now()/1000};},
 async deleteUser(){if(deleteAuthError)throw deleteAuthError;}, async getUser(uid){return {uid};}
};
const context=vm.createContext({console,Buffer,Date,Math,JSON,Map,Set,Object,Number,String,Error,Array,process:{env:{GARDEN_ANDROID_APP_ID:'test-app'}}});
const cache=new Map();
const stubs={
 'firebase-admin/app':{initializeApp:()=>{}},
 'firebase-admin/auth':{getAuth:()=>auth},
 'firebase-admin/app-check':{getAppCheck:()=>({verifyToken:async()=>({appId:'test-app'})})},
 'firebase-admin/firestore':{getFirestore:()=>db,Timestamp,FieldValue:{serverTimestamp:stamp,delete:()=>deleted}},
 'firebase-admin/storage':{getStorage:()=>({bucket:()=>({deleteFiles:async()=>{}})})},
 'firebase-functions/v2/https':{onRequest:(_,fn)=>fn},
 'firebase-functions/v2/pubsub':{onMessagePublished:(_,fn)=>fn},
 'firebase-functions/params':{defineSecret:()=>({value:()=>''})},
 'google-auth-library':{GoogleAuth:class{}}
};
async function load(name){
 if(cache.has(name))return cache.get(name);
 let mod;
 if(name.startsWith(root)){
  mod=new vm.SourceTextModule(await fs.readFile(name,'utf8'),{context,identifier:name});
  cache.set(name,mod);
 }else{
  const values=stubs[name]??await import(name);
  mod=new vm.SyntheticModule(Object.keys(values),function(){for(const [key,value]of Object.entries(values))this.setExport(key,value);},{context,identifier:name});
  cache.set(name,mod);
 }
 return mod;
}
const mod=await load(root+'/index.js');
await mod.link((spec, from) => load(spec.startsWith('.') ? new URL(spec, pathToFileURL(from.identifier)).pathname : spec));
await mod.evaluate();
async function call(uid,body){
 body = {deviceId: "device-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", ...body};
 let result={status:200};
 const req={method:'POST',body,rawBody:Buffer.from(JSON.stringify(body)),get:name=>name==='Authorization'?'Bearer '+uid:'test-appcheck'};
 const res={set(){return this;},status(code){result.status=code;return this;},json(value){result.body=value;return this;}};
 await mod.namespace.gardenApi(req,res);
 return result;
}

rows.set('users/bob/receivedCheers/gift1',{giftLightEssence:5,claimed:false});
const oldClient = await call('bob',{action:'claimCheer',id:'gift1'});
assert.equal(oldClient.body.error, 'client-update-required');
const first=await call('bob',{action:'claimCheerV2',id:'gift1'});
const retry=await call('bob',{action:'claimCheerV2',id:'gift1'});
assert.equal(first.status, 200);
assert.equal(first.body.amount, 5);
assert.equal(retry.body.receipt, first.body.receipt);
assert.equal(retry.body.amount, 5);
const inbox=await call('bob',{action:'listMyCheers'});
assert.equal(inbox.body.cheers[0].id, 'gift1');
const ack=await call('bob',{action:'ackCheer',id:'gift1',receipt:first.body.receipt});
assert.equal(ack.body.acknowledged, true);
assert.equal((await call('bob',{action:'claimCheerV2',id:'gift1'})).body.amount, 0);
assert.equal((await call('bob',{action:'claimCheerV2',id:'../gift1'})).status, 400);
console.log('PASS: actual routes replay pending gifts, list them after lost responses, ACK idempotently and reject unsafe old clients.');

rows.clear();
rows.set('publicGardens/bob',{nickname:'test'});
const currency = await call('alice',{action:'sendPublicCheer',gardenId:'bob',messageIndex:0,giftLightEssence:5});
assert.equal(currency.status,403);
assert.equal(currency.body.error,'currency-gifts-unavailable');
assert.equal([...rows.keys()].some(k=>k.startsWith('users/bob/receivedCheers/')), false);
rows.set('users/alice/neighbors/bob',{status:'accepted'});
rows.set('users/bob/neighbors/alice',{status:'accepted'});
const payload={action:'sendPublicCheer',gardenId:'bob',messageIndex:0,flowerKind:'tulip',reaction:'heart'};
assert.equal((await call('alice',payload)).status,200);
assert.equal((await call('alice',payload)).status,200);
assert.equal([...rows.keys()].filter(k=>k.startsWith('users/bob/receivedCheers/')).length,1);
assert.equal(rows.get('publicGardens/bob').reactions.length,1);
assert.equal((await call('alice',{...payload,messageIndex:1})).status,409);
console.log('PASS: new currency is blocked; flowers/reactions survive; retry sends one flower and one reaction.');

rows.clear();
rows.set('publicGardens/bob',{nickname:'test'});
const {accountHash} = await import('../policy.js');
rows.set(`accountLocks/${accountHash('bob')}`,{deleting:true});
assert.equal((await call('alice',payload)).body.error,'garden-not-found');
assert.equal([...rows.keys()].some(k=>k.startsWith('users/bob/receivedCheers/')),false);
console.log('PASS: sending to a deleting account cannot recreate its received-gift data.');

rows.clear();
rows.set('gardenNews/n1',{reservedCount:2,capacity:2});
rows.set('gardenNewsReservations/n1_alice',{newsId:'n1',uid:'alice',email:'alice@example.invalid',note:'test'});
rows.set('gardenNewsReservations/n1_bob',{newsId:'n1',uid:'bob'});
rows.set('users/alice',{});
rows.set('publicGardens/alice',{});
const removal=await call('alice',{action:'deleteCloudAccount'});
assert.equal(removal.status,200);
assert.equal(rows.has('users/alice'),false);
assert.equal(rows.has('publicGardens/alice'),false);
assert.equal(rows.has('gardenNewsReservations/n1_alice'),false);
assert.equal(rows.has('gardenNewsReservations/n1_bob'),true);
assert.equal(rows.get('gardenNews/n1').reservedCount,1);
assert.equal(rows.get(`accountLocks/${accountHash('alice')}`).deletionCompleted,true);
console.log('PASS: actual deletion route removes personal reservations and releases the correct seat.');

rows.clear();
deleteAuthError=new Error('simulated auth outage');
assert.equal((await call('partial-delete',{action:'deleteCloudAccount'})).status,503);
assert.equal(rows.get(`accountLocks/${accountHash('partial-delete')}`).deleted,true);
assert.notEqual(rows.get(`accountLocks/${accountHash('partial-delete')}`).deletionCompleted,true);
assert.equal((await call('partial-delete',{action:'listPublicGardens'})).body.error,'account-deleting');
deleteAuthError=null;
assert.equal((await call('partial-delete',{action:'deleteCloudAccount'})).status,200);
assert.equal(rows.get(`accountLocks/${accountHash('partial-delete')}`).deletionCompleted,true);
console.log('PASS: failed Auth deletion leaves social rejoin locked; successful retry alone marks completion.');

rows.clear();
for (const provider of ['kakao','naver','facebook']) {
 tokenIdentity={uid:`social-${provider}`,firebase:{sign_in_provider:'custom'},
  garden_social_verified:true,garden_social_provider:provider};
 assert.equal((await call('ignored',{action:'listPublicGardens'})).status,200);
}
tokenIdentity={uid:'google',firebase:{sign_in_provider:'google.com'},email_verified:false};
assert.equal((await call('ignored',{action:'listPublicGardens'})).status,200);
for (const identity of [
 {uid:'unknown-custom',firebase:{sign_in_provider:'custom'}},
 {uid:'forged-provider',firebase:{sign_in_provider:'password'},garden_social_verified:true,garden_social_provider:'facebook'},
 {uid:'anonymous',firebase:{sign_in_provider:'anonymous'},email_verified:true},
]) {
 tokenIdentity=identity;
 assert.equal((await call('ignored',{action:'listPublicGardens'})).status,403);
}
tokenIdentity={uid:'social-no-email',firebase:{sign_in_provider:'custom'},
 garden_social_verified:true,garden_social_provider:'facebook'};
rows.set('gardenNews/social-event',{capacity:10,reservedCount:0});
assert.equal((await call('ignored',{action:'reserveGardenNews',newsId:'social-event'})).status,200);
assert.equal(rows.get('gardenNewsReservations/social-event_social-no-email').email,null);
context.process.env.ADMIN_EMAILS='admin@example.invalid';
tokenIdentity.email='admin@example.invalid';
for (const action of ['adminCreateGardenNews','adminDeleteGardenNews','adminListGardenNewsReservations']) {
 assert.equal((await call('ignored',{action})).body.error,'admin-required');
}
assert.equal(typeof mod.namespace.socialAuth,'function');
console.log('PASS: Google and three verified social providers reach real garden routes; unverified/anonymous claims and admin spoofing fail; email-less reservations work.');

rows.clear();
tokenIdentity={uid:'unverified-owner',email_verified:false,firebase:{sign_in_provider:'password'},auth_time:Date.now()/1000};
rows.set('users/unverified-owner',{private:true});
assert.equal((await call('ignored',{action:'listPublicGardens'})).status,403);
assert.equal((await call('ignored',{action:'deleteCloudAccount'})).status,200);
assert.equal(rows.has('users/unverified-owner'),false);
assert.equal(rows.get(`accountLocks/${accountHash('unverified-owner')}`).deletionCompleted,true);
for (const auth_time of [undefined,null,NaN,Infinity,'100',0,Date.now()/1000-301,Date.now()/1000+60]) {
 tokenIdentity={uid:'bad-auth-time',email_verified:false,firebase:{sign_in_provider:'password'},auth_time};
 assert.equal((await call('ignored',{action:'deleteCloudAccount'})).body.error,'recent-login-required');
 assert.equal(rows.has(`accountLocks/${accountHash('bad-auth-time')}`),false);
}
for (const provider of ['anonymous',undefined,'']) {
 tokenIdentity={uid:'not-an-account',email_verified:true,firebase:{sign_in_provider:provider},auth_time:Date.now()/1000};
 assert.equal((await call('ignored',{action:'deleteCloudAccount'})).status,401);
 assert.equal(rows.has(`accountLocks/${accountHash('not-an-account')}`),false);
}
console.log('PASS: unverified-email owner can delete after recent login; ordinary access stays denied, anonymous and invalid/stale/future auth time cannot begin cleanup.');

rows.clear();
rows.set('publicGardens/account-a',{nickname:'A의 정원',seedCounts:{pine:9},privateField:'never-return'});
tokenIdentity={uid:'account-a',firebase:{sign_in_provider:'google.com'}};
const ownA=await call('ignored',{action:'getMyPublicGardenStatus',uid:'account-b',gardenId:'account-b'});
assert.equal(ownA.status,200);
assert.equal(JSON.stringify(ownA.body),JSON.stringify({published:true,nickname:'A의 정원',visibility:'public',discoveryOptIn:false,receiveGifts:true,snapshot:{seedCounts:{pine:9},equippedDecorationIds:[],treeStageIndex:0,memoryTreeStage:0,hasCheerFlowers:false,flowerKinds:[],layout:null},updatedAt:null}));
tokenIdentity={uid:'account-b',firebase:{sign_in_provider:'custom'},garden_social_verified:true,garden_social_provider:'kakao'};
const ownB=await call('ignored',{action:'getMyPublicGardenStatus',uid:'account-a',gardenId:'account-a'});
assert.equal(ownB.status,200);
assert.equal(JSON.stringify(ownB.body),JSON.stringify({published:false,nickname:null,visibility:'private',discoveryOptIn:false,receiveGifts:true,snapshot:null,updatedAt:null}));
tokenIdentity={uid:'unverified-viewer',firebase:{sign_in_provider:'password'},email_verified:false};
assert.equal((await call('ignored',{action:'getMyPublicGardenStatus'})).status,403);
tokenIdentity={uid:'account-a',firebase:{sign_in_provider:'google.com'}};
const madePrivate=await call('ignored',{action:'unpublishGarden',uid:'account-b'});
assert.equal(JSON.stringify(madePrivate.body),JSON.stringify({published:false,nickname:null}));
assert.equal((await call('ignored',{action:'getMyPublicGardenStatus'})).body.published,false);
console.log('PASS: own-publication status follows verified token UID only; account changes, injected UID and private fields cannot leak another publication.');

rows.clear();
tokenIdentity = null;
const publicSnapshot = {seedCounts:{pine:1},equippedDecorationIds:['bench'],treeStageIndex:1};
assert.equal((await call('alice',{action:'publishGarden',snapshot:publicSnapshot,nickname:'앨리스',visibility:'neighbors',discoveryOptIn:false})).status,200);
assert.equal((await call('bob',{action:'publishGarden',snapshot:publicSnapshot,nickname:'보리',visibility:'neighbors',discoveryOptIn:false})).status,200);
const bobProfile = (await call('bob',{action:'getVillageProfile'})).body;
assert.match(bobProfile.inviteCode,/^[A-F0-9]{12}$/);
assert.equal((await call('alice',{action:'lookupNeighbor',inviteCode:bobProfile.inviteCode})).body.nickname,'보리');
assert.equal((await call('alice',{action:'getNeighborGarden',gardenId:'bob'})).status,404);
assert.equal((await call('alice',{action:'requestNeighbor',inviteCode:bobProfile.inviteCode})).body.status,'outgoing');
assert.equal((await call('bob',{action:'listNeighbors'})).body.incoming.length,1);
assert.equal((await call('bob',{action:'respondNeighbor',gardenId:'alice',accept:true})).body.accepted,true);
assert.equal((await call('alice',{action:'getNeighborGarden',gardenId:'bob'})).body.garden.nickname,'보리');
assert.equal((await call('alice',{action:'sendPublicCheer',gardenId:'bob',messageIndex:0,deliveryKind:'cheer',flowerKind:null,reaction:'hug'})).status,200);
assert.equal((await call('bob',{action:'sendPublicCheer',gardenId:'alice',messageIndex:0,deliveryKind:'gift',flowerKind:'tulip'})).status,200);
const receivedFlower = (await call('alice',{action:'listMyCheers'})).body.cheers.find(value=>value.deliveryKind==='gift');
assert.equal(receivedFlower.senderNickname,'보리');
assert.equal(receivedFlower.senderGardenId,'bob');
const transferPayload = {action:'sendGardenGift',gardenId:'bob',sourceCheerId:receivedFlower.id,requestId:'route-request-1234567890'};
const transferResult = await call('alice',transferPayload);
assert.equal(transferResult.status,200);
assert.equal((await call('alice',transferPayload)).body.id,transferResult.body.id);
assert.equal((await call('alice',{action:'listMyCheers'})).body.retiredIds.includes(receivedFlower.id),true);
assert.equal((await call('alice',{action:'confirmFlowerPlanted',id:receivedFlower.id,flowerKind:'tulip'})).body.error,'cheer-transferred');
assert.equal((await call('bob',{action:'confirmFlowerPlanted',id:transferResult.body.id,flowerKind:'tulip'})).body.confirmed,true);
assert.equal((await call('bob',{action:'updateVillageProfile',visibility:'public',discoveryOptIn:true,receiveGifts:false})).body.receiveGifts,false);
assert.equal((await call('carol',{action:'listPublicGardens'})).body.gardens.length,1);
assert.equal((await call('bob',{action:'blockNeighbor',gardenId:'alice',blocked:true})).body.blocked,true);
assert.equal((await call('alice',{action:'getNeighborGarden',gardenId:'bob'})).status,404);
assert.equal((await call('alice',{action:'lookupNeighbor',inviteCode:bobProfile.inviteCode})).status,404);
assert.equal((await call('alice',{action:'listPublicGardens'})).body.gardens.length,0);
assert.equal((await call('bob',{action:'reportGarden',gardenId:'alice',reason:'spam'})).body.reported,true);
assert.equal((await call('bob',{action:'deleteCloudAccount'})).status,200);
assert.equal(rows.has(`villageInviteCodes/${bobProfile.inviteCode}`),false);
assert.equal(rows.has('villageProfiles/bob'),false);
assert.equal(rows.get(`users/alice/receivedCheers/${receivedFlower.id}`).senderId,null);
console.log('PASS: actual village routes connect two accounts, enforce scopes, send free emoji/flowers, transfer once, reject planted retired sources, block both directions and erase deleted attribution.');
rows.clear();
tokenIdentity = null;
for (const id of ['one', 'two', 'three']) {
 rows.set(`users/owner/receivedCheers/${id}`, {createdAt:new Timestamp(100, 7),claimed:true,flowerKind:'tulip',bloomConfirmed:true});
 rows.set(`villageProfiles/${id}`, {visibility:'public',discoveryOptIn:true});
 rows.set(`publicGardens/${id}`, {...publicSnapshot,nickname:id});
}
const inboxPage = await call('owner',{action:'listMyCheers',pageSize:2});
assert.equal(inboxPage.status,200);
assert.equal(inboxPage.body.cheers.length,2);
const olderPage = await call('owner',{action:'listMyCheers',pageSize:2,cursor:inboxPage.body.nextCursor});
assert.equal(olderPage.status,200);
assert.equal(olderPage.body.cheers.length,1);
assert.equal(olderPage.body.nextCursor,null);
assert.equal(new Set([...inboxPage.body.cheers,...olderPage.body.cheers].map(c=>c.id)).size,3);
const browsePage=await call('owner',{action:'listPublicGardens',pageSize:2});
assert.equal(browsePage.body.gardens.length,2);
assert.equal((await call('owner',{action:'listPublicGardens',pageSize:2,cursor:browsePage.body.nextCursor})).body.gardens.length,1);
for (const body of [{action:'listMyCheers',cursor:'bad'}, {action:'listPublicGardens',pageSize:25}]) {
 const invalid=await call('owner',body);
 assert.equal(invalid.status,400);
 assert.match(invalid.body.error,/^invalid-(cursor|page-size)$/);
}
assert.equal((await call('another',{action:'listMyCheers',cursor:inboxPage.body.nextCursor})).status,400);
const publication=await call('owner',{action:'publishGarden',snapshot:publicSnapshot,nickname:'지킬 이름',visibility:'neighbors'});
assert.equal(publication.body.updatedAt,'2026-10-13T11:00:00.000Z');
assert.equal(publication.body.snapshot.treeStageIndex,1);
const appearance=await call('owner',{action:'publishGarden',snapshot:{...publicSnapshot,treeStageIndex:2},appearanceOnly:true});
assert.equal(appearance.body.visibility,'neighbors');
assert.equal(appearance.body.nickname,'지킬 이름');
assert.equal(appearance.body.snapshot.treeStageIndex,2);
assert.equal((await call('owner',{action:'publishGarden',snapshot:publicSnapshot,appearanceOnly:true,visibility:'public'})).status,400);
console.log('PASS: actual routes paginate discovery and timestamp-tied inbox history, reject invalid/cross-account cursors with 400, return owner-only appearance/time and preserve privacy on appearance-only update.');
console.log('Local VM with fake Auth/AppCheck/Firestore/Storage; not real Firebase/device verification.');
