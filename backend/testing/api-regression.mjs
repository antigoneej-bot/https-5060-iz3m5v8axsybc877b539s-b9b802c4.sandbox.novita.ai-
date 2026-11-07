import fs from 'node:fs/promises';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import {pathToFileURL, fileURLToPath} from 'node:url';
const root = fileURLToPath(new URL('../', import.meta.url)).replace(/[\\/]$/, '');
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
let appCheckId='test-app';
let deleteAuthError;
let storageMetadataError;
let storageDeleteCalls = 0;
const backupFiles = new Map();
const backupBucket = {
 async getMetadata() {if (storageMetadataError) throw storageMetadataError; return [{name:'test-private-backups'}];},
 async getFiles({prefix,maxResults}) {
  if (storageMetadataError) throw storageMetadataError;
  return [[...backupFiles.keys()].filter(name=>name.startsWith(prefix)).slice(0,maxResults).map(name=>({name}))];
 },
 file(name) {return {
  async save(data) {backupFiles.set(name, data);},
  async download() {if (!backupFiles.has(name)) throw new Error('not-found'); return [Buffer.from(backupFiles.get(name))];},
  async delete() {backupFiles.delete(name);},
 };},
 async deleteFiles({prefix}) {storageDeleteCalls++; for (const name of backupFiles.keys()) if (name.startsWith(prefix)) backupFiles.delete(name);},
};
const auth={
 async verifyIdToken(uid){return tokenIdentity ?? {uid,email:uid+'@example.invalid',email_verified:true,
  firebase:{sign_in_provider:'password'},auth_time:Date.now()/1000};},
 async deleteUser(){if(deleteAuthError)throw deleteAuthError;}, async getUser(uid){return uid==='audited-admin' ? {uid,email:'antigone.ej@gmail.com',emailVerified:true} : {uid};}
};
const context=vm.createContext({console,Buffer,Date,Math,JSON,structuredClone,Map,Set,Object,Number,String,Error,Array,process:{env:{GARDEN_ANDROID_APP_ID:'test-app'}}});
const cache=new Map();
const registeredCloudEvents=new Map();
const stubs={
 '@google-cloud/functions-framework':{cloudEvent:(name,handler)=>registeredCloudEvents.set(name,handler)},
 'firebase-admin/app':{initializeApp:()=>{}},
 'firebase-admin/auth':{getAuth:()=>auth},
 'firebase-admin/app-check':{getAppCheck:()=>({verifyToken:async()=>({appId:appCheckId})})},
 'firebase-admin/firestore':{getFirestore:()=>db,Timestamp,FieldValue:{serverTimestamp:stamp,delete:()=>deleted}},
 'firebase-admin/messaging':{getMessaging:()=>({send:async()=> 'test-message-id'})},
 'firebase-functions/v2/firestore':{onDocumentCreated:(_,fn)=>fn},
 'firebase-admin/storage':{getStorage:()=>({bucket:()=>backupBucket})},
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
await mod.link((spec, from) => load(spec.startsWith('.') ? fileURLToPath(new URL(spec, pathToFileURL(from.identifier))) : spec));
await mod.evaluate();
assert.equal(registeredCloudEvents.get('playNotifications'),mod.namespace.playNotifications);
assert.equal(registeredCloudEvents.get('gardenPush'),mod.namespace.gardenPush);
async function call(uid,body){
 body = {deviceId: "device-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", ...body};
 let result={status:200};
 const req={method:'POST',body,rawBody:Buffer.from(JSON.stringify(body)),get:name=>name==='Authorization'?'Bearer '+uid:'test-appcheck'};
 const res={set(){return this;},status(code){result.status=code;return this;},json(value){result.body=value;return this;}};
 await mod.namespace.gardenApi(req,res);
 return result;
}

// Consent is enforced by the actual API, not merely a widget.
const combinedEntry = await call('entry-user', {action:'getVillageEntry'});
assert.equal(combinedEntry.status, 200);
assert.match(combinedEntry.body.profile.inviteCode, /^[A-F0-9]{12}$/);
assert.deepEqual(JSON.parse(JSON.stringify(combinedEntry.body.neighbors)), {neighbors:[], incoming:[], outgoing:[], blocked:[]});
assert.equal((await call('consent-user',{action:'publishGarden'})).body.error,'community-consent-required');
assert.equal((await call('consent-user',{action:'acceptCommunityPolicy',version:'old'})).status,403);
assert.equal((await call('consent-user',{action:'acceptCommunityPolicy',version:'2026-10-31'})).status,200);
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});

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
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
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
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
rows.set('publicGardens/bob',{nickname:'test'});
const {accountHash} = await import('../policy.js');
rows.set(`accountLocks/${accountHash('bob')}`,{deleting:true});
assert.equal((await call('alice',payload)).body.error,'garden-not-found');
assert.equal([...rows.keys()].some(k=>k.startsWith('users/bob/receivedCheers/')),false);
console.log('PASS: sending to a deleting account cannot recreate its received-gift data.');

rows.clear();
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
rows.set('gardenNews/n1',{reservedCount:2,capacity:2});
rows.set('gardenNewsReservations/n1_alice',{newsId:'n1',uid:'alice',email:'alice@example.invalid',note:'test'});
rows.set('gardenNewsReservations/n1_bob',{newsId:'n1',uid:'bob'});
rows.set('users/alice',{});
rows.set('publicGardens/alice',{});
rows.set('socialAuthIdentities/alice-key',{provider:'kakao',generation:2,uid:'alice'});
rows.set('socialAuthIdentities/bob-key',{provider:'naver',generation:1,uid:'bob'});
const removal=await call('alice',{action:'deleteCloudAccount'});
assert.equal(removal.status,200);
assert.equal(rows.get('socialAuthIdentities/alice-key').uid,undefined);
assert.equal(rows.get('socialAuthIdentities/alice-key').generation,2);
assert.equal(rows.get('socialAuthIdentities/alice-key').provider,'kakao');
assert.equal(rows.get('socialAuthIdentities/bob-key').uid,'bob');
assert.equal(rows.has('users/alice'),false);
assert.equal(rows.has('publicGardens/alice'),false);
assert.equal(rows.has('gardenNewsReservations/n1_alice'),false);
assert.equal(rows.has('gardenNewsReservations/n1_bob'),true);
assert.equal(rows.get('gardenNews/n1').reservedCount,1);
assert.equal(rows.get(`accountLocks/${accountHash('alice')}`).deletionCompleted,true);
console.log('PASS: actual deletion route removes personal reservations and releases the correct seat.');

rows.clear();
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
rows.set('socialAuthIdentities/partial-key',{provider:'naver',generation:0,uid:'partial-delete'});
deleteAuthError=new Error('simulated auth outage');
assert.equal((await call('partial-delete',{action:'deleteCloudAccount'})).status,503);
assert.equal(rows.get(`accountLocks/${accountHash('partial-delete')}`).deleted,true);
assert.equal(rows.get('socialAuthIdentities/partial-key').uid,undefined);
assert.equal(rows.get('socialAuthIdentities/partial-key').generation,0);
assert.notEqual(rows.get(`accountLocks/${accountHash('partial-delete')}`).deletionCompleted,true);
assert.equal((await call('partial-delete',{action:'listPublicGardens'})).body.error,'account-deleting');
deleteAuthError=null;
assert.equal((await call('partial-delete',{action:'deleteCloudAccount'})).status,200);
assert.equal(rows.get(`accountLocks/${accountHash('partial-delete')}`).deletionCompleted,true);
console.log('PASS: failed Auth deletion leaves social rejoin locked; successful retry alone marks completion.');

rows.clear();
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
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
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
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
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
rows.set('publicGardens/account-a',{nickname:'A의 정원',seedCounts:{pine:9},privateField:'never-return'});
tokenIdentity={uid:'account-a',firebase:{sign_in_provider:'google.com'}};
const ownA=await call('ignored',{action:'getMyPublicGardenStatus',uid:'account-b',gardenId:'account-b'});
assert.equal(ownA.status,200);
assert.equal(JSON.stringify(ownA.body),JSON.stringify({published:true,nickname:'A의 정원',visibility:'public',discoveryOptIn:false,randomVisitOptIn:false,receiveGifts:true,snapshot:{seedCounts:{pine:9},equippedDecorationIds:[],treeStageIndex:0,memoryTreeStage:0,hasCheerFlowers:false,flowerKinds:[],layout:null},updatedAt:null}));
tokenIdentity={uid:'account-b',firebase:{sign_in_provider:'custom'},garden_social_verified:true,garden_social_provider:'kakao'};
const ownB=await call('ignored',{action:'getMyPublicGardenStatus',uid:'account-a',gardenId:'account-a'});
assert.equal(ownB.status,200);
assert.equal(JSON.stringify(ownB.body),JSON.stringify({published:false,nickname:null,visibility:'private',discoveryOptIn:false,randomVisitOptIn:false,receiveGifts:true,snapshot:null,updatedAt:null}));
tokenIdentity={uid:'unverified-viewer',firebase:{sign_in_provider:'password'},email_verified:false};
assert.equal((await call('ignored',{action:'getMyPublicGardenStatus'})).status,403);
tokenIdentity={uid:'account-a',firebase:{sign_in_provider:'google.com'}};
const madePrivate=await call('ignored',{action:'unpublishGarden',uid:'account-b'});
assert.equal(JSON.stringify(madePrivate.body),JSON.stringify({published:false,nickname:null}));
assert.equal((await call('ignored',{action:'getMyPublicGardenStatus'})).body.published,false);
console.log('PASS: own-publication status follows verified token UID only; account changes, injected UID and private fields cannot leak another publication.');

rows.clear();
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
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
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
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

rows.clear();
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
const newsAdminIdentity = {uid:'news-admin-kakao',firebase:{sign_in_provider:'custom'},
 garden_social_verified:true,garden_social_provider:'kakao',garden_news_admin:true};
tokenIdentity = newsAdminIdentity;
const newsInput = {title:'클래스 안내',body:'테스트 클래스입니다.',type:'event',status:'recruiting',capacity:2};
const createdNews = await call('ignored',{action:'adminCreateGardenNews',news:newsInput});
assert.equal(createdNews.status,200);
const newsId = createdNews.body.id;
assert.equal(rows.get(`gardenNews/${newsId}`).createdBy,newsAdminIdentity.uid);
assert.equal((await call('ignored',{action:'adminUpdateGardenNews',id:newsId,
 news:{...newsInput,title:'클래스 안내 수정'}})).status,200);
assert.equal(rows.get(`gardenNews/${newsId}`).title,'클래스 안내 수정');
tokenIdentity = {...newsAdminIdentity,uid:'news-member',garden_news_admin:false};
assert.equal((await call('ignored',{action:'reserveGardenNews',newsId})).status,200);
tokenIdentity = newsAdminIdentity;
const attendees = await call('ignored',{action:'adminListGardenNewsReservations',newsId});
assert.equal(attendees.status,200);
assert.equal(attendees.body.reservations.length,1);
assert.equal(attendees.body.reservations[0].email,null);
const adminStatus = await call('ignored',{action:'status'});
assert.equal(adminStatus.status,200);
assert.equal(adminStatus.body.active,false);
assert.equal(adminStatus.body.state,'free');
const adminBackup = await call('ignored',{action:'backup',envelope:{}});
assert.equal(adminBackup.status,403);
assert.equal(adminBackup.body.error,'subscription-required');
assert.equal((await call('ignored',{action:'adminDeleteGardenNews',id:newsId})).status,200);
assert.equal(rows.has(`gardenNews/${newsId}`),false);
assert.equal(rows.has(`gardenNewsReservations/${newsId}_news-member`),false);
console.log('PASS: claimed Kakao news admin creates, updates, reads attendees and deletes news; scoped role does not grant subscription or paid cloud backup.');

rows.clear();
for (const uid of ['alice','bob','carol','owner']) rows.set(`users/${uid}/settings/community`, {version:'2026-10-31'});
rows.set('gardenNews/protected-news',{...newsInput,reservedCount:1});
rows.set('gardenNewsReservations/protected-news_attendee',{newsId:'protected-news',uid:'attendee',email:'private@example.invalid'});
const newsAdminActions = ['adminCreateGardenNews','adminUpdateGardenNews',
 'adminListGardenNewsReservations','adminDeleteGardenNews'];
for (const [index, identity] of [
 {...newsAdminIdentity,uid:'ordinary-kakao',garden_news_admin:undefined},
 {...newsAdminIdentity,uid:'string-role',garden_news_admin:'true'},
 {uid:'ordinary-google',firebase:{sign_in_provider:'google.com'},email:'member@example.invalid',email_verified:true},
 {...newsAdminIdentity,uid:'unverified-admin-email',garden_news_admin:false,email:'antigone.ej@gmail.com',email_verified:false},
].entries()) {
 tokenIdentity = identity;
 for (const action of newsAdminActions) {
  const denied = await call('ignored',{action,id:'protected-news',newsId:'protected-news',news:newsInput,
   uid:newsAdminIdentity.uid,email:'antigone.ej@gmail.com',email_verified:true,
   garden_news_admin:true,identity:newsAdminIdentity,customClaims:{garden_news_admin:true}});
  assert.equal(denied.status,403,`${index}: ${action}`);
  assert.equal(denied.body.error,'admin-required',`${index}: ${action}`);
 }
}
assert.equal([...rows.keys()].filter(key=>key.startsWith('gardenNews/')).length,1);
assert.equal(rows.get('gardenNews/protected-news').title,newsInput.title);
assert.equal(rows.has('gardenNewsReservations/protected-news_attendee'),true);
for (const identity of [
 {uid:'untrusted-custom',firebase:{sign_in_provider:'custom'},garden_news_admin:true},
 {...newsAdminIdentity,uid:'anonymous-news-admin',firebase:{sign_in_provider:'anonymous'}},
 {...newsAdminIdentity,uid:''},
]) {
 tokenIdentity=identity;
 assert.equal((await call('ignored',{action:'adminCreateGardenNews',news:newsInput})).body.error,'verify-email');
}
tokenIdentity={uid:'legacy-news-admin',firebase:{sign_in_provider:'password'},
 email:'antigone.ej@gmail.com',email_verified:true};
assert.equal((await call('ignored',{action:'adminListGardenNewsReservations',newsId:'protected-news'})).status,200);
console.log('PASS: unclaimed members, nonboolean claims, unverified admin emails and forged request fields cannot manage news; existing trusted-account and legacy-admin checks remain effective.');
console.log('Local VM with fake Auth/AppCheck/Firestore/Storage; not real Firebase/device verification.');

tokenIdentity=null;
// Real API boundary: free callers cannot provision an orchard or mutate it.
for (const action of ['getOrchard', 'mutateOrchard']) {
 const denied = await call('free-orchard-user', {action, op:'water',kind:'apple'});
 assert.equal(denied.status, 403);
 assert.equal(denied.body.error, 'subscription-required');
}
assert.equal(rows.has('users/free-orchard-user/orchard/state'), false);
// Existing paid data is preserved when access is denied.
rows.set('users/expired-orchard-user/orchard/state', {stock:{apple:25}});
await call('expired-orchard-user', {action:'getOrchard'});
assert.equal(rows.get('users/expired-orchard-user/orchard/state').stock.apple,25);

// Preserve the existing verified-administrator benefit; no fabricated receipt.
assert.equal((await call('audited-admin',{action:'getOrchard'})).status,200);
assert.equal(rows.has('users/audited-admin/orchard/state'),true);

// Legacy clients need no community acceptance to read or save PRIVATE data.
rows.clear();
backupFiles.clear();
tokenIdentity = null;
context.process.env.PREMIUM_TEST_ACCESS = 'true';
delete context.process.env.RELEASE_ENV;
rows.set('users/legacy-private/private/journal', {text:'keep-existing-record'});
rows.set('users/other-private/private/journal', {text:'other-owner'});
const envelope = {format:'maeumnyang-backup',version:1,
 salt:Buffer.alloc(16).toString('base64'),nonce:Buffer.alloc(12).toString('base64'),
 mac:Buffer.alloc(16).toString('base64'),ciphertext:Buffer.from('encrypted-records').toString('base64')};
assert.equal((await call('legacy-private',{action:'status'})).status,200);
const savedPrivate = await call('legacy-private',{action:'backup',envelope,uid:'other-private'});
assert.equal(savedPrivate.status,200);
const privateBackupId = savedPrivate.body.id;
assert.equal(backupFiles.has(`backups/legacy-private/${privateBackupId}.json`),true);
assert.equal(backupFiles.has(`backups/other-private/${privateBackupId}.json`),false);
const listedPrivate = await call('legacy-private',{action:'listBackups'});
assert.equal(listedPrivate.status,200);
assert.equal(listedPrivate.body.versions[0].id,privateBackupId);
const recoveredPrivate = await call('legacy-private',{action:'downloadBackup',id:privateBackupId});
assert.equal(recoveredPrivate.status,200);
assert.deepEqual(recoveredPrivate.body.envelope,envelope);
const outsider = await call('other-private',{action:'downloadBackup',id:privateBackupId,uid:'legacy-private'});
assert.notEqual(outsider.status,200);
assert.equal(outsider.body.envelope,undefined);
assert.deepEqual((await call('other-private',{action:'listBackups'})).body.versions,[]);
assert.equal((await call('legacy-private',{action:'downloadBackup',id:'../other-private/private'})).status,400);
assert.equal(rows.has('users/legacy-private/settings/community'),false);
assert.equal(rows.get('users/legacy-private/private/journal').text,'keep-existing-record');
assert.equal(rows.get('users/other-private/private/journal').text,'other-owner');

// No fabricated acceptance: the same legacy identity still cannot publish.
assert.equal((await call('legacy-private',{action:'publishGarden'})).body.error,'community-consent-required');
assert.equal((await call('legacy-private',{action:'acceptCommunityPolicy',version:'old'})).body.error,'community-consent-required');
assert.equal(rows.has('users/legacy-private/settings/community'),false);
rows.set('users/legacy-private/settings/community',{suspended:true,version:'old'});
assert.equal((await call('legacy-private',{action:'listBackups'})).status,200);
assert.equal((await call('legacy-private',{action:'downloadBackup',id:privateBackupId})).status,200);
assert.equal((await call('legacy-private',{action:'publishGarden'})).body.error,'community-suspended');
console.log('PASS: legacy/suspended private backup save, list, recovery and status remain independent of community consent; owner paths cannot be forged.');

// Missing/forbidden configured Storage must not start destructive cleanup.
const beforeStorageDeletes = storageDeleteCalls;
rows.set('publicGardens/legacy-private',{nickname:'existing-public-garden'});
rows.set('socialAuthIdentities/legacy-private-key',{provider:'kakao',generation:3,uid:'legacy-private'});
rows.set('gardenNewsReservations/n1_legacy-private',{newsId:'n1',uid:'legacy-private'});
for (const code of [404,403]) {
 storageMetadataError = Object.assign(new Error('simulated-unavailable-bucket'),{code});
 const blocked = await call('legacy-private',{action:'deleteCloudAccount'});
 assert.equal(blocked.status,503);
 assert.equal(blocked.body.error,'backup-storage-unavailable');
 assert.equal(rows.get('users/legacy-private/private/journal').text,'keep-existing-record');
 assert.equal(rows.get('publicGardens/legacy-private').nickname,'existing-public-garden');
 assert.equal(rows.get('socialAuthIdentities/legacy-private-key').uid,'legacy-private');
 assert.equal(rows.has('gardenNewsReservations/n1_legacy-private'),true);
 assert.notEqual(rows.get(`accountLocks/${accountHash('legacy-private')}`).deleting,true);
 assert.equal(storageDeleteCalls,beforeStorageDeletes);
 assert.equal(backupFiles.has(`backups/legacy-private/${privateBackupId}.json`),true);
 assert.equal((await call('legacy-private',{action:'listBackups'})).status,200);
 assert.equal((await call('legacy-private',{action:'status'})).status,200);
}
storageMetadataError = null;
delete context.process.env.PREMIUM_TEST_ACCESS;
console.log('PASS: Storage 404/403 abort deletion before private records, reservations, identities, files or deletion markers are removed.');

// New discovery actions still pass through the real account/App Check/consent
// and rate-limit controller above; private preferences never select a body UID.
rows.clear(); tokenIdentity = null;
rows.set('users/public-owner/settings/community',{version:'2026-10-31'});
assert.equal((await call('public-owner',{action:'publishGarden',snapshot:publicSnapshot,visibility:'public',discoveryOptIn:true,randomVisitOptIn:true,nickname:'공개 정원'})).status,200);
const discovery = await call('visitor',{action:'randomPublicGarden',uid:'public-owner'});
assert.equal(discovery.status,200);assert.equal(discovery.body.garden.gardenId,'public-owner');
assert.equal((await call('visitor',{action:'setFavoriteGarden',gardenId:'public-owner',favorite:true,uid:'public-owner'})).status,200);
assert.equal(rows.has('users/visitor/favoriteGardens/public-owner'),true);
assert.equal(rows.has('users/public-owner/favoriteGardens/public-owner'),false);
assert.equal((await call('visitor',{action:'getPublicVisitGarden',gardenId:'public-owner'})).body.garden.isFavorite,true);
assert.equal((await call('visitor',{action:'updateVillageProfile',randomVisitOptIn:true,visibility:'public',discoveryOptIn:true})).body.error,'community-consent-required');
const oldUser=auth.getUser;
auth.getUser=async()=>{throw Object.assign(new Error('missing-user'),{code:'auth/user-not-found'});};
assert.equal((await call('visitor',{action:'getPublicVisitGarden',gardenId:'public-owner'})).status,404);
auth.getUser=oldUser;
appCheckId='another-app';
assert.equal((await call('visitor',{action:'randomPublicGarden'})).status,401);
appCheckId='test-app';
assert.equal((await call('public-owner',{action:'updateVillageProfile',visibility:'private'})).status,200);
assert.equal((await call('visitor',{action:'getPublicVisitGarden',gardenId:'public-owner'})).status,404);
assert.equal((await call('visitor',{action:'listFavoriteGardens'})).body.gardens.length,0);
for(let i=0;i<20;i++)assert.equal((await call('rate-viewer',{action:'randomPublicGarden'})).status,200);
assert.equal((await call('rate-viewer',{action:'randomPublicGarden'})).status,429);
console.log('PASS: discovery/favorite routes enforce App Check, current Auth existence, owner UID, consent, withdrawal and the shared 20/minute server limit.');
